---
title: java
date: 2023-02-17 15:04:12
excerpt: 回顾总结一下java语法
tags: 编程语言
categories: 专业基础
---

# 一、变量：

## **1.1命名规则：**

1. **字母和数字**：变量名可以包含字母（a-z, A-Z）、数字（0-9）、美元符号（$）和下划线（_）。
2. **开头字符**：变量名不能以数字开头，必须以字母、美元符号或下划线开头。
3. **关键字**：不能使用Java保留关键字作为变量名。

**驼峰命名法**

- **小驼峰命名法**（camelCase）：用于变量名和函数名，第一个单词以小写字母开始，后续单词的首字母大写。例如：`firstName`, `totalAmount`。
- **大驼峰命名法**（PascalCase）：通常用于类名，每个单词的首字母都大写。例如：`ClassName`, `EmployeeDetails`。

**变量使用前必须要初始化，属性不用（类中的是属性，方法中的是变量）**

## 1.2数据类型

**8种基本数据类型**：

- `byte`：字节型，8位，表示整数。
- `short`：短整型，16位，表示整数。
- `int`：整型，32位，表示整数。
- `long`：长整型，64位，表示整数。
- `float`：单精度浮点型，32位，表示小数，数据需要使用F(f)结尾。
- `double`：双精度浮点型，64位，表示小数。
- `char`：字符型，16位，表示单个字符。
- `boolean`：布尔型，表示真或假。

**引用数据类型**：类，接口，数组，枚举，特殊类型数值：null

string是引用类型，他的值存储在堆空间，它的值不会变化，如果对他修改只会产生一个新的string

## 1.3数据类型的转换

可以直接将小的数据类型转换为大的数据类型。byte→short→int→long→float→double

```java
byte a=10;
short b=a;//小的赋值可以直接给大的
```

范围大的不能直接转换为小的（有精度损失），使用强制类型转换

```java
int a=10;
short b=(short)a;//小的赋值可以直接给大的
```

## 1.4final

- final关键字可以修饰变量，一旦初始化后不能修改。
- final修饰属性时，jvm不会进行初始化，要自己进行初始化
- 可以修饰方法，这个方法不能被子类重写
- 可以修饰类，这个类就不能有子类
- 可以修饰方法参数，一旦修饰，参数无法修改
- 不能修饰构造方法

# 二、常用类和对象

## 2.1 数组

### 1.数组的声明方法

```java
int[] arr;        // 推荐写法
int arr[];        // 也可以这样写
```

### 2.数组的初始化

```java
//动态初始化
int[] arr; // 声明数组
arr = new int[5]; // 分配内存空间
int[] arr = new int[5];//也可以在声明时直接初始化
int[] arr = {1, 2, 3, 4, 5};//使用静态初始化
```

### 3.常用属性方法

```java
arr.length//数组长度

import java.util.Arrays;
System.out.println(Arrays.toString(arr));//输出字符串[1, 2, 3]
```

### 4.二维数组

```java
int[][] matrix = new int[2][3];   // 2 行 3 列的数组
matrix[0][0] = 1;                 // 访问或赋值
System.out.println(matrix[1][2]); // 访问第二行第三列的元素
```

## 2.2string

### 1.字符串的定义和创建

```java
//1. 字面值定义（最常用）
String str = "Hello, Java!";
//2. 使用构造方法
String str = new String("Hello");
```

一般推荐使用字面量定义方式，效率更高（避免重复创建对象） 字符串有一个非常特殊的机制：**字符串常量池（String Pool）**

字符字面量会自动进入常量池

```java
String s1 = "abc"
String s2 = "abc"
```

这两个变量会共享同一个对象，JVM会在常量池中查找"abc"：

- 如果存在就复用
- 如果不存在就创建放入常量池

### 2.常用方法大全

```java
//length()：获取字符串长度
System.out.println(str.length());

//substring(int begin, int end)：截取子串（左闭右开）
String sub = str.substring(0, 5);  // "Hello"
//substring(int beginIndex)：返回从指定索引开始的子字符串。

//indexOf(String s) / lastIndexOf()：查找子串
int index = str.indexOf("Java");  // 返回第一次出现的起始索引，没有找到返回 -1
//lastIndexOf(int ch)：返回指定字符在字符串中最后一次出现处的索引。
//contains(CharSequence s)：判断字符串中是否包含指定的字符序列。

//replace()：替换字符或子串
String newStr = str.replace("Java", "World");  // "Hello, World!"

//equals() / equalsIgnoreCase()：判断字符串是否相等
str.equals("abc");             // 区分大小写
str.equalsIgnoreCase("ABC");  // 忽略大小写

//trim()：去除首尾空格
String s = "  Hello  ";
System.out.println(s.trim());  // "Hello"
//toUpperCase()：将字符串转换为大写。
//toLowerCase()：将字符串转换为小写。

//split(String regex)：按规则分割字符串
String[] parts = "a,b,c".split(",");  // ["a", "b", "c"]
```

### 3.字符串的不可变性

在 Java 中，string 是 **不可变对象（immutable）**，也就是说：

```java
String s = "hello";
s = s + " world";  // 实际上是创建了一个新的字符串对象

//推荐使用 StringBuilder 进行频繁拼接
//如果需要大量拼接字符串，建议使用：
StringBuilder sb = new StringBuilder();
sb.append("Hello");
sb.append(", ");
sb.append("Java");
System.out.println(sb.toString());
//比用 + 效率高很多，尤其在循环中。
```

为什么String要设置成不可变的呢？

1. 缓存：因为字符串常量的存在，可能会使多个变量同时指向字符串常量池中的一个字符串，这样改变一个其他的也会同时改变，显然这是不合理的。如：String a="abc",String b="abc"，如果改变a那么b也会改变

2. 安全性：字符串存储的一般为敏感信息，当我们在程序中传递一个字符串的时候，如果这个字符串的内容是不可变的，那么我们就可以相信这个字符串中的内容。

3. 线程安全：不可变会自动使字符串成为线程安全的，因为当从多个线程访问它们时，它们不会被更改。

## 2.3包装类

在Java中，包装类（Wrapper Classes）是用于将基本数据类型（如int、char、boolean等）转换为对应的对象类型（如Integer、Character、Boolean等）。这样做的好处是，对象类型可以提供更多的功能，如方法调用、常量定义等，并且可以用于泛型、集合等需要对象类型的场景。

1. boolean - Boolean
2. byte - Byte
3. char - Character
4. short - Short
5. int - Integer
6. long - Long
7. float - Float
8. double - Double

自动装箱（AutoBoxing）和自动拆箱（AutoUnboxing）是Java 5及以上版本提供的特性，允许基本类型和对应的包装类之间自动转换：

- **自动装箱**：将基本类型自动转换为对应的包装类对象。
- **自动拆箱**：将包装类对象自动转换为对应的基本类型值。

```java
Integer a = 10; // 自动装箱，相当于 Integer a = Integer.valueOf(10);
int b = a; // 自动拆箱，相当于 int b = a.intValue();
```

使用包装类时需要注意以下几点：

- 包装类对象是不可变的（immutable），一旦创建，其值不能改变。
- 包装类对象之间存在缓存机制，例如Integer会缓存-128到127之间的值。如果将其中的值赋给包装类就不会new新的对象，超过则会new。

```java
Integer a = 100;
Integer b = 100;
System.out.println(a == b);  // ✅ true 引用是同一个

Integer x = 200;
Integer y = 200;
System.out.println(x == y);  // ❌ false
```

- 在进行比较时，应使用equals()方法比较包装类对象的值，而不是使用==运算符，因为==比较的是对象的引用。

## 2.4日期类

Date：日期类

时间戳：毫秒

## 2.5工具类

- 工具类应该可以直接使用类中的属性和方法，一般都声明为静态的
- 工具类对外提供的属性和方法都应该是public
- 为了使用者开发方便，应该多提供方法

## 2.6比较

- ==基本数据类型比较的是值，引用比较的是地址，equals比较的是值（可以被重写）
- 基本数据类型比较，双等号（==）比较数值（10.0==10为true）
- 对于字符串，使用字面量（常量池），如果相等也是true（使用new则不等）
- 可以重写equals方法自定义比较

## 2.7集合：

分为两种，一种是单一数据（Collection下的），另一种是成对数据（Map下）

单一数据：

- `Collection`：是集合框架中的根接口，它定义了集合的基本操作，如添加、删除、遍历等。
- `List接口`：有序集合，可以包含重复元素，常用的实现类有`ArrayList`、`LinkedList`等。
- `Set接口`：无序集合，不包含重复元素，常用的实现类有`HashSet`、`TreeSet`等。
- `Queue`：队列接口，用于元素排队，常用的实现类有`LinkedList`、`PriorityQueue`等。

成对数据：

- `Map`：键值对映射表，不是`Collection`的子接口，但也是集合框架的一部分，常用的实现类有`HashMap`、`TreeMap`等。

### 1.Collection

#### ArrayList：

底层由数组实现

特点：**动态数组、有序、允许重复、随机访问、非线程安全**

三种初始化方法：

1. 不需要传递参数，直接new就可以
2. 传递int类型，代表初始化列表的长度
3. 传递集合类型，将其他集合的数据放进去

**扩容机制**：当向 ArrayList 添加元素时，如果底层数组不足以容纳更多元素，ArrayList 会进行扩容。默认的扩容策略是扩展为原数组大小的 1.5 倍（如果为空，则添加第一个数据会设置长度为10），然后复制原数组到新数组中。这个过程会有一定的性能开销，因此如果预先知道将要存储的元素数量，最好在创建 ArrayList 时指定初始容量，以减少扩容操作的次数。

常用方法：

```java
ArrayList list = new ArrayList();
```

- 增删改查：

添加元素 add(E e)、add(int index, E element)

删除元素 remove(int index)、 remove(Object o)成功返回true，不成功返回false

设置值：set(int index, E element)

获得下标对应的值：get(int index) 获得元素对应的下标：indexOf(Object o)、lastIndexOf(Object o)不包含返回-1

- 判断是否包含元素：contains(Object o)
- 获得元素数量：size()
- 判断是否为空：isEmpty()
- 清空列表：clear()
- 转换为数组：toArray()
- 将一个列表加到另一个列表后面：list.addAll(otherList)
- 删除列表中的子列表：list.removeAll(otherList)

#### LinkedList：

**LinkedList**实现了 List 接口和 Deque 接口，因此它既可以用作列表（List），也可以用作双端队列（Deque）。LinkedList 的底层实现是**基于双向链表**的，这使得它在插入、删除元素时具有很高的效率，但在随机访问元素时效率较低。LinkedList 不是线程安全的

特点：每个节点都包含前后节点的引用。LinkedList 的大小可以动态变化。任意位置插入或删除元素都非常高效。LinkedList 的随机访问效率较低，因为它需要从头或尾遍历到指定位置。

常用方法（ArrayList的方法大部分都能用）:

添加到头：addFirst(E e)、push(E e)

删除尾：pop(E e)

#### CopyOnWriteArrayList

是List一个线程安全的实现类，其核心设计思想是 **“写时复制”**（Copy-On-Write），适用于读多写少的并发场景。

当对 `CopyOnWriteArrayList` 进行 **修改操作**（如 `add`、`set`、`remove` 等）时，它不会直接修改原数组，而是先创建一个新的数组副本，在副本上完成修改，最后将引用指向新数组；而 **读操作** 则直接访问原数组，无需加锁。

这种机制保证了：

- 读操作完全无锁，性能极高（适合读多写少场景）。
- 写操作通过复制数组实现线程安全，避免了对读操作的阻塞以及多个写操作同时修改。

#### 泛型：

ArrayList<E> list=new ArrayList<>();

#### 比较器（类似于c++中的自定义sort）：

```java
class mySort implements Comparator<Integer>{
	@override
	public int compare(Integer a,Integer b){
		return a-b;
	}
}

list.sort(new muSort());
```

#### HashSet：

HashSet基于哈希表（实际上是一个 HashMap 实例）来存储元素

特点：元素唯一，值无序（如果需要有序的集合，可以考虑使用 `LinkedHashSet`），允许存储一个null值，HashSet 不是线程安全的

遍历方法：

```java
HashSet<String> set = new HashSet<>();
//1.使用迭代器
Iterator<String> iterator = hashSet.iterator();
while (iterator.hasNext()) {
    String element = iterator.next();
    System.out.println(element);
}

//2.增强for
for (String element : hashSet) {
    System.out.println(element);
}
```

#### Queue（接口）：

部分实现类：

1. **ArrayDeque**：基于数组实现的双端队列，可以当作栈使用，也可以当作队列使用。
2. **LinkedList**：基于链表实现的队列，同时实现了List接口和Deque接口，因此可以作为双向队列使用。
3. **PriorityQueue**：基于优先级堆实现的队列，元素按照优先级顺序出队，而不是按照插入顺序。

常用方法：

1. 插入元素：
   - `boolean add(E e)`：将元素添加到队列的尾部。如果操作成功，返回true；如果队列已满，抛出IllegalStateException。
   - `boolean offer(E e)`：将元素添加到队列的尾部。如果操作成功，返回true；如果队列已满，返回false。
2. 移除元素：
   - `E remove()`：获取并移除队列的头部元素。如果队列为空，抛出NoSuchElementException。
   - `E poll()`：获取并移除队列的头部元素。如果队列为空，返回null。
3. 查看元素：
   - `E element()`：获取但不移除队列的头部元素。如果队列为空，抛出NoSuchElementException。
   - `E peek()`：获取但不移除队列的头部元素。如果队列为空，返回null。

### 2.HashMap

HashMap基于哈希表实现，用于存储键值对。HashMap 允许使用 null 值和 null 键，但需要注意的是，它不保证元素的顺序，且不保证线程安全。HashMap 的内部实现基于数组和一个用于处理哈希冲突的链表（在 Java 8 及以上版本中，链表过长时会转换为红黑树）。Hashmap 中的元素达到数组长度的0.75倍就会扩容为原来的两倍（扩容加载因子0.75）

其他方法：

- `put(K key, V value)`：将指定的键值对插入到 HashMap 中（Map接口定义了put方法，其他容器几乎都是使用add添加）。
- `get(Object key)`：返回指定键所映射的值。
- `remove(Object key)`：从 HashMap 中移除指定的键及其对应的值。
- `containsKey(Object key)`：判断 HashMap 中是否包含指定的键。
- `containsValue(Object value)`：判断 HashMap 中是否包含指定的值。
- `keySet()`：返回 HashMap 中所有键的集合。
- `values()`：返回 HashMap 中所有值的集合。
- `entrySet()`：返回 HashMap 中所有键值对的集合

遍历方法：

```java
HashMap<String,String> map = new HashMap<>();
//1.使用键值遍历
for (String key : hashMap.keySet()) {
    System.out.println("Key: " + key + ", Value: " + hashMap.get(key));
}
//2.使用值集遍历
for (String value : hashMap.values()) {
    System.out.println("Value: " + value);
}
//3.使用键值对集遍历 Entry是一个键值对（key-value pair）的映射项
for (Map.Entry<String, String> entry : hashMap.entrySet()) {
    System.out.println("Key: " + entry.getKey() + ", Value: " + entry.getValue());
}
//使用迭代器遍历
//不能直接写Iterator<Map<String, String>>来遍历映射中的键值对
//因为迭代器需要知道它正在遍历的是映射中的单个元素（即键值对）而不是整个映射。
//Map<String, String> 表示整个映射，而 Map.Entry<String, String> 表示映射中的一个键值对
Iterator<Map.Entry<String, String>> iterator = hashMap.entrySet().iterator();
while (iterator.hasNext()) {
    Map.Entry<String, String> entry = iterator.next();
    System.out.println("Key: " + entry.getKey() + ", Value: " + entry.getValue());
}
```

hashmap使用红黑树的优势？

当链表长度超过阈值（默认 8）时，HashMap 会将链表转换为**红黑树**，原因是红黑树的查询、插入、删除操作的时间复杂度为 **O(log k)**，远优于长链表的 O (k)：

- 例如，当链表长度为 8 时，链表查询平均需要遍历 4 次，而红黑树只需 3 次（log₂8 = 3）；若长度增至 16，链表平均 8 次，红黑树仅需 4 次，差距随长度增加而扩大。
- 红黑树是自平衡二叉搜索树，通过着色和旋转维持平衡，避免了二叉树退化为链表的问题，确保稳定的高效操作。

为什么选择红黑树而非其他平衡树？

- **AVL 树**：虽然平衡性更好（左右子树高度差不超过 1），但插入 / 删除时旋转次数更多，维护成本高。HashMap 中树的转换和修改较频繁，红黑树的旋转次数更少（最多 3 次），性能更优。
- **B 树 / B + 树**：多叉树，适合磁盘存储（如数据库索引），但内存中红黑树的结构更简单，操作更高效。
- **链表**：短链表（长度≤6 时，HashMap 会将红黑树转回链表）的遍历成本低于红黑树的节点查找（红黑树有额外的颜色和指针维护开销），因此仅在链表过长时才转换为树。

是线程安全的吗？

不是线程安全的，ConcurrentHashMap为线程安全

### 3在遍历过程中使用迭代器对数据进行删除会避免冲突

```java
public class java01 {
    public static void main(String[] args) {
        HashMap<String,String> map=new HashMap<>();
        map.put("1","a");
        map.put("2","b");
        map.put("3","c");
        Iterator<Map.Entry<String,String>> iterator=map.entrySet().iterator();
        while(iterator.hasNext()){
            Map.Entry<String, String> entry = iterator.next();
            if(entry.getKey().equals("2")){
                //map.remove(entry.getKey());//出错
                iterator.remove();
            }
        }
        System.out.println(map.entrySet());
    }
}
```

第一种方式会出错，迭代器（for的底层也依赖于迭代器）设计时有一个重要的约束：在迭代过程中不允许直接修改集合（添加、删除元素），以防止出现不一致的状态。即直接删除remove元素，此时迭代器指向的元素变成空了会引发错误，所以要使用迭代器的方式进行删除。

# 三、面向对象

面向对象编程具有以下四个基本特性：

1. **封装**：将对象的属性和行为封装在一起，形成一个独立的实体。对外界隐藏对象的内部实现细节，通过对象提供的接口与外界交互。
2. **继承**：允许一个新的类（子类）从现有的类（父类）中继承属性和方法，实现代码的复用和扩展。
3. **多态**：允许不同类的对象对同一消息作出响应，即同一操作在不同对象上具有不同的行为。多态性提高了程序的灵活性和可扩展性。
4. **抽象**：将现实世界中的复杂问题抽象为程序世界中的类和对象，关注对象的基本属性和行为，忽略与问题无关的细节。

✅ 如何理解解耦（举个例子：打车系统）

❌ 糟糕的写法（强耦合）

```java
class Taxi {
    public void drive() {
        System.out.println("打车出发");
    }
}
class RideService {
    public void go() {
        Taxi taxi = new Taxi();  // 直接写死具体类
        taxi.drive();
    }
}
```

- 缺点：只能打车，未来不能换成网约车或共享单车。
- 每加一个新功能就要改 `RideService`，**耦合紧、扩展难**。

✅ 解耦版：使用抽象 + 多态

```java
// 抽象接口
interface Transport {
    void drive();
}

// 具体实现类
class Taxi implements Transport {
    public void drive() {
        System.out.println("打车出发");
    }
}

class Bike implements Transport {
    public void drive() {
        System.out.println("骑共享单车出发");
    }
}

// 使用方只依赖接口
class RideService {
    private Transport transport;

    public RideService(Transport transport) {
        this.transport = transport;
    }

    public void go() {
        transport.drive();
    }
}
```

调用：

```java
RideService s1 = new RideService(new Taxi());
s1.go();  // 打车出发

RideService s2 = new RideService(new Bike());
s2.go();  // 骑共享单车出发
```

✅ 解耦 + 可扩展性体现在哪？

| 特性   | 表现                                                         |
| ------ | ------------------------------------------------------------ |
| 解耦   | RideService 只依赖接口，不关心用什么车                       |
| 可扩展 | 新增类 `Train implements Transport` 不用改 RideService       |
| 多态   | `Transport t = new Taxi()` 可以调用 `t.drive()`，不同实现自动分发 |
| 灵活   | 可以通过配置文件、Spring 注入等动态切换实现类                |

## 3.1类和对象

### 1.基本概念

类可以被视为一种蓝图或模板，用于定义对象的属性和行为。在类中，我们定义了对象所共有的特征和功能。这些特征称为属性（或成员变量），而功能称为方法（或成员函数）

对象是类的具体实例。根据类定义的蓝图，我们可以创建多个具体的对象。每个对象都有自己独立的属性值，但共享类中定义的方法。在Java中，使用`new`关键字来创建对象。

new是一个关键字，表示创建一个具体的对象，每次使用都会创建一个全新的对象，一般会将new出来的对象回赋值给变量重复使用

```java
class Cooking{
	String name;
	String type="baocao";
	String food;
	String relish;
	void excute(){
		System.out.println("start");
		System.out.println("end");
	}
}
```

### 2.堆 栈 元空间

#### **栈（Stack）**

栈是一种线程私有的内存区域，每个线程创建时都会分配一个独立的栈。栈的主要功能包括：

- **存储局部变量**：包括方法参数、局部变量等。
- **管理方法调用**：记录方法的调用和返回，维护调用栈帧。（方法在栈执行）
- **执行基本类型操作**：**基本数据类型**的值直接存储在栈上。

栈的特点：

- **快速访问**：栈内存的分配和回收都非常快。
- **容量有限**：栈的大小通常较小，且有限制，容易发生栈溢出（Stack Overflow）。
- **生命周期短**：栈内存随着方法的调用而分配，随着方法的返回而释放。

#### **堆（Heap）**

堆是所有线程共享的内存区域，**用于存储Java对象实例**。堆的主要功能包括：

- **存储对象实例**：所有通过new关键字创建的对象都存储在堆中。
- **管理对象生命周期**：垃圾回收器（Garbage Collector）负责回收不再被引用的对象，释放内存。

堆的特点：

- **动态分配**：堆内存的大小可以根据需要进行动态扩展。
- **容量较大**：相比栈，堆的容量通常较大，可以存储大量对象。
- **生命周期不定**：对象的生命周期取决于引用的存在，可能很长，也可能很短。

#### **元空间/方法区（Metaspace ）**

元空间是Java 8及以上版本中替代永久代（PermGen）的内存区域，用于存储类元数据、常量池等。元空间的主要功能包括：

- **存储类元数据**：**类**的结构信息，包括类名、方法信息、字段信息、字节码等。
- **存储常量池**：包括**字符串常量、数值常量等**。
- **避免永久代限制**：元空间使用本地内存而不是JVM堆内存，减少了永久代内存溢出的风险。

元空间的特点：

- **使用本地内存**：元空间不占用JVM堆内存，而是使用本地内存。
- **动态调整**：元空间的大小可以根据需要进行动态调整，默认不受限制。
- **减少内存溢出风险**：由于使用本地内存，减少了永久代内存溢出的风险。

### 3.静态

针对于具体对象的属性称为对象属性，成员属性，实列属性（方法相同），用来表示不同对象之间的特性。**静态属性存在元空间中**

把和对象无关，只和类别相关的属性称为静态属性（方法相同），用来表示某一个类的共性。静态类**不用new，直接就可以通过类调用**

先有类再有对象，所以**成员方法可以访问静态方法，但是静态方法不能访问成员方法**（静态方法访问成员方法时，可能类还没有对象，如果使用类.静态方法，此时静态方法调用成员方法是会出错的）。

**注意：静态方法和类有关，非静态方法和对象有关**

**为什么静态方法不能直接访问非静态成员方法？**

```java
public class Example {
    public static void staticMethod() {
        System.out.println("这是静态方法");
        // 非法调用（错误）
        // nonStaticMethod();  ❌ 编译错误
        // 正确调用：先创建对象
        Example e = new Example();
        e.nonStaticMethod();  // ✅
    }

    public void nonStaticMethod() {
        System.out.println("这是非静态方法");
    }

    public static void main(String[] args) {
        staticMethod();
    }
}
```

- **缺少对象上下文**：

  - 静态方法不依赖于对象实例，因此在静态方法中没有 this 引用（this 指向当前对象）。
  - 非静态成员方法通常需要通过 this 或某个对象实例来调用，因为它可能需要访问实例变量或对象的状态。如果静态方法直接调用非静态方法，JVM 无法确定调用的是哪个对象的成员方法（因为没有对象上下文）。

- **生命周期差异**：

  - 静态方法在类加载时（程序启动时）就已经存在，而非静态成员方法依赖于对象的创建。
  - **在静态方法执行时，可能还没有任何对象被创建，因此无法调用非静态方法。**

  **设计逻辑**：Java 的设计要求静态方法是独立的，与具体对象无关

静态方法的使用场景？

1. 工具类方法
2. 工厂方法
3. 访问/操作静态成员变量
4. 提供常量相关的辅助逻辑（如定义静态常量）

**静态代码块：**

```java
//放在类里面定义
static{
	//方法体 类加载后自动执行
}
{
	//方法体 对象加载后自动执行
}
```

### 4.构造方法

如果一个类没有构造方法，jvm会自动添加一个公共的，无参构造方法

```java
class User{
	int age;
	User(){
	}
	User(int age){
		this.age=age;
	}
}
```

## 3.2 继承

- 子类可以直接获得父类的成员属性和成员方法
- 一个类只能有一个父类。一个类可以有多个子类

![](/image/java/img1.png)

new一个child的对象就可以直接用父类的东西了

### 1.super this

如果父类和子类含有相同的属性，super调用父，this默认可以不写（super、this指的是对象）

![](/image/java/img2.png)

### 2.构造方法

每new一个子类对象就会获得父类对象的信息，而且父类信息是在子类对象创建前获得的。

创建子类对象前，会先获得父类对象的构造方法。

默认情况下，子类对象构建时，会调用父类的无参构造方法（用于初始化父类的属性）。在子类的构造方法中使用super()的方式（默认是隐藏的）。如果父类的构造不是无参的，要在子类的构造方法中写上。

![](/image/java/img3.png)

### 3.多态

一个对象在不同场景下表现出来的不同状态和形态，多态语法其实就是对对象的使用场景进行了约束。

#### 关于多态中的方法：

**一个对象可以使用的方法取决于引用变量（左边）的类型（能使用这个方法），但是如果这个方法被子类重写，则使用重写后的逻辑**，也就是一个方法的**具体使用**（直接或间接使用）需要看**具体的对象（右边）**

#### 关于多态中的属性：

一个对象**可以使用的属性**取决于**引用变量的类型（左边）**，也就是说编译时只有左边包含的属性才会编译通过

```java
class Parent { int x = 1; }
class Child extends Parent { int y = 2; }

Parent p = new Child();
System.out.println(p.x); // 合法（父类有x）
System.out.println(p.y); // 编译报错（父类无y，引用类型限制）
```

一个对象的属性**具体的值使用**只需要看属性声明的位置，**属性在哪个类里声明，就永远使用哪个类的版本**（**如果子类对象调用的是父类的方法，那么里面的属性也是根据父类计算的**）

```java
class Parent {
    int x = 10;
    void print() {
        System.out.println("Parent x = " + x);
    }
}
class Child extends Parent {
    int x = 20;
    void print() {
        System.out.println("Child x = " + x);
    }
}

Parent p = new Child();
System.out.println(p.x); // 输出10（父类的x），没有使用子类的方法，由编译期类型Parent决定 → 用父类的字段。
p.print();               // 输出 "Child x = 20"（子类方法），由运行期对象类型 Child 决定 → 调用子类方法
```

（在多态约束下父类要求子类的属性方法全按父类的来，否则不给编译，叛逆期的子类表面上满足条件答应了，**实际执行的时候能做的方法就按自己的来，不能的方法才按父类的来，属性就地取材**，**用谁的方法就用谁的属性**）

### 4.重载

一个类中不能重复声明方法名和参数列表均一样的方法（和返回类型无关），也不能声明相同的属性

**如果方法名相同，但是参数列表（个数、顺序、类型）不相同，会认为是不同的方法（重载）**

![](/image/java/img4.png)

### 5.重写

父类的方法主要体现的是通用性，无法在特殊的场合下使用，如果子类对象要在特殊的场合使用，就需要重写父类的方法。

这里的重写并不意味着父类的方法被覆盖掉，如果在子类使用super还是可以调用父类的方法。

方法的重写要求，子类的方法和父类的方法，**方法名相同，参数列表相同，返回值类型相同，访问权限等（构造方法不能重写，名字不同）**

## 3.3 访问权限

**public：**

- 公共权限，是限制最宽松的访问级别。
- 任何外部类都可以访问public成员，没有限制

**protected**：

- 受保护权限。
- 同一个包内的类以及所有子类都可以访问protected成员。
- 不同包的非子类无法访问protected成员。

**default（包访问权限）**：

- 当不使用任何访问修饰符时，成员的访问级别是包私有的。
- 同一个包（package）内的类可以访问这些成员。
- 不同包的类无法访问default成员。

**private**：

- 私有权限，是限制最严格的访问级别。
- 只有在定义它们的类内部才能访问private成员。
- 例如，一个类的private方法只能被该类中的其他方法调用。

### **外部类和内部类：**

外部类就是在源码中直接声明的类，外部类只能使用public和默认修饰

内部类就是在类中声明的类，内部类当成外部类的属性即可

### **要初始化内部类要先初始化他的外部类**

![](/image/java/img5.png)

## 3.4 抽象

**抽象类：不完整的类就是抽象类（abstract class 类名） 。抽象类可以有构造方法但是无法直接构建对象，但可以通过子类间接构建。**

**抽象方法：只有声明没有实现的方法（修饰符 abstract 返回值类型 方法名（参数）），抽象方法只能在抽象类中定义。抽象方法在子类中必须被补充完整。**

抽象类可以有非抽象方法

为什么抽象类不能构建对象？

因为如果构建出来但是它里面连方法体都没有，那么去调用他的方法显然是不合理的。其次对于jvm来说，抽象类中含有抽象方法时，这些方法**没有对应的实现地址**，也就无法正确构造出对象的运行时结构，因此new不出来。

abstract不能和final同时使用

![](/image/java/img6.png)

## 3.5 接口

所谓的接口可以简单的理解为规则

基本语法：

- interface 接口名称{规则属性，规则的行为}
- 接口是抽象的，不能被初始化（**没有构造方法**），可以声明接口类型的成员变量
- 接口**不能直接实例化**，但**可以通过实现类、匿名类或 Lambda 表达式**来创建“对象”，这些对象都会被当作接口的引用来使用。

```java
UserDao userDao = new UserDaoImpl
```

- 接口的属性必须为固定值且不能被修改
- 属性和行为的访问权限必须为public
- 属性是静态的
- 行为是抽象的
- 接口可以继承其他的接口
- 类需要实现接口，且一个类可以实现多个接口

## 3.6 其他

### 1.枚举

枚举是一个特殊的类，包含了一些特定的**对象**（客观存在的或者其他..），这些对象不会发生改变，一般使用大写的标识符。关键字为enum，一般用来规定一些固定的信息方便开发使用

枚举类不能创建对象，他的对象是在自己的内部创建的（不需要用new的方式，直接声明就会创建）

![](/image/java/img7.png)

### 2.匿名类

在某些情况，类的名字不重要，我们只想使用类中的方法或功能。此时可以使用匿名类

实现：相当于new一个类直接去重写它里面的方法（需要的那个）

![](/image/java/img8.png)

### 3.bean规范

- 数据模型（bean类）只包含属性，数据私有，使用set设置和get取值（公有）
- 类要求必须含有无参公共的构造方法

![](/image/java/img9.png)

# 四、一些小方法

## 4.1可变参数

当方法的参数不确定，类型相同时，可以采用可变参数。注意：可变参数最多只有一个且应放在最后。（可变参数本质是一个数组）

语法：参数类型… 参数名称

```java
public class Calculator {
    // 使用可变参数的方法，用于计算多个整数的总和
    public int sum(int... numbers) {
        int total = 0;
        for (int number : numbers) {
            total += number;
        }
        return total;
    }

    public static void main(String[] args) {
        Calculator calc = new Calculator();
        // 调用可变参数方法，可以传递任意数量的整数
        int result1 = calc.sum(1, 2, 3, 4, 5); // 结果为15
        System.out.println("The sum is: " + result1);

        int result2 = calc.sum(10, 20); // 结果为30
        System.out.println("The sum is: " + result2);

        int result3 = calc.sum(); // 结果为0，没有传递任何参数
        System.out.println("The sum is: " + result3);
    }
}
```

## 4.2Lambda表达式

Lambda表达式允许将函数作为方法参数，或者将代码作为数据对待。适用于接口只有一个抽象方法的场景（如Runnable接口）

语法：->左侧是参数列表，右侧是 Lambda 体（即函数体）

(参数) -> 表达式  // 单条语句 (参数) -> { 代码块; }  // 多条语句 主要特点：

1. **可选类型声明**：不需要声明参数类型，编译器可以统一识别参数值。
2. **可选的参数圆括号**：无参写()，一个参数不需要写圆括号，多个参数需要写圆括号。
3. **可选的大括号**：如果主体包含了一个语句，就不需要使用大括号。
4. **可选的返回关键字**：如果主体只有一个表达式返回值则编译器会自动返回值，大括号需要指定明表达式返回了一个数值。（一行代码不需要写return，多行需要return）

```java
// Lambda表达式实现Runnable接口
Runnable task = () -> System.out.println("Running task");
// 等同于匿名类：
Runnable task = new Runnable() {
    @Override
    public void run() {
        System.out.println("Running task");
    }
}
 //lambda表达式，等效于实现了flavors.forEach中的接口，在遍历过程中实现某些操作
flavors.forEach(dishFlavor -> {
    dishFlavor.setDishId(dishId);
});
//等效于以下匿名类实现
flavors.forEach(new Consumer<DishFlavor>() {
    @Override
    public void accept(DishFlavor dishFlavor) {
        dishFlavor.setDishId(dishId);
    }
});
```

lambda表达式含义：接口 对象 = (参数（接口中函数的参数）) -> {具体实现};
