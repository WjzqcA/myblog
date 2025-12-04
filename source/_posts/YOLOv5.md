---
title: YOLOv5
date: 2024-01-20 13:01:49
excerpt: YOLOv5 在 YOLOv4 的基础上进行了多项改进，包括更高效的 SPPF 结构、多尺度特征融合的 CSP-PAN、改进的边框偏移量计算，以及更灵活的正样本匹配策略。通过 MixUp、Mosaic、Cutout 等丰富的数据增强方法和基于 CIoU 的损失函数，YOLOv5 提高了小目标检测能力和训练稳定性，同时保持了轻量化和高精度。
tags:
  - YOLO
  - 目标检测
categories:
  深度学习 
---

# YOLOv5

![](/image/YOLOv5/img1.png)

[https://blog.csdn.net/weixin_43334693/article/details/129312409](https://blog.csdn.net/weixin_43334693/article/details/129312409)（整体流程细节）

## 一、数据增强

YOLO v5 中对输入图像进行了 MixUp、Mosaic、copy paste、随机水平翻转、HSV随机增强、Random affine、Cutout 等多种图像增强。

## 二、SPPF

YOLO v5 SPP换成了SPPF、，两者的作用是一样的，但后者效率更高。spp结构如下图所示，是将输入并行通过多个不同大小的Maxpool，然后做进一步融合，能在一定程度上解决目标多尺度问题。

![](/image/YOLOv5/img2.png)

SPPF 则是将输入的特征图串行通过多个5*5大小的maxpooling层，这里需要注意的是串行通过2个5*5大小的 maxpooling 层和1个 9*9 大小的 maxpooling层的计算结果是一样的。但是SPPF比SPP的计算速度快了2倍还多。它是通过串行进行下采样，所以卷积核的尺寸要比SPF的要小。

![](/image/YOLOv5/img3.png)

## 三、CSP-PAN

在 YOLO v4 中只有骨干网络中使用了 CSP 结构，而 YOLO v5 在 PAN 结构中也加入了 CSP，加强了网络特征融合的能力，做到了轻量化的同时保证准确性，降低计算瓶颈，降低内存成本。

## 四、改进边框偏移量计算

yolov5中采用了v4中对偏移量xy的改进，同时对wh也做了进一步优化。

![](/image/YOLOv5/img4.png)

调整为

![](/image/YOLOv5/img5.png)

因为tx和th是不受限制的，对于指数来说 这样可能出现梯度爆炸，训练不稳定等问题。

![](/image/YOLOv5/img6.png)

## 五、匹配正样本

YOLOv4中是直接将每个GT box与对应的Anchor计算IoU，只要Iou大于设定的阈值就算匹配成功。在YOLOv5中，作者先去计算每个GT box与对应的anchor模板的高宽比例：

![](/image/YOLOv5/img7.png)

然后统计这些比例和它们倒数之间的最大值，这里可以理解成计算GT box和anchor分别在宽度以及高度方向的最大差异（当相等的时候比例为1，差异最小）：

![](/image/YOLOv5/img8.png)

![](/image/YOLOv5/img9.png)

如果GT Box和对应的Anchor Template的rmax小于阈值anchor_t（在源码中默认设置为4.0），即GT Box和对应的Anchor Template的高、宽比例相差不算太大，则将GT Box分配给该Anchor Template模板。假设对某个GT Box而言，只要GT Box满足在某个Anchor Template宽和高× 0.25倍和×4.0倍之间就算匹配成功。

![](/image/YOLOv5/img10.png)

剩下的步骤和YOLOv4中一致：

- 将GT投影到对应预测特征层上，根据GT的中心点定位到对应Cell，注意图中有三个对应的Cell。因为网络预测中心点的偏移范围已经调整到了( − 0.5 , 1.5 ) (-0.5, 1.5)(−0.5,1.5)，所以按理说只要Grid Cell左上角点距离GT中心点在( − 0.5 , 1.5 ) (−0.5,1.5)(−0.5,1.5)范围内它们对应的Anchor都能回归到GT的位置处。这样会让正样本的数量得到大量的扩充。

- 则这三个Cell对应的AT2和AT3都为正样本。

![](/image/YOLOv5/img11.png)

## 六、损失函数

YOLOv5的损失主要由三个部分组成：

- Classes loss，分类损失，采用的是BCE loss（二值交叉熵损失），注意只计算正样本的分类损失。
- Objectness loss，obj损失，采用的依然是BCE loss，注意这里的obj指的是网络预测的目标边界框与GT Box的**CIoU**。这里计算的是所有样本的obj损失。

- Location loss，定位损失，采用的是CIoU loss，注意只计算正样本的定位损失。

![](/image/YOLOv5/img12.png)

对于不同尺度特征图的损失：针对预测小目标的预测特征层采用的权重是0.4，针对预测中等目标的预测特征层采用的权重是0.1，针对预测大目标的预测特征层采用的权重是0.4，作者说这是针对coco数据集设置的超参数。

![](/image/YOLOv5/img13.png)
