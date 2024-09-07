 ### Rust笔记

### crate 类似 java 的 maven 仓库
    1. 在Rust里面，代码的包称作 crate
    2. 地址 https://crates.io/


### rustup

### rustc
 
### cargo
    1. toml(Tom's Obvious, Minimal Language) 格式，是Cargo的配置文件格式

### 变量与可变性;
    1. 不可变变量 let x = 1;
    2. 可变变量   let mut x = 1;
    3. 隐藏(shadowing),同名变量覆盖   let mut x = 1; let mut x = 2;
    4. 常量 const MAX_VALUE:u32 = 10_000;
### 数据类型:标量类型，复合类型
#### 标量类型:整型，浮点型，字符，布尔:
    1. let x: i8 = 2;
    2. 无符号整型:i8,i16,i32,i64,i128,isize(arch) 
    3. let x = 2.0; // f64;
    4. 无符号浮点型:
#### 复合类型:整型，浮点型，字符，布尔
#### 元组(Tuple)
    1. 声明 let tup: (i32,f64,i128) = (1,2.1,3);
    2. 使用 tup.0  tup.1
#### 数组(Array)
    1. 存储在栈内存
    2. 声明 let a：[i32,i32] = [10,10];
    3. 简写 let a = [10,11,12]

#### Vector(列表)
### 引用与借用
    1. 
### 字符串 
    1. 尽量使用字符串切片，而不是字符串引用
    2. 字符串字面值其实就是一个字符串切片
