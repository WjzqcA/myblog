---
title: swin-transformer
date: 2024-02-10 11:48:49
excerpt: Swin Transformer 是一种优化的vit模型，提出了窗口多头自注意力（W-MSA）和滑动窗口自注意力（SW-MSA）。它将图像分块处理，通过Patch Merging逐步下采样，生成多尺度特征，适合目标检测和分割等任务。W-MSA在窗口内计算注意力以降低计算量，SW-MSA通过窗口偏移实现跨窗口信息交互，结合相对位置偏置进一步提升性能。
tags:
  - Transformer
  - 大模型
categories:
  深度学习 
---

# Swin Transformer 模型详解

## 一、网络整体框架

Swin Transformer文章中给出的图1，左边是Swin Transformer，右边是Vision Transformer。通过对比至少可以看出两点不同：

1. Swin Transformer使用了类似卷积神经网络中的层次化构建方法（Hierarchical feature maps），比如特征图尺寸中有对图像下采样4倍的，8倍的以及16倍的，这样的backbone有助于在此基础上构建目标检测，实例分割等任务。而在之前的Vision Transformer中是一开始就直接下采样16倍，后面的特征图也是维持这个下采样率不变。
2. 在Swin Transformer中使用了Windows Multi-Head Self-Attention(W-MSA)的概念，比如在下图的4倍下采样和8倍下采样中，将特征图划分成了多个不相交的区域（Window），并且Multi-Head Self-Attention只在每个窗口（Window）内进行。相对于Vision Transformer中直接对整个（Global）特征图进行Multi-Head Self-Attention，这样做的目的是能够减少计算量的，尤其是在浅层特征图很大的时候。这样做虽然减少了计算量但也会隔绝不同窗口之间的信息传递，所以在论文中作者又提出了 Shifted Windows Multi-Head Self-Attention(SW-MSA)的概念，通过此方法能够让信息在相邻的窗口中进行传递，后面会细讲。

![](/image/swintrans/img1.png)

基本框架流程：

![](/image/swintrans/img2.png)

- 首先将图片输入到Patch Partition模块中进行分块，即每4x4相邻的像素为一个Patch，然后在channel方向展平（flatten）。假设输入的是RGB三通道图片，那么每个patch就有4x4=16个像素，然后每个像素有R、G、B三个值所以展平后是16x3=48，所以通过Patch Partition后图像shape由 [H, W, 3]变成了 [H/4, W/4, 48]。然后在通过Linear Embeding层对每个像素的channel数据做线性变换，由48变成C，即图像shape再由 [H/4, W/4, 48]变成了 [H/4, W/4, C]。其实在源码中Patch Partition和Linear Embeding就是直接通过一个卷积层实现的，和之前Vision Transformer中讲的 Embedding层结构一模一样。
- 然后就是通过四个Stage构建不同大小的特征图，除了Stage1中先通过一个Linear Embeding层外，剩下三个stage都是先通过一个Patch Merging层进行下采样（后面会细讲）。然后都是重复堆叠Swin Transformer Block，这里的Block有两种结构，如图(b)中所示，这两种结构的不同之处仅在于一个使用了W-MSA结构，一个使用了SW-MSA结构。而且这两个结构是成对使用的，先使用一个W-MSA结构再使用一个SW-MSA结构。堆叠Swin Transformer Block的次数都是偶数（因为成对使用）。
- 最后对于分类网络，后面还会接上一个Layer Norm层、全局池化层以及全连接层得到最终输出。

## 二、Patch Merging

在每个Stage中首先要通过一个Patch Merging层进行下采样（Stage1除外）。如下图所示，假设输入Patch Merging的是一个4x4大小的单通道特征图（feature map），Patch Merging会将每个2x2的相邻像素划分为一个patch，然后将每个patch中相同位置（同一颜色）像素给拼在一起就得到了4个feature map。接着将这四个feature map在深度方向进行concat拼接，然后在通过一个LayerNorm层。最后通过一个全连接层在feature map的深度方向做线性变化，将feature map的深度由C变成C/2。通过这个简单的例子可以看出，通过Patch Merging层后，feature map的高和宽会减半，深度会翻倍。

![](/image/swintrans/img3.png)

## 三、W-MSA（窗口自注意力）

引入Windows Multi-head Self-Attention（W-MSA）模块是为了**减少计算量**。如下图所示，左侧使用的是普通的Multi-head Self-Attention（MSA）模块，对于feature map中的每个像素（或称作token，原图片的patch）在Self-Attention计算过程中需要和所有的像素去计算。但在图右侧，在使用Windows Multi-head Self-Attention（W-MSA）模块时，首先将feature map按照MxM（例子中的M=2）大小划分成一个个Windows，然后单独对每个Windows内部进行Self-Attention。

![](/image/swintrans/img4.png)

两者的计算量：

![](/image/swintrans/img5.png)

- h代表feature map的高度
- w代表feature map的宽度
- C代表feature map的深度
- M代表每个窗口（Windows）的大小

### MSA模块计算量：

对于feature map中的每个像素（或称作token，patch），都要通过Wq、Wk、Wv生成对应的query(q)，key(k)以及value(v)。这里假设q, k, v的向量长度与feature map的深度C保持一致。那么对应所有像素生成Q的过程如下式：

![](/image/swintrans/img6.png)

- A为将所有像素（token）拼接在一起得到的矩阵（一共有hw个像素，每个像素的深度为C）
- W为生成query的变换矩阵
- Q为所有像素通过W得到的query拼接后的矩阵

根据矩阵运算的计算量公式可以得到生成Q的计算量为hw*C*C，生成k和v同理都是hwC²，那么总共是3hwC²。接下来Q和K转置相乘，对应计算量为(hw)²C。

![](/image/swintrans/img7.png)

接下来忽略除以根号d以及softmax的计算量，假设得到Λ ，最后还要乘以V，对应的计算量为(hw)²C

![](/image/swintrans/img8.png)

那么对应单头的Self-Attention模块，总共需要3hwC²+2(hw)²C。在实际使用过程中，使用的是多头的Multi-head Self-Attention模块，多头注意力模块相比单头注意力模块的计算量仅多了最后一个融合矩阵Wo的计算量hwC²

![](/image/swintrans/img9.png)

所以总共加起来是：4hwC²+2(hw)²C

### W-MSA的计算量

对于W-MSA模块首先要将feature map划分到一个个窗口中，假设每个窗口的宽高都是M，那么总共会得到h/M*w/M个窗口，然后对每个窗口内使用多头注意力模块。刚刚计算高为h，宽为w，深度为C的feature map的计算量为4hwC²+2(hw)²C，这里每个窗口的高为M宽为M，带入公式得：

![](/image/swintrans/img10.png)

又因为有h/M*w/M个窗口，则：

![](/image/swintrans/img11.png)

故使用W-MSA模块的计算量为：4hwC²+2M²hwC

## 四、SW-MSA（滑动窗口多头自注意力）

采用W-MSA模块时，只会在每个窗口内进行自注意力计算，所以窗口与窗口之间是无法进行信息传递的。为了解决这个问题，作者引入了Shifted Windows Multi-Head Self-Attention（SW-MSA）模块，即进行偏移的W-MSA。如下图所示，左侧使用的是刚刚讲的W-MSA（假设是第L层），那么根据之前介绍的W-MSA和SW-MSA是成对使用的，那么第L+1层使用的就是SW-MSA（右侧图）。

根据左右两幅图对比能够发现窗口（Windows）发生了偏移（可以理解成窗口从左上角分别向右侧和下方各偏移了M/2个像素）。看下偏移后的窗口（右侧图），比如对于第一行第2列的2x4的窗口，它能够使第L层的第一排的两个窗口信息进行交流。再比如，第二行第二列的4x4的窗口，他能够使第L层的四个窗口信息进行交流，其他的同理。那么这就解决了不同窗口之间无法进行信息交流的问题。

![](/image/swintrans/img12.png)

根据上图，可以发现通过将窗口进行偏移后，由原来的4个窗口变成9个窗口了。后面又要对每个窗口内部进行MSA，这样做感觉又变麻烦了。为了解决这个麻烦，作者又提出而了Efficient batch computation for shifted configuration，一种更加高效的计算方法。下面是原论文给的示意图。

![](/image/swintrans/img13.png)

通过像素的移位产生新的特征图。图左侧是刚刚通过偏移窗口后得到的新窗口，方便理解，用右侧的图对原图做标记，0对应的窗口标记为区域A，3和6对应的窗口标记为区域B，1和2对应的窗口标记为区C。

![](/image/swintrans/img14.png)

先将区域A和C移到最下方。

![](/image/swintrans/img15.png)

再将区域A和B移至最右侧。

![](/image/swintrans/img16.png)

移动完后，4是一个单独的窗口；将5和3合并成一个窗口；7和1合并成一个窗口；8、6、2和0合并成一个窗口。这样又和原来一样是4个4x4的窗口了，所以能够保证计算量是一样的。但是位移后的特征图把本来不该相邻的信息放到了一起，就不应该直接计算自注意力（也就是说0286在原图不是相邻的，但是再新的就成为了相邻的，所以直接计算他们之间的self-attention（但是他们之间有位置信息，可不可以在平移的时候让他们的相对位置不变，然后计算全部的自注意力？））为了防止这个问题，在实际计算中使用的是masked MSA即带蒙板mask的MSA，这样就能够通过设置蒙板来隔绝不同区域的信息了。

下图是以上面的区域5和区域3为例来使用mask。

![](/image/swintrans/img17.png)

对于该窗口内的每一个像素（或称作token，patch）在进行MSA计算时，都要先生成对应的query(q)，key(k)，value(v)。假设对于上图的像素0而言，得到q0后要与每一个像素的k进行匹配（match），假设a0,0代表q0与像素0对应的k0进行匹配的结果，同理可以得到所有的aij。按照普通的MSA计算，接下来就是SoftMax操作了。但对于这里的masked MSA，像素0是属于区域5的，我们只想让它和区域5内的像素进行匹配。那么我们可以将像素0与区域3中的所有像素匹配结果都减去100（例如a02、a03、a06、a07等），由于α的值都很小，一般都是零点几的数，将其中一些数减去100后在通过SoftMax得到对应的权重都等于0了。所以对于像素0而言实际上还是只和区域5内的像素进行了MSA。那么对于其他像素也是同理。注意，在计算完后还要把数据给挪回到原来的位置上（例如上述的A，B，C区域），在进行下一个模块的处理。

## 五、Relative Position Bias

[https://blog.csdn.net/qq_37541097/article/details/121119988](https://blog.csdn.net/qq_37541097/article/details/121119988)
