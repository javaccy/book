# 常用资源库

## java https://resource.mingrisoft.com/QuickUse/index/id/247.html
## 敏感词 https://resource.mingrisoft.com/QuickUse/index/id/805.html

# gradle 


### gradle 配置代理

    方式1：编译命令添加执行参数
    gradlew -Dhttp.proxyHost=127.0.0.1 -Dhttp.proxyPort=8118 -Dhttps.proxyHost=127.0.0.1 -Dhttps.proxyPort=8118
    方式2：项目根目录添加配置文件
    项目根目录添加配置文件 gradle.properties
```properties
    systemProp.http.proxyHost=127.0.0.1
    systemProp.http.proxyPort=8118
    systemProp.https.proxyHost=127.0.0.1
    systemProp.https.proxyPort=8118
```
### java 代理
```text
http  代理
-Dhttp.proxyHost=127.0.0.1 -Dhttp.proxyPort=1446
https 代理
-Dhttp.proxyHost=127.0.0.1 -Dhttp.proxyPort=1446 
socks 代理
-DsocksProxyHost=127.0.0.1 -DsocksProxyPort=1446
```
```java
// http 代理 
System.setProperty("http.proxyHost","127.0.0.1"); 
System.setProperty("http.proxyPort","1446");
// https 代理 
System.setProperty("https.proxyHost","127.0.0.1"); 
System.setProperty("https.proxyPort","1446");
// socks 代理 
System.setProperty("socksProxyHost","127.0.0.1"); 
System.setProperty("socksProxyPort","1446");
```



# java 代码收藏


### 根据经纬度计算两点之间距离

```java


/**
 * 类名称：PointToDistance    
 * 类描述：两个百度经纬度坐标点，计算两点距离
 * 创建人：钟志铖    
 * 创建时间：2014-9-7 上午10:14:01    
 * 修改人：
 * 修改时间：
 * 修改备注：    
 * 版本信息：1.0  
 * 联系：QQ：433647
 */
public class PointToDistance {

	public static void main(String[] args) {
		double distanceFromTwoPoints = getDistanceFromTwoPoints(23.5539530, 114.8903920, 23.5554550, 114.8868890);
		System.out.println(distanceFromTwoPoints);
		double v = distanceOfTwoPoints(23.5539530, 114.8903920, 23.5554550, 114.8868890);
		System.out.println(v);
	}
	
	private static final Double PI = Math.PI;

	private static final Double PK = 180 / PI;
	
	/**
	 * @Description: 第一种方法
	 * @param lat_a 经度1
	 * @param lng_a 维度1
	 * @param lat_b 经度2
	 * @param lng_b 维度2
	 * @return double
	 * @author 钟志铖
	 */
	public static double getDistanceFromTwoPoints(double lat_a, double lng_a, double lat_b, double lng_b) {
		double t1 = Math.cos(lat_a / PK) * Math.cos(lng_a / PK) * Math.cos(lat_b / PK) * Math.cos(lng_b / PK);
		double t2 = Math.cos(lat_a / PK) * Math.sin(lng_a / PK) * Math.cos(lat_b / PK) * Math.sin(lng_b / PK);
		double t3 = Math.sin(lat_a / PK) * Math.sin(lat_b / PK);

		double tt = Math.acos(t1 + t2 + t3);

		System.out.println("两点间的距离：" + 6366000 * tt + " 米");
		return 6366000 * tt;
	}

	
	/********************************************************************************************************/
	// 地球半径
	private static final double EARTH_RADIUS = 6370996.81;

	// 弧度
	private static double radian(double d) {
		return d * Math.PI / 180.0;
	}

	/**
	 * @Description: 第二种方法
	 * @param lat1   经度1
	 * @param lng1 	 维度1
	 * @param lat2 	 经度2
	 * @param lng2   维度2
	 * @return void
	 * @author 钟志铖
	 */
	public static double distanceOfTwoPoints(double lat1, double lng1, double lat2, double lng2) {
		double radLat1 = radian(lat1);
		double radLat2 = radian(lat2);
		double a = radLat1 - radLat2;
		double b = radian(lng1) - radian(lng2);
		double s = 2 * Math.asin(Math.sqrt(Math.pow(Math.sin(a / 2), 2)
				+ Math.cos(radLat1) * Math.cos(radLat2) * Math.pow(Math.sin(b / 2), 2)));
		s = s * EARTH_RADIUS;
		s = (double) Math.round(s * 10000) / 10000;
		double ss = s * 1.0936132983377;
		System.out.println("两点间的距离是：" + s + "米" + "," + (int) ss + "码");
		return s;
	}

```
