---
title: langchain
date: 2025-06-10 14:46:40
excerpt: LangChain旨在帮助开发者利用大型语言模型（LLMs）和聊天模型构建强大的端到端应用程序。它通过提供工具、组件和接口，简化了与外部数据连接、上下文记忆、工具调用和复杂任务拆解等功能，弥补了 LLM 的局限性。适用于构建智能对话系统、语义搜索和自动化任务处理等场景。
tags:
  - 开发框架
  - 大模型应用
categories:
  技术
---

# LangChain

LangChain 是一个开源框架，旨在帮助开发者利用大型语言模型（LLMs）和聊天模型构建端到端的应用程序。它提供了一系列工具、组件和接口，简化了由这些模型驱动的应用程序开发过程。核心概念包括组件（Components）、链（Chains）、模型输入输出（Model I/O）、数据连接（DataConnection）、内存（Memory）和代理（Agents）。其中，链（Chain）是 LangChain 的核心，将多个处理步骤（如输入处理、模型调用、输出解析）组合成一个工作流。

## 1. LangChain 的作用

LangChain 弥补了 LLM 的局限性，使 Agent 能够完成更复杂的任务：

1. **连接外部数据**：LLM 的知识是静态的，LangChain 允许其查询数据库、搜索网页或调用 API 获取实时信息。
2. **记忆功能**：支持短期记忆（对话上下文）或长期记忆（用户偏好），实现个性化交互。
3. **工具调用**：使 Agent 能够使用外部工具，如计算器、天气 API 或运行 Python 代码。
4. **复杂任务拆解**：将复杂需求（如“计划一次旅行”）分解为小步骤，逐步完成。

## 2. 环境配置

1. **创建虚拟环境**  
   使用 Python 的 `venv` 或 `conda` 创建虚拟环境，以隔离项目依赖。

2. **安装 LangChain 包**  
   每个大模型可能需要特定的 LangChain 集成包，但核心包 `langchain-core` 会由 `langchain` 自动安装。以下是安装示例：

   ```bash
   pip install langchain-community==0.3.27
   pip install dashscope==1.23.7
   ```

3. **注册 API Key**  
   根据所使用的大模型（如 OpenAI、DashScope 等），在对应平台注册并获取 API Key。

## 3. 使用方法

### 3.1 获取 LLM 服务

LangChain 支持通过 API 或本地模型调用 LLM。

#### 3.1.1 使用 API

不同语言模型需要对应的 LangChain 集成包，参考官方文档：[LangChain 集成提供商](https://www.langchain.com.cn/docs/integrations/providers/)。调用方式可参考：[LLM 链教程](https://www.langchain.com.cn/docs/tutorials/llm_chain/)。

#### 3.1.2 使用本地模型

使用 [Ollama](https://ollama.com/) 部署本地 LLM。下载并安装 Ollama 后，通过终端命令拉取模型：

```bash
ollama pull deepseek-r1:7b
```

在 LangChain 中与 Ollama 交互需安装 `langchain-ollama`：

```bash
pip install langchain-ollama
```

示例代码：

```python
from langchain_ollama.llms import OllamaLLM

model = OllamaLLM(model="deepseek-r1:7b")
response = model.invoke("夏天适合吃什么水果？,直接回复水果名称")
print(response)  # 输出：西瓜
```

### 3.2 提示词模板

提示词模板（Prompt Template）用于将用户输入或动态数据结构化嵌入预定义模板，生成适合模型的提示词。

```python
from langchain.prompts import PromptTemplate

# 定义模板
template = '你是一个{role},请用{style}风格回答问题:{question}'
prompt_template = PromptTemplate.from_template(template)
# 填充变量
filled_prompt = prompt_template.format(role='数学老师', style='通俗易懂', question='勾股定理是什么？')
# 调用模型
response = chat.invoke(filled_prompt)
print(response.content)
```

另一种方式是使用 `ChatPromptTemplate`：

```python
from langchain_core.prompts import ChatPromptTemplate
```

### 3.3 输出格式化

输出格式化将 LLM 的自由文本输出解析为结构化数据（如 JSON、字典）。

```python
from langchain.output_parsers import StructuredOutputParser, ResponseSchema

# 定义输出结构
response_schemas = [
    ResponseSchema(name="name", description="人的姓名", type="string"),
    ResponseSchema(name="age", description="人的年龄", type="integer")
]
output_parser = StructuredOutputParser.from_response_schemas(response_schemas)

# 定义提示词模板
template = """你是一个信息提取助手，请从以下文本中提取姓名和年龄，并以 JSON 格式返回：
文本：{input_text}
{format_instructions}"""
prompt = PromptTemplate(
    template=template,
    partial_variables={"format_instructions": output_parser.get_format_instructions()}
)

# 填充输入
input_text = "张三今年25岁，来自北京。"
filled_prompt = prompt.format(input_text=input_text)

# 调用模型并解析
response = chat.invoke(filled_prompt)
parsed_output = output_parser.parse(response.content)
print(parsed_output)  # 输出：{"name": "张三", "age": 25}
```

使用 Pydantic 模型进行格式化：

```python
from pydantic import BaseModel, Field
from langchain.output_parsers import PydanticOutputParser

# 定义 Pydantic 模型
class Person(BaseModel):
    name: str = Field(description="人的姓名")
    age: int = Field(description="人的年龄")

output_parser = PydanticOutputParser(pydantic_object=Person)
```

### 3.4 链式调用

LLMChain 将提示词模板、模型和输出解析器组合为一个可重复执行的流程。

```python
from langchain.chains import LLMChain

# 创建链
llm_chain = prompt | chat | output_parser
# 运行链
rs = llm_chain.invoke({
    'style': '通俗易懂',
    'question': '勾股定理是什么？'
})
print(rs)
```

### 3.5 流式输出

流式输出让模型边生成边显示响应，展示“思考”过程。

```python
llm_chain = prompt | chat
chunks = []

for chunk in llm_chain.stream({
    'style': '通俗易懂',
    'question': '勾股定理是什么?'
}):
    chunks.append(chunk)
    print(chunk.content, end='', flush=True)
```

### 3.6 记忆系统

记忆系统为对话提供上下文连贯性，支持短期和长期记忆。

#### 3.6.1 缓冲记忆（ConversationBufferMemory）

存储所有历史对话。

```python
from langchain.memory import ConversationBufferMemory
from langchain.chains import ConversationChain

memory = ConversationBufferMemory()
conversation = ConversationChain(llm=chat, memory=memory)
conversation.predict(input="你好我是一个程序员")
conversation.predict(input="我的职业是什么？")  # 输出：程序员
```

#### 3.6.2 窗口记忆（ConversationBufferWindowMemory）

仅存储最近 k 轮对话。

```python
from langchain.memory import ConversationBufferWindowMemory

memory = ConversationBufferWindowMemory(k=2)
conversation = ConversationChain(llm=chat, memory=memory)
conversation.predict(input="你好我是一个程序员")
print(memory.buffer)  # 查看记忆
memory.save_context({"input": "你好"}, {"output": "你也好"})
```

#### 3.6.3 Token 缓冲记忆（ConversationTokenBufferMemory）

根据 Token 数量限制存储对话。

```python
from langchain.memory import ConversationTokenBufferMemory

memory = ConversationTokenBufferMemory(llm=chat, max_token_limit=30)
conversation = ConversationChain(llm=chat, memory=memory)
```

#### 3.6.4 总结缓冲记忆（ConversationSummaryBufferMemory）

近期对话保留完整，早期对话自动总结。

### 3.7 文本嵌入模型（Embedding）

将文本转换为向量表示，用于语义搜索或相似度计算。

#### 3.7.1 使用 API 嵌入模型

```python
from langchain_community.embeddings import ZhipuAIEmbeddings

embeddings = ZhipuAIEmbeddings(model="embedding-2")
comments = ["这个产品太棒了！", "一天就坏了，辣鸡！"]
vectors = embeddings.embed_documents(comments)
print(f"向量的维度：{len(vectors[0])}")
```

#### 3.7.2 使用本地嵌入模型

```python
from langchain_huggingface import HuggingFaceEmbeddings

embeddings = HuggingFaceEmbeddings(
    model_name="./bge-small-zh-v1.5",
    model_kwargs={"device": "cpu"},
    encode_kwargs={"normalize_embeddings": True}
)
query = "如何使用C++"
vectors = embeddings.embed_query(query)
print(f"向量的维度：{len(vectors)}")
```

#### 3.7.3 数据持久化与匹配

将文本分块并存储到向量数据库，进行语义搜索。

```python
from langchain_community.document_loaders import TextLoader
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.vectorstores import Chroma

# 加载并分块
loader = TextLoader("./政策文件.txt", encoding='utf-8')
documents = loader.load()
text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=100,
    chunk_overlap=20,
    separators=["\n\n", '\n', "。", "！", "？"]
)
splits = text_splitter.split_documents(documents)

# 存储到向量数据库
db = Chroma.from_documents(
    documents=splits,
    embedding=embeddings,
    persist_directory="./chroma_db"
)

# 语义搜索
docs = db.similarity_search("几点上班", k=1)
for doc in docs:
    print(doc.page_content)
```

### 3.8 工具封装

工具封装将外部 API 或功能转换为 LangChain 工具，扩展 Agent 能力。

#### 示例：天气查询工具

1. **获取城市编码**

```python
import pandas as pd
from langchain.tools import tool

@tool
def get_city_code(city_name: str) -> int:
    """返回城市编码，格式为 int"""
    city_df = pd.read_csv('city.csv')
    try:
        match = city_df[city_df['district'] == city_name]
        if not match.empty:
            return match.iloc[0]['areacode/城市ID']
        match = city_df[city_df['city'] == city_name]
        if not match.empty:
            return match.iloc[0]['areacode/城市ID']
        match = city_df[city_df['city'].str.contains(city_name, na=False)]
        if not match.empty:
            return match.iloc[0]['areacode/城市ID']
        return 101010100  # 默认北京
    except Exception as e:
        print(f"城市编码查询错误: {e}")
        return 101010100
```

2. **创建 Agent**

```python
from langchain.agents import create_react_agent, AgentExecutor
from langchain import hub

tools = [get_city_code, get_weather]  # get_weather 为天气查询工具
prompt = hub.pull("hwchase17/react")
agent = create_react_agent(chat, tools, prompt)
agent_executor = AgentExecutor(agent=agent, tools=tools, verbose=True)

test_inputs = [
    "请告诉我上海的天气",
    "北京今天冷吗？"
]
for user_input in test_inputs:
    response = agent_executor.invoke({"input": user_input})
    print(f"用户输入：{user_input}\nAgent回答：{response['output']}")
```

3. **多工具调用示例**

添加简单计算工具：

```python
import re
from langchain.tools import tool

@tool
def add_numbers(input_str: str) -> int:
    """将两个数字相加，输入格式为 a+b"""
    match = re.findall(r'\d+', input_str)
    if len(match) == 2:
        a, b = map(int, match)
        return a + b
    raise ValueError("输入格式错误，应为 a+b")

tools = [get_city_code, get_weather, add_numbers]
```

测试多工具调用：

```python
test_inputs = [
    "今天青岛的天气怎么样？1+2等于几",
    "1*2等于几"
]
for user_input in test_inputs:
    response = agent_executor.invoke({"input": user_input})
    print(f"用户输入：{user_input}\nAgent回答：{response['output']}")
```

**输出示例**：

```markdown
用户输入：今天青岛的天气怎么样？1+2等于几
Agent回答：青岛今天的天气是多云，温度为27.3℃。1加2等于3。

用户输入：1*2等于几
Agent回答：1*2等于2
```
