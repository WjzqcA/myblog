---
title: YOLOv2
date: 2023-12-29 14:59:28
excerpt: YOLOv2 相较 YOLOv1 提升了检测精度与鲁棒性，引入 anchor 机制、K-Means 聚类生成先验框、Darknet-19 网络及高分辨率预训练。移除全连接层，采用 BN+ReLU、多尺度训练，输入灵活（416x416），特征图升级至 13x13，融合高低维特征，优化小物体检测，兼顾速度与准确性。
tags:
  - YOLO
  - 目标检测
categories:
  深度学习 
---

# YOLOv2 

## 一、使用BN层

与 YOLOv1 相比，YOLOv2 去掉了全连接层（fc）和 dropout 层，直接使用 BN（Batch Normalization）+ ReLU 激活函数。去除全连接层减少了参数量，提升了性能。通常 dropout 和 BN 二选一，若 dropout 在 BN 之前，会导致方差偏移。

## 二、高分辨率分类器

大多数检测模型在 ImageNet 上进行预训练，通常使用 224x224 分辨率的图像，适合分类但对检测任务分辨率偏低。YOLOv1 在分类预训练后直接将分辨率切换到 448x448 进行微调，模型需额外时间适应高分辨率输入。

YOLOv2 改进了这一流程，在 224x224 图像完成分类预训练后，进一步以 448x448 图像对分类模型进行 10 个 epochs 的微调，使模型适应高分辨率输入。这使得在检测数据集微调时性能更优，mAP 提升约 4%。

## 三、预测边框引入 anchor 机制

YOLOv2 引入了 anchor（先验框）机制，通过预测相对于预设 anchor 的偏移量来训练模型。**Anchor 在预设后保持不变，通过 anchor 与 GT 的 IoU 判断正负样本**。相较于 YOLOv1 直接将 GT 作为正样本、每个 grid cell 仅预测一个目标框，YOLOv2 预设 5 个 anchor，预测相对于 anchor 的平移和缩放量，通过 IoU 区分正负样本，提升了泛化能力，解决了单一 grid cell 难以预测多个目标的问题。

![](/image/YOLOv2/img1.png)

YOLOv2 移除全连接层，**采用卷积和 anchor 预测 bbox**。输入图像为 416x416，经过 32 倍下采样，生成 13x13 的特征图（相比 YOLOv1 的 7x7 网格）。每个网格预设 5 个 anchor，预测 5 个 bbox。YOLOv1 每个网格预测 2 个 bbox 和共享的类别概率，而 YOLOv2 每个 anchor 单独预测类别，输出维度从 7x7x30 变为 13x13x125（(4+1)+20）x5。

![](/image/YOLOv2/img2.png)

**处理 GT**：GT 转换为同维度张量，边界框中心坐标映射到 13x13 网格（同 YOLOv1）。xy 为相对于 grid cell 左上角的偏移量，wh 为相对于 anchor 的缩放量。为约束 bbox 中心点在当前网格内，偏移量通过 sigmoid 函数处理，确保值在 (0,1) 范围内。

![](/image/YOLOv2/img3.png)

![](/image/YOLOv2/img4.png)

## 四、采用 K-Means 聚类得到先验框

Anchor 是预设的边界框，尺寸和长宽比需适配不同物体。手动设置 anchor 引入主观性，YOLOv2 使用 **K-Means 聚类**在训练集 GT box 上分析，基于 **预测框与聚类中心的 IoU** 作为距离指标，聚类得到 5 个 anchor 的宽高维度，确保更高的 IoU 和适应性。

## 五、采用 Darknet-19 新卷积网络

YOLOv2 使用新的骨干网络 Darknet-19 进行特征提取，包含 19 个卷积层和 5 个 maxpooling 层，提升了特征提取能力。

## 六、预测坐标改为偏移缩放

**从直接预测 xy 相对坐标改为预测相对于预设 anchor 的偏移和缩放量**，每个 grid cell 基于 5 个 anchor 生成 5 个预测框。

![](/image/YOLOv2/img5.png)

## 七、高低维特征融合

YOLOv2 输入 416x416 图像，经 5 次下采样得到 13x13x1024 特征图，适合大物体检测，但对小物体不友好。为此，YOLOv2 通过 passthrough 层融合高分辨率特征图（26x26x512）与低分辨率特征图（13x13x1024）。在 passthrough 层前，使用 64 个 1x1 卷积降维至 26x26x64。

![](/image/YOLOv2/img6.png)

Passthrough 层将特征图拆分为 4 个尺寸减半、通道不变的子特征图，再叠加为尺寸减半、通道 4 倍的特征图，与 13x13x1024 特征图融合，提升小物体检测能力。

![](/image/YOLOv2/img7.png)

## 八、多尺度训练

YOLOv2 仅包含卷积层和池化层，输入尺寸不限于 416x416。为增强鲁棒性，YOLOv2 采用多尺度训练策略，每隔一定 iterations 调整输入图像尺寸（需为 32 的倍数，因下采样 32 倍），提升模型对不同尺寸图像的适应性。

![](/image/YOLOv2/img8.png)
