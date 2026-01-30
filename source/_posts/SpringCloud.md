---
title: SpringCloud
date: 2025-06-21 15:25:40
excerpt: 对于SpringCloud框架，在https://github.com/mofan212/spring-cloud-demo项目的基础上，根据阅读中疑惑的地方进行了进一步的补充解释。
tags:
  - 分布式
  - 开发框架
categories : 技术
---

# 1. Nacos

![](/image/SpringCloud/img1.png)

这是一个简单的微服务架构，如果用户想要查询自己的订单，那就要向订单微服务发送请求。那么用户要怎么找到订单所在的服务器？如果访问的订单所在的服务器宕机，那么如何切换到别的服务器上的订单服务？这就需要注册中心，当一个微服务部署到服务期之后，就会在注册中心进行服务注册，下线同样也会操作注册中心。当用户想要向订单服务发送请求，就会去注册中心查找。

## 1.1 简介与下载

Nacos 是 Dynamic Naming and Configuration Service 的首字母简称，一个更易于构建云原生应用的动态服务发现、配置管理和服务管理平台。

官网：[Nacos官网](https://nacos.io/)

安装：

- 下载最新的 Nacos 安装包，本文使用 Nacos-2.5.1
- 启动命令：`startup.cmd -m standalone`（单体启动）

下载好最近的安装包后，解压到非中文目录，进入 `bin` 目录，执行启动命令。

## 1.2 服务注册

1. 在项目中引入 `spring-boot-starter-web`（微服务中）、`spring-cloud-starter-alibaba-nacos-discovery`（主项目中） 依赖

2. 编写主启动类，编写配置文件对应微服务的配置文件（分布式项目中**每个独立部署的应用模块**通常是一个独立的 Spring Boot 项目，都需要对应的配置文件），**这里的服务名称很重要，用来标识每一类微服务**

   ```yaml
   # 服务名称
   spring:
     application:
       name: service-order
   # 端口
   server:
     port: 8000
   ```

3. 配置 Naocs 地址

   ```yaml
   spring:
     cloud:
       nacos:
         # 配置 Nacos 地址
         server-addr: 127.0.0.1:8848
   ```

4. 启动微服务，配置好的服务就会自动注册到nacos中

5. 查看注册中心效果，访问 `http://localhost:8848/nacos/`，**注册中心存储了每一个微服务的名字和他的ip端口号列表**![](/image/SpringCloud/img2.png)

6. 测试集群模式启动：单机情况下通过改变端口号模拟微服务集群，例如添加复制已有应用的配置，添加Program arguments信息，修改端口号为 `--server.port=8001`等![](/image/SpringCloud/img3.png)

添加之后可以看到，实例数发生了变化

![](/image/SpringCloud/img4.png)

点击详情后可以看到存储的信息

![](/image/SpringCloud/img5.png)

## 1.3 服务发现

指的是一个微服务要使用另一个微服务如何查找

1. 开启服务发现，在主启动类（微服务类）上添加 `@EnableDiscoveryClient` 注解，这个类就可以发现注册的微服务
2. 有两款 API 的服务发现功能：`DiscoveryClient` 为 Spring 提供的服务发现标准接口，可通过spring自动注入。 `NacosServiceDiscovery`由 Nacos 提供的类，只有使用Nacos才可以使用。这两个可以获得注册中心关于每个微服务的信息。

```java
@SpringBootTest
public class DiscoveryTest {
    @Autowired
    DiscoveryClient discoveryClient;
    @Test
    void discoveryClientTest(){
        for (String service : discoveryClient.getServices()) {
            //遍历并打印所有服务名称
            System.out.println("service:" + service);
            //获取所有服务的ip+port
            for (ServiceInstance instance : discoveryClient.getInstances(service)) {
                System.out.println("ip:" + instance.getHost() + "port:" + instance.getPort());
            }
        }
    }
}
```

这里仅需要了解，在实际使用的过程中会使用封装好的自动化过程，不需要使用这些代码

## 1.4 远程调用

远程调用基本流程：

![远程调用基本流程](/image/SpringCloud/img6.svg)

**每一个实体类都在每一个的服务器上，无法方便的相互调用，可以抽取出一个专门放实体类的服务**

这里以订单服务获得productId和userId，通过订单服务获得商品列表进行订单操作为例：

首先有一个问题，如何在Order的微服务中使用Product呢？

直接新建一个和微服务同级的模块作为公共层（在微服务的上级pom里引入这个模块就可以使用），将所有的Bean抽取到里面，每一个微服务就不需要自己定义Bean了。

代码：

```java
@Slf4j
@Service
public class OrderServiceImpl implements OrderService {

    @Autowired
    DiscoveryClient discoveryClient;
    @Autowired
    RestTemplate restTemplate;

    @Override
    public Order createOrderById(Long productId, Long userId) {
        Product product = getProductFromRemote(productId);
        Order order = new Order();
        order.setId(3L);
        //总金额，这里模拟获得某个商品总数，全部购买
        order.setTotalAmount(product.getPrice().multiply(new BigDecimal(product.getNum())));
        order.setUserId(userId);
        order.setNickName("zqc");
        order.setAddress("青岛");
        order.setProductList(Arrays.asList(product));

        return order;
    }
    //从远程获得产品信息
    private Product getProductFromRemote(Long productId) {
        //1.获得商品服务所在的所有机器IP+port
        List<ServiceInstance> instances = discoveryClient.getInstances("service-product");
        ServiceInstance instance = instances.get(0);
        //http://localhost:9002/product/4 拼接获得对应服务的url地址
        String uri = "http://"+instance.getHost()+":"+instance.getPort()+"/product/"+productId;
        log.info("远程uri:"+uri);
        //2.使用RestTemplate向远程发送请求 这里可以设置一个配置类用于注册RestTemplate
        Product product = restTemplate.getForObject(uri, Product.class);//请求的uri，返回的json转为对应的class
        return product;
    }
}
```

控制台可以看到：远程uri:http://172.20.10.8:9000/product/5，那么这里有一个缺陷，每一次请求都达到同一个服务器，接下来将会配置负载均衡来解决。

## 1.5 负载均衡

如何让RestTemplate编程式请求实现负载均衡

> 使用 **LoadBalancerClient** 实现（spring cloud提供的）

注入 **LoadBalancerClient**，调用其 **choose()** 方法，传入服务名，实现负载均衡。

```java
@SpringBootTest
public class LoadBalancerTest {

    @Autowired
    LoadBalancerClient loadBalancerClient;

    @Test
    void Test(){
        //负载均衡获得一个指定名称的微服务地址（默认轮询访问）
        ServiceInstance choose = loadBalancerClient.choose("service-product");
        System.out.println("choose: " + choose.getHost() + ":" + choose.getPort());
        choose = loadBalancerClient.choose("service-product");
        System.out.println("choose: " + choose.getHost() + ":" + choose.getPort());
    }
}
```

> **使用 @LoadBalanced 注解实现（spring cloud提供的 更简单，最常用的方法）**

在配置类中对RestTemplate的 Bean上加入**@LoadBalanced**注解，这样使用**RestTemplate**向远程发送请求自动带有负载均衡功能

```java
@Configuration
public class ProductServiceConfig {

    @LoadBalanced
    @Bean
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }
}
```

```java
//从远程获得产品信息
private Product getProductFromRemote(Long productId) {
    //1.基于注解的负载均衡 直接写远程微服务的名字，service-product
    String uri = "http://service-product/product/" + productId;
    log.info("远程uri:"+uri);
    //2.使用RestTemplate向远程发送请求 uri中的service-order会被动态替换
    Product product = restTemplate.getForObject(uri, Product.class);//请求的uri，返回的json转为对应的class
    return product;
}
```

> 经典面试题：

如果注册中心宕机，远程调用是否可以成功？

![远程调用步骤](/image/SpringCloud/img7.svg)

**远程调用细节**，微服务会发送两个请求，**第一个是给注册中心发送**请求获得目标地址列表，**第二个是给目标微服务发送请求**。如果每一次都要发送两次请求，那么效率太低了。因为注册中心中的信息是比较稳定的，因此在第一次发送请求后会**将地址列表放到缓存实例中，并和注册中心实现同步更新**。

- 如果从未调用过，此时注册中心宕机，调用会立即失败
- 如果调用过：
  - 此时注册中心宕机，会因为存在缓存的服务信息，调用会成功
  - 如果注册中心和对方服务都宕机，因为会缓存名单，调用会阻塞后失败（Connection Refused）

缓存是如何进行更新的？

1. 核心更新方式：**长轮询**（主动拉取，默认策略，最主要的方式）+服务端主动推送

注意与短轮询的区别：短轮询是**客户端每隔很短的固定时间，主动向服务端发送一次请求，询问数据有没有变化**的通信模式。

这是 Nacos 客户端更新缓存的主要方式，兼顾实时性和性能：

- **触发逻辑**：客户端首次拉取全量服务列表后，会向 Nacos 服务端发起一个**长轮询请求**（默认超时时间 30 秒）；
- 更新时机：发送长轮询请求后，服务端会挂起，不消化资源
  - 如果 30 秒内服务端的服务列表（实例上线 / 下线 / 健康状态变化）没有变化，服务端会返回空，客户端重新发起长轮询；
  - 如果 30 秒内服务列表发生变化，服务端会**立即响应**，把变更的实例信息返回给客户端；
- **缓存同步**：客户端收到变更信息后，先更新内存中的服务列表，再同步更新本地文件缓存；
- **核心参数**：默认长轮询间隔由 `naming-request-timeout` 控制（默认 30000ms），可以在配置中调整：

```yaml
spring:
  cloud:
    nacos:
      discovery:
        naming-request-timeout: 20000 # 改为20秒，缩短轮询超时时间（按需调整）
```

2. 特殊场景：强制刷新 / 兜底更新

- **本地文件缓存兜底**：如果客户端和 Nacos 服务端网络断开，客户端会停止内存缓存更新，但依然会使用本地文件中最新的缓存数据；
- **重启后加载**：客户端重启时，会先加载本地文件缓存到内存，再向服务端发起全量拉取，保证启动后就能提供服务列表；
- **手动触发更新**（可选）：可以通过 Nacos 客户端 API 手动刷新缓存（极少用到）

## 1.6 配置中心

**可以实现不停机更新（只是对于配置项的更新）**。在微服务架构中，不同服务的配置（如数据库连接、服务地址、开关控制等）需要集中管理并支持动态更新。Nacos 配置中心正是为此而设计的。

### 1.6.1 配置中心实现的流程：

**步骤 1：配置存储与订阅**

把配置（比如 `service.product.timeout=5000`）存在 Nacos 服务端，应用启动时会从 Nacos 拉取配置并加载到内存，同时**订阅该配置的变更事件**（底层也是长轮询机制，和服务发现类似）。

**步骤 2：配置变更推送**

当你在 Nacos 控制台修改配置并发布后，Nacos 服务端会立即推送变更通知给所有订阅了该配置的应用客户端。

**步骤 3：客户端热加载配置**

客户端收到通知后，会重新拉取最新配置，**更新内存中的配置值**（比如把 `timeout` 从 5000 改成 8000），这个过程完全在运行时完成，无需重启 JVM。

**步骤 4：业务代码读取新配置**

后续业务代码再读取这个配置时，会拿到最新值（比如接口超时时间变成 8 秒），实现 “不停机生效”。

**简单来说就是将配置文件托管到nacos中，当变动时Nacos会推送给订阅了该配置的微服务**

### 1.6.2 配置中心的使用流程：

1. 导入对应依赖 **spring-cloud-starter-alibaba-nacos-config**，注意引入了这个依赖就要设置配置文件路径，否则项目会报错

2. 在需要引入配置的微服务配置文件中进行配置，指明要导入nacos的哪些配置（nacos的配置中心可以发布多个配置，微服务根据data id选择导入指定配置，data id相当于配置文件名）

```yaml
spring:
  application:
    name: service-order
  cloud:
    nacos:
      # 配置 Nacos 地址
      server-addr: 127.0.0.1:8848
  config:
  	#指定引入的文件名
    import: nacos:service-order.yaml
    # optional:nacos: 表示Nacos配置是可选的，找不到也不报错
    #import: optional:nacos:service-order.yaml
```

3. 在**配置中心编写和管理配置文件**，并且支持以不同格式（如 YAML、Properties、JSON 等）来组织这些配置内容。

在页面 配置管理-->配置列表中创建配置

![](/image/SpringCloud/img8.png)

4. 动态获取配置文件中的值（三种方法）

**使用@RefreshScope+@Value：**

```java
@RefreshScope
@RestController
public class OrderController {

    @Value("${order.timeout}")
    String orderTimeout;
    @Value("${order.auto-confirm}")
    String orderAutoConfirm;
}
```

**@configurationProperties(prefix="")实现前缀批量映射：**

第一种方法每一个属性都要手动去映射，过于繁琐，因此对于相同的前缀可以使用批量映射。

将配置文件中要使用的**数据项抽取到一个单独的类中**（OrderProperties），注意要把这个类也放到spring容器中。使用@Data来自动默认生成getter和setter方法。使用**@configurationProperties(prefix="order")**，可以进行批量绑定，将配置文件中以order开头的数据项映射到类中对应的属性中。这样只需要注入OrderProperties这个类就可以获得配置文件的数据。

```java
@Component
@ConfigurationProperties(prefix = "order") //配置批量绑定在nacos下，可以无需@RefreshScope就能实现自动刷新
@Data
public class OrderProperties {
    String timeout; //对应配置文件中的order.timeout
    String autoConfirm;//对应配置文件中的order.auto-confirm
}
```

**监听配置变换：**

首先要知道NacosConfigManager类，它是Spring 应用操作 Nacos 配置中心的 “总管家”，不用直接对接复杂的 Nacos 原生 API，通过它就能便捷实现配置的获取、监听等操作。

1. 项目启动就监听配置文件变化

   在微服务的启动类中，添加一个新的方法，让spring启动就会执行这个方法。

   在此之前先补充一个知识点：**ApplicationRunner**接口，它只有一个run方法，作用是添加启动执行逻辑。因此可以用它来实现启动监听功能

2. 监听到变化后拿到变化值，发送消息提醒

```java
@SpringBootApplication
public class OrderMainApplication {
    public static void main(String[] args) {
        SpringApplication.run(OrderMainApplication.class,args);
    }

    @Bean
    ApplicationRunner applicationRunner(NacosConfigManager nacosConfigManager) {
        return args -> {
            ConfigService configService = nacosConfigManager.getConfigService();
            configService.addListener("service-order.properties", "DEFAULT_GROUP", new Listener() {
                @Override
                public Executor getExecutor() {
                    return Executors.newFixedThreadPool(4);
                }

                @Override
                public void receiveConfigInfo(String configInfo) {
                    System.out.println("变化的配置信息: " + configInfo);
                    System.out.println("邮件通知...");
                }
            });
            System.out.println("========");
        };
    }
}
```

问题：如果存在多个相同的配置信息，那么：外部导入的优先级最高，合并后会选取优先级高的配置项

![配置信息优先级](/image/SpringCloud/img9.svg)

## 1.7 数据隔离

一个项目通常部署在多套环境上，比如 dev、test、prod。

项目中每个微服务的配置信息在每套环境上的值可能不一样，数据库连接也不同，要求项目可以通过切换环境，加载本环境的配置。

如果要完成以上需求，其中的难点是如何：

- 区分多套环境
- 区分多种微服务
- 区分多种配置
- 按需加载配置

![Nacos数据隔离解决方案](/image/SpringCloud/img10.svg)

Nacos 的解决方案：

- 用名称空间（namespace）区分多套环境
- 用 Group 区分多种微服务
- 用 Data-id 区分多种配置
- 使用 SpringBoot 激活对应环境的配置

# 2. OpenFeign

## 2.1 简介与使用

OpenFeign，是一种 Declarative REST Client，即**声明式 Rest 客户端**，与之对应的是**编程式 Rest 客户端**，比如 RestTemplate。

声明式不需要在编码整个流程，只需要结合注解去进行简单的信息填充

OpenFeign 由注解驱动：

- 指定远程地址：`@FeignClien`（标记一个接口为 Feign 客户端，指定要调用的远程服务）
- 指定请求方式：`@GetMapping`、`@PostMapping`、`@DeleteMapping`...（给哪一个接口路径发请求）
- 指定携带数据：`@RequestHeader`、`@RequestParam`、`@RequestBody`...
- 指定返回结果：响应模式

FeignClien用于微服务间发送请求的客户端，每一个FeignClien对应一个微服务，**代表此微服务向外发送请求**。比如account要获得product中的信息，就要使用Feign中的方法，他会向product发送请求然后将数据封装返回。

使用步骤：

1. 引入对应的starter

2. 使用**OpenFeign**要先在微服务的启动类上加上`@EnableFeignClients`注解开启功能

3. 创建一个**接口**作为微服务用来发送请求的客户端，如**ProductFeignClient**，用`@FeignClient(value="目标微服务名称")`标注

4. 新建方法用于发送http请求，为了与减少记忆难度，OpenFeign直接采用了和SpringMVC同样的注解。例如 `@GetMapping` 等注解：

- 当它们标记在 Controller 上时，用于处理http请求，获得参数后执行方法。表示将http请求中的@GetMapping("/{id}")传入的id拆解到方法的形参@PathVariable("id") Long id中。**只有发送正确的http请求才会触发相应的controller**

```java
@Controller
@RequestMapping("/product") // 统一请求前缀
public class ProductController { 
    @GetMapping("/{id}")
    @ResponseBody 
    public String getProductById(@PathVariable("id") Long id, @RequestHeader("token") String token) {
        // 处理业务逻辑：比如查数据库获取产品信息
        return "product-" + id; // 返回响应给调用方（比如订单服务的 Feign 客户端）
    }
}
```

- 当它们标记在 FeignClien（微服务间发送请求）方法上时，会自动连接上注册中心，向@GetMapping中的路径发送请求。@Pathvariable("id") Long id表示将传入的id给到@GetMapping("/product/{id}")。**不需要写实现类，直接在service中注入ProductFeignClient，再调用这个接口就实现和 service-product 服务之间的数据传递**。**如果需要对请求进行一些附加功能，比如说fallback（兜底返回），那么需要实现接口并重写对应方法。**

```java
@FeignClient(value = "service-product")
public interface ProductFeignClient {

    @GetMapping("product/{id}")
    void getProductById(@PathVariable("id") Long id, @RequestHeader("token") String token);
}
```

![OpenFeign的远程调用](/image/SpringCloud/img11.svg)

- 远程调用注册中心中的服务参考：`ProductFeignClient`
- 远程调用指定 URL 参考：`MockUrlFeignClient`

## 2.2 小技巧

如何编写好 OpenFeign 声明式的远程调用接口：

- 针对业务 API：**写 Feign 接口时，把远程服务 Controller 中对应方法的「请求注解、路径、参数、返回值」原封不动地复制过来，就能保证 Feign 调用和远程 HTTP 请求完全匹配，避免因签名不一致导致调用失败**。
- OpenFeign向第三方 API：根据接口文档确定请求如何发

## 2.3 负载均衡

在使用声明式Rest客户端时同样也需要负载均衡，OpenFeign作为声明式REST客户端，**内置了对 Spring Cloud LoadBalancer 的集成**。无需在接口中写任何负载均衡代码，只需保证配置正确，就能自动实现负载均衡。

OpenFeign是**客户端负载均衡**：发起请求端获得地址列表后，自己去选择进行负载均衡

还有一个是服务端负载均衡，一般是请求第三方api，然后第三方将请求进行负载均衡，比如nginx

OpenFeign发送请求的流程以及服务端负载均衡：

![客户端负载均衡与服务端负载均衡](/image/SpringCloud/img12.svg)

## 2.5进阶用法

> 日志

在配置文件中指定 feign 接口所在包的日志级别：

```yaml
logging:
  level:
    # 指定 feign 接口所在的包的日志级别为 debug 级别
    indi.mofan.order.feign: debug
```

向 Spring 容器中注册 `feign.Logger.Level` 对象：

```java
@Bean
public Logger.Level feignlogLevel() {
    // 指定 OpenFeign 发请求时，日志级别为 FULL
    return Logger.Level.FULL;
}
```

> 超时控制

服务器连接超时不及时处理会积压大量的请求，导致服务雪崩

连接超时（connectTimeout），默认 10 秒。

读取超时（readTimeout），默认 60 秒。

如果需要修改默认超时时间，在配置文件中进行如下配置：

```yaml
spring:
  cloud:
    openfeign:
      client:
        config:
          # 默认配置
          default:
            logger-level: full
            connect-timeout: 1000
            read-timeout: 2000
          # 具体 feign 客户端的超时配置
          service-product:
            logger-level: full
            # 连接超时，3000 毫秒
            connect-timeout: 3000
            # 读取超时，5000 毫秒
            read-timeout: 5000
```

> 重试机制

**远程调用超时失败后**，还可以进行多次尝试，如果某次成功则返回 ok，如果多次尝试后依然失败则结束调用，返回错误。

OpenFeign 底层**默认使用** `NEVER_RETRY`，即**不重试策略**。

向 Spring 容器中添加 `Retryer` 类型的 Bean：

```java
@Bean
public Retryer retryer() {
    return new Retryer.Default();
}
```

这里使用 OpenFeign 的默认实现 `Retryer.Default`，在这种默认实现下：

```java
public Default() {
    this(100L, TimeUnit.SECONDS.toMillis(1L), 5);
}
```

OpenFeign 的重试规则是：

- 重试间隔 100ms
- 最大重试间隔 1s。新一次重试间隔是上一次重试间隔的 1.5 倍，但不能超过最大重试间隔。
- 最多重试 5 次

> 拦截器

![OpenFeign的拦截器](/image/SpringCloud/img13.svg)

OpenFeign提供拦截器，可以在发送请求后或者相应操作后进行拦截

以请求拦截器为例，自定义的请求拦截器需要实现 `RequestInterceptor` 接口，并重写 `apply()` 方法：

```java
package indi.mofan.order.interceptor;

public class XTokenRequestInterceptor implements RequestInterceptor {
    /**
     * 请求拦截器
     *
     * @param template 封装本次请求的详细信息
     */
    @Override
    public void apply(RequestTemplate template) {
        System.out.println("XTokenRequestInterceptor ...");
        template.header("X-Token", UUID.randomUUID().toString());
    }
}
```

要想要该拦截器生效有两种方法：

1. 在配置文件中配置对应 Feign 客户端的请求拦截器，此时该拦截器只对指定的 Feign 客户端生效

   ```yaml
   spring:
     cloud:
       openfeign:
         client:
           config:
             # 具体 feign 客户端
             service-product:
               # 该请求拦截器仅对当前客户端有效
               request-interceptors:
                 - indi.mofan.order.interceptor.XTokenRequestInterceptor
   ```

2. 还可以直接将自定义的请求拦截器添加到 Spring 容器中，此时该拦截器对服务内的所有 Feign 客户端生效

   ```java
   @Component
   public class XTokenRequestInterceptor implements RequestInterceptor {
       // --snip--
   }
   ```

> Fallback

![OpenFeign的Fallback](/image/SpringCloud/img14.svg)

Fallback，即兜底返回。如果请求失败会返回错误信息，而兜底返回则返回一个特定的信息，而使业务流程更加流程

注意，此功能需要整合 Sentinel 才能实现。

因此需要先导入 Sentinel 依赖：

```xml
<dependency>
    <groupId>com.alibaba.cloud</groupId>
    <artifactId>spring-cloud-starter-alibaba-sentinel</artifactId>
</dependency>
```

并在需要进行 Fallback 的服务的配置文件中开启配置：

```yaml
feign:
  sentinel:
    enabled: true
```

现在需要对 Feign 客户端 `ProductFeignClient` 配置 Fallback，那么需要先**实现** `ProductFeignClient` 接口编写兜底返回逻辑，并将其交由 Spring 管理：

```java
@Component
public class ProductFeignClientFallback implements ProductFeignClient {
    @Override
    public Product getProductById(Long id) {
        System.out.println("Fallback...");
        Product product = new Product();
        product.setId(id);
        product.setPrice(new BigDecimal("0"));
        product.setProductName("未知商品");
        product.setNum(0);
        return product;
    }
}
```

之后回到对应的 Feign 客户端，配置 Fallback：

```java
@FeignClient(value = "service-product", fallback = ProductFeignClientFallback.class)
public interface ProductFeignClient {

    @GetMapping("/product/{id}")
    Product getProductById(@PathVariable("id") Long id);
}
```

如果要对一个FeignClient中的每一个方法都设置Fallback，要创建一个FallbackFactory类来实现

# 3. Sentinel

官方文档：[Sentinel](https://sentinelguard.io/zh-cn/docs/introduction.html)

## 3.1 工作原理

随着微服务的流行，服务和服务之间的稳定性变得越来越重要。Spring Cloud Alibaba Sentinel 以流量为切入点，从流量控制、流量路由、熔断降级、系统自适应过载保护、热点流量防护等多个维度保护服务的稳定性。

![Sentinel架构原理](/image/SpringCloud/img15.svg)

定义规则：

- 主流框架自动适配（Web Servlet、Dubbo、Spring Cloud、gRPC、Spring WebFlux、Reactor），**所有 Web 接口均为资源** 

- 编程式：SphU API

- 声明式：`@SentinelResource`定义一个方法为资源

定义资源：（资源可以是一个请求或者其他）

- 流量控制（FlowRule）

- 熔断降级（DegradeRule）

- 系统保护（SystemRule）

- 来源访问控制（AuthorityRule）

- 热点参数（ParamFlowRule）

![Sentinel工作原理](/image/SpringCloud/img16.svg)

## 3.2 整合 Sentinel

> 启动 Dashboard

前往 Sentinel GitHub Realease 页下载 Sentinel Dashboard，这里选择 1.8.8 版本，因此下载 `sentinel-dashboard-1.8.8.jar`。

在 `sentinel-dashboard-1.8.8.jar` 所在的目录运行以下命令，启动 Dashboard：

```shell
java -jar sentinel-dashboard-1.8.8.jar
```

启动完成后，浏览器访问 `http://localhost:8080/`，默认用户与密码均为 `sentinel`。

> 服务整合 Sentinel

引入依赖：

```xml
<dependency>
    <groupId>com.alibaba.cloud</groupId>
    <artifactId>spring-cloud-starter-alibaba-sentinel</artifactId>
</dependency>
```

配置文件中添加：

```yaml
spring:
  application:
    name: service-product
  cloud:
    sentinel:
      transport:
        # 控制台地址
        dashboard: localhost:8080
      # 立即加载服务  
      eager: true
```

配置完成后启动对应服务，再前往 Sentinel Dashboard 查看，能够看到对应服务信息。

可以在一个方法上使用 `@SentinelResource` 注解，**将其标记为一个「资源」**，使用value属性来设置Sentinel 资源名称，当方法被调用时，能够在页面上的 Dashboard 的「簇点链路」上找到对应的资源，之后在界面上完成对资源的流控、熔断、热点、授权等操作。

## 3.3 异常处理

![Sentinel异常处理](/image/SpringCloud/img17.svg)

能够被作为资源的可以进行异常处理：

> Web 接口

**当 Web 接口作为资源被流控时**（一段时间访问过多），默认情况下会在页面显示：

<pre>
Blocked by Sentinel (flow limiting)
</pre>

`SentinelWebInterceptor`是一个拦截器，实现了`BlockExceptionHandler`接口，prehandle方法会在执行前检查是否符合规则，如果违背则发起拦截，然后抛出错误输出页面提示

如果需要自定义异常处理，同样可以实现 `BlockExceptionHandler` 接口，并将实现类交给 Spring 管理就可以生效：

```java
@Component
public class MyBlockExceptionHandler implements BlockExceptionHandler {
	//Jackson 库的核心类，用于将 Java 对象（如自定义的 R 类）转换为 JSON 字符串。
    private final ObjectMapper objectMapper;

    public MyBlockExceptionHandler(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    //这个方法会在 Sentinel 触发限流 / 熔断时被调用
    @Override
    public void handle(HttpServletRequest request,
                       HttpServletResponse response,
                       String resourceName,
                       BlockException e) throws Exception {
        response.setContentType("application/json;charset=utf-8");
        PrintWriter writer = response.getWriter();
		//自定义一个R对象 提供static方法
        R error = R.error(500, resourceName + " 被 Sentinel 限制了, 原因: " + e.getClass());

        String json = objectMapper.writeValueAsString(error);
        writer.write(json);

        writer.flush();
        writer.close();
    }
}
```

以 `/create` 接口为例，当其被流控时，页面显示：

```json
{
    "code": 500,
    "message": "/create 被 Sentinel 限制了, 原因: class com.alibaba.csp.sentinel.slots.block.flow.FlowException",
    "data": null
}
```

> `@SentinelResource注解标记的资源`

当 `@SentinelResource` 注解标记的**资源**被流控时，默认返回 500 错误页。

如果需要自定义异常处理（兜底回调），一般可以增加 `@SentinelResource` 注解的以下任意配置：

- `blockHandler`
- `fallback`
- `defaultFallback`

区别：**blockHandler专门处理 Sentinel 规则触发的「主动拦截异常」（BlockException），比如限流、熔断、降级；fallback专门处理业务代码抛出的「非 Sentinel 异常」，比如空指针、数据库报错、远程调用超时，也能兜底 BlockException（需手动配置）**。

以 `blockHandler` 为例：

```java
@SentinelResource(value = "createOrder", blockHandler = "createOrderFallback")
public Order createOrder(Long productId, Long userId) {
    // --snip--
}//当触发规则是会执行createOrderFallback方法
```

在当前类中创建名称为 `blockHandler` 值的方法，并且返回值类型、参数信息与 `@SentinelResource` 标记的方法一致（可以额外增加一个 `BlockException` 类型的参数）：

```java
/**
 * 指定兜底回调
 */
public Order createOrderFallback(Long productId, Long userId, BlockException e) {
    Order order = new Order();
    order.setId(0L);
    order.setTotalAmount(new BigDecimal("0"));
    order.setUserId(userId);
    order.setNickname("未知用户");
    order.setAddress("异常信息: " + e.getClass());
    return order;
}
```

当资源被流控时，执行 `blockHandler` 指定的方法：

```json
{
    "id": 0,
    "totalAmount": 0,
    "userId": 666,
    "nickname": "未知用户",
    "address": "异常信息: class com.alibaba.csp.sentinel.slots.block.flow.FlowException",
    "productList": null
}
```

> Feign 接口

如果配置了兜底回调会触发fallback，没有兜底回调的话spring的全局异常处理器会进行处理

## 3.4 流控规则

**用来控制接口、方法、Feign 等资源的请求流量，防止系统被压垮的一套规则配置**，核心是定义 “允许多少请求、超过了怎么处理”。它是 Sentinel 最基础、最核心的规则，专门解决流量过载、突发洪峰问题。

![Sentinel流控](/image/SpringCloud/img18.svg)

> 阈值类型

![Sentinel设置流控阈值类型](/image/SpringCloud/img19.png)

Sentinel 的**流控阈值规则**有两种：

1. QPS：Queries Per Second，用于限制资源每秒的请求次数，防止突发流量，应用于高频短时接口（如 API 网关）。当每秒的请求数超过设定的阈值时，就会触发流控。比如上图设置的 QPS = 5，就表示每秒最多允许 5 个请求。
2. 并发线程数：用于限制同时处理该资源的线程数（即并发数），保护系统资源（线程池），应用于耗时操作（如数据库查询）。当处理该资源的线程数超过阈值时，就会触发流控。比如设置并发线程数为 5，表示最多允许 5 个线程同时处理该资源。

当勾选「是否集群」时，有两种集群阈值模式可供选择：

1. 单机均摊：将设置的「均摊阈值」均摊到每个节点。以上图为例，假设集群有 3 个节点，那么每个节点的阈值都是 5；
2. 总体阈值：整个集群共享设置的「均摊阈值」。假设集群有 3 个节点，这 3 个节点的的总阈值只有 5，比如按 `2-2-1` 的形式将阈值均摊到每个节点。

> 流控模式

![Sentinel的流控模式](/image/SpringCloud/img20.png)

配置流控规则时，可以点击下方的「高级选项」，在这里可以配置「**流控模式**」。

流控模式简单说就是**决定 “怎么选限流的触发条件”**—— 是直接限制资源本身，还是关联其他资源、或是限制特定调用链路，本质是为了让限流规则更灵活，适配不同业务场景的流量控制需求

共有三种可选项：

1. 直接：默认选项，只对调用方法流控。
2. 关联：**两个资源建立关联关系，当「关联资源」的流量超阈值时，限流「当前资源」**—— 核心是 “保核心、限非核心”，通过限制非核心资源，为核心资源释放系统资源。（当前资源不超压，但**它依赖的其他资源已超压**）。
3. 链路：仅对于某一路径下的资源访问生效。使用时需要在配置文件中设置 `spring.cloud.sentinel.web-context-unify=false`。（同一个接口被不同服务调用时，可以**对指定的调用方服务做限流**）

调用关系包括调用方、被调用方；一个方法又可能会调用其他方法，形成一个调用链路的层次关系；有了调用链路的统计信息，可以衍生出多种流量控制手段。

![Sentinel流控模式](/image/SpringCloud/img21.svg)

上面为直接模式，关联模式和链路模式

| **维度** |        直接        |              关联              |                   链路                    |
| :------: | :----------------: | :----------------------------: | :---------------------------------------: |
| 作用对象 |    当前资源本身    |         关联的其他资源         | 特定调用链路的入口（有AC资源但是只控制C） |
| 触发逻辑 |   当前资源超阈值   | 关联资源超阈值时，限流当前资源 |        从指定入口发起的请求超阈值         |
| 核心目的 |    保护当前资源    |     保护关联资源或间接限流     |            按入口细分流量控制             |
| 典型场景 | 独立接口的直接限流 | 资源依赖（如读操作限流写操作） |             区分不同调用来源              |
| 配置依赖 |    无需额外配置    |         需指定关联资源         |            需指定资源访问入口             |

> 流控效果

打开流控规则中的高级配置后，还可以配置「**流控效果**」，指的是**当请求量超过你设定的阈值（Threshold）时，Sentinel 具体采用什么策略来处理这些多余的请求**。同样有三种选项：

1. 快速失败：默认选项。注意，只有该选项支持「流控模式」（直接、关联、链路）的设置。
2. Warm Up：初始阈值并不等于设定的阈值，而是比他低（默认是 设定阈值 / 冷加载因子，冷加载因子默认是3），随后在预热时间内逐步提升至设定阈值。例如设定阈值为 3 QPS、预热时间 3 秒，初始阈值为 1 QPS，3 秒内逐步升至 3。
3. 排队等待：基于漏桶算法，请求不立即失败，排队等待一段时间按固定间隔时间匀速处理。若请求的预期等待时间超过设定的超时时间，则拒绝请求。

![Sentinel流控效果](/image/SpringCloud/img22.svg)

|   效果   |        核心机制        |              适用场景              | 阈值动态变化 |    流量特征    |
| :------: | :--------------------: | :--------------------------------: | :----------: | :------------: |
| 快速失败 | 直接拒绝超出阈值的请求 |     明确系统处理能力并快速保护     |   固定阈值   |    突发流量    |
| Warm Up  |      阈值逐步提升      | 服务刚启动或恢复，防止瞬间突发流量 |   动态提升   | 逐步增长的流量 |
| 排队等待 |      匀速处理请求      |     服务处理均匀，避免突发压力     |   固定阈值   |   均匀的流量   |

## 3.5 熔断规则

熔断降级（规则），即 DegradeRule。一般用于处理一个微服务调用另一个微服务得不到响应或者非常慢的情况，防止系统崩溃。

使用熔断降级可以配置熔断降级，用于：

- 切断不稳定调用
- 快速返回不积压
- 避免雪崩效应

**最佳实践：** 熔断降级作为保护自身的手段，通常在**客户端（调用端）进行配置**。

熔断降级里的核心组件是「断路器」，其工作原理如下：

**降级响应**，指的是当某个服务接口调用失败或被熔断、限流时，**不调用真实接口，而是返回一个“备用的、默认的响应结果”**（比如配置类兜底返回），来保证用户依然能收到系统的正常响应，而不是报错或长时间无响应。

断路器合闭（关闭）请求可以通过，断路器打开则请求被切断（短时间内不再调用目标服务，快速失败，返回降级响应）

半开状态：一段时间后允许部分请求“试探”目标服务是否恢复，如果成功率正常，则恢复为关闭状态；否则重新熔断。

![断路器工作原理](/image/SpringCloud/img23.svg)

Sentinel 提供了三种熔断策略：

1. 慢调用比例
2. 异常比例
3. 异常数

> 慢调用比例

![配置慢调用比例的熔断规则](/image/SpringCloud/img24.png)

在 5000ms 内，有 80%（0.8 的比例阈值）的请求的最大响应时间（RT）超过 1000ms，则进行 30s 的熔断。

如果 5000ms 内，请求数不超过 5，就算达到熔断规则，也不进行熔断。

> 异常比例

在远程调用的目标接口里添加 `int i = 1 / 0;` 模拟远程调用异常。

此时尚未配置任何熔断规则，然后远程调用存在异常的接口，此时会触发使用 OpenFeign 配置的兜底回调。

换句话说，**没有配置任何熔断规则就可以触发兜底回调，而配置熔断规则也是为了触发兜底回调，那岂不是配不配置熔断规则都可以**？

![有无熔断规则的比较](/image/SpringCloud/img25.svg)

当 A 服务向 B 服务发送请求时，远程调用的 B 服务接口中存在异常，此时触发兜底回调。

在这个过程，由 A 服务发送的请求依旧会打到 B 服务上。

**而配置熔断规则后，A 服务发送的请求快速失败，立即出发兜底回调，不会再把请求打到 B 服务上**。

![配置异常比例的熔断规则](/image/SpringCloud/img26.png)

在 5000ms 内，有 80%（0.8 的比例阈值）的请求产生了异常，则进行 30s 的熔断。

> 异常数

![配置异常数的熔断规则](/image/SpringCloud/img27.png)

「异常数」的熔断策略与「异常比例」很类似，只不过「异常数」是直接统计异常个数，就算统计时长内产生了一百万个请求，但只要有 10 个请求出现了异常，也会触发熔断。

------

## 🚦 熔断 vs 限流的区别

| 项目     | 熔断                           | 限流                       |
| -------- | ------------------------------ | -------------------------- |
| 控制对象 | 不稳定/异常的服务              | 过多的并发/流量            |
| 触发条件 | 请求失败率高、超时多           | QPS 或并发数超过阈值       |
| 目的     | 避免持续调用故障服务，加快恢复 | 限制访问速率，保护资源     |
| 恢复方式 | 监控成功请求后自动恢复         | 通常不涉及恢复，只限制请求 |

## 3.6 热点规则

所谓热点，即经常访问的数据。很多时候希望统计某个热点数据中访问频次最高的 Top K 数据，并对其访问进行限制。比如：

- 商品 ID 为参数，统计一段时间内最常购买的商品 ID 并进行限制
- 用户 ID 为参数，针对一段时间内频繁访问的用户 ID 进行限制

热点参数限流会统计传入**参数**中的热点参数，并根据配置的限流阈值与模式，对包含热点参数的资源调用进行限流。

**热点参数限流可以看做是一种特殊的流量控制，仅对包含热点参数的资源调用生效。** 

![Sentinel热点规则概述](/image/SpringCloud/img28.png)

Sentinel 利用 LRU 策略统计最近最常访问的热点参数，结合令牌桶算法来进行参数级别的流控。

> 在需求中学习

现有如下需求：

- 每个用户秒杀 QPS 不得超过 1（秒杀下单时，userId 级别）
- 6 号用户是 vvip，不限制 QPS（例外情况）
- 666 号商品是下架商品，不允许访问

在 Sentinel GitHub Wiki 中指出：

- 目前 Sentinel 自带的 adapter 仅 Dubbo 方法（基于 RPC 协议的微服务之间的远程调用工具）埋点带了热点参数，其它适配模块（如 Web）默认不支持热点规则，可通过自定义埋点方式指定新的资源名并传入希望的参数。注意自定义埋点的资源名不要和适配模块生成的资源名重复，否则会导致重复统计。
- **埋点（Tracing/Pointcut）** 就是在代码执行的关键位置 “插个标记”—— 这个标记会告诉 Sentinel：“这里是需要被监控、限流、熔断的资源，请你盯着这个位置的调用情况”。

```java
@GetMapping("/seckill")
@SentinelResource(value = "seckill-order", fallback = "seckillFallback")
public Order seckill(@RequestParam(value = "userId", required = false) Long userId,
                     @RequestParam(value = "productId", defaultValue = "1000") Long productId) {
    Order order = orderService.createOrder(productId, userId);
    order.setId(Long.MAX_VALUE);
    return order;
}

public Order seckillFallback(Long userId,
                             Long productId,
                             // 使用 fallback，而不是 blockHandler
                             // 最后一个参数类型是 Throwable，而不是 BlockException
                             Throwable throwable) {
    System.out.println("seckillFallback...");
    Order order = new Order();
    order.setId(productId);
    order.setUserId(userId);
    order.setAddress("异常信息: " + throwable.getClass());
    return order;
}
```

对 `seckill-order` 资源进行如下热点规则配置：

![根据需求1配置热点规则](/image/SpringCloud/img29.png)

这表示：访问 `seckill-order` 资源时，第一个参数（参数索引 0，意思是http请求传入的第0个参数）在 1 秒的统计窗口时长下，其阈值为 1，也就是每一个参数下的 QPS = 1。

需要注意：**携带此参数，则参与流控；不携带不流控**。

```java
@GetMapping("/seckill")
@SentinelResource(value = "seckill-order", fallback = "seckillFallback")
public Order seckill(@RequestParam(value = "userId", defaultValue = "888") Long userId,
                     @RequestParam(value = "productId", defaultValue = "1000") Long productId) {
    // --snip--
}
```

上述代码中，`userId` 的默认值为 `888`，也就是以 `http://localhost:8000/seckill?productId=777` 的形式进行访问时，`userId` 的值为 `888`，此时依旧传入了 `userId`，依旧触发流控。

```java
@GetMapping("/seckill")
@SentinelResource(value = "seckill-order", fallback = "seckillFallback")
public Order seckill(@RequestParam(value = "userId", required = false) Long userId,
                     @RequestParam(value = "productId", defaultValue = "1000") Long productId) {
    // --snip--
}
```

上述代码中，`userId` 可以不传，当以 `http://localhost:8000/seckill?productId=777` 的形式进行访问时，`userId` 为 `null`，没有传入 `userId`，不会触发流控。

经过上述配置，已经完成「每个用户秒杀 QPS 不得超过 1」的需求，但「6 号用户」是个例外：

![根据需求2编辑热点规则](/image/SpringCloud/img30.png)

访问 `seckill-order` 资源时，第一个参数（参数索引 0）的类型是 `long`，当其值为 `6` 时，限流阈值为 `1000000`，变相不限制「6 号用户」的 QPS。

现在还有最后一个需求「666 号商品是下架商品，不允许访问」，这其实相当于：对 666 号商品进行流控（限流阈值为 0，不允许访问），对其他商品不进行流控（或阈值非常大）。

新增热点规则：

![根据需求3配置热点规则](/image/SpringCloud/img31.png)

访问 `seckill-order` 资源时，第二个参数（参数索引 1）在 1 秒的统计窗口时长下，其阈值为 1000000，这是一个无法达到的值，相当于不进行限流。但有一个例外：当其值为 666 时，限流阈值为 0，也就是不允许访问。

# 4. Gateway

![Gateway的概述](/image/SpringCloud/img32.svg)

## 4.1 路由

需求：

1. 客户端发送 `/api/order/**` 转到 `service-order`
2. 客户端发送 `/api/product/**` 转到 `service-product`
3. 以上转发有负载均衡效果

配置路由规则时，可直接在配置文件中完成：

route是一个list，所以可以使用-表示它是一个列表的元素来配置多个路由规则

```yaml
spring:
  cloud:
    gateway:
      routes: # 网关的路由规则列表，是一个数组，可配置多个路由
        - id: bing-route # id 路由的全局唯一标志
          uri: https://cn.bing.com #路由的转发目标地址
          predicates:	#断言规则（匹配规则）支持多个断言（同时满足才匹配）
            - Path=/**
          order: 10 #数字越小优先级越高
        - id: order-route
          # 指定服务名称
          uri: lb://service-order #lb（Load Balance）是负载均衡协议
          predicates:
            - Path=/api/order/**
          order: 1
        - id: product-route
          uri: lb://service-product
          predicates:
            - Path=/api/product/**
          order: 2
```

转发流程：

拉取实例：网关启动后，会从注册中心（如 Nacos）订阅`service-order`这个服务名，拉取它的**所有在线实例地址**（比如 192.168.1.100:8081、192.168.1.101:8081，多实例部署时会有多个）；

负载分发：当有请求命中`order-route`路由时，网关会按照**默认轮询策略**（也可自定义为随机、权重等），从拉取的实例列表中选一个；

路径转发：分为精准匹配（path不带** ）和前缀匹配（path带 **）

精确匹配`Path=/search` + `uri=https://cn.bing.com`：

访问`localhost/search?q=java` → 转发到`https://cn.bing.com/search?q=java`（完整拼接，不剥离）；

前缀匹配`Path=/api/order/**` + `uri=lb://service-order`：

访问`localhost/api/order` → 转发到`service-order/api/order/`。

浏览器中的网址是没有变化的（反向代理）

Gateway 路由的工作原理如下：

![Gateway路由的工作原理](/image/SpringCloud/img33.svg)

## 4.2 断言

官方文档：[Route Predicate Factories](https://docs.spring.io/spring-cloud-gateway/reference/spring-cloud-gateway/request-predicates-factories.html)

断言的两种书写方式：短写法和长写法

```yaml
spring:
  cloud:
    gateway:
      routes:
          # id 全局唯一
        - id: order-route
          # 指定服务名称
          uri: lb://service-order
          # 指定断言规则，即路由匹配规则
          predicates: #长写法
            - name: Path
              args:
                patterns: /api/order/**
                matchTrailingSlash: true #开启后认为/red/1和/red/1/是一个路径
        - id: product-route
          uri: lb://service-product
          # Shortcut Configuration
          predicates:
            - Path=/api/product/**
```

在 Spring Cloud Gateway 的实现中，断言的实现都是 `RoutePredicateFactory` 接口的实现。

因此除了直接查看官方文档外确定有哪些断言形式外，还可以通过查看 `RoutePredicateFactory` 的实现：

- `HeaderRoutePredicateFactory`
- `PathRoutePredicateFactory`
- `ReadBodyRoutePredicateFactory`
- `BeforeRoutePredicateFactory`
- ...

断言的名称可以通过去掉实现类名后的 `RoutePredicateFactory` 来确定，比如 `HeaderRoutePredicateFactory` 对应名为 `Header` 的断言。

|         名称         |     参数（个数/类型）     |                             作用                             |
| :------------------: | :-----------------------: | :----------------------------------------------------------: |
|        After         |        1/datetime         |               请求在指定时间之后发送才能被路由               |
|        Before        |        1/datetime         |                        在指定时间之前                        |
|       Between        |        2/datetime         |                       在指定时间区间内                       |
|        Cookie        |      2/string,regexp      |                包含 cookie 名且必须匹配指定值                |
|        Header        |      2/string,regexp      |                  包含请求头且必须匹配指定值                  |
|         Host         |         N/string          |                  请求 host 必须是指定枚举值                  |
|        Method        |         N/string          |                   请求方式必须是指定枚举值                   |
|         Path         | 2/List&lt;String&gt;,bool |             请求路径满足规则，是否匹配最后的 `/`             |
|        Query         |      2/string,regexp      |                       包含指定请求参数                       |
|      RemoteAddr      |   1/List&lt;String&gt;    |               请求来源于指定网络域（CIDR写法）               |
|        Weight        |       2/string,int        |                      按指定权重负载均衡                      |
| XForwardedRemoteAddr |   1/List&lt;String&gt;    | 从 `X-Forwarded-For` 请求头中解析请求来源，并判断是否来源于指定网络域 |

以 `Query` 为例：

```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: bing-route
          uri: https://cn.bing.com
          predicates:
            - name: Path
              args:
                patterns: /search
            - name: Query
              args:
                param: q
                regexp: haha
```

这表示：访问网关的 `/search` 地址，并且使用了名为 `q` 的请求参数，且值为 `haha`，才会将请求转到 `https://cn.bing.com`并且拼接path的值。

尽管 Gateway 内置了许多断言规则，但依旧难以满足千变万化的需求，可以自定义断言。

在上述规则的基础上，再指定一个名为 `Vip` 的断言规则，要求存在名为 `user` 的请求参数，并且值为 `mofan` 时才将请求跳转到 `https://cn.bing.com`：

```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: bing-route
          uri: https://cn.bing.com
          predicates:
            - name: Path
              args:
                patterns: /search
            - name: Query
              args:
                param: q
                regexp: haha
            - Vip=user,mofan
```

使用 `AbstractRoutePredicateFactory` 实现类 `VipRoutePredicateFactory`：

```java
/**
 * @author mofan
 * @date 2025/4/29 22:49
 */
@Component
public class VipRoutePredicateFactory extends AbstractRoutePredicateFactory<VipRoutePredicateFactory.Config> {


    public VipRoutePredicateFactory() {
        super(Config.class);
    }

    @Override
    public List<String> shortcutFieldOrder() {
        return List.of("param", "value");
    }

    @Override
    public Predicate<ServerWebExchange> apply(Config config) {
        return (GatewayPredicate) serverWebExchange -> {
            // localhost/search?q=haha&user=mofan
            ServerHttpRequest request = serverWebExchange.getRequest();
            String first = request.getQueryParams().getFirst(config.param);
            return StringUtils.hasText(first) && first.equals(config.value);
        };
    }

    @Validated
    @Getter
    @Setter
    public static class Config {
        @NotEmpty
        private String param;
        @NotEmpty
        private String value;
    }
}
```

然后访问 `http://localhost/search?q=haha&user=mofan` 时，会跳转到 Bing 搜索 `haha`。

## 4.3 过滤器

官方文档：[GatewayFilter Factories](https://docs.spring.io/spring-cloud-gateway/reference/spring-cloud-gateway/gatewayfilter-factories.html)

![Gateway过滤器](/image/SpringCloud/img34.svg)

先前在网关中配置了将 `/api/order/` 开头的请求转到 `service-order` 服务，并要求在 `service-order` 服务中也存在 `/api/order/` 开头的请求路径，比如 `/api/order/readDb`。如果该服务中原先并不存在 `/api/order/` 开头的请求，比如只有 `/readDb`，那么在以 `/api/order/readDb` 进行访问就会出现 404 错误。

为了解决这个问题，可以在 `service-order` 服务对应的 Controller 上添加 `@RequestMapping("/api/order")` 注解，但这并不是最佳方案，如果能直接在网关层面解决这个问题就好了，就像把 `/api/order/readDb` 重写为 `/readDb`。

Gateway 中内置了许多过滤器，一般都是对请求头请求体等进行修改，其中有一个常用的过滤器名为：`RewritePath`，即路径重写。

![RewritePath过滤器](/image/SpringCloud/img35.svg)

```yaml
spring:
  cloud:
    gateway:
      routes:
          # id 全局唯一
        - id: order-route
          # 指定服务名称
          uri: lb://service-order
          # 指定断言规则，即路由匹配规则
          # Fully Expanded Arguments
          predicates:
            - name: Path
              args:
                patterns: /api/order/**
                matchTrailingSlash: true
          filters:
            # 类似把 /api/order/a/bc 重写为 /a/bc，移除路径前的 /api/order/
            - RewritePath=/api/order/?(?<segment>.*), /$\{segment}
          order: 1
        - id: product-route
          uri: lb://service-product
          # Shortcut Configuration
          predicates:
            - Path=/api/product/**
          filters:
            - RewritePath=/api/product/?(?<segment>.*), /$\{segment}
          order: 2
```

> 默认过滤器

如果需要为所有路由都添加同一个过滤器，则可以使用 **默认过滤器**，比如：

```yaml
spring:
  cloud:
    gateway:
      default-filters:
        # 为所有路由添加响应头过滤器
        - AddResponseHeader=X-Response-Abc, 123
```

> 全局过滤器

除了默认过滤器，全局过滤器也能为所有匹配的路由添加一个过滤器，全局过滤器的配置无需修改配置文件。

实现 `GlobalFilter` 接口，并将实现类交由 Spring 管理，即可实现全局过滤器。

还可以实现 `Ordered` 接口，调整多个全局过滤器的执行顺序。

```java
/**
 * @author mofan
 * @date 2025/5/1 13:49
 */
@Slf4j
@Component
public class RtGlobalFilter implements GlobalFilter, Ordered {
    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        ServerHttpRequest request = exchange.getRequest();
        String uri = request.getURI().toString();
        long start = System.currentTimeMillis();
        log.info("请求 [{}] 开始，时间：{}", uri, start);
        return chain.filter(exchange)
                .doFinally(res -> {
                    long end = System.currentTimeMillis();
                    log.info("请求 [{}] 结束，时间：{}，耗时：{}ms", uri, start, end - start);
                });
    }

    @Override
    public int getOrder() {
        return 0;
    }
}
```

> 自定义过滤器工厂

尽管 Gateway 内置了许多过滤器，但仍有无法满足需求的情况，此时就需要自定义过滤器工厂。

与自定义断言类似，自定义过滤器工厂的类名也有限制，要求以 `GatewayFilterFactory` 结尾，而配置文件中配置的名称就是类名开头。

比如需要在配置文件中定义名为 `OnceToken` 的过滤器，那么需要新增 `OnceTokenGatewayFilterFactory`：

```java
/**
 * @author mofan
 * @date 2025/5/1 14:24
 */
@Component
public class OnceTokenGatewayFilterFactory extends AbstractNameValueGatewayFilterFactory {
    @Override
    public GatewayFilter apply(NameValueConfig config) {
        return (exchange, chain) -> chain.filter(exchange).then(Mono.fromRunnable(() -> {
            ServerHttpResponse response = exchange.getResponse();

            String value = switch (config.getValue().toLowerCase()) {
                case "uuid" -> UUID.randomUUID().toString();
                case "jwt" -> "Test Token";
                default -> "";
            };

            HttpHeaders headers = response.getHeaders();
            headers.add(config.getName(), value);
        }));
    }
}
```

```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: order-route
          uri: lb://service-order
          filters:
            # 自定义过滤器
            - OnceToken=X-Response-Token, uuid
```

## 4.4 全局跨域

先讲一下跨域：

跨域，全称**跨域资源共享（CORS，Cross-Origin Resource Sharing）**，是浏览器出于**安全考虑**，强制执行的一种同源策略限制，用来阻止一个域的网页，去请求另一个域的资源（只针对前端发起的请求，比如js里面一个像另一个域名、网关等发送请求）。

浏览器判定是否同源，只看三个核心部分，**必须完全一致**才是同源：

- 协议（http /https）
- 域名（[www.xxx.com](https://www.xxx.com) / [api.xxx.com](https://api.xxx.com) / [localhost](https://localhost)）
- 端口（80 / 8080 / 3000 等）

只要**任意一项不同**，就属于跨域，浏览器会默认拦截请求。

举个危险场景的例子：

- 你正常登录银行：`https://www.bank.com`
- 登录成功后，浏览器里存了银行的登录 Cookie（凭证）
- 恶意网站：`https://www.bad.com`

**第一步：先看 “同源”，一眼就看出跨域**

银行网站的源：`https://www.bank.com`

恶意网站的源：`https://www.bad.com`

协议一样（都是 https），但**域名完全不同**，所以：

**恶意网页 → 银行接口 的请求，是标准的跨域请求。**

------

**第二步：浏览器的一个关键机制**

浏览器有一条规则：

> **只要是向某个域名发请求，就会自动带上该域名下已保存的 Cookie。**
>
> 不管这个请求，是从哪个网页、哪个域名发出来的。

也就是说：

1. 你登录银行，浏览器存了 `bank.com` 的 Cookie。
2. 你打开 `bad.com`，这个网页里的 JS 代码，发起一个请求到 `https://www.bank.com/api/transfer`（转账接口）。
3. 浏览器在发送这个请求时，**会自动把银行的登录 Cookie 带上**。

这一步，是整个风险的核心。

------

**第三步：没有跨域限制的话，会发生什么**

如果浏览器**没有同源策略、没有跨域拦截**，流程是这样的：

1. `bad.com` 的 JS 偷偷发请求：`POST https://www.bank.com/api/transfer`
2. 浏览器自动带上 `bank.com` 的登录 Cookie
3. 银行服务器收到请求，看到 Cookie 有效，认为是你本人操作
4. 执行转账，钱被转走
5. 恶意网页拿到响应，整个过程用户完全不知情

**在这个过程里，请求的发起方是 [bad.com](https://bad.com)，目标是 [bank.com](https://bank.com)，这就是跨域。**

只是在 “无限制” 的情况下，浏览器不拦，恶意请求就成功了。

------

**第四步：有了跨域限制，浏览器做了什么**

浏览器的同源策略，会在这里直接 “掐断” 风险：

1. `bad.com` 发起请求到 `bank.com`
2. 浏览器检查：当前页面是 [bad.com](https://bad.com)，请求目标是 [bank.com](https://bank.com) → **跨域，禁止**
3. 浏览器直接**不发送请求**，或者发送后**拦截响应，不把结果给恶意 JS**
4. 银行接口收不到有效请求，或者恶意代码拿不到返回结果，攻击失败



如果需要Gateway配置跨域，可以在 Controller 的类上添加 `@CrossOrigin` 注解。

**问题：**既然跨域是浏览器的限制，那为什么还要在后端配置跨域（比如加 `@CrossOrigin`、网关配置 CORS）？

后端配置的跨域，本质是**在响应头里加上许可信息**，告诉浏览器：这个请求是我允许的，你别拦截，把数据交给前端页面。这是**给浏览器看的**，不是给调用的服务看的，服务间调用根本不看这些响应头（就是允许指定的域名在前端进行跨域请求吗）。

如果有许多 Controller，逐一添加注解太麻烦，可以在项目的配置类中添加 `CorsFilter` 类型的 Bean。

上述方法只适用于单体服务，那如果在微服务中呢？

借由 Gateway 的功能，可以在配置文件中轻松完成微服务的跨域配置：

```yaml
spring:
  cloud:
    gateway:
      # 全局跨域配置（网关层统一处理，微服务无需再单独配跨域，避免冲突）
      globalcors:
        cors-configurations:
          '[/**]':
            # 允许的跨域源（核心）：* 代表任意域名/IP/端口的前端都能跨域
            allowed-origin-patterns: '*'
            # 允许的请求头：* 代表任意自定义/默认请求头（如Token、Content-Type等）
            allowed-headers: '*'
            # 也可以写为 allowed-methods: '*'，网关两种写法都支持
            allowedMethods: '*'
```

 之后在请求的 Response Headers 中会增加一些允许跨域的信息。

# 5. Seata

在微服务项目中，一个操作往往会涉及多个不同的服务，每个服务又会连接不同的数据库：

![一个操作涉及多个微服务](/image/SpringCloud/img36.svg)

此时应该如何保证多个事务的统一提交和统一回滚呢？

[Seata](https://seata.apache.org/zh-cn/) 是一款开源的分布式事务解决方案，致力于在微服务架构下提供高性能和简单易用的分布式事务服务。

现有如下交易流程：

![Seata演示示例流程](/image/SpringCloud/img37.png)

发起采购流程后，需要扣库存、生成订单、从账户中扣除指定金额，任一流程发生异常时，整个流程应当回滚。

![Seata演示示例分布式事务解决方案.](/image/SpringCloud/img38.png)

- TC：Transaction Coordinator，即事务协调者。维护全局和分支事务的状态，驱动全局事务提交或回滚；
- TM：Transaction Manager，即事务管理器。定义全局事务的范围，开始全局事务、提交或回滚全局事务；
- RM：Resource Manager，即资源管理器。管理分支事务处理的资源，与 TC 交谈以注册分支事务和报告分支事务的状态，并驱动分支事务提交或回滚。

[下载](https://seata.apache.org/zh-cn/download/seata-server)并解压 Seata 后，进入 `bin` 目录，使用 `seata-server.bat` 命令启动 Seata。

下载的 Seata 版本保证与 pom 文件中引入的 `spring-cloud-alibaba-dependencies` 依赖中的 Seata 版本一致。

在需要使用分布式事务的模块中添加依赖：

```xml
<dependency>
    <groupId>com.alibaba.cloud</groupId>
    <artifactId>spring-cloud-starter-alibaba-seata</artifactId>
</dependency>
```

在需要使用 Seata 的模块中添加 Seata 的配置文件 `file.conf` ：

```properties
service {
  #transaction service group mapping
  vgroupMapping.default_tx_group = "default"
  #only support when registry.type=file, please don't set multiple addresses
  default.grouplist = "127.0.0.1:8091"
  #degrade, current not support
  enableDegrade = false
  #disable seata
  disableGlobalTransaction = false
}
```

最后在最顶端的方法入口上使用 `@GlobalTransactional` 注解，由此开启全局事务。

![Seata二阶提交协议](/image/SpringCloud/img39.svg)

解释：

1. **XID**：**全局事务 ID**，是整个分布式事务的**唯一全局标识**，一个**全局事务只有一个 XID**，所有参与的分支事务都绑定这个 XID；**Branch ID**：**分支事务 ID**，是单个分支事务的**唯一局部标识**，一个全局事务下会有多个 Branch ID（有多少个分支事务就有多少个），与 XID 配合唯一标识一个分支事务。所有微服务的 undo_log 表，都有 XID 和 Branch ID。

2. 在过程6中申请的是分支事务控制的数据库表中的记录，因为seata要将前后镜像数据存到自己微服务数据库的undolog表中，所以要把原库中的这个表（业务表）锁上防止其他线程修改。

3. **获取锁**的时机是是在业务 SQL 执行后、本地事务提交前完成的。**只有当全局事务彻底结束（全局提交 / 全局回滚），或分支事务执行失败触发本地回滚**时，才会释放对应的全局锁，**分支事务一阶段提交后，全局锁会一直持有，不会提前释放**

4. Seata 的全局锁是**Seata Server（TC）层面维护的、针对数据库中「具体行数据」的分布式锁**，核心属性：

   锁的粒度：**行级**（和 MySQL 的行锁粒度一致，只锁被修改的那一行数据，不影响其他行，保证性能）；

   锁的标识：由「**数据库名 + 表名 + 主键值**」唯一标识（比如`order_db.t_order.id=100`），确保分布式场景下，不同微服务操作同一条数据时，锁的唯一性；（那一条数据被锁）

   锁的归属：全局锁绑定**全局事务 XID**，只有持有该 XID 的分支事务，才能操作对应数据并释放锁；（谁可以动锁定的数据）

   自动管理：全程由 Seata 框架（数据源代理 + TC）自动加锁、解锁，开发人员无需写任何代码。

5. 如果所有分支事务全部成功则进行分支提交，否则进行分支回滚。**正常回滚下，后镜像和当前数据库里的数据是完全相等的。**
