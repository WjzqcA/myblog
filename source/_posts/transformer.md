---
title: transformer
date: 2024-01-28 14:52:23
excerpt: Transformer 是一种革命性的深度学习模型，2017年论文《Attention is All You Need》中提出。它通过自注意力机制并行处理序列，取代传统循环神经网络。利用查询、键、值向量捕捉 token 间关系，Transformer 在翻译、文本生成及视觉中表现出色。
tags:
  - Transformer
  - 大模型
categories:
  深度学习 
---

# Transformer 模型详解

## 一、Self-attention

![](/image/transformer/img1.png)

（每一个token生成的q(k、v)的参数是相同的，wq矩阵每一行都是相同的）对于每个输入的数据，将他们乘以矩阵三个不同的矩阵得到三个新的向量q、k、v。每个不同输入的q矩阵都是由输入向量乘以同一矩阵得来的（kv同理）。那么对于所有的输入来说，可以表示成矩阵相乘的形式。

![](/image/transformer/img2.png)

接下来计算每一个q和不同v的点乘，来获得不同输入之间的相似度。如图a11为本身的差异（比如多义词），其他为不同输入与a1的差异。

![](/image/transformer/img3.png)

因为要计算每一个a之间的相似度，所以可以写成矩阵的形式。之后再对每一列的得分进行softmax来进行分类。

![](/image/transformer/img4.png)

得到每个输入softmax处理的分数后，再将分数与v向量进行点乘得到四个向量，再将他们累加起来即得到最后的特征。

![](/image/transformer/img5.png)

整个流程只有wq、wv、wa是通过网络训练得到的。

## 二、Multi-head Self-attention

多头自注意力，理解为不只有一种相关关系，表现为多个头，即将原来的qkv矩阵平分维度（如果有三个head，那么平分成3份分给每一个head）分配给各个head（可以通过乘以矩阵得到），其他的流程与原来的一样。

![](/image/transformer/img6.png)

得到每个head的bi之后，将他们进行拼接再乘以矩阵得到特征

![](/image/transformer/img7.png)

## 三、Positional Encoding

![](/image/transformer/img8.png)

## 四、Transformer

![](/image/transformer/img9.png)

### 4.1 整体架构

![](/image/transformer/img10.png)

**Transformer 由 Encoder 和 Decoder 两个部分组成**，Encoder 和 Decoder 都包含 6 个 block（N=6时）。Transformer 的工作流程大体如下：

**第一步：**获取输入句子的每一个单词的表示向量 **X**，**X**由单词的 Embedding（Embedding就是从原始数据提取出来的Feature） 和单词位置的 Embedding 相加得到。

![](/image/transformer/img11.png)

**第二步**：将得到的单词表示向量矩阵 (如上图所示，每一行是一个单词的表示 x) 传入 Encoder 中，经过 6 个 Encoder block 后可以得到句子所有单词的编码信息矩阵 C，如下图。单词向量矩阵用Xnd表示， n 是句子中单词个数，d 是表示向量的维度 (论文中 d=512)。每一个 Encoder block 输出的矩阵维度与输入完全一致。

![](/image/transformer/img12.png)

**第三步**：(训练过程)将 Encoder 输出的编码信息矩阵 **C**传递到 Decoder 中，Decoder 依次会根据当前翻译过的单词 1~ i 翻译下一个单词 i+1，如下图所示。在使用的过程中，翻译到单词 i+1 的时候需要通过 **Mask (掩盖)** 操作遮盖住 i+1 之后的单词。

![](/image/transformer/img13.png)

上图 Decoder 接收了 Encoder 的编码矩阵 **C**，然后首先输入一个翻译开始符 "<Begin>"，预测第一个单词 "I"；然后输入翻译开始符 "<Begin>" 和单词 "I"，预测单词 "have"，以此类推。这是 Transformer 使用时候的大致流程，接下来是里面各个部分的细节

### 4.2 Transformer的输入

Transformer 中单词的输入表示 **x**由**单词 Embedding** 和**位置 Embedding** （Positional Encoding）相加得到。单词的 Embedding 有很多种方式可以获取，例如可以采用 Word2Vec、Glove 等算法预训练得到，也可以在 Transformer 中训练得到。

Transformer 中除了单词的 Embedding，还需要使用**位置 Embedding **表示单词出现在句子中的位置。**因为 Transformer 不采用 RNN 的结构，而是使用全局信息，不能利用单词的顺序信息，而这部分信息对于 NLP 来说非常重要。**所以 Transformer 中使用位置 Embedding 保存单词在序列中的相对或绝对位置。

位置 Embedding 用 **PE**表示，**PE** 的维度与单词 Embedding 是一样的。PE 可以通过训练得到，也可以使用某种公式计算得到。在 Transformer 中采用了后者，计算公式如下：

![](/image/transformer/img14.png)

其中，pos 是词在词表中出现的位置序号，d 表示 PE的维度 (与词 Embedding 一样)，i 是维度序号。2i 和 2i+1 是交替出现的，所以图1中的结果不应该是“左边的是 sin 函数的结果，右边是 cos 函数的结果”，而是两者是交替出现的才对，类似下图2所示使用这种公式计算 PE 有以下的好处：

- 使 PE 能够适应比训练集里面所有句子更长的句子，假设训练集里面最长的句子是有 20 个单词，突然来了一个长度为 21 的句子，则使用公式计算的方法可以计算出第 21 位的 Embedding。
- 可以让模型容易地计算出相对位置，对于固定长度的间距 k，**PE(pos+k)** 可以用 **PE(pos)** 计算得到。因为 Sin(A+B) = Sin(A)Cos(B) + Cos(A)Sin(B), Cos(A+B) = Cos(A)Cos(B) - Sin(A)Sin(B)。

d个位置（i的值）的PE值构成了最终的PE。

## 五、自注意力机制

![](/image/transformer/img15.png)

左侧为 Encoder block，右侧为 Decoder block。红色圈中的部分为 **Multi-Head Attention**，是由多个 **Self-Attention**组成的，Encoder block 包含一个 Multi-Head Attention，而 Decoder block 包含两个 Multi-Head Attention (其中有一个用到 Masked)。Multi-Head Attention 上方还包括一个 Add & Norm 层，Add 表示残差连接 (Residual Connection) 用于防止网络退化，Norm 表示 Layer Normalization，用于对每一层的激活值进行归一化。

## 六、Encoder结构

![](/image/transformer/img16.png)

一个block由Multi-Head Attention、Add&Norm和Feed Forward组成，Encoder总共有6个block堆叠而成。Feed Forward 是一个两层的全连接层，第一层的激活函数为 Relu，第二层不使用激活函数。

![](/image/transformer/img17.png)

Encoder block 接收输入矩阵X(n*d) ，并输出一个矩阵O(n*d) 。通过多个 Encoder block 叠加就可以组成 Encoder。第一个 Encoder block 的输入为句子单词的表示向量矩阵，后续 Encoder block 的输入是前一个 Encoder block 的输出，最后一个 Encoder block 输出的矩阵就是**编码信息矩阵 C**，这一矩阵后续会用到 Decoder 中。

## 七、Decoder结构

![](/image/transformer/img18.png)

上图红色部分为 Transformer 的 Decoder block 结构，与 Encoder block 相似，但是存在一些区别：

- 包含两个 Multi-Head Attention 层。
- 第一个 Multi-Head Attention 层采用了 Masked 操作。
- 第二个 Multi-Head Attention 层的**K, V**矩阵使用 Encoder 的**编码信息矩阵C**进行计算，而**Q**使用上一个 Decoder block 的输出计算。
- 最后有一个 Softmax 层计算下一个翻译单词的概率。

### 7.1 Masked Multi-Head Attention

Decoder block 的第一个 Multi-Head Attention 采用了 Masked 操作，因为在翻译的过程中是顺序翻译的，即翻译完第 i 个单词，才可以翻译第 i+1 个单词。通过 Masked 操作可以防止第 i 个单词知道 i+1 个单词之后的信息。下面以 "我有一只猫" 翻译成 "I have a cat" 为例，了解一下 Masked 操作。

在 Decoder 的时候，是需要根据之前的翻译，求解当前最有可能的翻译，如下图所示。首先根据输入 "<Begin>" 预测出第一个单词为 "I"，然后根据输入 "<Begin> I" 预测下一个单词 "have"。

![](/image/transformer/img19.png)

Decoder 可以在训练的过程中使用 Teacher Forcing （就是将真实标签作为模型输入，在测试阶段没法使用）并且并行化训练，即将正确的单词序列 (<Begin> I have a cat) 和对应输出 (I have a cat <end>) 传递到 Decoder。那么在预测第 i 个输出时，就要将第 i+1 之后的单词掩盖住，**注意 Mask 操作是在 Self-Attention 的 Softmax 之前使用的，下面用 0 1 2 3 4 5 分别表示 "<Begin> I have a cat <end>"。**

**第一步：**是** Decoder 的输入矩阵和** **Mask** 矩阵，输入矩阵包含 "<Begin> I have a cat" (0, 1, 2, 3, 4) 五个单词的表示向量，**Mask** 是一个 5×5 的矩阵。在 **Mask** 可以发现单词 0 只能使用单词 0 的信息，而单词 1 可以使用单词 0, 1 的信息，即只能使用之前的信息。（mask矩阵不是与输入矩阵相乘，而是与QKT进行相乘的）

![](/image/transformer/img20.png)

第二步：接下来的操作和之前的 Self-Attention 一样，通过输入矩阵X计算得到Q K V矩阵。然后计算Q和K的乘积QKT 。

![](/image/transformer/img21.png)

第三步：在得到QKT之后需要进行 Softmax，计算 attention score，我们在 Softmax 之前需要使用Mask矩阵遮挡住每一个单词之后的信息，遮挡操作如下：

QKT的每一个元素表示的是第i和j个单词的相关性，所以按位与mask矩阵相乘后，第一行只会保留第一个和第一个的相关性，第二行会保留第二个单词之前的相关性，以此类推。

![](/image/transformer/img22.png)

得到 MaskQKT 之后在 MaskQKT上进行 Softmax，每一行的和都为 1。但是单词 0 在单词 1, 2, 3, 4 上的 attention score 都为 0。

第五步：通过上述步骤就可以得到一个 Mask Self-Attention 的输出矩阵Zi ，然后和 Encoder 类似，通过 Multi-Head Attention 拼接多个输出Zi然后计算得到第一个 Multi-Head Attention 的输出Z，Z与输入X维度一样。

### 7.2 Multi-Head Attention

Decoder block 第二个 Multi-Head Attention 变化不大， 主要的区别在于其中 Self-Attention 的 **K, V**矩阵不是使用 上一个 Decoder block 的输出计算的，而是使用 **Encoder 的编码信息矩阵 C** 计算的。

根据 Encoder 的输出 **C**计算得到 **K, V**，根据上一个 Decoder block 的输出 **Z** 计算 **Q** (如果是第一个 Decoder block 则使用输入矩阵 **X** 进行计算)，后续的计算方法与之前描述的一致。

这样做的好处是在 Decoder 的时候，每一位单词都可以利用到 Encoder 所有单词的信息 (这些信息无需 **Mask**)。

### 7.3 Softmax 预测输出单词

Decoder block 最后的部分是利用 Softmax 预测下一个单词，在之前的网络层我们可以得到一个最终的输出 Z，因为 Mask 的存在，使得单词 0 的输出 Z0 只包含单词 0 的信息，如下：

![](/image/transformer/img23.png)

Softmax 根据输出矩阵的每一行预测下一个单词：

![](/image/transformer/img24.png)
