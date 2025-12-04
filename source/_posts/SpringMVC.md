---
title: SpringMVC
date: 2023-04-16 19:27:01
excerpt: Spring MVC 是一个基于 Java 的 Web 框架，通过 DispatcherServlet 统一处理 HTTP 请求，结合注解或和配置，实现灵活的请求映射和数据响应。支持页面跳转、JSON 数据处理及 RESTful 风格开发，核心组件包括 HandlerMapping、HandlerAdapter 和 ViewResolver，简化 Web 开发流程。
tags:
  - SSM
  - 开发框架
categories: 技术
---

# SpringMVC 概述

Spring MVC 是一个基于 Java 的 Web 框架，集成在 Spring 框架中，用于处理 HTTP 请求和响应。它通过 DispatcherServlet（前端控制器）协调请求的分发，结合注解和配置，提供强大的 Web 开发能力。

以前每个业务可能需要单独的 Servlet，现在 Spring MVC 使用一个 DispatcherServlet 统一接收请求，再根据 @RequestMapping 映射到对应的 Controller 处理业务。

![](/image/SpringMVC/img1.png)

客户端发送的所有请求首先被 DispatcherServlet 接收（它是整个 Spring MVC 的入口）。DispatcherServlet 根据请求路径（如 /user/list），通过 HandlerMapping （根据请求的地址以及其他条件）找到对应的 Controller 方法。

## 1 功能及步骤

开发步骤

- 导入 SpringMVC 坐标（spring-webmvc）

```xml
<dependency>
  <groupId>org.springframework</groupId>
  <artifactId>spring-webmvc</artifactId>
  <version>6.1.14</version>
</dependency>
```

- 配置 SpringMVC 前端控制器 DispatcherServlet，封装共有的行为（可以配置拦截器**Interceptor**）

```xml
<!-- 配置前端控制器 -->
<servlet>
  <servlet-name>DispatcherServlet</servlet-name>
  <servlet-class>org.springframework.web.servlet.DispatcherServlet</servlet-class>
  <init-param><!-- 声明配置文件 -->
    <param-name>contextConfigLocation</param-name>
    <param-value>classpath:spring-mvc.xml</param-value>
  </init-param>
  <load-on-startup>1</load-on-startup> <!-- 服务器启动就加载 tomcat 来创建加载定义的 servlet -->
</servlet>
<servlet-mapping><!-- 告诉 Servlet 容器（如 Tomcat）哪些 HTTP 请求应该由该 Servlet 处理 -->
  <servlet-name>DispatcherServlet</servlet-name>
  <url-pattern>/</url-pattern>
</servlet-mapping>
```

- 创建 Controller 类（代替自定义的 Servlet）和视图页面

```java
@Controller
public class UserController {
    @RequestMapping("/quick")
    public String save(){
        System.out.println("Controller save running");
        // 没有配置视图解析器的情况下 success.jsp 和 /success.jsp 的区别
        // /success.jsp 为绝对路径 直接跳转到 Web 根目录下的 /success.jsp
        // success.jsp 为逻辑视图名 技术上是找 /quick/success.jsp，但因为这个路径找不到，它会去找 /success.jsp
        return "success.jsp";
    }
}
```

- 使用注解配置 Controller 类中业务方法的映射地址（@RequestMapping("/xxx")）
- 配置 SpringMVC 核心文件 spring-mvc.xml，配置控制器、视图解析器、静态资源、拦截器（filter）等（以后用配置类）

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:context="http://www.springframework.org/schema/context"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd http://www.springframework.org/schema/context https://www.springframework.org/schema/context/spring-context.xsd">

    <!-- Controller 自动扫描 扫描带有特定注解的类交给 spring 注册 -->
    <context:component-scan base-package="com.test.controller"></context:component-scan>
</beans>
```

- 客户端发起请求

## 2 SpringMVC 组件解析

三大组件

- **HandlerMapping**：处理器映射器，匹配请求到 Controller。
- **HandlerAdapter**：处理器适配器，执行 Controller 方法。
- **ViewResolver**：视图解析器，解析逻辑视图到物理视图。

### 2.1 SpringMVC 执行流程

![](/image/SpringMVC/img2.png)

### 2.2 SpringMVC 注解解析

**@RequestMapping：**

**作用**

- 用于映射请求 URL 和处理方法，控制 HTTP 请求到特定 Controller 方法。
- 支持多种属性配置灵活性。

**属性**

- **value**：指定请求 URL（与 path 等效），如 /quick。
- **method**：指定 HTTP 方法（GET、POST 等），默认支持所有方法。
- **params**：指定请求参数条件，如 params={"accountName"} 或 params={"money!=100"}。
- **补充**：value 是必需属性，method 和 params 可选，用于精确匹配请求。

**@RequestBody：** 接收 HTTP 请求的 JSON 数据，将 JSON 转换为 Java 对象

**@ResponseBody：** 将 Controller 方法返回对象转化为字符串/JSON（不走视图）

**@RestController**：@Controller + @ResponseBody，简化 REST API。

### 2.3 SpringMVC 的 XML 配置文件

#### 2.3.1 视图解析器

DispatcherServlet.properties 可以开启组件扫描外，还可以对组件进行配置

![](/image/SpringMVC/img3.png)

**视图解析器**推荐配置，不配置会使用框架默认的（在 DispatcherServlet.properties 文件中）

假设 page.jsp 在 webapp/view 下

```xml
<bean id="viewResolver" class="org.springframework.web.servlet.view.InternalResourceViewResolver">
    <property name="prefix" value="/view/"/>
    <property name="suffix" value=".jsp"/>
</bean>
```

配置完视图解析器后，控制跳转方式（转发或重定向）主要通过控制器方法的返回值或显式使用 RedirectView 来实现

**转发（Forward）**是服务器内部跳转，客户端无感知，URL 不变，请求数据保留。

```java
@Controller
public class MyController {
    @RequestMapping("/toPage")
    public String toPage() {
        return "page"; // 逻辑视图名，解析为 /view/page.jsp，默认为转发
    }
    
    @RequestMapping("/explicitForward")
    public String explicitForward() {
        return "forward:/view/page.jsp"; // 显式转发
    }
}
```

**重定向不会经过视图解析器**，所以它跳的是路径

```java
@RequestMapping("/home")
public String redirectHome() {
    return "redirect:/view/home.jsp";
}
```

## 3 SpringMVC 的数据响应

### 3.1 SpringMVC 的数据响应方式

- 页面跳转：返回字符串或 ModelAndView。
- 回写数据：字符串、JSON（需 @ResponseBody）。

### 3.2 页面跳转

**1. 返回字符串**（return 字符串）

- 默认转发：return "page";（经视图解析器）。
- 显式转发：return "forward:/view/page.jsp";。
- 重定向：return "redirect:/view/home.jsp";。

只 return 一个字符串默认转发，可以配置视图解析器（只有转发会经过视图解析器）

使用前缀显示的控制转发和重定向的路径

```java
@RequestMapping("/toPage")
public String toPage() {
    return "page";  // 转发到 /view/page.jsp
}
```

**2. 返回 ModelAndView 对象**

方法 1

```java
@RequestMapping("/quick2")
public ModelAndView save2(){
    ModelAndView modelAndView = new ModelAndView();
    modelAndView.addObject("username","zqc");
    modelAndView.setViewName("success");
    return modelAndView;
}
```

跳转到 success.jsp 把数据转发到 success 页面（用 EL 表达式接 ${username}）

方法 2

```java
@RequestMapping("/quick3")
public ModelAndView save2(ModelAndView modelAndView){
    modelAndView.addObject("username","zqc");
    modelAndView.setViewName("success");
    return modelAndView;
}

@RequestMapping("/quick4")
public String save3(Model model){
    model.addAttribute("username","zqc");
    return "success";
}
```

Spring MVC 的容器会自动为方法参数提供一个实例

### 3.2 回写数据 @ResponseBody 告诉 SpringMVC 返回的是字符串

**字符串**：

```java
@RequestMapping("/quick5")
@ResponseBody
public String quickMethod5() {
    return "Hello SpringMVC!!!";
}
```

**JSON：**

1. 使用 Jackson 返回 JSON（需 Jackson 依赖）

```java
@RequestMapping("/quick6")
@ResponseBody
public User save6() {
    User user = new User("lisi", 30);
    ObjectMapper objectMapper = new ObjectMapper();
    String json = objectMapper.writeValueAsString(user);
    return json ;
}
```

2. Spring MVC **框架可以自动将对象转为 JSON，要先告诉它（配置消息转换器）**

**在 spring-mvc.xml 文件中进行配置** JSON 转换，直接返回 JSON（要加 @ResponseBody）

1. **使用 MVC 注解驱动的方法（<mvc:annotation-driven> ）推荐**

可以不进行额外配置直接使用 **<mvc:annotation-driven>** 实现 JSON 转换，前提条件如下：

- **依赖已添加**：项目中包含 Jackson 相关依赖（如 jackson-databind）。
- **注解使用正确**：使用 @ResponseBody 返回对象或 @RequestBody 接收 JSON 数据。

在 spring-mvc.xml 中配置，需要 mvc 命名空间

## 4 SpringMVC 获取请求数据

### 4.1获得基本类型参数

Controller 中的参数名称与请求参数的 name 一致，参数值会自动映射匹配

http://localhost:8080/springmvc1/quick9?username=zhangsan&age=12

```java
@RequestMapping("/quick")
public void save(String username, int age) {
    System.out.println(username + ", " + age);
}
```

### 4.2 获得 POJO（简单类）类型的参数

通过判断 URL 中的参数名与类的属性名配对，直接封装到相应类中

```java
@RequestMapping("/quick7")
@ResponseBody
public void save7(User user) {
    System.out.println(user);
}
```

### 4.3 获得数组类型的参数

Controller 中的业务方法数组名称与请求参数的 name 一致，参数值会自动映射匹配。

http://localhost:8080/springmvc/quick8?strs=111&strs=222&strs=333

```java
@RequestMapping("/quick8")
@ResponseBody
public void save8(String[] strs) {
    System.out.println(Arrays.asList(strs));
}
```

### 4.4 获得集合类型的参数

#### 4.4.1 表单提交多个实例时

如果前端提交的数据是多个实例，要创建一个 POJO 容器包装所有接收到的实例

```java
public class VO {
    private List<User> userList;
    // getter/setter
}
```

表单中 name 值为第 i 个 user 对象的属性值

```xml
<body>
    <form action="${pageContext.request.contextPath}/user/quick14" method="post">
        <%-- 第一个 User 对象的 username 和 age --%>
        <input type="text" name="userList[0].username"><br/>
        <input type="text" name="userList[0].age"><br/>
        <%-- 第二个 User 对象的 username 和 age --%>
        <input type="text" name="userList[1].username"><br/>
        <input type="text" name="userList[1].age"><br/>
        <input type="submit" value="提交">
    </form>
</body>
```

**提交 userList[0].username="xxx" 到 UserController 后，SpringMVC 创建 VO 对象，比较参数名和 VO 类中的属性名，直接进行封装**

```java
@RequestMapping("/quick9")
@ResponseBody
public void save9(VO vo) {
    System.out.println(vo.getUserList());
}
```

#### 4.4.2 使用 AJAX 提交（@RequestBody）

当使用 AJAX 提交时，可以指定 contentType 为 JSON 形式，那么在方法参数位置使用 @RequestBody 可以直接接收集合数据而无需使用 POJO 进行包装。

AJAX 提交（JSON 格式）数据：

```xml
<script src="${pageContext.request.contextPath}/js/jquery-3.3.1.js"></script>
<script>
// 创建用户列表数组
var userList = new Array();
// 向数组添加用户对象
userList.push({username: "zhang san", age: 18});
userList.push({username: "lisi", age: 28});

// 发送 AJAX 请求
$.ajax({
    type: "POST",
    url: "${pageContext.request.contextPath}/user/quick10",
    data: JSON.stringify(userList),  // 将 JavaScript 对象转换为 JSON 字符串
    contentType: "application/json; charset=utf-8",  // 指定请求内容类型为 JSON
    success: function(response) {
        // 请求成功后的处理逻辑
        console.log("请求成功", response);
    },
    error: function(xhr) {
        // 请求失败后的处理逻辑
        console.error("请求失败", xhr);
    }
});
</script>
```

直接获得 AJAX 提交的集合（要使用 @RequestBody）

```java
@RequestMapping(value="/quick10")
@ResponseBody
public void save10(@RequestBody List<User> userList) throws IOException {
    System.out.println(userList);
}
```

**注意**：**Spring MVC 的核心是通过 DispatcherServlet 拦截所有请求**，然后根据配置将请求分发给对应的处理器。使用 JS 要在 XML 文件中配置（页面用了 jQuery 会自动发送 jQuery 请求，不配置 SpringMVC 会把 jQuery.js 发送的请求也当成 RequestMapping 进行匹配，要**放行静态资源**，不让 SpringMVC 对其进行匹配）

**配置方式**：

1. 在 spring-mvc.xml 配置文件中添加静态资源映射**（传统 Spring MVC 项目）**

```xml
<!-- 方式 1：放行指定目录的静态资源 -->
<mvc:resources mapping="/js/**" location="/js/"/>
<mvc:resources mapping="/css/**" location="/css/"/>
<mvc:resources mapping="/images/**" location="/images/"/>
<!-- 方式 2：使用默认 Servlet 处理静态资源（推荐） -->
<mvc:default-servlet-handler/>
```

2. Java 配置类
3. Spring Boot

Spring Boot 对静态资源有默认处理规则，无需额外配置即可访问以下目录的静态资源

- classpath:/static/
- classpath:/public/
- classpath:/resources/
- classpath:/META-INF/resources/

如果需要自定义路径，可在 application.properties 或 application.yml 中配置

### 4.5 请求数据乱码问题

当 POST 请求时，数据会出现乱码，我们可以设置一个过滤器来进行编码的过滤（web.xml）

```xml
<filter>
    <filter-name>CharacterEncodingFilter</filter-name>
    <filter-class>org.springframework.web.filter.CharacterEncodingFilter</filter-class>
    <init-param>
        <param-name>encoding</param-name>
        <param-value>UTF-8</param-value>
    </init-param>
</filter>
<filter-mapping>
    <filter-name>CharacterEncodingFilter</filter-name>
    <url-pattern>/*</url-pattern>
</filter-mapping>
```

### 4.6 参数绑定注解 @RequestParam

自定义参数映射，显示绑定传递来的参数名称和 Controller 业务方法的参数的对应

```java
@RequestMapping("/quick11")
public void quickMethod11(@RequestParam(value="name") String username) {
    System.out.println(username);
}
```

将传递过来的 name 值赋值给 username

注解 @RequestParam 还有如下参数可以使用：

- **value**：请求参数名称
- **required**：指定某个请求参数是否必须包括，默认是 true，提交时如果没有此参数则报错
- **defaultValue**：当没有指定请求参数时，则使用指定的默认值赋值

### 4.7 获得 Restful 风格的参数（@PathVariable 进行占位符匹配，可以方便的使用 Restful 风格）

REST（Representational State Transfer）是一种架构风格，它强调资源（Resource）的表示状态转移，通过 HTTP 方法（GET、POST、PUT、DELETE 等）操作资源，而不是传统的基于动作的 URL 设计。RESTful 是一种设计 API 的规范，广泛用于 Web 服务。

RESTful 使用 HTTP 方法映射 CRUD 操作：

- **GET**：读取资源（查询）
- **POST**：创建资源
- **PUT**：更新资源
- **DELETE**：删除资源

```java
@RequestMapping("/quick12/{name}")
@ResponseBody
public void quickMethod12(@PathVariable("name") String username) {
    System.out.println(username);
}
```

**补充**：@RequestMapping("/quick/{name}", method=RequestMethod.GET) 可以设置请求方法，默认支持所有方法，加上 GET 等类型只支持对应的请求。方法上的注解可替换为 @GetMapping("/quick/{name}")，类上的注解一般还是写 **@RequestMapping**（作为一级路径）

```java
// PostMapping 中只有 {status}，参数中只要给 status 加上 @PathVariable 将变量绑定到控制器方法的参数上
@GetMapping("/status/{status}")
public Result startOrStop(@PathVariable Integer status, Long id) {
    return Result.success();
}
```

### 4.8 三个**形参注解**的区别和应用

**@RequestBody，@RequestParam，@PathVariable**

**区别**：

- **@RequestParam** 用于接收 URL 地址传参或表单传参，显示绑定参数映射关系
- **@RequestBody** 用于接收 JSON 数据
- **@PathVariable** 用于接收路径参数进行占位符匹配，使用 {参数名称} 描述路径参数

**应用**：

- 后期开发中，发送请求参数超过 1 个时，以 JSON 格式为主，@RequestBody 应用较广
- 如果发送非 JSON 格式数据，选用 @RequestParam 接收请求参数
- 采用 RESTful 进行开发，当参数数量较少时，例如 1 个，可以采用 @PathVariable 接收请求路径变量，通常用于传递 id 值

### 4.9 注解简化

**@RestController**

类注解，用于设置当前控制器类为 RESTful 风格，等同于 @Controller 与 @ResponseBody 两个注解组合

**@GetMapping（@PostMapping，@PutMapping，@DeleteMapping）**

方法注解，设置当前控制器方法请求访问路径与请求动作，每种对应一个请求动作

### 4.10 自定义类型转换器

- Spring MVC 默认提供了一些常用的类型转换器，例如客户端提交的字符串转成 int 型进行参数设置。
- 但是不是所有的类型数据都提供了转换器，没有提供的就需要自定义转换器，例如：日期类型的数据就需要自定义转换器

**自定义类型转换器开发步骤**：

1. 定义转换器类实现 Converter 接口
2. 在配置文件中声明转换器
3. 在 <annotation-driven> 中引用转换器

### 4.11 获得 Servlet 相关 API

Spring MVC 支持使用原始 Servlet API 对象作为控制器方法的参数进行注入，常用的对象如下：

- HttpServletRequest
- HttpServletResponse
- HttpSession

```java
@RequestMapping("/quick16")
@ResponseBody
public void quickMethod16(HttpServletRequest request, HttpServletResponse response, HttpSession session) {
    System.out.println(request);
    System.out.println(response);
    System.out.println(session);
}
```

### 4.12获得请求头

#### @RequestHeader

使用 @RequestHeader 可以获得请求头信息，相当于 Web 阶段学习的 request.getHeader(name)

**注解的属性如下**：

- **value**：请求头的名称
- **required**：是否必须携带此请求头

#### @CookieValue

使用 @CookieValue 可以获得指定 Cookie 的值

**注解属性如下**：

- **value**：指定 Cookie 的名称
- **required**：是否必须携带此 Cookie
