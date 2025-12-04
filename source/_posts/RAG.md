---
title: RAG
date: 2025-06-15 21:53:53
excerpt: RAG（检索增强生成）是一种结合信息检索与文本生成的 AI 技术，通过从外部知识库检索相关信息并注入到大语言模型（LLM）的提示中，生成更准确、上下文相关的回答。RAG 解决了 LLM 知识局限、幻觉问题和数据安全性等挑战，适用于需要实时数据或私有数据的场景，如智能问答和语义搜索。
tags:
  - 大模型应用
categories:
  技术
---

# RAG

RAG（Retrieval-Augmented Generation，检索增强生成）是一种将信息检索与文本生成相结合的 AI 技术。例如，我们向 LLM 提问一个问题，RAG 从各种数据源检索相关的信息，并将检索到的信息和问题注入到 LLM 提示中，LLM 最后给出答案。

## 1 为什么要提出？

- **知识的局限性**  

  模型自身的知识完全源于它的训练数据，而现有的主流大模型的训练集基本都是源于网络公开的数据，对于一些实时性的、非公开的或离线的数据是无法获取到的，这部分知识也就无从具备。  

- **幻觉问题**  

  所有 AI 模型的核心基于数学概率，输出本质是一系列数值运算，大模型也不例外。因此，在知识欠缺或不擅长的领域，大模型可能一本正经地输出错误信息。这种“幻觉”问题难以辨别，因为它要求使用者具备相关领域知识。  

- **数据安全性**  

  对企业而言，数据安全至关重要，没有企业愿意冒数据泄露风险将私域数据上传至第三方平台进行训练。因此，完全依赖通用大模型的应用方案往往需在数据安全与效果之间权衡。

## 2 工作原理（流程）

RAG 的核心思想是在 LLM 回答用户问题之前，先进行一次信息检索。这个过程通常分为以下几个主要步骤：

1. 用户查询
2. 将问题 embedding
3. 在知识库中检索（和向量数据库中的数据进行相似度计算）
4. 使用检索的结果增强提示词
5. 生成最终的回答

![](/image/Langchain/img1.png)

## 3 搭建步骤

```python
# 收集数据
from langchain_community.document_loaders import TextLoader
loader = TextLoader("./政策文件.txt", encoding='utf-8')
documents = loader.load()
```

```python
# 数据分块
from langchain_community.document_loaders import TextLoader
from langchain.text_splitter import RecursiveCharacterTextSplitter
# 中文分块
text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=50,  # 每一个文本块最大100
    chunk_overlap=0,  # 避免上下缺失
    separators=["\n\n", '\n', "。", "！", "？"]  # 按中文标点分割
)
splits = text_splitter.split_documents(documents)
```

```python
# 选择文本嵌入模型
from langchain_huggingface import HuggingFaceEmbeddings
# 加载本地模型
embeddings = HuggingFaceEmbeddings(
    model_name="./bge-small-zh-v1.5",
    model_kwargs={"device": "cuda"},  # 无GPU时使用cpu
    encode_kwargs={"normalize_embeddings": False}  # 提升相似度计算精度
)
```

```python
# 初始化向量数据库
# 数据持久化
from langchain_community.vectorstores import Chroma
# 持久化到本地
db = Chroma.from_documents(
    documents=splits,
    embedding=embeddings,
    persist_directory="./chroma_db"
)
# 语义搜索示例
docs = db.similarity_search("年假有效期", k=1)
# k表示返回最相关的k个结果
print("最相关结果：")
for doc in docs:
    print(doc.page_content)
```

到这一步为止，已经实现了从知识库中查找最相近的结果。但是这个结果是原文的内容并没有更进一步的解析。这就需要使用 RAG，将知识库的内容来增强用户的输入，产生更加合理的输出。这里使用了 RetrievalQA 来链式构建 RAG，可以实现将后面传入的问题与知识库检索后再传递给大模型，然后获得答案

```python
# 结合 LLM 模型使用
from langchain.chains.retrieval_qa.base import RetrievalQA
from langchain_ollama.llms import OllamaLLM
# 加载本地大模型
model = OllamaLLM(model="deepseek-r1:7b")

# 创建一个 RAG 链 用户输入再后面传递键值对
qa_chain = RetrievalQA.from_chain_type(
    llm=llm,  # 传入大语言模型实例
    # RAG 的核心检索组件
    # db 是一个已加载文档的向量数据库
    # search_kwargs={"k": 1} 是检索参数，k=1 表示只返回与最相关的1条文档
    retriever=db.as_retriever(search_kwargs={"k": 1}),
    return_source_documents=True  # 返回答案对应的原始参考文档
)
# 步骤 2：执行查询 & 输出结果
# 定义查询问题
query = "年假有效期"

# 调用问答链获取结果
result = qa_chain({"query": query})

# 打印核心答案
print("答案：", result['result'])
print("答案：", result['source_documents'][0].page_content)
```
