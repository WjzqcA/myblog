---
title: SpringMVC拦截器及异常处理
date: 2023-04-26 11:35:04
excerpt: 拦截器用于请求的预处理和后处理，可实现日志记录、权限检查等功能，通过实现 HandlerInterceptor 接口并在 springmvc.xml 或 WebMvcConfigurer 中配置。异常处理提供 SimpleMappingExceptionResolver 和自定义 HandlerExceptionResolver 两种方式，用于映射异常到视图或自定义错误处理逻辑。
tags:
  - SSM
  - 开发框架
categories: 技术
---

# 1 拦截器

Spring MVC 的拦截器类似于 Servlet 的 Filter，用于对请求进行预处理和后处理。拦截器是面向切面编程（AOP）的具体应用（不是严格的 Spring AOP），主要用于日志记录、权限检查、性能监控等场景。多个拦截器会形成一个拦截器链，按照配置顺序执行。

## 1.1 拦截器和过滤器的区别

![](/image/mvcinter/img1.png)

Filter 可以处理所有请求（包括静态资源），而 Interceptor 只针对 HandlerMapping 映射的请求。

## 1.2 使用步骤

1. 创建拦截器类，实现 HandlerInterceptor 接口，并重写方法：
   - preHandle()：请求处理前。
   - postHandle()：请求处理后（Controller 执行后，但视图渲染前）。
   - afterCompletion()：整个请求完成后（视图渲染后）。

拦截器类：

```java
public class MyInterceptor implements HandlerInterceptor {
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        System.out.println("preHandle: 请求前处理");
        return true; // 返回 false 可中断请求
    }
    public void postHandle(HttpServletRequest request, HttpServletResponse response, Object handler, ModelAndView modelAndView) {
        System.out.println("postHandle: 请求后处理");
    }
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) {
        System.out.println("afterCompletion: 完成处理");
    }
}
```

2. 在 springmvc.xml 中配置拦截器：

```xml
<mvc:interceptors>
    <mvc:interceptor>
        <mvc:mapping path="/**" />
        <bean class="com.wjzqc.interceptor.MyInterceptor1" />
    </mvc:interceptor>
    <mvc:interceptor>
        <mvc:mapping path="/user" />
        <bean class="com.wjzqc.interceptor.MyInterceptor2" />
    </mvc:interceptor>
</mvc:interceptors>
```

3. 如果使用 Spring Boot 或 Java 配置类，可通过 WebMvcConfigurer 配置

```java
@Configuration
public class WebConfig implements WebMvcConfigurer {
    
    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        // 注册拦截器并配置规则
        registry.addInterceptor(new MyInterceptor())
                .addPathPatterns("/user/**") // 拦截路径
                .excludePathPatterns("/user/login"); // 排除路径
    }
}
```

## 1.3 拦截器方法说明

![](/image/mvcinter/img2.png)

# 2 异常处理

## 2.1 异常处理的思路

![](/image/mvcinter/img3.png)

## 2.2 异常处理的方式

- 使用 Spring MVC 提供的简单异常处理器 SimpleMappingExceptionResolver。
- 实现 HandlerExceptionResolver 接口自定义处理器。

## 2.3 简单异常处理器 SimpleMappingExceptionResolver

Spring MVC 已经定义好了该类型转换器，在使用时可以根据项目情况进行相应异常与视图的映射配置

```xml
<bean class="org.springframework.web.servlet.handler.SimpleMappingExceptionResolver">
    <property name="defaultErrorView" value="error" />
    <property name="exceptionMappings">
        <map>
            <entry key="com.wjzqca.exception.MyException" value="error" />
        </map>
    </property>
</bean>
```

defaultErrorView 为默认错误视图，若 map 中无此异常则前往默认视图，value 为跳转的视图名

## 2.4 自定义异常处理器

步骤：

1. 创建类实现 HandlerExceptionResolver 接口。
2. 重写 resolveException 方法，返回 ModelAndView（错误视图）或 null（继续抛出）。
3. 在 XML 配置 bean。
