---
title: 线程基础（Java）
date: 2023-03-05 17:14:27
excerpt: Java 多线程编程通过继承 Thread 类、实现 Runnable 或 Callable 接口创建线程。synchronized 和 ReentrantLock 提供线程同步机制，防止数据冲突。synchronized 适用于简单场景，而 Lock 提供更灵活的锁控制。线程生命周期和死锁管理是多线程开发的关键。
tags:
  - 并发
  - 锁
categories : 技术
---

# Java 线程

- Java 程序在运行时默认会产生一个进程。
- 这个进程会有一个主线程。
- 代码都在主线程中执行。

## 1. 多线程的创建

开启线程都需要使用 Thread 类中的 start 方法，start方法会调用线程的run方法。

### 1.1 继承 Thread 类

```java
public class Thread1 extends Thread {
    @Override
    public void run() {
        for (int i = 0; i < 50; i++) {
            System.out.println(Thread.currentThread().getName() + "执行" + i);
        }
    }
}

public class Main {
    public static void main(String[] args) {
        Thread1 mythread = new Thread1();
        mythread.start();//输出子线程
        for (int i = 0; i < 50; i++) {//主线程不会等待子线程，因此会和子线程交替输出
            System.out.println(Thread.currentThread().getName() + "执行" + i);
        }
    }
}
```

### 1.2 实现 Runnable 接口

```java
public class Thread2 implements Runnable {
    public void run() {
        for (int i = 0; i < 50; i++) {
            System.out.println(Thread.currentThread().getName() + "执行" + i);
        }
    }
}//Runnable只是一个接口，不是线程类本身

public class Main {
    public static void main(String[] args) {
        Thread2 mythread = new Thread2();
        Thread thread = new Thread(mythread);
        thread.start();
        for (int i = 0; i < 50; i++) {
            System.out.println(Thread.currentThread().getName() + "执行" + i);
        }
    }
}
```

✅ 推荐实现 Runnable实现多线程：

1. 可以避免 Java 单继承限制
2. 多个线程可以共享同一个Runnable对象的数据：

```java
Runnable task = new Thread2(); // 一个任务对象
Thread t1 = new Thread(task);
Thread t2 = new Thread(task);
t1.start();
t2.start();
//这里 t1 和 t2 共享同一个 task 对象，可以共享变量、状态。
//方便多个线程操作同一份资源，减少内存开销。
```

3. 方便使用线程池

ExecutorService、ThreadPoolExecutor 等线程池 **只能接受 Runnable 或 Callable 对象**

### 1.3 实现 Callable 接口 + FutureTask（支持抛出异常）

1. **`Callable` 接口**：
   - 泛型接口，定义了一个 `call()` 方法，返回泛型指定的结果类型，且可抛出异常。
   - 语法：`public interface Callable<V> { V call() throws Exception; }`
2. **`Future` 接口**：
   - 用于接收 `Callable` 的返回结果，提供了获取结果、取消任务等方法。
   - 常用方法：`get()`（阻塞等待结果）、`isDone()`（判断任务是否完成）等。

```java
import java.util.concurrent.Callable;
import java.util.concurrent.FutureTask;

public class MyCallable implements Callable<Integer> {
    @Override
    public Integer call() throws Exception {
        System.out.println("线程运行中！");
        return 123;
    }

    public static void main(String[] args) throws Exception {
        MyCallable myCallable = new MyCallable();
        FutureTask<Integer> futureTask = new FutureTask<>(myCallable);
        Thread thread = new Thread(futureTask);
        thread.start();
        Integer result = futureTask.get();
        System.out.println("线程返回的结果是：" + result);
    }
}
```

**好处**：有返回值、可以抛出异常。

| 方法                       | 是否支持返回值 | 是否能抛异常 | 使用场景             |
| -------------------------- | -------------- | ------------ | -------------------- |
| 继承 Thread                | 不支持         | 不支持       | 简单线程任务         |
| 实现 Runnable              | 不支持         | 不支持       | 推荐，解耦任务和线程 |
| 实现 Callable + FutureTask | 支持           | 支持         | 需要结果和异常处理   |

## 1.4线程池

线程的创建和销毁是一项开销较大的操作，频繁地创建和销毁线程会耗费大量的系统资源。通过使用线程池，可以事先创建一定数量的线程，并将它们放入池中，需要执行任务时直接从池子中获取复用线程。这样可以避免频繁地创建和销毁线程，提高系统的资源利用率。



## 2. 线程的执行周期

![](/image/线程基础java/img1.png)

线程对象必须处于运行状态才能运行，其他状态无法运行。

## 3. Lambda 表达式创建线程

当需要使用多个线程时，可以不创建自己的线程对象，使用 Lambda 表达式使代码更简洁。

**匿名类：**

```java
Thread thread = new Thread() {
    @Override
    public void run() {
        System.out.println("线程运行中（匿名类）！");
    }
};

Thread thread = new Thread(new Runnable() {
    @Override
    public void run() {
        System.out.println("线程正在运行");
    }
});
thread.start();
```

**Lambda 表达式：**

```java
Thread thread = new Thread(() -> {
    System.out.println("线程正在运行");
});
thread.start();
```

**Lambda 表达式含义**：接口 对象 = (参数) -> {具体实现};

## 4. 线程相关方法

### 4.1**Thread 类的核心方法**

以下是工作和面试中最常涉及的 Thread 类方法，简洁实用：

#### **start()**

- **功能**：启动线程，调用 run() 方法，使线程进入可运行状态（Runnable）。

- 面试要点：

  - 只能调用一次，重复调用抛出 IllegalThreadStateException。
  - 直接调用 run() 不会创建新线程，只在当前线程执行。

- 示例：

  ```java
  Thread t = new Thread(() -> System.out.println("Running"));
  t.start(); // 启动新线程
  ```

#### **run()**

- **功能**：定义线程的执行逻辑，通常通过继承 Thread 或实现 Runnable 重写。

- 面试要点：常被问与 start() 的区别，强调 run() 是普通方法，start() 触发线程调度。

- 示例：

  ```java
  public class MyThread extends Thread {
      @Override
      public void run() {
          System.out.println("Thread logic");
      }
  }
  ```

#### **sleep(long millis)**

- **功能**：暂停当前线程指定毫秒，进入 Timed Waiting 状态，不释放锁。

- 面试要点：

  - 常用于模拟延迟或定时任务。
  - 抛出 InterruptedException，需处理。
  - 常被问与 wait() 的区别（sleep 不释放锁且自动唤醒，wait 释放）。

- 示例

  ```java
  try {
      Thread.sleep(1000); // 暂停 1 秒
  } catch (InterruptedException e) {
      e.printStackTrace();
  }
  ```

#### **join()**

- **功能**：使当前线程等待调用 join() 的线程执行完成。

- 面试要点：

  - 用于线程间的依赖协调，常在面试题中出现（如“确保线程按顺序执行”）。
  - 抛出 InterruptedException。

- 示例

  ```java
  Thread t = new Thread(() -> System.out.println("T running"));
  t.start();
  t.join(); // 主线程等待 t 完成
  ```

#### **interrupt()**

- **功能**：设置线程的中断标志，用于中断线程。

- 面试要点：

  - 常被问如何优雅地停止线程。
  - 阻塞状态（如 sleep、wait）会抛出 InterruptedException，运行状态需检查 isInterrupted()。

- 示例：

  ```java
  Thread t = new Thread(() -> {
      while (!Thread.currentThread().isInterrupted()) {
          System.out.println("Running");
      }
  });
  t.start();
  t.interrupt(); // 中断线程
  ```

------

### 4.2 **Object 类的同步方法**

这些方法用于线程协作，常与 synchronized 结合讨论。

#### **wait()**

- **功能**：使线程进入等待状态（Waiting 或 Timed Waiting），释放对象锁，直到被 notify() 或 notifyAll() 唤醒。

- 面试要点：

  - 必须在 synchronized 块中调用，否则抛 IllegalMonitorStateException。
  - 常用于生产者-消费者模型。
  - 需在循环中检查条件，防止伪唤醒。

- 示例

  ```java
  synchronized (obj) {
      while (!condition) {
          obj.wait();
      }
  }
  ```

#### **notify() 和 notifyAll()**

- 功能：

  - notify()：唤醒一个在对象监视器上等待的线程。
  - notifyAll()：唤醒所有等待的线程。

- 面试要点：

  - 常被问与 signal() 的区别或如何避免线程饥饿。
  - notifyAll() 更安全但开销大，面试常要求解释选择场景。

- 示例：

  ```java
  synchronized (obj) {
      obj.notify(); // 唤醒一个线程
  }
  ```

------

### 4.3 **Lock 核心方法**

java.util.concurrent.locks 包中的方法在现代 Java 开发中越来越重要，面试中常被问及与 synchronized 的对比。

#### **lock() 和 unlock()**

- 功能：

  - lock()：获取锁，阻塞直到成功。
  - unlock()：释放锁，通常在 finally 块中调用。

- 面试要点：

  - 比 synchronized 更灵活（如支持超时、可中断）。
  - 需手动释放锁，面试常问如何避免死锁。

- 示例：

  ```java
  Lock lock = new ReentrantLock();
  lock.lock();
  try {
      // 受保护代码
  } finally {
      lock.unlock();
  }
  ```

## 6. 线程同步

### 6.1 synchronized

#### 什么是 synchronized？

synchronized 是 Java 提供的一种内置同步机制，用于解决多线程环境下的线程安全问题。它保证同一时刻只有一个线程可以执行被修饰的代码块或方法，避免数据不一致或冲突。

#### synchronized 的作用

- **保证线程互斥访问共享资源**
- **确保内存可见性**

#### synchronized 的使用方式

1. **修饰实例方法**

```java
public synchronized void method() {
    // 同步方法体
}
```

- 作用于当前实例方法的锁（对象锁/实例锁），只有获得该对象锁的线程才能进入该方法。

```java
public class InstanceLockExample {
    private int count = 0;

    public synchronized void increment() {
        count++;
        System.out.println(Thread.currentThread().getName() + " count: " + count);
    }

    public void incrementWithBlock() {
        synchronized (this) {
            count++;
            System.out.println(Thread.currentThread().getName() + " count: " + count);
        }
    }

    public static void main(String[] args) {
        InstanceLockExample example1 = new InstanceLockExample();
        InstanceLockExample example2 = new InstanceLockExample();

        new Thread(() -> {
            for (int i = 0; i < 5; i++) {
                example1.increment();
            }
        }, "Thread-A").start();

        new Thread(() -> {
            for (int i = 0; i < 5; i++) {
                example2.increment();
            }
        }, "Thread-B").start();
    }
}
```

2. **修饰静态方法**

```java
public static synchronized void staticMethod() {
    // 同步静态方法体
}
```

- 作用于当前类的 Class 对象锁（类锁），所有该类的实例共享这把锁。

```java
public class ClassLockExample {
    private static int count = 0;

    public static synchronized void increment() {
        count++;
        System.out.println(Thread.currentThread().getName() + " count: " + count);
    }

    public static void incrementWithBlock() {
        synchronized (ClassLockExample.class) {
            count++;
            System.out.println(Thread.currentThread().getName() + " count: " + count);
        }
    }

    public static void main(String[] args) {
        ClassLockExample example1 = new ClassLockExample();
        ClassLockExample example2 = new ClassLockExample();

        new Thread(() -> {
            for (int i = 0; i < 5; i++) {
                example1.increment();
            }
        }, "Thread-A").start();

        new Thread(() -> {
            for (int i = 0; i < 5; i++) {
                example2.increment();
            }
        }, "Thread-B").start();
    }
}
```

3. **修饰代码块**

```java
public void method() {
    synchronized(this) {
        // 同步代码块
    }
}
```

- 锁住括号中指定的对象，只有获得该对象锁的线程才能执行代码块。

```java
public class SyncBlockExample {
    private int count = 0;
    private final Object lock = new Object();

    public void increment() {
        synchronized (lock) {
            count++;
            System.out.println(Thread.currentThread().getName() + " count: " + count);
        }
        System.out.println("Increment done");
    }
}
```

### 6.2 Lock

Lock 是一个接口，最常用的实现类是 ReentrantLock（可重入锁），提供了与 synchronized 类似的排它锁功能，但可以更灵活地控制锁的获取和释放。

#### Lock 代码示例

```java
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

public class LockExample {
    private int count = 0;
    private final Lock lock = new ReentrantLock();

    public void increment() {
        lock.lock();
        try {
            count++;
            System.out.println(Thread.currentThread().getName() + " count: " + count);
        } finally {
            lock.unlock();
        }
    }

    public static void main(String[] args) {
        LockExample example = new LockExample();

        Runnable task = () -> {
            for (int i = 0; i < 5; i++) {
                example.increment();
                try {
                    Thread.sleep(50);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        };

        Thread t1 = new Thread(task, "Thread-1");
        Thread t2 = new Thread(task, "Thread-2");

        t1.start();
        t2.start();
    }
}
```
