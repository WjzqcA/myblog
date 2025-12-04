---
title: mybatis
date: 2023-05-12 10:25:52
excerpt: MyBatis 是一种高效的持久层框架，简化了 Java 应用与数据库的交互。通过映射文件（如 UserMapper.xml）定义 SQL 语句，支持动态 SQL 和多表操作，并提供灵活的配置（如 SqlMapConfig.xml）来管理数据源和环境。结合代理开发方式，开发者只需定义接口，MyBatis 自动生成实现，处理参数映射和结果集转换，显著提高开发效率。
tags:
  - SSM
  - 开发框架
categories : 技术
---

# 1 MyBatis 基础

## 1.1 步骤

1. 添加 mubatis 的坐标
2. 创建 MyBatis 的核心配置文件（通常为 SqlMapConfig.xml）。
3. 创建实体类（User）。
4. 创建映射文件（UserMapper.xml）。
5. 在核心配置文件中加载映射文件。
6. 通过 MyBatis API 执行 SQL 操作。

## 1.2 映射文件（UserMapper.xml）概述

主要写 sql 语句

![](/image/mybatis/img1.png)

### 1.2.1 查询操作

```XML
<select id="findAll" resultType="com.zqc.domain.User">
  select * from user
</select>
```

### 1.2.2 插入操作

```XML
<insert id="save" parameterType="com.zqc.domain.User">
  insert into user values(#{id}, #{username}, #{password})
</insert>
```

执行插入语句的 java 代码：

```Java
public void test() throws IOException {
    User user = new User();
    user.setUsername("tom");
    user.setPassword("abc");

    InputStream resourceAsStream = Resources.getResourceAsStream("SqlMapConfig.xml");
    SqlSessionFactory sqlSessionFactory = new SqlSessionFactoryBuilder().build(resourceAsStream);
    SqlSession sqlSession = sqlSessionFactory.openSession();

    UserMapper mapper = sqlSession.getMapper(UserMapper.class);
    mapper.save(user);

    sqlSession.close();
}
```

1. 插入语句使用 insert 标签
2. 在映射文件中使用 parameter Type 属性指定要插入的数据类型
3. Sql 语句中使用 #{实体属性名} 方式引用实体中的属性值
4. 插入操作使用的 API 是 sql Session.insert(“[命名空间.id](http://xn--eqrzj591h57w.id)”， 实体对象) ；
5. 插入操作涉及数据库数据变化， 所以要使用 sqI Session 对象显示的提交事务
   即 sqlSession.commit()

### 1.2.3 更新操作

```XML
<update id="update" parameterType="com.zqc.domain.User">
  update user set username=#{username}, password=#{password} where id=#{id}
</update>
```

### 1.2.4 删除操作

```XML
<delete id="delete" parameterType="java.lang.Integer">
  delete from user where id=#{id}
</delete>
```

## 1.3 核心配置文件概述

核心配置文件（SqlMapConfig.xml）用于配置 MyBatis 的环境、数据源等。

核心标签包括：

- properties：引入外部属性文件。
- settings：全局设置。
- typeAliases：类型别名。
- typeHandlers：类型处理器。
- objectFactory：对象工厂。
- plugins：插件。
- environments：环境配置。
- databaseIdProvider：数据库厂商标识。
- mappers：映射器。

### 1.3.1 environments 标签

![](/image/mybatis/img2.png)

其中， 事务管理器(transactionManager) 类型有两种：

- JDBC：这个配置就是直接使用了 JDBC 的提交和回滚设置，它依赖于从数据源得到的连接来管理事务作用域。
- MANAGED：这个配置几乎没做什么。它从来不提交或回滚一个连接，而是让容器来管理事务的整个生命周期(比如 JEE 应用服务器的上下文) 。默认情况下它会关闭连接， 然而一些容器并不希望这样， 因此需要将 close Connection 属性设置为 false 来阻止它默认的关闭行为。

 数据源(dataSource) 类型有三种：

- UN POOLED：这个数据源的实现只是每次被请求时打开和关闭连接。
- POOLED：这种数据源的实现利用“池”的概念将 JDBC 连接对象组织起来。
- JNDI：这个数据源的实现是为了能在如 EJB 或应用服务器这类容器中使用， 容器可以集中或在外部配置数据源， 然后放置一个 JNDI 上下文的引用。

一般情况下为 JDBC 和 POOLED

### 1.3.2 mapper 标签

在核心配置文件中加载映射文件，也可以使用 <package name="包名"/> 自动扫描指定包下的所有映射文件

```XML
<mappers>
  <mapper resource="com/zqc/mapper/UserMapper.xml"/>
</mappers>
```

### 1.3.3 properties 标签

将数据源的信息抽取为一个 properties 文件，在核心配置文件中使用 properties 标签引入

```XML
<properties resource="jdbc.properties"/>
```

jdbc.properties 文件：

```.properties
jdbc.driver=com.mysql.jdbc.Driver
jdbc.url=jdbc:mysql://localhost:3306/test
jdbc.username=root
jdbc.password=root
```

### 1.3.4 typeAliases

为 Java 类型设置别名，简化 resultType 和 parameterType 的书写。

示例：

```XML
<typeAliases>
  <typeAlias type="com.zqc.domain.User" alias="User"/>
</typeAliases>
```

然后在映射文件中：

```XML
<select id="findAll" resultType="User">
  select * from user
</select>
```

**包别名**：

```XML
<typeAliases>
  <package name="com.zqc.domain"/>
</typeAliases>
```

## 1.4 MyBatis 相应 API

SqlSession 是 MyBatis 框架中的一个核心接口，它提供了与数据库进行交互的方法。

### 1.4.1 SqlSession 工厂构建器 SqlSessionFactoryBuilder

用于创建 SqlSessionFactory。

```Java
String resource = "org/mybatis/builder/mybatis-config.xml";
InputStream inputStream = Resources.getResourceAsStream(resource);
SqlSessionFactoryBuilder builder = new SqlSessionFactoryBuilder();
SqlSessionFactory factory = builder.build(inputStream);
```

resources 用于加载配置文件。

### 1.4.2 通过工厂对象 SqlSessionFactory 创建 SqlSession 实例

![](/image/mybatis/img3.png)

### 1.4.3 SqlSession 会话对象

SqlSession 实例在 MyBatis 中是非常强大的一个类。在这里你会看到所有执行语句、提交或回滚事务和获取映射器实例的方法（用于执行语句与数据库进行交互）
执行语句的方法主要有：

```Java
<T> T selectOne(String statement, Object parameter);
<E> List<E> selectList(String statement, Object parameter);
int insert(String statement, Object parameter);
int update(String statement, Object parameter);
int delete(String statement, Object parameter);
```

事务控制：

```Java
void commit();
void rollback();
void close();
```

**注意**：SqlSession 非线程安全，每次使用后关闭。

# 2 代理开发方式

**只要写 dao 层的接口，不需要实现类，mybatis 会去做接口的实现**

## 2.1 方式介绍

采用 Mybatis 的代理开发方式实现 DAO 层的开发，这种方式是主流的方式。
Mapper 接口开发方法只需要程序员编写 Mapper 接口(相当于 Dao 接口) ， 由 Mybatis 框架根据接口定义创建接口的动态代理对象， 代理对象的方法体同上边 Dao 接口实现类方法。
Mapper 接口开发需要遵循以下规范：

1. Mapper.xml 文件中的 namespace 与 mapper 接口的全限定名相同
2. Mapper 接口方法名和 Mapper.xml 中定义的每个 statement 的 id 相同
3. Mapper 接口方法的输入参数类型和 mapper.xml 中定义的每个 sql 的 parameter Type 的类型相同
4. Mapper 接口方法的输出参数类型和 mapper.xml 中定义的每个 sql 的 result Type 的类型相同

流程：

1. 映射器接口（Mapper Interface）：
   - 首先需要定义一个映射器接口，该接口包含与数据库操作相关的方法。
   - 这些方法通常使用注解（如 @Select, @Insert, @Update, @Delete）来定义 SQL 语句，或者通过 XML 配置文件来定义。
2. 映射器 XML 配置文件（可选）：
   - 除了注解方式，开发者还可以选择使用 XML 配置文件来定义 SQL 语句。
   - XML 文件通常与映射器接口同名，并放在与接口相同的包路径下（如果使用 XML 配置，需要在 MyBatis 配置文件中注册映射器 XML 文件的位置）。
3. 动态代理机制：
   - 当需要使用映射器接口时，MyBatis 会通过 SqlSession 的 getMapper 方法来获取接口的代理实现。
   - 这个代理实现会在运行时拦截接口方法的调用，并将调用转发到对应的 SQL 语句执行。
4. 使用映射器接口：
   - 一旦你有了映射器接口的代理，就可以像调用普通 Java 方法一样调用数据库操作。
   - MyBatis 会处理所有的 SQL 映射、参数设置、结果集映射等细节。

## 2.2 编写 mapper 接口

parameterType 通常是可选的，因为 MyBatis 可以从方法签名中自动推断参数类型，但是写上代码更清晰、兼容性更好。

```Java
public interface UserMapper {
  List<User> findAll() throws IOException;
  User findById(int id) throws IOException;
}
```

## 2.3 测试代理方式

```Java
InputStream resourceAsStream = Resources.getResourceAsStream("SqlMapConfig.xml");
SqlSessionFactory sqlSessionFactory = new SqlSessionFactoryBuilder().build(resourceAsStream);
SqlSession sqlSession = sqlSessionFactory.openSession();
UserMapper mapper = sqlSession.getMapper(UserMapper.class);
List<User> all = mapper.findAll();
User user = mapper.findById(1);
System.out.println(user);
sqlSession.close();
```

## 2.4 简单代码

dao 层：UserMapper 接口。

UserMapper.xml（映射文件）：

```XML
<mapper namespace="com.zqc.mapper.UserMapper">
  <select id="findAll" resultType="com.zqc.domain.User">
    select * from user
  </select>
  <select id="findById" parameterType="int" resultType="com.zqc.domain.User">
    select * from user where id=#{id}
  </select>
</mapper>
```

service 层：调用 mapper。

# 3 MyBatis 映射文件深入

## 3.1 动态 SQL

My bat is 的映射文件中， 前面我们的 SQL 都是比较简单的， 有些时候业务逻辑复杂时， 我们的 SQL 是动态变化的，此时在前面的学习中我们的 SQL 就不能满足要求了。

在 MyBatis 中，<where> 标签是一个动态 SQL 辅助标签，用于简化**WHERE 条件**的拼接逻辑，尤其在处理**多个可选条件**时非常实用。它的主要作用是智能处理 WHERE 子句中的**AND/OR 连接符**和**空条件**，避免 SQL 语法错误。

### **核心功能**

1. **自动处理 WHERE 关键字**：当<where> 标签内至少有一个条件成立时，会自动添加 WHERE 关键字。
2. **移除多余的 AND/OR**：如果第一个条件包含 AND 或 OR，会自动剔除。
3. **空条件处理**：如果<where> 标签内没有任何条件成立，不会生成 WHERE 子句，避免 WHERE 1=1 这种冗余写法。

## 3.2 <if> 语句

```XML
<select id="findByCondition" parameterType="user" resultType="user">
  select * from user
  <where>
    <if test="id!=0">
      and id=#{id}
    </if>
    <if test="username!=null">
      and username=#{username}
    </if>
    <if test="password!=null">
      and password=#{password}
    </if>
  </where>
</select>
```

如果所有 if 不满足，SQL 为 select * from user。

一般 mapper 方法的参数为一个实体类，然后再用 if 去判断属性值如果不为空就加入这个属性语句

## 3.3 <foreach> 语句

用于处理动态 SQL 中需要迭代集合参数的场景。它允许你遍历一个集合（如 List、Array、Set 等），并为集合中的每个元素生成相应的 SQL 片段，常见于 IN 条件、**批量插入**等操作

collection：必填，指定要迭代的集合参数名

open：字符串起始，#{id} 的左边

close：字符串结尾，#{id} 的右边

item：动态获取的值（每一个循环的对象）

separator：分隔符

```XML
<insert id="insertBatch">
    insert into dish_flavor (dish_id, name, value) VALUES
    <foreach collection="list" item="df" separator=",">
        (#{df.dishId},#{df.name},#{df.value})
    </foreach>
</insert>
```

实际是

insert into dish_flavor (dish_id, name, value) VALUES (0，"甜味"，"["无糖","少糖"]"), (1，"辣度"，"["不辣","微辣"]")

## 3.4 SQL 片段抽取

抽取重复 SQL。

示例：

```SQL
<sql id="selectUser">select * from user</sql>
<select id="findAll" resultType="user">
  <include refid="selectUser"></include>
</select>
```

# 4 MyBatis 核心文件深入

## 4.1 typeHandles 标签

用于自定义类型处理器（TypeHandler），处理 Java 类型与 JDBC 类型的转换。

MyBatis 内置处理器：

BooleanTypeHandler：Java Boolean <-> JDBC BOOLEAN

ByteTypeHandler：Java Byte <-> JDBC NUMERIC 等 SHORT INTEGER

...（更多内置）

自定义示例：处理特殊类型，如 JSON 到对象。

## 4.2 plugins 标签

MyBatis 可以使用第三方的插件来对功能进行扩展，分页助手 PageHelper 是将分页的复杂操作进行封装，使用简单的方式即可获得分页的相关数据
开发步骤：

1. 导入通用 Page Helper 的坐标
2. 在 mybatis 核心配置文件中配置 PageHelper 插件
3. 测试分页数据获取

# 5 多表操作

## 5.1 xml 文件开发

为查询出的结果进行自定义的映射，封装到相应对象中

**一对一：**

```XML
<resultMap id="orderMap" type="order">
  <id column="oid" property="id"/>
  <result column="ordertime" property="ordertime"/>
  <result column="total" property="total"/>
  <association property="user" javaType="user">
    <id column="uid" property="id"/>
    <result column="username" property="username"/>
    <result column="password" property="password"/>
  </association>
</resultMap>
```

order 实体中还存在 user 类，需要再用 association 封装 user 的属性

**一对多：** user 中有 List（order）属性

```XML
<resultMap id="userMap" type="user">
  <id column="uid" property="id"/>
  <result column="username" property="username"/>
  <result column="password" property="password"/>
  <collection property="orderList" ofType="order">
    <id column="oid" property="id"/>
    <result column="ordertime" property="ordertime"/>
    <result column="total" property="total"/>
  </collection>
</resultMap>
```

**多对多：** 查找时多一张中间表，配置同一对多

## 5.2 注解开发

### 5.2.1 常用注解（简单的 sql 语句可以直接使用注解）

简单 SQL 可直接用注解：

- @Insert：插入。
- @Update：更新。
- @Delete：删除。
- @Select：查询。
- @Result：结果映射。
- @Results：结果集映射。
- @One：一对一。
- @Many：一对多。
