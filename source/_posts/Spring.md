---
title: Spring
date: 2023-04-01 17:12:47
excerpt: 系统整理 Spring 核心技术：控制反转（IoC）与依赖注入（DI）实现低耦合设计；涵盖 XML 配置、注解开发以及 @Configuration 类替代 XML 的现代化配置方式；深入讲解 Bean 的生命周期管理、范围配置（singleton/prototype）等
tags:
  - SSM
  - 开发框架
categories : 技术
---

# Spring

## 1. Spring 介绍

### 1.1 Spring 是什么?

- Spring 是 Java EE 开发的“一站式”框架，提供 IoC（控制反转）、AOP（面向切面编程）、事务管理、Web 支持等功能。
- 它不是取代现有技术，而是与它们集成，帮助开发者构建可维护、可扩展的应用。

### 1.2 Spring 的优势

- **解耦合**：通过 IoC 和依赖注入，减少代码之间的紧耦合。
- **模块化**：核心模块可独立使用，易扩展。
- **简化开发**：自动管理对象生命周期、事务等，减少 boilerplate 代码。
- **生态丰富**：支持 Spring Boot、Spring Cloud 等扩展。

### 1.3 Spring 的体系结构

![](/image/Spring/img1.png)

- **核心容器**：包括 Spring Core（IoC）、Spring Beans、Spring Context。
- **AOP 和 Instrumentation**：支持切面编程。
- **数据访问/集成**：JDBC、ORM、事务。
- **Web**：MVC、WebSocket。
- **测试**：单元测试支持。

## 2. Spring 两大核心

### 2.1 IoC（控制反转）

**定义**：IoC 是一种设计思想，将对象的创建和依赖管理从应用代码中转移到外部容器（Spring IoC 容器），实现解耦。

**传统问题**：手动创建依赖导致代码强耦合。例如：

```Java
public class UserService {
    private UserRepository userRepository = new MySQLUserRepository(); // 指定了具体实现
}
```

切换实现（如 PostgreSQLUserRepository）需修改并重新编译代码。

- 如果你要换成`PostgreSQLUserRepository`，你就得**改这一行代码**：

```Java
private UserRepository userRepository = new PostgreSQLUserRepository();
```

**IoC** 解决方式：业务类只依赖接口，容器注入实现。

```Java
@Component
public class UserService {
    @Autowired
    private UserRepository userRepository;
}
```

- **本质**：引入接口作为中间层，业务代码不关心具体实现。
- **切换实现**：只需修改配置（如 @Primary 注解或 Bean 定义），无需改业务代码.

**传统写法**：业务类**知道具体实现**（强耦合）。**IoC 写法**：业务类只依赖接口，由容器提供实现（解耦）。

### 2.2 AOP（面向切面编程）

**定义**：AOP 用于处理横切关注点（如日志、事务、安全），将它们从业务逻辑中分离。

**核心概念**：切面（Aspect）、切点（Pointcut）、通知（Advice，如 Before/After/Around）、织入（Weaving）。

## 3 Spring 相关 API

### 3.1 ApplicationContext

IoC 容器的主要接口，代表应用上下文，提供 Bean 管理、事件发布等。

### 3.2 ApplicationContext 的实现类

- **ClassPathXmlApplicationContext**：从 classpath 加载 XML。
- **FileSystemXmlApplicationContext**：从文件系统加载。
- **AnnotationConfigApplicationContext**：基于注解配置。

### 3.3 getBean 的使用方法

- **用 ID**：app.getBean("userService")（返回 Object，需要强转）
- **用 ID 和类型**：app.getBean("userService", UserService.class)（推荐）
- **用反射**：app.getBean(UserService.class)（如果唯一）

## 4. Spring 快速使用（基本流程及概念）

- 引入坐标（Maven POM）

```XML
<dependencies>
    <dependency>
        <groupId>org.springframework</groupId>
        <artifactId>spring-context</artifactId>
        <version>5.0.5.RELEASE</version> <!-- 可更新到最新版本，如 6.x -->
    </dependency>
</dependencies>
```

- 创建接口及实现类（创建Bean）
- 在 resource 下创建 spring 的配置文件 applicationContext.xml
- 在配置文件中进行配置（默认无参构造）

```XML
<bean id="userDao" class="com.test.dao.impl.UserDaoImpl"></bean>
```

- 在测试代码中获得 applicationContext 对象，通过提供的方法对 bean 进行操作

```Java
public class UserDaoDemo {
    public static void main(String[] args) {
        ApplicationContext app = new ClassPathXmlApplicationContext("applicationContext.xml");
        //在编写代码时，编译器并不知道userDao具体是什么类型，所以它使用最通用的类型Object来表示。
//        Object userDao = app.getBean("userDao");
//        UserDao userDao = (UserDao) app.getBean("userDao");
        UserDao userDao = app.getBean("userDao", UserDao.class);//更建议使用
        userDao.save();
    }
}
```

### 4.1 Bean 标签基本配置

在 Spring 中，任何被 IoC 容器管理的对象都被称为 Bean。这些对象通常是由容器创建、初始化、装配和销毁的。Bean 默认情况下调用的是类中的无参构造函数，如果没有无参构造函数则不能创建成功。

基本属性：

- id：Bean 实例在 Spring 容器中的唯一标识
- class：Bean 的全限定名称

### 4.2 Bean 标签范围配置

![](/image/Spring/img2.png)

scope 为 singleton 时表示，容器中的对象只有一个

```Java
UserDao userDao1 = app.getBean("userDao",UserDao.class);
UserDao userDao2 = app.getBean("userDao",UserDao.class);
System.out.println(userDao1);
System.out.println(userDao2);//获得的bean的两个地址是一样的
```

scope 为 prototype 时表示，容器中的对象能创建多个

```Java
UserDao userDao1 = app.getBean("userDao",UserDao.class);
UserDao userDao2 = app.getBean("userDao",UserDao.class);
System.out.println(userDao1);
System.out.println(userDao2);//获得的bean的两个地址是不同的
```

### 4.3 Bean 生命周期配置

![](/image/Spring/img3.png)

可以在配置文件中定义对象初始化和销毁时要执行的方法：

```XML
<bean id="userDao" class="com.test.dao.impl.UserDaoImpl" init-method="init" destroy-method="destory"></bean>
```

### 4.4 Bean 实例化的三种方式

- 无参构造（默认）
- 静态工厂方法
- 实例工厂方法

### 4.5 Bean 的依赖注入

依赖注入（Dependency Injection, DI）是 Spring 实现控制反转（IoC）的一种具体方式。它的核心思想是：将对象的依赖关系（即对象所需的外部资源或对象）从代码中剥离，由 Spring IoC 容器动态提供，从而降低代码耦合度，提高灵活性和可测试性。

就是说对于对象 A 和 B，A（Service 层）的内部会使用 B（Dao 层）。我不想在 A 中自己去创建 B，而是让 A 中自动就含有 B 的对象**，也就是我获得的 service 层的对象自带所需 dao 层的对象**（把这种依赖关系交给 spring 容器，这个就是依赖注入）。

**传统方式中**，UserService 中需要 new UserDao

![](/image/Spring/img4.png)

```Java
public class UserService {
    private UserDao userDao = new UserDaoImpl(); // 硬编码具体实现
    public void save() {
        userDao.save();
    }
}
```

如果要切换 UserDaoImpl 为 UserDaoImpl2（如从 MySQL 切换到 PostgreSQL），必须修改 UserService 的代码并重新编译，违背了开闭原则（对扩展开放，对修改关闭）。

**DI 的解决方式：** Spring IoC 容器负责创建和管理依赖对象，业务代码只依赖接口，由容器注入具体实现。切换实现（如从 UserDaoImpl 到 UserDaoImpl2）只需修改配置（XML 或注解），无需更改业务代码。

![](/image/Spring/img5.png)

### 4.6 依赖注入的方式

- set 方法（配置文件 name 的值为 set 方法去掉 set，然后首字母大写变小写）

```XML
<bean id="userDao" class="com.test.dao.impl.UserDaoImpl" scope="prototype"></bean>

<bean id="userService" class="com.test.service.impl.UserServiceImpl">
    <property name="userDao" ref="userDao"></property>
</bean>
```

在 xml 文件中表明通过 userService 中的 setUserDao 方法将 UserDao 注给了 UserService。

```Java
public class UserServiceImpl implements UserService {
    private UserDao userDao;
    public void setUserDao(UserDao userDao) {
        this.userDao = userDao;
    }
    @Override
    public void save() {
        userDao.save();
    }
}
```

- 构造方法（name 是构造方法的参数名）

```XML
<bean id="userService" class="com.test.service.impl.UserServiceImpl">
    <constructor-arg name="userDao" ref="userDao"></constructor-arg>
</bean>
```

### 4.7 Bean 的依赖注入的数据类型

- 普通数据类型：使用 value 属性。
- 引用数据类型：使用 ref 属性。
- 集合数据类型：使用 list/set/map 等标签。

### 4.8 引入其他配置文件

使用 import 引用其他的配置文件

```XML
<import resource="classpath:other.xml"/>
```

### 4.9 重点配置总结

![](/image/Spring/img6.png)

## 5 Spring 注解开发（需要配置组件扫描）

**目的**：通过注解声明 Bean、注入依赖、配置容器，减少 XML 配置。

**前提**：需要引入 context 命名空间同时需要在 XML 文件中启用组件扫描以支持注解：

```XML
<context:component-scan base-package="com.test"/>
```

### 5.1 Spring 原始注解（只能注入自定义的 bean）

![](/image/Spring/img7.png)

以 service 为例：

```Java
@Service // 声明为 Service 层的 Bean
public class UserService {
    @Autowired // 按类型自动注入 UserDao
    private UserDao userDao;

    @Value("admin") // 注入普通属性值
    private String role;

    public void performSave() {
        System.out.println("UserService role: " + role);
        userDao.save();
    }
}
```

@Component("")：用于 Spring 创建对象 括号内为相当于 xml 中的 id

@Autowired：自动注入，会根据声明的**类型**从 Spring 容器中查找**此类型的 Bean**。如果容器中此类型有多个 bean 就会出错

@Qualifier("")：是**按照 id 值从**容器中进行匹配的并且并于要有 @Autowired 才能使用，**如果 spring 中有多个此类型的 Bean**那就需要用 @Qualifier 指定注入

@Resource(name="")：就相当于 @Autowired+@Qualifier("")

@Controller、@Service、@Repository 与 @Component 功能一样，增强可读性

@Value("") 注入普通属性值，用于查找配置文件的值并赋值

### 5.2 Spring 新注解（用于实现配置类替代 applicationContext.xml 文件）

![](/image/Spring/img8.png)

例子：

```Java
@Configuration // 标记为 Spring 核心配置类
@PropertySource("classpath:application.properties") // 加载配置文件
public class AppConfig {
    @Bean("userDao") // 定义 Bean，名称为 userDao
    public UserDao userDao() {
        return new UserDaoImpl();
    }
    @Bean("userService") // 定义 Bean，名称为 userService
    public UserService userService(UserDao userDao) { // 注入 userDao
        UserService service = new UserService();
        service.setUserDao(userDao);
        return service;
    }
}
```

@Configuration：标志该类是 Spring 的一个核心**配置类** (创建一个**类，用于代替 xml 配置文件**)。相比于 @Component，@Configuration 会使用 cglib 代理对象确保配置类是单例模式，也就是每次取出来的 bean 是同一个

@Bean("")：Spring 会将当前方法的返回值以指定名称存储到 Spring 容器中

@PropertySource("classpath:xxx.properties")：加载外部的配置文件，放入 Spring 容器

@Import({xxx.class,xxxx.class})：加载其他配置类

这里说一下 @Bean 和 @Component 的区别：

1. **作用对象不同**
   - @Component 注解作用于**类**上，用于标识一个类为 Spring 管理的组件，Spring 会自动扫描并实例化该类
   - @Bean 注解作用于**方法**上，用于手动定义一个 Bean 对象，方法的返回值将被纳入 Spring 容器
2. **使用场景不同**
   - @Component 适用于**自定义类**，通过类路径扫描自动检测并注册到容器中
   - @Bean 适用于**第三方类**（无法修改源代码添加 @Component）或需要**复杂配置**的对象创建
3. **配置方式不同**
   - @Component 是**自动配置**，只需在类上标注，配合 @ComponentScan 即可被 Spring 扫描到
   - @Bean 是**手动配置**，需要在配置类（标注 @Configuration）中定义方法，显式返回 Bean 实例
