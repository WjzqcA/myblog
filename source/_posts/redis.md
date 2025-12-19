---
title: redis
date: 2023-05-18 21:54:01
excerpt: Redis 是一个高性能的内存级 key-value 数据库，以其极快的读写速度和灵活的数据结构广受欢迎。它支持字符串、哈希、列表、集合、有序集合等多种数据类型，适用于缓存、消息队列、排行榜等场景。Redis 采用单线程 + 非阻塞 I/O 模型，避免线程切换和锁竞争，结合高效的数据结构优化，显著提升性能。通过 Spring Data Redis 等客户端，开发者可轻松集成 Redis，实现缓存管理、分布式锁和消息队列等功能，广泛应用于热点数据存储和实时处理场景。
tags:
  - 数据库
  - 缓存
categories:
  技术
---

# Redis 简介

Redies是一个基于内存的key-value结构数据库

- 基于内存存储，读写性能高
- 适合存储热点数据（热点商品、资讯、新闻）

## 为什么redis速度快呢？

1. **内存级存储，省去了磁盘 I/O**
2. **单线程模型 + 非阻塞 I/O**
   - Redis 使用**单线程+多路复用（epoll）**模型，避免线程切换和加锁开销
   - 不用担心并发控制问题，CPU 利用率高，调度效率高
   - 所有命令按顺序执行，无锁竞争，也就无死锁、无上下文切换
3. **高效的数据结构，进行了针对性优化**

# 一、数据类型

Redis存储的是key-value的数据，key是字符串，value有五种常用的数据类型

- 字符串string
- 哈希hash
- 列表list
- 集合set
- 有序集合sorted set/zset

![](/image/redis/img1.png)

# 二、常用命令

## 2.1 String（字符串）

最基础的类型，常用于缓存单个值，如：用户信息、Token、验证码等。

| 命令                      | 说明               | 示例                             |
| ------------------------- | ------------------ | -------------------------------- |
| `SET key value`           | 设置字符串键值     | `SET name "Tom"`                 |
| `GET key`                 | 获取字符串值       | `GET name` → `"Tom"`             |
| `SETEX key seconds value` | 设置值并自动过期   | `SETEX code 60 "123456"`         |
| `GETSET key value`        | 设置新值并返回旧值 | `GETSET name "Jack"` → `"Tommy"` |

## 2.2 **Hash（哈希）**

适合存储对象（如用户、商品）的属性集合，类似于 Java 中的 Map

| 命令                   | 说明             | 示例                                 |
| ---------------------- | ---------------- | ------------------------------------ |
| `HSET key field value` | 设置哈希字段值   | `HSET user:1 name "Tom"`             |
| `HGET key field`       | 获取字段值       | `HGET user:1 name` → `"Tom"`         |
| `HDEL key field`       | 删除字段         | `HDEL user:1 name`                   |
| `HGETALL key`          | 获取所有字段和值 | `HGETALL user:1` → `name:Tom age:20` |
| `HEXISTS key field`    | 判断字段是否存在 | `HEXISTS user:1 name` → `1`          |
| `HLEN key`             | 获取字段数量     | `HLEN user:1` → `2`                  |

## 2.3 **List（列表）**

一个按顺序排列的字符串集合，底层为双向链表，适合消息队列等场景

| 命令                    | 说明           | 示例                           |
| ----------------------- | -------------- | ------------------------------ |
| `LPUSH key value`       | 从左边插入元素 | `LPUSH queue "task1" "task"`   |
| `RPUSH key value`       | 从右边插入元素 | `RPUSH queue "task3"`          |
| `LPOP key`              | 弹出左侧元素   | `LPOP queue` → `"task1"`       |
| `RPOP key`              | 弹出右侧元素   | `RPOP queue` → `"task2"`       |
| `LRANGE key start stop` | 获取范围内元素 | `LRANGE queue 0 -1` → 所有元素 |
| `LLEN key`              | 获取长度       | `LLEN queue` → `2`             |

## 2.4 Set（集合）

无序、去重，适合统计、去重场景，例如“签到”、“共同好友”。

| 命令                  | 说明         | 示例                                  |
| --------------------- | ------------ | ------------------------------------- |
| `SADD key value`      | 添加元素     | `SADD tags "java"`                    |
| `SREM key value`      | 删除元素     | `SREM tags "java"`                    |
| `SMEMBERS key`        | 获取所有元素 | `SMEMBERS tags` → `["java", "redis"]` |
| `SISMEMBER key value` | 判断是否存在 | `SISMEMBER tags "java"` → `1`         |
| `SCARD key`           | 获取集合大小 | `SCARD tags` → `2`                    |
| `SINTER key1 key2`    | 交集         | `SINTER set1 set2`                    |
| `SUNION key1 key2`    | 并集         | `SUNION set1 set2`                    |
| `SDIFF key1 key2`     | 差集         | `SDIFF set1 set2`                     |

## **2.5 ZSet（有序集合）**

带分数的集合（二元组，相当于键值对列表<member，score>，但是member只能是string，score只能是数字），元素唯一，分数可重复。可用于排行榜、优先队列等。

| 命令                                 | 说明             | 示例                          |
| ------------------------------------ | ---------------- | ----------------------------- |
| `ZADD key score member`              | 添加元素及分数   | `ZADD rank 100 "Tom"`         |
| `ZRANGE key start stop [WITHSCORES]` | 正序获取元素     | `ZRANGE rank 0 -1 WITHSCORES` |
| `ZREVRANGE key start stop`           | 倒序获取         | `ZREVRANGE rank 0 -1`         |
| `ZSCORE key member`                  | 获取成员分数     | `ZSCORE rank "Tom"` → `100`   |
| `ZRANK key member`                   | 获取排名（升序） | `ZRANK rank "Tom"` → `0`      |
| `ZREVRANK key member`                | 获取排名（降序） | `ZREVRANK rank "Tom"` → `2`   |
| `ZREM key member`                    | 删除成员         | `ZREM rank "Tom"`             |

### 2.6 Key 管理：

| 命令                 | 说明             | 示例                |
| -------------------- | ---------------- | ------------------- |
| `DEL key`            | 删除键           | `DEL name`          |
| `EXPIRE key seconds` | 设置过期时间     | `EXPIRE name 60`    |
| `TTL key`            | 获取剩余过期时间 | `TTL name`          |
| `KEYS pattern`       | 模糊匹配键       | `KEYS user:*`       |
| `EXISTS key`         | 判断键是否存在   | `EXISTS name` → `1` |

# 三、Java客户端

主要有三种客户端

- Jedis
- Lettuce
- Spring Data Redis

## 3.1 Spring Data Redis使用方式

1. 导入Spring Data Redis的maven坐标

```xml
<!-- Spring Boot Redis starter -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>

<!-- 使用 Jackson 做 JSON 序列化（可选但推荐） -->
<dependency>
    <groupId>com.fasterxml.jackson.core</groupId>
    <artifactId>jackson-databind</artifactId>
</dependency>
```

2. 配置Redis数据源

```yaml
spring.redis.host=localhost
spring.redis.port=6379
spring.redis.password=
spring.redis.database=0
spring.redis.timeout=3000
```

3. 编写配置类，创建RedisTemplate对象(如果只是存储字符串，可以使用内置的 `StringRedisTemplate`，无需自定义)

```java
@Configuration
public class RedisConfig {

    @Bean
    public RedisTemplate<String, Object> redisTemplate(RedisConnectionFactory factory) {
        RedisTemplate<String, Object> template = new RedisTemplate<>();
        template.setConnectionFactory(factory);

        // key 的序列化方式为字符串
        template.setKeySerializer(new StringRedisSerializer());
        template.setHashKeySerializer(new StringRedisSerializer());

        // value 的序列化方式为 JSON
        Jackson2JsonRedisSerializer<Object> jsonSerializer =
            new Jackson2JsonRedisSerializer<>(Object.class);
        ObjectMapper mapper = new ObjectMapper();
        mapper.activateDefaultTyping(mapper.getPolymorphicTypeValidator(), ObjectMapper.DefaultTyping.NON_FINAL);
        jsonSerializer.setObjectMapper(mapper);

        template.setValueSerializer(jsonSerializer);
        template.setHashValueSerializer(jsonSerializer);

        template.afterPropertiesSet();
        return template;
    }
}
```

4. 通过RedisTemplate对象操作Redis

```java
@Autowired
private RedisTemplate<String, Object> redisTemplate;

public void testString() {
    redisTemplate.opsForValue().set("name", "Tom");
    String name = (String) redisTemplate.opsForValue().get("name");
    System.out.println("name = " + name);
}
```

## 3.2 常用API

RedisTemplate 提供以下操作子类：

| 操作方式  | 方法            | 说明                             |
| --------- | --------------- | -------------------------------- |
| key-value | `opsForValue()` | 常用的字符串键值对操作（如缓存） |
| 哈希      | `opsForHash()`  | Redis Hash 操作，类似 Map        |
| 列表      | `opsForList()`  | Redis List 操作，队列、栈等结构  |
| 集合      | `opsForSet()`   | Redis 无序集合 Set               |
| 有序集合  | `opsForZSet()`  | Redis 有序集合 Sorted Set        |

## 3.3 常用操作示例

### 操作普通字符串（opsForValue）

```java
redisTemplate.opsForValue().set("name", "Alice");
String name = (String) redisTemplate.opsForValue().get("name");
redisTemplate.opsForValue().set("token", "123456", 10, TimeUnit.MINUTES);//带过期时间
```

---

### 操作对象Lever（需配置序列化）

```java
User user = new User("Tom", 18);
redisTemplate.opsForValue().set("user:1", user);
User cachedUser = (User) redisTemplate.opsForValue().get("user:1");
```

---

### 操作 Hash（类似 Map）

```java
// 设置
redisTemplate.opsForHash().put("user:100", "name", "Tom");
redisTemplate.opsForHash().put("user:100", "age", 30);

// 获取
String name = (String) redisTemplate.opsForHash().get("user:100", "name");

// 获取整个 Hash
Map<Object, Object> map = redisTemplate.opsForHash().entries("user:100");
```

---

### 操作 List

```java
// 从左插入
redisTemplate.opsForList().leftPush("myList", "a");
redisTemplate.opsForList().leftPush("myList", "b");

// 获取范围
List<Object> list = redisTemplate.opsForList().range("myList", 0, -1);
```

---

### 操作 Set

```java
redisTemplate.opsForSet().add("mySet", "a", "b", "c");
Set<Object> members = redisTemplate.opsForSet().members("mySet");
```

---

### 操作 ZSet（有序集合）

```java
redisTemplate.opsForZSet().add("myZset", "a", 1);
redisTemplate.opsForZSet().add("myZset", "b", 2);

// 获取排名前2的元素
Set<Object> range = redisTemplate.opsForZSet().range("myZset", 0, 1);
```

---

### 通用操作（key 相关）

```java
redisTemplate.delete("user:1");                  // 删除 key
Boolean exists = redisTemplate.hasKey("user:1"); // 判断是否存在
redisTemplate.expire("user:1", 10, TimeUnit.MINUTES); // 设置过期时间
```

# 四、缓存策略

## 4.1缓存过期和淘汰策略

### 过期策略

Redis 支持为键设置过期时间（TTL，Time To Live），通过命令如 EXPIRE、SETEX 或 PX 设置。过期时间到达后，键会被自动删除。Redis 采用以下两种主要策略来处理过期键：

- **惰性删除（Lazy Deletion）**：**当客户端访问某个键时，Redis 才会检查该键是否过期**。如果已过期，键会被立即删除，并返回空结果。这种方式对内存清理是按需进行的，适合访问频繁的场景。
- **定期删除（Periodic Deletion）**：Redis 后台会定期扫描一部分设置了过期时间的键，检查是否过期并删除。这是通过一个定时任务实现的，扫描的频率和范围由配置参数（如 hz）控制。

### 淘汰策略

- 缓存更新是Redis为了节约内存而设计出来的一个东西，主要是因为内存数据宝贵，当我们想Redis插入太多数据，此时就可能会导致缓存中数据过多，所以Redis会对部分数据进行更新，或者把它淘汰更合适
- `内存淘汰`：Redis自动进行，当Redis内存达到我们设定的`max-memery`时，会自动触发淘汰机制，淘汰掉一些不重要的数据（可以自己设置策略方式）
- `超时剔除`：当我们给Redis设置了过期时间TTL之后，Redis会将超时的数据进行删除，方便我们继续使用缓存
- `主动更新`：我们可以手动调用方法把缓存删除掉，通常用于解决缓存和数据库不一致问题
- 最近最少使用

- 缓存更新是Redis为了节约内存而设计出来的一个东西，主要是因为内存数据宝贵，当我们想Redis插入太多数据，此时就可能会导致缓存中数据过多，所以Redis会对部分数据进行更新，或者把它淘汰更合适
- `内存淘汰`：Redis自动进行，当Redis内存达到我们设定的`max-memery`时，会自动触发淘汰机制，淘汰掉一些不重要的数据（可以自己设置策略方式）
- `超时剔除`：当我们给Redis设置了过期时间TTL之后，Redis会将超时的数据进行删除，方便我们继续使用缓存
- `主动切换`：我们可以手动调用方法把缓存删除掉，通常用于解决缓存和数据库不一致问题

## 4.2缓存穿透

缓存穿透是指客户端请求的数据在缓存中和数据库中都不存在，这样缓存永远都不会生效（只有数据库查到了，才会让redis缓存，但现在的问题是查不到），会频繁的去访问数据库。

正常的缓存流程是：**客户端请求 → 查缓存 → 缓存命中 → 返回数据客户端请求 → 查缓存 → 缓存未命中 → 查数据库 → 写入缓存 → 返回数据**

而缓存穿透的流程是：**客户端请求（数据不存在） → 查缓存（未命中） → 查数据库（未命中） → 不写入缓存 → 重复请求循环**

常见解决思路如下：

### **1. 缓存空值（Null Value）**

- **原理**：当数据库查询结果为空时，仍将空值写入缓存（设置较短的过期时间），避免后续相同请求穿透到数据库。
- **注意**：
  - 需设置较短过期时间，避免缓存大量空值占用内存。
  - 适用于请求参数有限、空值场景可控的情况。

### **2. 布隆过滤器（Bloom Filter）**

- **原理**：
  - 组成部分
    - 一个大小为 `m` 的 **bit 数组**，初始化全为 0。
    - K个独立的hash函数
  - 插入数据流程
    - 对要插入的元素，通过 `k` 个哈希函数计算出 `k` 个位置。
    - 把 bit 数组中这 `k` 个位置设置为 1
  - 查询元素流程
    - 对查询的元素，同样计算出 `k` 个位置
    - 如果这 `k` 个位置有任意一个是 0 → 一定不存在
    - 如果全部是 1 → 可能存在（存在误判可能）
- **操作**：在缓存前增加一层布隆过滤器，预先存储所有**存在的有效数据**的标识（如 ID）。
  - 请求到来时，先通过布隆过滤器判断数据是否存在：
    - 若不存在，直接返回空（无需查缓存和数据库）；
    - 若可能存在（布隆过滤器有一定误判率，因为哈希碰撞），再走正常缓存 + 数据库流程。
- **优势**：布隆过滤器占用内存极小，可快速判断数据是否存在，适合海量数据场景（如亿级用户 ID）。
- **注意**：
  - 存在一定误判率（可能将不存在的数据判定为存在），需配合缓存空值方案兜底。
  - 数据新增 / 删除时需同步更新布隆过滤器，否则会出现误判。

### **3. 热点参数缓存预热**

- **原理**：对高频访问的有效参数，预先将其对应的数据加载到缓存中，减少缓存未命中的概率。例如：电商平台可在大促前预热热门商品数据到缓存。

### **4. 参数校验与限流**

- **参数校验**：在接口层对请求参数进行合法性校验（如 ID 必须为正整数），直接拦截明显无效的请求（如`ID=-1`）。
- **限流熔断**：使用限流工具（如 Guava RateLimiter、Sentinel）对高频请求进行限制，或通过熔断机制（如 Hystrix）在数据库压力过大时降级返回默认值。

## 4.3缓存雪崩

指的是**大量缓存 key 在同一时间集中失效（或缓存服务整体宕机），导致所有请求瞬间穿透到数据库，造成数据库压力骤增甚至宕机**，最终引发整个系统连锁故障。

1. **让缓存失效时间错开**：给批量缓存的过期时间加个随机值（比如原本 24 小时过期，改成 24 小时 ±10 分钟），避免同一时间大量缓存失效。
2. **提高缓存可靠性**：缓存服务做集群（如 Redis 主从 + 哨兵），避免单点故障；甚至加一层本地缓存（如 Caffeine），作为分布式缓存的兜底。多级缓存？
3. **保护数据库**：给数据库加限流（限制每秒请求数）、熔断（缓存挂了就返回默认值），或者用队列把请求排队，避免瞬间冲垮数据库。
4. **核心数据永不过期**：对特别重要的热点数据（如首页信息）不设过期时间，后台定时主动更新，确保缓存一直可用。

## 4.4缓存击穿

指的是**某个热点缓存 key 突然失效（过期或被淘汰）或者Redis 服务整体宕机，此时大量并发请求同时访问该 key，导致所有请求瞬间穿透到数据库，造成数据库短时间压力剧增**的场景

解决方法

1. **互斥锁（分布式锁）**
   - 当缓存失效时，只有一个请求能获取锁并查询数据库，其他请求等待该请求更新缓存后，再从缓存中获取数据。
   - 例：Redis 的`SETNX`命令可实现分布式锁，第一个请求拿到锁后查库更新缓存，其他请求自旋等待（或短暂休眠后重试），直到缓存被更新。
2. **热点 key 永不过期**
   - 对绝对热点数据不设置过期时间，通过后台线程定时主动更新缓存（如每 10 分钟从数据库同步一次），避免因过期导致的击穿。
3. **提前预热热点数据**
   - 在流量高峰前（如秒杀开始前），主动将热点 key 加载到缓存，并设置较长的过期时间，确保高峰期间缓存不会失效。
4. **逻辑过期**
   - 方案分析：我们之所以会出现缓存击穿问题，主要原因是在于我们对key设置了TTL，如果我们不设置TTL，那么就不会有缓存击穿问题，但是不设置TTL，数据又会一直占用我们的内存，所以我们可以采用逻辑过期方案
   - **缓存 key 永不过期，但设计新的数据存储每一个key和对应地过期时间**，由业务代码判断是否过期。即使 “逻辑过期”，也不会直接删除缓存，而是先返回旧值，再异步更新缓存，避免请求穿透到数据库。
   - 这种方案巧妙在于，异步构建缓存数据，缺点是在重建完缓存数据之前，返回的都是脏数据

# 五、reids持久化

Redis 提供了两种主要的持久化机制来确保数据在服务器重启后不丢失：RDB（Redis DataBase） 和 AOF（Append Only File）。以下是对这两种机制的详细说明，以及它们的优缺点和适用场景。

### 1. **RDB（快照持久化）**

RDB 是通过定期将内存中的数据集以二进制快照的形式保存到磁盘上（默认文件名为 dump.rdb）。

### **工作原理**

- Redis 在满足特定条件时（如通过配置触发）生成内存数据的快照，保存到磁盘。
- 触发条件通常由配置文件中的 save 参数定义，例如：
  - save 900 1：900 秒内至少有 1 次键变更。
  - save 300 10：300 秒内至少有 10 次键变更。
- 手动触发：使用 SAVE（同步阻塞）或 BGSAVE（异步后台保存）命令。
- 快照生成时，Redis 会 fork 一个子进程来完成保存操作，尽量减少对主进程的影响。

### **优点**

- **高效**：RDB 文件是压缩的二进制格式，体积小，适合备份和恢复。
- **恢复快**：加载 RDB 文件比 AOF 快，适合大规模数据恢复。
- **性能影响小**：通过 fork 子进程，保存过程对主线程影响较小。

### **缺点**

- **数据丢失风险**：RDB 是周期性快照，两次快照之间发生崩溃可能丢失最近的数据。
- **fork 开销**：在大数据量场景下，fork 子进程可能导致短暂性能抖动。
- **不适合实时性要求高的场景**：数据一致性不如 AOF。

### **适用场景**

- 适合对数据丢失不敏感的场景，如缓存系统。
- 用于定期备份或灾难恢复。
- 数据量较大时，优先考虑 RDB 以加快恢复速度。

### 2. **AOF（追加日志持久化）**

AOF 通过记录每次写操作命令（如 SET、DEL 等）到日志文件（默认文件名为 appendonly.aof），触发时机由**刷盘策略**决定（控制命令写入磁盘的时机），在重启时通过重放命令恢复数据。

### **工作原理**

- 每次刷盘会使写操作追加到 AOF 文件中，记录 Redis 命令。

- 同步策略

  （通过 appendfsync 参数配置）：

  - always：每次写操作都同步到磁盘，数据安全性最高，但性能最低。
  - everysec：每秒同步一次，平衡性能和安全性（默认，可能会丢失 1 秒数据）。
  - no：由操作系统决定同步时机，性能最高，但数据安全性最低。

- **AOF 重写**：为避免文件过大，Redis 支持重写 AOF 文件，**合并冗余命令**（如多次 SET 同一个键值合并为最后一次）。

  - 自动触发：通过 auto-aof-rewrite-percentage（文件增长百分比）和 auto-aof-rewrite-min-size（最小文件大小）配置。
  - 手动触发：Redis 支持通过 BGREWRITEAOF 命令重写 AOF 文件，**合并冗余命令**，使用fork线程去实现

### **优点**

- **数据安全性高**：特别是 appendfsync always 模式，几乎无数据丢失。
- **文件可读性强**：AOF 文件是文本格式，记录的是 Redis 命令，便于调试和理解。
- **灵活性高**：支持不同同步策略，适应多种场景。

### **缺点**

- **文件体积大**：AOF 文件通常比 RDB 大，尤其是未重写时。
- **恢复较慢**：重放命令恢复数据比加载 RDB 慢，特别是在数据量大时。
- **性能开销**：always 模式下频繁磁盘写入会影响性能。

### **适用场景**

- 对数据一致性要求高的场景，如金融系统或订单数据存储。
- 需要最小化数据丢失的应用。
- 需要查看或修改操作日志的场景。

### 3. **RDB 和 AOF 的混合模式**

从 Redis 4.0 开始，支持 **RDB-AOF 混合持久化**：

- 默认情况下，AOF 只记录写操作命令，但可以通过配置 aof-use-rdb-preamble yes 启用**混合模式**。
- 在 **AOF 重写时**，Redis 首先将舍弃掉原来的AOF，将当前内存数据以 RDB 格式写入 AOF 文件开头，然后追加后续写命令。
- 新的 AOF 文件既包含初始的 RDB 快照（当前数据状态），也包含后续的增量写命令。
- **优点**：结合 RDB 的快速恢复和 AOF 的高一致性，文件体积更小，恢复速度更快。
- **适用场景**：需要兼顾恢复速度和数据安全性的场景。

# 六、redis实现锁机制

## 6.1使用SETNX实现逻辑上锁

SET key value NX EX（setnx）只有key不存在时才能写入。如果我们想要进行上锁可以设定一个键值，使用语句创建此键值相当于获取锁，一个线程创建成功其他线程则不会成功，可以让其他线程循环去等待锁的释放。键值删除相当于释放锁

## 6.2redis实现分布式锁

加锁：使用 Redis 的 SET key value NX EX 命令实现加锁，保证只有一个线程或节点能持有这把锁。在分布式的情况下，唯一标识不能只使用线程id，因为不同jvm中不同的线程可能会有相同的线程id，但是uuid一般不会重复。

```java
Boolean success = stringRedisTemplate.opsForValue().setIfAbsent(
    "lock:my-lock",        // 锁的key
    uuid,                  // 锁的value：唯一标识，常用UUID + 线程标识
    10, TimeUnit.SECONDS   // 锁的过期时间，避免死锁
);
```

解锁：解锁要注意只能持有锁的线程才能释放锁，否则可能会引发误删除锁的操作

示例1：

```java
获得锁...
业务处理...
redis.del("lock:my-lock");
```

直接释放锁会出现问题，对于两个线程来说：

- 持有锁的线程1在锁的内部出现了阻塞，导致他的锁TTL到期，自动释放
- 此时线程2也来尝试获取锁，由于线程1已经释放了锁，所以线程2可以拿到
- 但是现在线程1阻塞完了，继续往下执行，要开始释放锁了
- 那么此时就会将属于线程2的锁释放，这就是误删别人锁的情况

解决方案就是在每个线程释放锁的时候，都判断一下这个锁是不是自己的，如果不属于自己，则不进行删除操作

示例2：让我们加上判断再来看看

```java
获得锁...
业务处理...
if (redis.get("lock:my-lock") == uuid) {
    redis.del("lock:my-lock");
}
```

这时还是会出现问题

- 假设线程1已经获取了锁，在判断标识一致之后，准备释放锁的时候，又出现了阻塞（例如JVM垃圾回收机制）
- 于是锁的TTL到期了，自动释放了
- 那么现在线程2趁虚而入，拿到了一把锁
- 但是线程1的逻辑还没执行完，那么线程1就会执行删除锁的逻辑
- 但是在**阻塞前线程1已经判断了标识一致，所以现在线程1把线程2的锁给删了**
- 这就是删锁时的原子性问题
- 因为线程1的拿锁，判断标识，删锁，不是原子操作，所以我们要防止刚刚的情况

解决方案是使用lua去操作redis，让判断锁是否是自己的与删除操作成为原子操作

```java
String script = """
    if redis.call('get', KEYS[1]) == ARGV[1] then
        return redis.call('del', KEYS[1])
    else
        return 0
    end
    """;

stringRedisTemplate.execute(
    new DefaultRedisScript<>(script, Long.class),// Lua 脚本对象
    Collections.singletonList("lock:my-lock"),
    uuid
);
```

使用Redis实现分布式锁会有许多问题，可以使用Redisson直接实现分布式锁

1. 重入问题
   - 重入问题是指获取锁的线程，可以再次进入到相同的锁的代码块中。可重入锁的意义在于防止死锁，例如在HashTable这样的代码中，它的方法都是使用synchronized修饰的，假如它在一个方法内调用另一个方法，如果此时是不可重入的，那就死锁了。所以可重入锁的主要意义是防止死锁，synchronized和Lock锁都是可重入的（比如递归调用会重复获取同一把锁，或者a调用b，a和b两个方法都有锁，这种要可以进入）
2. 不可重试
   - 我们编写的分布式锁只能尝试一次，失败了就返回false，没有重试机制。但合理的情况应该是：当线程获取锁失败后，他应该能再次尝试获取锁
3. 超时释放
   - 我们在加锁的时候增加了TTL，这样我们可以防止死锁，但是如果卡顿(阻塞)时间太长，也会导致锁的释放。虽然我们采用Lua脚本来防止删锁的时候，误删别人的锁，但现在的新问题是没锁住，也有安全隐患
4. 主从一致性
   - Redis 的主从结构是指：**主节点（Master）**：负责处理写请求。**从节点（Slave）**：负责复制主节点的数据，处理只读请求。主节点宕机哨兵会选择一个从节点当作新的主节点
   - 如果Redis提供了主从集群，那么当我们向集群写数据时，主机需要异步的将数据同步给从机，万一在同步之前，主机宕机了(主从同步存在延迟，虽然时间很短，但还是发生了)，，还没来得及把锁同步到从节点，就会出现**数据丢失或不一致**

# 七、redis实现消息队列

**Redis 并不是专门的消息队列中间件**，但可以利用它的 **数据结构（如 List、Stream）和 Pub/Sub 机制** 来实现轻量级的消息队列功能，适用于中小型项目或延迟要求不高的**异步任务处理场景**。

场景：用户A购买消费券，先根据redis的信息查看是否满足购买要求，如果满足将购买信息放到消息队列中，其他线程获取消息队列中的订单信息操作数据库在同步到redis中

- 消息队列是一种异步通信机制，用于在分布式系统中的不同组件（进程、应用或服务器）之间传递消息。强调解耦（是引入了一个中间层）和异步处理，生产者将消息放入队列，消费者异步处理，双方无需直接交互。
  1. 消息队列：存储和管理消息，也被称为消息代理（Message Broker）
  2. 生产者：发送消息到消息队列
  3. 消费者：从消息队列获取消息并处理消息
- 使用队列的好处在于`解耦`：举个例子，快递员(生产者)把快递放到驿站/快递柜里去(Message Queue)去，我们(消费者)从快递柜/驿站去拿快递，这就是一个异步，如果耦合，那么快递员必须亲自上楼把快递递到你手里，服务当然好，但是万一我不在家，快递员就得一直等我，浪费了快递员的时间。所以解耦还是非常有必要的
- 那么在这种场景下我们的秒杀就变成了：在我们下单之后，利用Redis去进行校验下单的结果，然后在通过队列把消息发送出去，然后在启动一个线程去拿到这个消息，完成解耦，同时也加快我们的响应速度
- 这里我们可以直接使用一些现成的(MQ)消息队列，如kafka，rabbitmq等，但是如果没有安装MQ，我们也可以使用Redis提供的MQ方案

## 1. **基于 List 的消息队列**

Redis 的 **List** 数据结构通过其 FIFO（先进先出）特性可以实现简单的消息队列，结合阻塞命令（如 BLPOP 和 BRPOP）支持高效的任务处理。

### 实现原理

- **生产者**：使用 LPUSH 或 RPUSH 将消息推入队列。
- **消费者**：使用 RPOP 或 LPOP 获取消息，或者使用 BRPOP/BLPOP 实现阻塞等待。
- **阻塞机制**：当队列为空时，BRPOP/BLPOP 会让消费者阻塞，直到新消息到达或超时。

```bash
#生产者：向队列推送消息  LPUSH key value
LPUSH queue:task "task1"
LPUSH queue:task "task2"

#消费者：非阻塞获取消息
RPOP queue:task

#消费者：阻塞获取消息（等待 10 秒）
BRPOP queue:task 10
```

### 优点

- **简单易用**：实现逻辑简单，适合快速开发。
- **高效阻塞**：BRPOP/BLPOP 避免轮询，降低 CPU 和网络的长。
- **FIFO 保证**：严格的先进先出顺序，适合任务队列。（**点对点，只有一个能接收到**）

### 缺点

- **功能单一**：仅支持简单的 FIFO 队列，缺乏消息确认、路由或消费者组等高级功能。
- **无持久性保证**：如果未启用 AOF/RDB，服务器重启可能丢失消息。
- **竞争消费**：多个消费者竞争同一队列，可能导致消息重复处理或分配不均。
- **扩展性有限**：不支持复杂的分组消费或大规模分布式场景。

## 2. **基于 Pub/Sub 的消息队列**

Redis 的 **Pub/Sub**（发布/订阅）机制通过发布者和订阅者模式实现消息广播，适合实时消息传递。

Pub/Sub 机制并不涉及传统意义上的 Redis 数据结构，而是基于频道（Channel）的概念：

### 实现原理

- **发布者**：使用 PUBLISH 命令向特定频道发送消息。
- **订阅者**：使用 SUBSCRIBE 或 PSUBSCRIBE 订阅频道，实时接收消息。
- **消息分发**：消息会广播给所有订阅该频道的消费者，Redis 不存储消息（无持久化）

```bash
# 发布者：向频道发布消息
PUBLISH channel:notifications "New message arrived"

# 订阅者：订阅频道
SUBSCRIBE channel:notifications
#接收所有以 channel: 开头的频道消息
PSUBSCRIBE channel:*
```

### 优点

- **实时性强**：消息立即广播给所有订阅者，适合实时通知。
- **简单轻量**：无需复杂配置，适合快速实现。
- **支持广播**：一个消息可被多个订阅者接收，适合一对多通信。(**多个接收者能够在同一时间接收**)

### 缺点

- **无持久化**：消息发送后不存储，若订阅者不在线会丢失消息。
- **无队列语义**：不支持 FIFO 或消息确认，严格来说不是传统消息队列。
- **连接依赖**：订阅者需保持连接，断开后无法恢复历史消息。
- **扩展性有限**：不支持复杂路由或消费者组，适合简单场景。

## 3. **基于 Stream 的消息队列**

Redis 5.0 引入的 **Stream** 数据结构是一种 **日志型数据结构**，支持复杂的消息处理机制，类似于专业消息队列（如 Kafka）。

### 实现原理

- **生产者**：使用 XADD 将消息添加到 Stream，消息自动生成唯一 ID（基于时间戳或序列号）。
- **消费者**：使用 XREAD 读取消息（支持阻塞模式），或通过消费者组（XGROUP）实现分组消费。
- **消费者组**：允许多个消费者并行处理消息，支持消息确认（XACK）和历史回溯（XRANGE）。
- **阻塞读取**：通过 XREAD BLOCK 实现阻塞等待。

```bash
# 生产者：向 tream添加消息 
# 将一条包含 field1=value1 和 field2=value2 的消息添加到 mystream 中
# * 的意思是让 Redis 自动生成消息的 ID
XADD mystream * field1 value1 field2 value2

# 消费者：非阻塞读取 COUNT 1：读取一个 $：从最新消息开始读取。 STREAMS mystream指定要读取的stream
XREAD COUNT 1 STREAMS mystream $

# 消费者：阻塞读取（等待 10 秒）
XREAD BLOCK 10000 STREAMS mystream $

# 创建消费者组
XGROUP CREATE mystream mygroup $ MKSTREAM

# 消费者组读取消息 GROUP mygroup consumer1：指定消费者组的名称
# >：表示读取未分配的新消息（即在消费者组中尚未分配给其他消费者的消息）
XREADGROUP GROUP mygroup consumer1 COUNT 1 STREAMS mystream >
```

### 优点

- **功能丰富**：支持消费者组、消息确认、历史回溯、持久化等，接近专业消息队列。
- **分布式支持**：消费者组允许多个消费者并行处理，适合分布式系统。
- **持久化**：消息存储在 Stream 中，支持历史查询和持久化（结合 AOF/RDB）。
- **灵活性**：支持阻塞和非阻塞读取，适应多种场景。

| 特性                   | 说明                       |
| ---------------------- | -------------------------- |
| **持久化**             | 消息默认持久化在内存+磁盘  |
| **支持多个消费者组**   | 每个组有自己的消费进度     |
| **消息可追溯**         | 通过 ID 精确读取历史消息   |
| **支持 ACK + 重试**    | 消息未处理可查，可重新分发 |
| **适合分布式队列场景** | 高可用、性能强             |

### 缺点

- **复杂性较高**：相比 List 和 Pub/Sub，配置和使用更复杂。
- **资源占用**：Stream 存储消息历史，可能增加内存使用（可通过 XTRIM 清理）。
- **性能开销**：相比 List 的简单队列，Stream 的功能更复杂，性能略低。

|              | List                                     | PubSub                                                       | Stream                                                 |
| ------------ | ---------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------ |
| 消息持久化   | 支持                                     | 不支持（设计就是用于高效的，持久化会影响效率所以就直接丢掉） | 支持                                                   |
| 阻塞读取     | 支持                                     | 支持                                                         | 支持                                                   |
| 消息堆积处理 | 受限于内存空间，可以利用多消费者加快处理 | 受限于消费者缓冲区                                           | 受限于队列长度，可以利用消费者组提高消费速度，减少堆积 |
| 消息确认机制 | 不支持                                   | 不支持                                                       | 支持                                                   |
| 消息回溯     | 不支持                                   | 不支持                                                       | 支持r                                                  |

# 九、redis多线程

Redis 最初设计为**单线程处理核心请求**（命令解析、数据读写、结果返回），原因是：

- Redis 基于内存操作，CPU 不是瓶颈，瓶颈主要在网络 IO 或内存；
- 单线程避免了多线程的上下文切换、锁竞争开销，实现简单且性能足够；
- 单线程天然保证命令执行的原子性（无需加锁）。

但随着业务场景升级，单线程在**高并发网络 IO**场景下出现瓶颈：

- 单线程同时处理 “接收请求、解析命令、返回结果”，网络读写耗时占比升高；
- 大报文（如大 key 的 GET/SET）的网络传输会阻塞单线程，降低 QPS。

Redis 6.0 正式引入**多线程处理网络 IO**，核心目标：

- 多线程仅作用于**网络请求的读写阶段**；
- 核心**命令执行仍保留单线程，保证原子性和兼容性**；
- 大幅提升高并发场景下的 QPS（尤其大报文场景）。

```
客户端请求 → 监听端口（主线程）→ 接入连接 → 分配给IO线程 →
IO线程读取请求并解析 → 主线程执行命令（单线程）→
IO线程将结果写回客户端 → 主线程回收连接
```
