### 一篇特别有意思的文章

内存管理单元(MMU)是您的工作部件，负责管理内存读/写。

用一句话来说明，“管理内存的部件”是“内存管理单元”。也可以省略内存管理单元，并将其表示为“MMU”。

 举个例子，内存是“电脑工作时使用的桌子”。电脑先生把工作工具摊在桌子(内存)上，勤勤恳恳地工作着。

电脑先生根据需要把东西放在这张桌子上。或者，从桌子上取东西。
  
实际上，电脑先生不擅长整理整理。随心所欲地使用的话，桌子上就乱七八糟的，变得很厉害。

这种情况很糟糕。这样想的电脑先生雇佣了管理桌子的人。

从那以后，电脑先生自己就不会碰桌子了。想把橘子放在桌子上的时候，会对桌子的管理员发出“这个橘子，放在桌子上”的指示。

反过来也是这样。想吃橘子的时候自己也不碰桌子。对桌子的管理员发出指示：“把桌子上的橘子拿来吧”。

这样电脑先生就不需要做不擅长的整理了。对桌子上的管理员来说，它会很好的进行处理。

在这个故事中，桌子的管理员就是内存管理单元。

接下来就用物理地址和逻辑地址的变换来说明一下吧。

电脑使用的桌子(内存)从上面看是用格子分隔的。而且，每个格子都被分配了一个号码，以便于使用。

这个“分配给网格的号码”叫做“地址”。

例如，假设你把橘子放在第13号上。表示在13号地址放了橘子。

那么，这张桌子的格子上的号码对于下面两个方面，看到的结果是不一样的。

实际分配的号码(物理地址)
从程序看时的号码(逻辑地址)
程序说：“我把橘子放在第一地址了！“我想，实际上是放在100号地址。

再举个例子，这里有带橘子的程序。程序先生想把橘子放在桌子上。

这个时候，程序先生不会把橘子直接放在桌子上。我要求内存管理单元“把这个橘子放在桌子上”。

程序先生委托内存管理单元说：“把这个橘子放在1号地址吧。”

接受了这个委托的内存管理单元先生把橘子作为1号地址……，却不一定放。根据内存管理单元的心情擅自决定。哎呀，这次好像把橘子放在13号地址了。

过了一会儿，程序先生回来了。程序先生好像饿了。他委托内存管理单元说：“把我放在1号地址上的那个橘子拿来吧。”

收到这项委托的内存管理单元先生，若无其事地从13号地址带来橘子。然后给他说：“好吧，这是放在1号地址的橘子。”

在这里，请注意放置橘子的方格号码。

程序先生原本打算把橘子放在“一号”的方格里。从程序先生的角度来看，虽说经过了内存管理单元先生，但也是从放在第一格中拿出来的橘子。

实际上，被内存管理单元先生的手放在“13号”的方格里了吧。

从程序先生的角度看，格子号码叫做“逻辑地址”。
实际分配给桌子的方格号码是“物理地址”。
这种情况可以说是在内存管理单元的手中，进行了逻辑地址和物理地址的转换。这是内存管理单元的工作之一。

最后
如果出现“内存管理单元”这个单词，请想一想：“这是管理内存各个方面的部件吧~”。
————————————————
版权声明：本文为CSDN博主「ソフト開発王さん」的原创文章，遵循CC 4.0 BY-SA版权协议，转载请附上原文出处链接及本声明。
原文链接：https://blog.csdn.net/qq_18191333/article/details/107521052