#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""tv-show / tv-play 共用的工具：找 TCL 电视自带的 DLNA 渲染器、推流、控制播放。

不单独运行，由同目录的 tv-show（图片）/ tv-play（视频）import。
细节和实测数据见 ../TCL电视投屏.md「在电视上显示图片 / 播放视频（DLNA）」。
"""

import json
import os
import re
import shutil
import signal
import socket
import subprocess
import sys
import threading
import time
import urllib.error
import urllib.request
import xml.etree.ElementTree as ET
from urllib.parse import urljoin
from xml.sax.saxutils import escape as xesc

TV_ADDR = os.environ.get("TCL_TV_ADDR", "192.168.144.188:5555")
TV_HOST = TV_ADDR.rsplit(":", 1)[0] if ":" in TV_ADDR else TV_ADDR
TV_DIR = os.environ.get("TCL_TV_DIR", os.path.expanduser("~/apps/tv"))
RUNTIME = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))

AVT_URN = "urn:schemas-upnp-org:service:AVTransport:1"
RENDERER_ST = "urn:schemas-upnp-org:device:MediaRenderer:1"
DEV_NS = "{urn:schemas-upnp-org:device-1-0}"
SSDP = ("239.255.255.250", 1900)
# 实测出来的电视端脾气（脚本里都绕开了）：
#   * GetCurrentTransportActions 返回空、SetNextAVTransportURI 401 → 没有"下一集"，
#     连播只能靠本机守护进程轮询状态、播完再推下一个
#   * RenderingControl.SetVolume 返回 200 但音量不变 → 音量只能用遥控器
#   * AVTransport 的 Pause/Play 时灵时不灵（402 Invalid Args / 701 Transition not available，
#     开播后几十秒内几乎必拒，之后也可能拒），**但 adb 发遥控媒体键 100% 可靠**，
#     所以暂停/继续优先走 keyevent（见 media_key），DMR 只当兜底
#   * Seek（DMR）反而一直好使，快进快退键（89/90/方向键）在播放器里没用


# ------------------------------------------------------------------ 日志 / 状态
def log(tag, msg):
    line = "%s %s\n" % (time.strftime("%F %T"), msg)
    try:
        os.makedirs(TV_DIR, exist_ok=True)
        with open(os.path.join(TV_DIR, "%s.log" % tag), "a", encoding="utf-8") as f:
            f.write(line)
    except OSError:
        pass
    sys.stderr.write(line)
    sys.stderr.flush()


def note(tag, title, body=""):
    try:
        subprocess.Popen(["notify-send", "-a", tag, title, body],
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except OSError:
        pass


def state_path(tag):
    return os.path.join(RUNTIME, "%s.state" % tag)


def read_state(tag):
    try:
        with open(state_path(tag), encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def write_state(tag, d):
    path = state_path(tag)
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(d, f)
    os.replace(tmp, path)


def clear_state(tag, pid=None):
    """删掉状态文件（只删自己的，避免把刚接管的新进程的状态删了）。"""
    path = state_path(tag)
    if pid is not None and read_state(tag).get("pid") != pid:
        return
    if os.path.exists(path):
        os.unlink(path)


def pid_alive(pid):
    try:
        os.kill(pid, 0)
        return True
    except (OSError, TypeError):
        return False


def wait_ready(tag, pid, key, timeout=60):
    """等后台进程把状态写出来（key 出现在 state 里），返回最终的 state dict。

    启动是异步的：子进程要先做 tv-on/CEC 唤醒 + SSDP 发现 + 建 HTTP 服务，
    这段时间父进程不该骗用户说"已开播"。
    """
    deadline = time.time() + timeout
    while time.time() < deadline:
        st = read_state(tag)
        if st.get(key):
            return st
        if not pid_alive(pid):
            break
        time.sleep(0.5)
    return read_state(tag)


def kill_daemon(tag, quiet=True):
    """停掉同名脚本的后台进程（不带确认，给另一个脚本抢渲染器前用）。"""
    pid = read_state(tag).get("pid")
    if not pid_alive(pid):
        return False
    try:
        os.kill(pid, signal.SIGTERM)
    except OSError:
        return False
    for _ in range(30):
        if not pid_alive(pid):
            return True
        time.sleep(0.1)
    try:
        os.kill(pid, signal.SIGKILL)
    except OSError:
        pass
    if not quiet:
        log(tag, "已强杀残留进程 %s" % pid)
    return True


# -------------------------------------------------------------------- 网络
def local_ip(host=TV_HOST):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect((host, 9))
        return s.getsockname()[0]
    finally:
        s.close()


def find_adb():
    """按 tv-*.sh 同一套顺序找 adb。"""
    cand = [os.environ.get("ADB", ""), shutil.which("adb") or ""]
    cand += [os.path.expanduser(p) for p in
             ("~/apps/android-studio/android/sdk/platform-tools/adb",
              "~/apps/Android/Sdk/platform-tools/adb", "~/Android/Sdk/platform-tools/adb")]
    cand.append(os.path.join(TV_DIR, "adb"))
    for c in cand:
        if c and os.path.isfile(c) and os.access(c, os.X_OK):
            return c
    return ""


def media_key(code, tag="", connect=True):
    """adb 发一个遥控按键（127=暂停 126=播放 85=播放/暂停）。返回是否成功。"""
    adb = find_adb()
    if not adb:
        log(tag, "没找到 adb，用不了遥控键")
        return False
    try:
        if connect:
            subprocess.run([adb, "connect", TV_ADDR], timeout=10,
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        r = subprocess.run([adb, "-s", TV_ADDR, "shell", "input", "keyevent", str(code)],
                           timeout=20, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        log(tag, "adb keyevent %s → %s" % (code, "ok" if r.returncode == 0 else "失败"))
        return r.returncode == 0
    except (subprocess.TimeoutExpired, OSError) as e:
        log(tag, "adb keyevent %s 出错: %s" % (code, e))
        return False


def ssdp_renderers(timeout=3.0):
    """M-SEARCH 找 MediaRenderer，返回 [(ip, location)]。"""
    msg = ("M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\n"
           'MAN: "ssdp:discover"\r\nMX: 2\r\nST: %s\r\n\r\n' % RENDERER_ST).encode()
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.setsockopt(socket.IPPROTO_IP, socket.IP_MULTICAST_TTL, 2)
    s.settimeout(timeout)
    try:
        for _ in range(2):
            s.sendto(msg, SSDP)
        found, deadline = [], time.time() + timeout
        while time.time() < deadline:
            try:
                data, addr = s.recvfrom(65535)
            except socket.timeout:
                break
            head = {}
            for line in data.decode(errors="replace").splitlines():
                if ":" in line:
                    k, v = line.split(":", 1)
                    head[k.strip().lower()] = v.strip()
            if RENDERER_ST in head.get("st", "") and head.get("location"):
                found.append((addr[0], head["location"]))
        return found
    finally:
        s.close()


def _service_url(location, svc):
    with urllib.request.urlopen(location, timeout=5) as r:
        root = ET.fromstring(r.read())
    for s in root.iter(DEV_NS + "service"):
        t = s.findtext(DEV_NS + "serviceType") or ""
        c = s.findtext(DEV_NS + "controlURL") or ""
        if t.startswith("urn:schemas-upnp-org:service:%s:" % svc) and c:
            return urljoin(location, c)
    raise RuntimeError("渲染器没有 %s 服务: %s" % (svc, location))


def wake_tv(tag):
    """复用 tv-on.sh：已亮秒退、画报屏保发 KEYCODE_WAKEUP、整机待机走树莓派 CEC。"""
    for cand in (os.path.join(SCRIPT_DIR, "tv-on.sh"),
                 os.path.expanduser("~/.local/bin/tv-on.sh"),
                 os.path.join(TV_DIR, "tv-on.sh")):
        if os.path.isfile(cand):
            log(tag, "先唤醒电视: %s" % cand)
            subprocess.run([cand], timeout=180, check=False)
            return True
    log(tag, "找不到 tv-on.sh，跳过唤醒（电视关着就先手动开机）")
    return False


def discover(tag, svc="AVTransport", tries=20, wait=3.0, wake=True, fallback=None):
    """找到电视的 AVTransport 控制地址。

    电视待机时渲染器一起断电（SSDP 收不到），所以先唤醒；冷启动要 40~100 秒，
    所以轮询次数给得比较宽。控制地址的端口每次重启都会变（17002 → 16606），
    绝对不能写死。
    """
    if wake and not any(ip == TV_HOST for ip, _ in ssdp_renderers(1.5)):
        wake_tv(tag)
    for i in range(tries):
        for ip, loc in ssdp_renderers(2.0):
            if ip != TV_HOST:
                continue
            try:
                url = _service_url(loc, svc)
            except (OSError, ET.ParseError, RuntimeError) as e:
                log(tag, "解析 device 描述失败: %s" % e)
                continue
            log(tag, "渲染器 %s → %s" % (ip, url))
            return url
        time.sleep(wait)
    if fallback:
        log(tag, "SSDP 没找到，沿用上次地址: %s" % fallback)
        return fallback
    raise RuntimeError("没找到电视的 DLNA 渲染器（电视没开？）")


# --------------------------------------------------------------------- SOAP
def soap(ctrl, action, args=None, urn=AVT_URN):
    body = ('<?xml version="1.0"?><s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" '
            's:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body>'
            "<u:%s xmlns:u=\"%s\">" % (action, urn))
    for k, v in (args or {}).items():
        body += "<%s>%s</%s>" % (k, xesc(str(v)), k)
    body += "</u:%s></s:Body></s:Envelope>" % action
    req = urllib.request.Request(ctrl, data=body.encode(),
                                 headers={"Content-Type": 'text/xml; charset="utf-8"',
                                          "SOAPACTION": '"%s#%s"' % (urn, action)})
    with urllib.request.urlopen(req, timeout=8) as r:
        return r.status, r.read().decode(errors="replace")


def fault_text(err):
    """把 UPnP 的 HTTPError 变成 "701 Transition not available" 这样可读的文字。"""
    try:
        body = err.read().decode(errors="replace")
    except Exception:                                   # noqa: BLE001
        return str(err)
    code = re.search(r"<errorCode>(\d+)</errorCode>", body)
    desc = re.search(r"<errorDescription>(.*?)</errorDescription>", body)
    if code or desc:
        return "%s %s" % (code.group(1) if code else "", desc.group(1) if desc else "")
    return "HTTP %s" % getattr(err, "code", "?")


def _pick(xml, tag):
    m = re.search(r"<%s>(.*?)</%s>" % (tag, tag), xml, re.S)
    return m.group(1) if m else ""


def transport_state(ctrl):
    try:
        return _pick(soap(ctrl, "GetTransportInfo", {"InstanceID": 0})[1], "CurrentTransportState")
    except (urllib.error.URLError, OSError):
        return "OFFLINE"


def position(ctrl):
    """返回 (相对时间, 总时长) 字符串，如 ("00:01:23", "00:42:00")。"""
    try:
        xml = soap(ctrl, "GetPositionInfo", {"InstanceID": 0})[1]
        return _pick(xml, "RelTime"), _pick(xml, "TrackDuration")
    except (urllib.error.URLError, OSError):
        return "", ""


def push(ctrl, url, mime, profile="", title="", upnp_class="object.item.videoItem",
         transfer="Streaming"):
    """SetAVTransportURI + Play。profile 是 DLNA profile（如 AVC_MP4_HP_HD_AAC），可为空。"""
    feats = ("DLNA.ORG_PN=%s;DLNA.ORG_OP=01;DLNA.ORG_FLAGS=01700000000000000000000000000000"
             % profile) if profile else \
            "DLNA.ORG_OP=01;DLNA.ORG_FLAGS=01700000000000000000000000000000"
    didl = ('<DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/" '
            'xmlns:dc="http://purl.org/dc/elements/1.1/" '
            'xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/">'
            '<item id="1" parentID="0" restricted="1">'
            "<dc:title>%s</dc:title><upnp:class>%s</upnp:class>"
            '<res protocolInfo="http-get:*:%s:%s">%s</res></item></DIDL-Lite>'
            % (xesc(title), upnp_class, mime, feats, xesc(url)))
    soap(ctrl, "SetAVTransportURI", {"InstanceID": 0, "CurrentURI": url,
                                     "CurrentURIMetaData": didl})
    soap(ctrl, "Play", {"InstanceID": 0, "Speed": 1})


# ----------------------------------------------------------------- HTTP 服务
class _Handler:
    """按 DLNA 要求带 contentFeatures/transferMode 头，并支持 Range（视频拖动必须）。"""

    files = {}
    log_tag = ""
    protocol_version = "HTTP/1.1"

    def do_HEAD(self):
        self._serve(head=True)

    def do_GET(self):
        self._serve(head=False)

    def _serve(self, head):
        item = self.files.get(self.path)
        if not item:
            self.send_error(404)
            return
        size = os.path.getsize(item["file"])
        start, end, code, rng = 0, size - 1, 200, self.headers.get("Range")
        if rng:
            m = re.match(r"bytes=(\d*)-(\d*)", rng.strip())
            if m:
                if m.group(1):
                    start = int(m.group(1))
                    if m.group(2):
                        end = min(int(m.group(2)), size - 1)
                elif m.group(2):
                    start = max(0, size - int(m.group(2)))
                if start <= end < size:
                    code = 206
        length = end - start + 1
        self.send_response(code)
        self.send_header("Content-Type", item["mime"])
        self.send_header("Accept-Ranges", "bytes")
        if code == 206:
            self.send_header("Content-Range", "bytes %d-%d/%d" % (start, end, size))
        self.send_header("Content-Length", str(length))
        self.send_header("contentFeatures.dlna.org", item["features"])
        self.send_header("transferMode.dlna.org", item.get("transfer", "Streaming"))
        self.end_headers()
        log(self.log_tag, "HTTP %d %s range=%s" % (code, self.path, rng))
        if head:
            return
        try:
            with open(item["file"], "rb") as f:
                f.seek(start)
                left = length
                while left > 0:
                    buf = f.read(min(262144, left))
                    if not buf:
                        break
                    self.wfile.write(buf)
                    left -= len(buf)
        except (BrokenPipeError, ConnectionResetError, OSError):
            pass

    def log_message(self, *_):
        pass


class Server:
    """本机只读 HTTP 服务：files = {url 路径: dict(file, mime, features, transfer)}。"""

    def __init__(self, files, tag):
        import http.server
        handler = type("Handler", (self._base(),), {})
        handler.files = files
        handler.log_tag = tag
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        sock.bind(("0.0.0.0", 0))
        sock.listen(16)
        self.port = sock.getsockname()[1]
        self.httpd = http.server.ThreadingHTTPServer(("0.0.0.0", self.port), handler,
                                                     bind_and_activate=False)
        self.httpd.socket = sock
        self.httpd.server_address = ("0.0.0.0", self.port)
        self.httpd.server_activate()
        threading.Thread(target=self.httpd.serve_forever, daemon=True).start()

    @staticmethod
    def _base():
        import http.server

        class H(_Handler, http.server.BaseHTTPRequestHandler):
            pass
        return H

    def url(self, path):
        return "http://%s:%d%s" % (local_ip(), self.port, path)

    def shutdown(self):
        try:
            self.httpd.shutdown()
        except Exception:                       # noqa: BLE001
            pass


def features(profile=""):
    if profile:
        return ("DLNA.ORG_PN=%s;DLNA.ORG_OP=01;DLNA.ORG_FLAGS=01700000000000000000000000000000"
                % profile)
    return "DLNA.ORG_OP=01;DLNA.ORG_FLAGS=01700000000000000000000000000000"


def parse_time(text):
    """'12:30' / '1:02:03' / '90' → 秒。"""
    parts = str(text).split(":")
    try:
        secs = 0
        for p in parts:
            secs = secs * 60 + int(p)
        return secs
    except ValueError:
        raise SystemExit("时间要写成 90 / 1:30 / 0:01:30 这样")


def fmt_time(secs):
    secs = int(secs)
    return "%d:%02d:%02d" % (secs // 3600, secs % 3600 // 60, secs % 60)


def daemonize(tag):
    """fork 出后台进程；父进程返回子进程 pid，子进程返回 0（并把 stdio 丢到 /dev/null）。"""
    pid = os.fork()
    if pid > 0:
        return pid
    os.setsid()
    devnull = os.open(os.devnull, os.O_RDWR)
    for fd in (0, 1, 2):
        os.dup2(devnull, fd)
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
    return 0
