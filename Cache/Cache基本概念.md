## 2022.4.4 Cache基本概念

```
参考资料:
    https://zhuanlan.zhihu.com/p/102293437
   《计算机组成与设计:硬件/软件接口》5.3-5.4
   Digital Design and Computer Architecture, Second Edition by David M. Harris, Sarah L. Harris 8.3
```

### 1.名词讲解

```
    Cache size:cache可以缓存数据的大小。
    Cache line:就是所谓的“块”的大小。cache line的大小一般是4-128 Bytes。
    注意:cache line是cache和主存之间数据传输的最小单位。也就是说，与存储器的交互一次是一个cache line大小的数据。
```

### 2.Cache直接映射

#### 2.1 直接映射下的Cache结构

- 注意是直接映射下的！！！
- 注意是直接映射下的！！！
- 注意是直接映射下的！！！
```
    首先谈访存的地址(32位)。这32位总是被分割为三部分:Tag,Index(下面这个图里面是Set,个人建议还是用Index比较统一一点)和Offset。
    一个Cache line(块)一般总是有多个byte,Offset就是用来定位块中具体的byte。同时，Cache中有多个Cache line，那么Index就是定位具体使用
那个Cache line。Tag则唯一确定具体要访问的地址。
    再看Cache结构，由存储数据Data域,Tag域,和Valid bit构成。Data域的宽度自己定义(当然下图是经典的4 bytes),Tag就是地址中的Tag,
valid bit判定当前Cache line是否有效。我们谈Cache size的时候一般只是谈Data域,不考虑Tag和Valid bit。
```
![输入图片说明](%E5%9B%BE%E7%89%87/Cache%20Structure.png)

#### 2.2 直接映射原理
知乎那篇文章讲的非常清楚，我就直接复制粘贴了。下面有配图。
```
    现在我们知道，如果两个不同的地址，其地址的bit3-bit5如果完全一样的话，那么这两个地址经过硬件散列之后都会找到同一个cache line。
所以，当我们找到cache line之后，只代表我们访问的地址对应的数据可能存在这个cache line中，但是也有可能是其他地址对应的数据。所以，
我们又引入tag array区域，tag array和data array一一对应。每一个cache line都对应唯一一个tag，tag中保存的是整个地址位宽去除index和offset
使用的bit剩余部分（如上图地址绿色部分）。tag、index和offset三者组合就可以唯一确定一个地址了。因此，当我们根据地址中index位找到cache line
后，取出当前cache line对应的tag，然后和地址中的tag进行比较，如果相等，这说明cache命中。如果不相等，说明当前cache line存储的是其他地址的数据，
这就是cache缺失。
    在上述图中，我们看到tag的值是0x19，和地址中的tag部分相等，因此在本次访问会命中。由于tag的引入，因此解答了我们之前的一个疑问
“为什么硬件cache line不做成一个字节？”。这样会导致硬件成本的上升，因为原本8个字节对应一个tag，现在需要8个tag，占用了很多内存。
tag也是cache的一部分，但是我们谈到cache size的时候并不考虑tag占用的内存部分。

    我们可以从图中看到tag旁边还有一个valid bit，这个bit用来表示cache line中数据是否有效（例如：1代表有效；0代表无效）。当系统刚启动时，
cache中的数据都应该是无效的，因为还没有缓存任何数据。cache控制器可以根据valid bit确认当前cache line数据是否有效。所以，上述比较tag确认
cache line是否命中之前还会检查valid bit是否有效。只有在有效的情况下，比较tag才有意义。如果无效，直接判定cache缺失。
```
![输入图片说明](%E5%9B%BE%E7%89%87/Cache%E7%9B%B4%E6%8E%A5%E6%98%A0%E5%B0%84.png)

### 3.二路组相连
#### 3.1 为什么设计二路组相连
```
    直接映射会比较简单，但是在某些情况下会有miss率特别高的状况。
    比如说，假设存储器的0x0000_0300和0x0000_0600都映射到Cache中的同一个块。那假设某些情况下，我们会交替访问这两个地址对应的数据。
不难想到，访问0x0000_0300时，发现Cache miss,于是把0x0000_0300对应的数置入Cache,0x0000_0600的数从Cache中被替换掉;反之亦然。这样miss率居然是100%。
```

#### 3.2 二路组相连结构
```
    简单来说，现在一个地址可以对应两个Cache line了。所以每次访存时，需要比较两次tag才能判断是否有Cache miss了。然而这样也非常顺畅的解决了
上面提到的Cache miss 100%的问题。
    王老师建议我们使用直接映射或者两路组相连结构，其余的结构我们就不讨论了。
```
![输入图片说明](%E5%9B%BE%E7%89%87/Cache%20Structure2.png)

### 4.Cache更新问题 -- 针对写存储器操作
```
    Write through:当CPU执行store指令并在cache命中时，我们更新cache中的数据并且更新主存中的数据。cache和主存的数据始终保持一致。
    Write back:当CPU执行store指令并在cache命中时，我们只更新cache中的数据。并且每个cache line中会有一个bit位记录数据是否被修改过，称之为
dirty bit。我们会将dirty bit置位。主存中的数据只会在cache line被替换或者显示的clean操作时更新。因此，主存中的数据可能是未修改的数据，而
修改的数据躺在cache中。cache和主存的数据可能不一致。
    
    Write allocate:当CPU写数据发生cache缺失时，才会考虑写分配策略。当我们不支持写分配的情况下，写指令只会更新主存数据，然后就结束了。当支持
写分配的时候，我们首先从主存中加载数据到cache line中，然后会更新cache line中的数据。
    Write allocate和Write back一般绑定使用。
```


