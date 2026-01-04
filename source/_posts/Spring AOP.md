---
title: Spring AOP
date: 2023-04-08 19:44:21
excerpt: Spring AOP（面向切面编程）是一种强大的编程范式，将日志记录、事务管理和安全性等横切关注点与核心业务逻辑分离，提升代码的模块化与可维护性。通过动态代理（JDK 或 CGLIB），Spring AOP 在运行时将增强逻辑织入目标方法，无需修改原始代码。
tags:
  - SSM
  - 开发框架
categories:
  - 技术
---

## 1 Spring AOP简介

Spring 的 AOP（面向切面编程，Aspect-Oriented Programming）是一种编程范式，用于将横切关注点（如日志记录、事务管理、安全性等）与业务逻辑分离，从而提高代码的模块化、可维护性和可重用性。

AOP 的核心是通过不修改原有业务代码的情况下，将通用功能（横切关注点）动态“织入”到程序执行流程中。具体来说，它可以对对象的某个方法进行增强，而无需侵入源代码。

**补充说明**：AOP 解决了传统 OOP（面向对象编程）中难以处理的“交叉关注”问题，例如在多个方法中重复添加日志代码。通过 AOP，这些重复逻辑可以集中管理。

## 2 AOP 的作用及优势

Spring AOP 通过代理对象操作而非修改原始对象，带来以下好处：

1. **非侵入性**：原始业务逻辑代码无需更改，保持纯粹，易于维护。
2. **模块化**：横切关注点（如日志、事务）集中定义在切面中，逻辑清晰，易于修改和复用。
3. **动态性**：运行时通过代理动态织入切面逻辑，支持灵活调整（如启用/禁用日志）。
4. **解耦合**：将横切关注点与业务逻辑分离，降低代码耦合度，业务代码专注核心功能。

解耦合的体现（业务代码尽可能不修改）：在传统开发中，日志或事务代码混杂在业务方法内，修改日志需更改每个业务方法。使用 AOP 后，这些逻辑抽取到独立切面，业务代码无需关心实现细节，修改切面不影响业务。

## 3 AOP 的底层实现

AOP 的底层是通过 Spring 提供的的**动态代理技术**实现的。在运行期间，Spring AOP 会在 Spring 容器初始化 Bean 时，为需要应用切面的目标对象生成代理对象。然后通过代理对象在运行时拦截目标方法的调用，并将增强逻辑（Advice，例如日志记录、事务管理等）与目标方法结合。（原始对象的代码和行为没有被修改）

### 3.1 AOP 动态代理技术

![](/image/SpringAOP/img1.png)

Spring AOP 支持两种动态代理：

JDK：根据目标对象找接口，然后在根据接口生成目标对象（代理对象只复刻了接口里的方法）

cglib：为目标对象的类生成子类对象（代理对象只复刻了父类里的方法）

目标对象：要被增强的类的对象

代理对象：代理对象是目标对象的“替身”，它**拦截对目标方法的调用**，并在前后执行额外逻辑（增强）代理对象**持有目标对象的引用**，通过这个引用访问目标对象的属性或方法，但不复制其属性或方法代码。**有目标对象方法的调用能力，但并不直接复制目标对象的方法代码，代理对象使用接口或父类中的方法，最终还是通过原对象调用**

### 3.2 JDK和cglib的性能对比

| 性能维度         | JDK 动态代理                                | CGLIB 动态代理                         | 核心原因                                                     |
| ---------------- | ------------------------------------------- | -------------------------------------- | ------------------------------------------------------------ |
| **对象创建速度** | 快（约是 CGLIB 的 2~5 倍）                  | 慢                                     | JDK 代理：仅通过反射生成实现接口的代理类，逻辑简单、字节码生成量少；CGLIB：需通过 ASM 框架解析目标类字节码→生成子类→重写所有非 final 方法→增强字节码，步骤多、字节码操作开销大。 |
| **方法调用速度** | 慢（约是 CGLIB 的 1~2 个数量级）            | 快                                     | JDK 代理：调用时需通过`InvocationHandler.invoke()`反射执行`Method.invoke()`，反射存在参数拆箱 / 装箱、权限检查、方法匹配等固定开销；CGLIB：调用时直接执行子类重写的方法，通过`MethodInterceptor.intercept()`直接调用目标方法（无反射），仅多一层简单的拦截逻辑。 |
| **内存占用**     | 低                                          | 高                                     | JDK 代理类仅实现接口，结构简单、字节码体积小；CGLIB 代理类是目标类的子类，包含目标类所有方法的重写逻辑，字节码体积大、实例占用内存更多。 |
| **JDK 版本影响** | JDK 7 + 逐步优化反射，JDK 11 + 性能提升明显 | 不受 JDK 版本直接影响（依赖 ASM 版本） | JDK 7 后优化了反射调用的缓存机制，JDK 11 进一步降低了`Method.invoke()`的开销，但仍不如 CGLIB 的直接调用；CGLIB 的性能仅和 ASM 版本相关（Spring 5 + 整合的 CGLIB 已优化）。 |

性能差异的 “优劣” 不是绝对的，核心看你的**使用场景**：

1. 单例场景（如 Spring Bean 默认单例）—— CGLIB 更优

- 特点：代理对象**仅创建一次**，后续高频调用方法；
- 性能逻辑：创建阶段的慢（CGLIB）只发生一次，可忽略；调用阶段的快（CGLIB）会在高频调用中持续体现优势，整体性能远超 JDK 代理。
- 实际场景：Spring AOP 中绝大多数 Bean 是单例，因此 Spring 5 + 默认对有接口的类也可配置优先用 CGLIB（`proxyTargetClass = true`）。

2. 多例场景（频繁创建代理对象）—— JDK 更优

- 特点：代理对象**频繁创建 / 销毁**（比如每次请求都生成新代理）；
- 性能逻辑：CGLIB 创建对象的高开销会被放大（每次创建都要做字节码操作），而 JDK 创建快的优势会抵消调用慢的问题（若调用次数少），整体性能更优。
- 实际场景：多例 Bean、短生命周期的代理对象（如请求级别的临时对象）。

3. 极致高频调用（如每秒上万次方法调用）—— CGLIB 优势极大

- 反射的固定开销在高频调用下会被无限放大：比如 JDK 代理调用 100 万次方法耗时 1 秒，CGLIB 可能仅需 0.1 秒；

4. 小对象 + 低调用频率 —— 差异可忽略

- 比如代理对象创建后仅调用几次方法，JDK 和 CGLIB 的耗时差异可能只有几微秒，在业务层面完全感知不到；
- 此时无需刻意选择，优先遵循框架默认规则（如 Spring 的默认代理策略）即可。

**使用配置方式：**

在springboot下，直接在`application.properties`/`application.yml`中配置即可

1. application.properties（键值对格式）

```java
# 强制使用CGLIB代理（推荐单例Bean场景）
spring.aop.proxy-target-class=true

# 恢复默认（有接口用JDK，无接口用CGLIB）
# spring.aop.proxy-target-class=false
```

2. application.yml（YAML 格式）

```yaml
spring:
  aop:
    proxy-target-class: true  # 强制CGLIB
    # proxy-target-class: false  # 默认规则
```

### 3.3 JDK 的动态代理过程（了解）

(Spring 中通常用 XML 或注解配置 AOP，而非手动编写代理，以简化开发)

- **定义接口**：将 OrderService 接口放入单独的文件，定义业务方法。
- **实现类**：将 OrderServiceImpl 放入单独的文件，作为目标对象实现业务逻辑。

```Java
public class OrderServiceImpl implements OrderService {
    @Override
    public void createOrder() {
        System.out.println("订单创建成功");
    }
}
```

- **代理逻辑**：将 LoggingInvocationHandler 放入单独的文件，定义增强逻辑。

```Java
public class LoggingInvocationHandler implements InvocationHandler {
    private final Object target;

    public LoggingInvocationHandler(Object target) {
        this.target = target;
    }
    @Override
    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
        System.out.println("日志: 方法 " + method.getName() + " 开始执行");
        Object result = method.invoke(target, args);
        System.out.println("日志: 方法 " + method.getName() + " 执行结束");
        return result;
    }
}
```

- **主程序**：将主程序 JdkDynamicProxyExample 放入单独的文件，负责创建目标对象、生成代理对象并调用。

```Java
public class JdkDynamicProxyExample {
    public static void main(String[] args) {
        // 创建目标对象
        OrderService target = new OrderServiceImpl();

        // 创建 InvocationHandler
        LoggingInvocationHandler handler = new LoggingInvocationHandler(target);

        // 生成代理对象
        OrderService proxy = ( ages/OrderService) Proxy.newProxyInstance(
            target.getClass().getClassLoader(),
            target.getClass().getInterfaces(),
            handler
        );

        // 通过代理对象调用方法
        proxy.createOrder();
    }
}
```

### 3.4 cglib 的动态代理（了解）

## 4 AOP 使用方法

Spring 的 AOP 实现底层就是对上面的动态代理的代码进行了封装，封装后只需要对需要关注的部分进行代码编写。首先要了解 AOP 相关的基本概念：

- **Target（目标）**：被增强的对象。
- **Proxy（代理）**：增强后的对象。
- **Joinpoint（连接点）**：可以被增强的方法（如目标类的所有方法）。
- **Pointcut（切入点）**：实际被增强的连接点（选中的方法）。
- **Advice（通知/增强）**：织入到切入点的逻辑（如前置、后置通知）。
- **Aspect（切面）**：切入点 + 通知的组合。
- **Weaving（织入）**：将切点与通知结合的 process。

代理目标有 10 个方法可以被增强，那这 10 个方法叫连接点，其中只有 5 个被增强了，那么这 5 个方法就叫切入点

### 4.1 AOP 开发明确的事项

- 使用 xml 或者注解的方式配置织入关系
- 框架会自动选择使用哪种动态代理方式，如果目标实现接口用 JDK 代理；否则用 CGLIB。
- Spring 默认使用 JDK，需配置可切换。

### 4.2 基于 XML 的 AOP 开发

#### 4.2.1 步骤

1. 引入 AOP 坐标（Maven 依赖）
2. 创建目标类和切面类

```XML
<!-- method="before"：增强方法（目标方法增强的逻辑）。pointcut：切入点（被增强的方法）-->
<!-- 目标类 Bean -->
<bean id="target" class="com.zqc.aop.Target"/>
<!-- 切面类 Bean -->
<bean id="myAspect" class="com.zqc.aop.MyAspect"/>
```

3. XML 配置 AOP。

```XML
<!-- 配置织入 告诉哪些方法需要进行哪些增强 -->
<!-- 将 before 方法作为前置通知织入到 com.aop.Target 类的 save 方法的执行流程中 -->
<aop:config>
    <aop:aspect ref="myAspect">
        <aop:before method="before" pointcut="execution(public void com.zqc.aop.Target.save())"/>
    </aop:aspect>
</aop:config>
```

#### 4.2.2 切点表达式的写法

使用 execution() 指定：

- execution(public void com.zqc.aop.Target.method())
- 通配符：*（任意）、..（任意参数/包）。

示例：execution(* com.zqc.aop.*.*(..))：匹配包下所有类所有方法。

#### 4.2.3 通知的类型

| 名称         | 标签                | 说明                                             |
| ------------ | ------------------- | ------------------------------------------------ |
| 前置通知     | aop:before          | 方法执行前织入，常用于日志或权限检查。           |
| 后置通知     | aop:after-returning | 方法正常返回后织入，常用于资源释放。             |
| 环绕通知     | aop:around          | 方法前后织入，可控制执行，常用于事务或性能监控。 |
| 异常抛出通知 | aop:after-throwing  | 方法抛异常时织入，常用于异常处理。               |
| 最终通知     | aop:after           | 方法结束时织入（无论正常或异常），常用于清理。   |

#### 4.2.4 切点表达式的抽取

在 AOP 配置中，切点表达式用于指定哪些方法需要被增强（例如，哪些方法需要添加日志或事务）。如果多个通知（如前置通知、后置通知等）需要应用到相同的切点，重复写相同的表达式会导致代码冗余，且后期修改时需更改多处。

```XML
<!-- 定义切点 -->
<aop:pointcut id="myPointcut" expression="execution(* com.example.aop.service.*.*(..))"/>

<!-- 引用切点 这里的切点就不需要再使用表达式指定对应的切点了 -->
<aop:config>
    <aop:aspect ref="myAspect">
        <aop:before method="before" pointcut-ref="myPointcut"/>
        <aop:after method="after" pointcut-ref="myPointcut"/>
    </aop:aspect>
</aop:config>
```

### 4.3 基于注解的 AOP 开发

#### 4.3.1 步骤

1. 引入 AOP 坐标。
2. 创建目标类和切面类，使用注解。
3. 启用 AOP 注解支持。在 Spring 配置类中添加 @EnableAspectJAutoProxy，启用 AOP 自动代理。
4. **创建切面类并配置切点与通知**
   - 使用 @Aspect 标记切面类。
   - 使用 @Pointcut 定义切点，指定需要增强的方法。
   - 使用 @Before、@After、@Around 等注解定义通知逻辑。

#### 4.3.2 常用注解

![](/image/SpringAOP/img2.png)

#### 4.3.3 示例

```Java
@Component
public class OrderService {
    public void createOrder() {
        System.out.println("订单创建成功");
    }
}
```

```Java
@Aspect
@Component
public class LoggingAspect {
    // 定义切点（被织入后的方法）service 下的所有方法都要被增强
    @Pointcut("execution(* com.example.aop.service.*.*(..))")//用于指定 Spring AOP 在哪些方法上应用增强逻辑
    public void serviceMethods() {}//本身没有实际逻辑，仅作为这个切点的名称

    // 环绕增强
    @Around("serviceMethods()")//JoinPoint 包含了被拦截方法的元信息
    public Object logAround(JoinPoint joinPoint){
        System.out.println("日志:方法" + joinPoint.getSignature().getName() + "开始执行");
        Object result = joinPoint.proceed(); // 执行目标方法
        System.out.println("日志:方法" + joinPoint.getSignature().getName() + "执行结束");
        return result;
    }
}
```

```Java
public class Main {
    public static void main(String[] args) {
        // 创建 Spring 容器
        AnnotationConfigApplicationContext context = new AnnotationConfigApplicationContext(AopConfig.class);
        // 获取目标对象（实际是代理对象）
        OrderService orderService = context.getBean(OrderService.class);
        // 调用方法
        orderService.createOrder(); 
        // 关闭容器
        context.close();
    }
}
```
