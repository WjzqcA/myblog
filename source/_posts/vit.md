---
title: vit
date: 2024-02-05 18:31:12
excerpt: ViT是将Transformer架构应用于视觉任务的创新模型。它将图像分割为固定大小的Patch，将每个Patch通过线性映射转换为一维向量（token），并添加位置编码和可学习的分类token。ViT通过Transformer编码器处理token序列，捕获全局关系，最终通过MLP头输出分类结果。在大规模数据集预训练后，ViT在图像分类任务中展现出优于传统CNN的性能。
tags:
  - Transformer
  - 大模型
categories:
  深度学习 
---

# Vision Transformer (ViT) 模型详解

![](/image/vit/img1.png)

此模型是将Transformer应用到视觉分类任务上面。视觉分类没有必要总是依赖于CNN，只用Transformer也能有较好的表现，尤其是在使用大规模训练集训练的情况下，并且将在大规模数据集上预训练好的模型迁移到中等数据集或小数据集的分类任务上以后，也能取得比CNN更优的性能。模型总体包括Patch Embedding、Positional Encoding、Transformer Encoder和Classification Head构成。

对于3D数据，一个3D的patch也是一个token。

**Embedding过程**

#(批次，通道，D，W，H) -> (批次，hiden_size,D，W，H) 

#(B,M*C*,D,W,H)(B,1*28*4,8,8,8) -> (B,hiden_size,D,W,H)(B,128,8,8,8) token的数量为8*8*8(patch为1)

#1*1*1*128为一个token的嵌入维度，
#(B,M*C,D,W,H)(B,*128*4,8,8,8) -> (B,M*C,D,W,H)(B,128,8,8,8)

## 一、Patch Embeddings

对于标准的Transformer模块，要求输入的是token（向量）序列，即二维矩阵[num_token, token_dim]，如下图，token0-9对应的都是向量，以ViT-B/16为例，每个token向量长度为768。

![](/image/vit/img2.png)

首先把x[H，W，C]的图像变成一个x[N，(P²*C)]的序列。它可以看做是一系列的展平的2D块的序列，这个序列中一共有N=(H*W)/P²个展平的2D块，**即Transformer的输入序列长度**(有几个patch)。每个块的维度是P²*C（每个patch输入到Transformer的维度）。其中P是块大小,C是通道数，然后将每个patch进行展平，相应的数据维度就可以写为 (N,P²*C)。之后要将x[N,(P²*C)]使用线性变换转换为（N,D），称为图像块嵌入（Patch Embeddings），类似于NLP中的词嵌入Word Embeddings，降维后的维度为D。 

对于图像数据而言，其数据格式为[H, W, C]是三维矩阵明显不是Transformer想要的。所以需要先通过一个Embedding层来对数据做个变换。首先将一张图片按给定大小分成一堆Patches。以ViT-B/16为例，将输入图片(224x224)按照16x16大小的Patch进行划分，划分后会得到( 224 / 16 ) ²= 196 个Patches，得到（14，14，768），**14*14个patch，第三维代表输入的张量为768维**。接着通过线性映射将每个Patch映射到一维向量中，以ViT-B/16为例，**每个Patch**通过映射得到一个长度为768的向量（后面都直接称为token）。每个patch的维度[16, 16, 3] -> [768]，整体维度[W,H,C]→[N,(P²*C)]。然后再用线性变换将维度变为transformer要用的输入维度。

代码中，直接通过一个卷积层来实现。以ViT-B/16为例，直接使用一个卷积核大小为16x16，步距为16，卷积核个数为768的卷积来实现。通过卷积[224, 224, 3] -> [14, 14, 768]，然后把H以及W两个维度展平即可[14, 14, 768] -> [196, 768]，此时正好变成了一个二维矩阵，正是Transformer想要的。

在输入Transformer Encoder之前注意需要加上[class]token以及Position Embedding。在原论文中，作者说参考BERT，在刚刚得到的一堆tokens中插入一个专门用于分类的[class]token，这个[class]token是一个可训练的参数，数据格式和其他token一样都是一个向量，以ViT-B/16为例，就是一个长度为768的向量，与之前从图片中生成的tokens拼接在一起，Cat([1, 768], [196, 768]) -> [197, 768]。

![](/image/vit/img3.png)

上式中的E即为块嵌入的全连接层，其输入大小为 P²*C(一维)，输出大小为D(也是一维)。

- 上式中给长度为 N的向量还追加了一个分类向量，用于Transformer训练过程中的类别信息学习。

![](/image/vit/img4.png)

第零个位置是位置编码加上一个cls（*是生成的class的token embeding），其他位置是通过patch映射得到的。

- 假设将图像分为 9个patch，即 N=9，输入到Transformer编码器中就有9个向量，但对于这9个向量而言，该取哪一个向量做分类预测呢？取哪一个都不合适。
- 一个合理的做法就是人为添加一个类别向量，该向量是可学习的嵌入向量，与其他9个patch嵌入向量一起输入到Transformer编码器中，最后取第一个向量作为类别预测结果。
- 所以，这个追加的向量可以理解为其他9个图像patch寻找的类别信息。

## 二、Positional Encoding

为了保持输入图像patch之间的空间位置信息，还需要对图像块嵌入中添加一个位置编码向量，如上式中的Epos所示。ViT的位置编码没有使用更新的2D位置嵌入方法，而是直接用的一维可学习的位置嵌入变量，原因是论文作者发现实际使用时2D并没有展现出比1D更好的效果。

![](/image/vit/img5.png)

## 三、Transformer Encoder

和Transformer中的Encoder一致

## 四、MLP head(全连接头)

上面通过Transformer Encoder后输出的shape和输入的shape是保持不变的，以ViT-B/16为例，输入的是[197, 768]输出的还是[197, 768]。注意，在Transformer Encoder后其实还有一个Layer Norm没有画出来。这里我们只需要分类的信息，所以我们只需要提取出[class]token生成的对应结果就行，即[197, 768]中抽取出[class]token对应的[1, 768]。接着我们通过MLP Head得到我们最终的分类结果。MLP Head原论文中说在训练ImageNet21K时是由Linear+tanh激活函数+Linear组成。

![](/image/vit/img6.png)

![](/image/vit/img7.png)
