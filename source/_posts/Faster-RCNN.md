---
title: Faster-RCNN
date: 2023-12-18 12:11:56
excerpt: Faster R-CNN 通过引入 RPN 优化候选框生成，实现端到端目标检测。骨干网络提取特征图，RPN 生成候选框，ROI Pooling 缩放特征后，全连接层进行分类和边界框回归，显著提升效率和精度。
tags:
  - RCNN
  - 目标检测
categories:
  深度学习 
---

# Faster R-CNN 模型详解

## 一、步骤模型

1. 将图像输入网络得到相应的特征图。
2. 使用 RPN 生成候选框，将生成的候选框投影到特征图上获得相应的特征矩阵。
3. 将每个特征矩阵通过 ROI Pooling 层缩放到 7x7 大小的特征图，接着将特征图展平通过一系列全连接层得到预测结果。

对比于 Fast R-CNN，Faster R-CNN 在边界框选取中采用了 RPN 结构。

![Faster R-CNN 流程图](/image/faster-rcnn/img1.png)

1. **Conv layers**：作为一种 CNN 网络目标检测方法，Faster RCNN 首先使用一组基础的 conv+relu+pooling 层提取 image 的 feature maps。该 feature maps 被共享用于后续 RPN 层和全连接层。
2. **Region Proposal Networks**：RPN 网络用于生成 region proposals。该层通过 softmax 判断 anchors 属于 positive 或者 negative，再利用 bounding box regression 修正 anchors 获得精确的 proposals。
3. **Roi Pooling**：该层收集输入的 feature maps 和 proposals，综合这些信息后提取 proposal feature maps，送入后续全连接层判定目标类别。
4. **Classification**：利用 proposal feature maps 计算 proposal 的类别，同时再次 bounding box regression 获得检测框最终的精确位置。

## 二、网络结构

![Faster R-CNN 网络结构图](/image/faster-rcnn/img2.png)

1. **Backbone**：共享基础卷积层，用于提取整张图片的特征。例如 VGG16，或 Resnet101，去除其中的全连接层，只留下卷基层，输出下采样后的特征图。
2. **RPN**：候选检测框生成网络（Region Proposal Networks）。
3. **Roi Pooling 与分类网络**：对候选检测框进行分类，并且再次微调候选框坐标（在 RPN 中，网络会根据先前人为设置的 anchor 框进行坐标调整，所以这里是第二次调整）。输出检测结果。

第一部分 backbone 就是普通的卷积网络，输出特征图供后续两阶段共用。第三部分中的分类网络，通过两个全连接层，再通过两个姊妹全连接层（论文中用词，指相同尺寸，不共享权值的两个全连接层），分别输出坐标微调回归信息与检测框分类信息。下面重点解释 RPN 与 RoI Pooling。

## 三、Region Proposal Networks (RPN 用于边界框回归)

通过滑动窗口与全连接层生成的 scores 和 coordinates 分别代表了基于当前感受野产生的 k 个候选框的正负样本分类及回归参数。

论文中的 RPN 示意图：

![](/image/faster-rcnn/img3.png)

在每个中心点生成的 anchor：

![](/image/faster-rcnn/img4.png)

RPN 更清晰的示意图：

![](/image/faster-rcnn/img5.png)

第一个图中的 **sliding window 就是一个 kernel size 为 3*3 的卷积层**，使用滑动窗口的方法在每个窗口的中心，生成多个不同尺寸和宽高比例的 anchor（锚框，然后还得把 anchor 映射到原图上就是对应的 proposal），这些锚框作为候选的目标区域。**对每个滑动窗口进行卷积得到特征，用于作为分类和回归任务的输入**，再通过两个姊妹 1*1 的卷积层，输出两个特征图，也就是图三中的 2k scores、4k coordinates，这两个支线没有影响。**但是分类和回归是与生成的锚点一一对应的，每个锚点都有一个与之关联的分类得分和边界框回归值。**

### 3.1 Anchor 生成、两个特征图维度与维度解释

**滑动窗口每滑动到一个位置进行卷积生成一个一维的向量（1*cnn 网络输出通道数），并在特征图上的每一个点都会生成 k 个锚点（框），计算其与 GT 之间的 IOU 损失标记为正负样本，并存储起来（当作训练样本），再分别通过两个全连接层输出 2k 维的 scores 和 4k 维的 coordinate。** 对其进行假设 anchor 框个数 k=9，RPN 的输入特征图的尺寸是 w*h*512（w, h 是特征图的宽高，假设之前的 backbone 是 VGG16，那么此特征图的通道数是 512），再经过共同的 3*3 卷积层，两个独立的 1*1 的卷积层，分别输出 w*h*18 的 scores（用于分类）与 w*h*36 的 coordinates（用于回归）。scores 通道数为 18=9（anchor 框个数）* 2（待检测物体类别，分为前景与背景）。coordinates 通道数为 36=9*4（**四个坐标 dx,dy,dw,dh 回归数值，存储的是变换值**）。通道，每一个通道的维度为 w*h。

![特征图维度示意图](/image/faster-rcnn/img6.png)

### 3.2 Scores 分支 (二分类，只用区分前景或背景)

用来判断生成的锚点是否包含物体。

在经历一个 1*1 卷积后，会对特征图（W*H*18）进行 reshape 操作。如上图，softmax 就是要将每个点的 9 个 anchor 进行二分类（positive 和 negative），如果直接将 18 个通道的像素点输入就成 18 个类别了，所以将 (n,18,37,50) 改为 (n,2,37*9,50)，然后对第二维 softmax 进行二分类。如图，这样两两一组，能把每一个特征点都分成前景与背景。在这之后，再把维度改回去。

![Scores 分支 reshape 和 softmax](/image/faster-rcnn/img7.png)

### 3.3 Anchor 回归（reg 层）

对于边界框，我们只是随机生成的（锚点），与 GT（真实目标框）会有一些差距，所以我们希望采用一种方法对生成的锚点进行微调，使得锚点和 GT 更加接近。对于窗口一般使用四维向量（x,y,w,h）表示，分别表示窗口的中心点坐标和宽高，我们的目标是寻找一种关系，使得输入原始的 anchor A 经过映射得到一个跟真实窗口 G 更接近的回归窗口 G'。

![Anchor 回归公式 1](/image/faster-rcnn/img8.png)

![Anchor 回归公式 2](/image/faster-rcnn/img9.png)

这里的 G' 指的是变换后的值，d(A) 指的是需要学习的参数，总共有四个参数（平移和缩放参数），Aw 和 Ah 指的是边界框的宽和高。对于平移，是使用宽和高乘上学习的参数在加上 x 和 y 的坐标得到新的中心点坐标。对于缩放使用了指数。

接下来的任务是通过线性回归（reg layers 的具体操作）来获得更加接近 GT 的（x,y,w,h），将特征图上的锚点区域作为输入。同时还有训练传入 A 与 GT 之间的变换量，即（tx,ty,th,tw）（旧的变化尺度），输出是 dx(A),dy(A),dw(A),dh(A) 四个变换（新的变化尺度），目标函数可表示为：

![回归目标函数](/image/faster-rcnn/img10.png)

Φ(A) 是对应 anchor 的 feature map 组成的特征向量，W 是需要学习的参数，d(A) 是得到的预测值，* 表示 x，y，w，h，也就是每一个变换对应一个目标函数。

positive anchor 与 ground truth 之间的平移量 tx，ty 与尺度因子 th，tw 计算，xa，ya，wa，ha 为存储的锚点值（锚点的坐标、长宽信息只用来求偏移和尺度，不用来当作输入，reg layers 的输入是与每个锚点相关的局部特征区域）：

![平移量和尺度因子计算](/image/faster-rcnn/img11.png)

通过梯度下降不断更新每个 Anchor 的平移量和变换尺度 (tx,ty,tw,th)，然后根据值对 anchor 进行调整。

### 3.4 Proposal Layer

Proposal Layer 负责综合所有 [dx(A),dy(A),dw(A),d(hA)] 变换量和 positive anchors，计算出精准的 proposal。Proposal Layer 有 3 个输入：positive vs negative anchors 分类器结果 rpn_cls_prob_reshape，对应的 bbox reg 的 [dx(A),dy(A),dw(A),d(hA)] 变换量 rpn_bbox_pred，以及 im_info；另外还有参数 feat_stride=16。

im_info 用来保存缩放信息，对于一副任意大小 PxQ 图像，传入 Faster RCNN 前首先 reshape 到固定的尺度 MxN，im_info=[M, N, scale_factor] 则保存了此次缩放的所有信息。然后经过 Conv Layers，经过 4 次 pooling 变为 WxH=(M/16)x(N/16) 大小，其中 feature_stride=16 则保存了该信息，用于计算 anchor 偏移量。

![Proposal Layer 处理流程](/image/faster-rcnn/img12.png)

Proposal Layer forward 按照以下顺序依次处理：

1. 生成 anchors，利用 [dx(A),dy(A),dw(A),d(hA)] 对所有的 anchors 做 bbox regression 回归。
2. 按照输入的 positive softmax scores 由大到小排序 anchors，提取前 pre_nms_topN (e.g. 6000) 个 anchors，再根据对应关系提取修正位置后的 positive anchors。
3. 限定超出图像边界的 positive anchors 为图像边界，防止后续 roi pooling 时 proposal 超出图像边界。
4. 剔除尺寸非常小的 positive anchors。
5. 对剩余的 positive anchors 进行 NMS（nonmaximum suppression）。
6. Proposal Layer 有 3 个输入：positive 和 negative anchors 分类器结果 rpn_cls_prob_reshape，对应的 bbox reg 的 (e.g. 300) 结果作为 proposal 输出。
