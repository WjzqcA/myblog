---
title: redisson
date: 2023-05-25 11:38:36
excerpt: Redisson 是一个基于 Redis 的 Java 内存数据网格（In-Memory Data Grid）框架，提供了对 Redis 的分布式、可扩展、高可用的数据结构、服务和工具的支持。它不仅封装了常见的 Redis 操作，还实现了如分布式锁（可重入锁、公平锁、红锁等）、分布式集合、布隆过滤器、队列、限流器、调度任务等功能，极大简化了开发分布式应用的复杂度。Redisson 支持多种部署模式，包括主从、哨兵和集群。
tags:
  - 缓存
  - 并发
  - 锁
categories:
  技术
---

# Redisson

Redisson 是一个基于 Redis 的 Java 内存数据结构工具包，它不只是一个客户端，而是提供了 分布式工具的完整实现，比如：

- 分布式锁 （可重入、公平、联锁、读写锁等）
- 分布式集合、Map、List、Set、Queue、Deque
- 分布式对象、消息队列、计数器、信号量
- 本地缓存 + Redis 缓存的整合（类似 Caffeine + Redis）

# 一、使用步骤

## Maven 引入

```xml
<dependency>
    <groupId>org.redisson</groupId>
    <artifactId>redisson-spring-boot-starter</artifactId>
    <version>3.27.2</version> <!-- 使用最新版本 -->
</dependency>
```

## 配置（application.yml）

```yaml
redisson:
  config: |
    singleServerConfig:
      address: "redis://127.0.0.1:6379"
```

## 创建redis配置类

```java
@Configuration
public class RedissonConfig {
    @Bean
    public RedissonClient redissonClient() {
        Config config = new Config();
        config.useSingleServer()
            .setAddress("redis://101.XXX.XXX.160:6379")
            .setPassword("root");
        return Redisson.create(config);
    }
}
```

## 使用分布式锁：

```java
@Autowired
private RedissonClient redissonClient;

public void doSomething() {
    RLock lock = redissonClient.getLock("my-lock"); // 获取一个可从入锁
    try {
        // 尝试加锁，最多等待100秒，上锁后10秒自动释放
        boolean locked = lock.tryLock(100, 10, TimeUnit.SECONDS);
        if (locked) {
            // 执行业务逻辑
        }
    } catch (InterruptedException e) {
        e.printStackTrace();
    } finally {
        if (lock.isHeldByCurrentThread()) {
            lock.unlock(); // 释放锁
        }
    }
}
```

# 二、Redisson 提供的锁类型

| 锁类型          | 说明                                  |
| --------------- | ------------------------------------- |
| `RLock`         | 可重入锁（默认）                      |
| `FairLock`      | 公平锁，按顺序获取锁                  |
| `ReadWriteLock` | 读写锁                                |
| `MultiLock`     | 联锁，多个key一起加锁                 |
| `RedLock`       | Redis官方推荐的红锁算法（用于多节点） |

## 2.1可重入锁

这里详细解释一下可重入锁：同一个线程在持有锁的情况下，能再次获取这把锁而不会死锁。即当线程 A 已经获取了锁，再次进入同一个锁定代码块时，如果锁是可重入的，就不会被阻塞或死锁。

### 1. 为什么需要可重入锁？

情景 1：递归调用中再次加锁

```java
public synchronized void methodA() {
    methodB(); // methodB 也被 synchronized 修饰
}

public synchronized void methodB() {
    // ...
}
```

- `methodA()` 和 `methodB()` 都是同步方法，当前线程调用 `methodA()` 后再进入 `methodB()`。
- 如果锁是**不可重入的**，当前线程在 `methodB()` 处会自己把自己阻塞，造成死锁。

但如果是**可重入锁**（如 Java 中的 `synchronized` 和 `ReentrantLock`），线程可以**多次加锁**，**内部计数器+1**，直到退出每一层时再 **逐级释放锁**。

情景 2：一个同步方法 A 调用另一个同步方法 B（同一个类）

```java
public class Example {
    public synchronized void methodA() {
        methodB(); // 调用另一个同步方法
    }

    public synchronized void methodB() {
        System.out.println("Inside methodB");
    }
}
```

- 这两个方法都锁的是同一个对象（默认是 `this`）。
- 当前线程调用 `methodA()` 并持有 `this` 的锁。
- 接着调用 `methodB()`，也需要 `this` 的锁。
- **由于是可重入锁，线程已经持有，所以可以“再次进入”**。

情景 3：子类调用父类的同步方法

```java
class Parent {
    public synchronized void doSomething() {
        System.out.println("Parent");
    }
}

class Child extends Parent {
    @Override
    public synchronized void doSomething() {
        super.doSomething(); // 父类方法也要获取锁
        System.out.println("Child");
    }
}
```

- 子类和父类方法都使用了 `synchronized`，**锁的对象仍是同一个：当前实例（this）**。
- 当调用子类方法时，线程先获得 `this` 锁，然后再调用 `super.methodParent()`。
- 父类方法也要获取 `this` 的锁。
- **可重入锁保证了子类可以顺利进入父类的同步方法**，不会死锁。

### 2.可重入锁的底层（同一个线程访问同一把锁可以直接放行）

- 内部维护一个 **锁计数器** 和 **持有锁的线程标识**。
- 当线程再次请求这把锁，判断当前线程标识，检测到自己再次加锁，计数器 +1，不会发生阻塞。
- 释放锁时，计数器 -1；直到为 0，锁才真正释放

## 2.2公平锁

公平锁的特点是：

- **按照线程请求锁的先后顺序来获取锁**。
- 类似于排队买票，谁先来谁先服务。
- 后来的线程不能插队。

代码：

```java
RLock fairLock = redissonClient.getFairLock("my-fair-lock");
```

Redisson 的公平锁在 Redis 中维护一个**等待队列**：

1. 所有请求锁的线程会按顺序加入一个 Redis 队列。
2. 当前持有锁的线程释放锁后，下一个排队的线程才能获得锁。
3. Redisson 会定时检查等待队列和锁状态，决定是否唤醒下一个等待者

## 2.3读写锁（读锁和写锁）

**读写锁（ReadWriteLock）** 是一种更细粒度的锁机制，它将锁分成两个部分：

- **读锁（共享锁readLock()）**：允许多个线程同时读，但不能写。
- **写锁（独占锁writeLock()）**：只允许一个线程写，写时不允许其他线程读或写。

Redisson 的读写锁底层通过 Redis + Lua 脚本实现：

1. 读锁使用一个计数器维护当前读线程数量。
2. 写锁是一个独占键，只有当没有读锁存在时才能成功加写锁。
3. 使用 Redis 的 `setnx`、`get`、`incr` 等命令，并配合 Lua 脚本做原子性判断

## 2.4联锁

**联锁（Redisson MultiLock）** 是一种同时对**多个 Redis 实例的锁对象加锁**的机制，只有当**所有的锁都加成功**，联锁才算加锁成功。

🚨 用于 Redis 多节点环境中，保证多个锁资源都被当前线程拥有，防止部分锁成功、部分失败造成的不一致。（多个资源，每个资源在不同 Redis 上）

### 1. 为什么需要联锁？

举个例子：

假如部署了多个 Redis 节点用于冗余（不是 Redis Cluster）

- 节点 A、B、C 上分别都有一个分布式锁；
- 你希望：**只有当 A、B、C 三个锁都加锁成功后，才继续执行后续逻辑**，否则回滚。

### 2.使用示列

```java
RLock lock1 = redissonClient.getLock("lock1");
RLock lock2 = redissonClient.getLock("lock2");
RLock lock3 = redissonClient.getLock("lock3");

// 创建联锁对象
RLock multiLock = new RedissonMultiLock(lock1, lock2, lock3);

// 加锁
multiLock.lock();
// 解锁
multiLock.unlock();
```

### 3.底层实现

- Redisson 会依次尝试获取传入的每个锁（即多个 Redis 实例的锁）。
- 只要有一个失败，就立即释放之前成功加上的锁。
- 所有锁加成功后，才算联锁加锁成功。
- 释放锁时，会依次释放所有的子锁。

## 2.5看门狗机制

当你通过 Redisson 加锁时，如果没有指定锁的**过期时间**，Redisson 会自动为这把锁设置一个默认的过期时间（默认 **30秒**），并且会启动一个“看门狗定时任务”。
作用：**定期自动延长锁的过期时间**，防止业务线程未执行完就锁被释放。

### 1.默认行为

- 加锁成功后，Redisson 会为锁设置一个 default **30秒过期时间**
- 然后开启一个**后台定时任务**，每隔 **10秒** 检查是否还持有锁
- 如果当前线程还持有锁，**会自动将锁的过期时间重置为30秒**

这个过程会一直持续，直到**手动解锁**或线程结束。

### 2.为什么需要看门狗？

假如没有看门狗机制：

1. 给锁设置 10 秒过期时间
2. 某个业务逻辑执行时间超过了 10 秒
3. 锁到期被释放
4. 其他线程获取了这把锁，**导致数据被并发修改，发生严重问题**

有了看门狗：

即使忘了设置合适的过期时间，**Redisson 会自动帮你续期，避免锁失效引发并发问题。**
