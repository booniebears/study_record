# 关于CPU和CACHE适配

## 在MEM级检测到异常是最高优先级

flush{所有流水线寄存器(除了PC), I$, D$}，PC写使能打开

### 在I$ 或是D$ busy是其次优先级 

初步考虑 暂停{所有流水线寄存器} 不能向I$ D$发送新的请求  I$做相应的返回数据的握手适配 

其实我想做到的就是 如果命中时 流水线的情形 和重新开始时的 流水线情形一致  所以在都不busy的那个周期可以发送新的请求  然后因为返回握手适配的原因 返回的数据也是一致的

流动和接受请求保持一致

说明 假设$ 都hit了 都能发送新请求 同时流水线流动 $返回上一拍的数据

如果 有busy 那么都不发送新的请求    流水线寄存器的值都不变             $返回停滞上一拍的数据

#### ID级跳转

在无异常 无busy的情况下 即 流水线可以流动  不做任何处理

#### EXE级跳转

在无异常 无busy的情况下 即 流水线可以流动  向I$发送flush信号 向IF_ID寄存器发送flush信号

在busy的情况下 不能发送flush信号   （细一点 实际上是D$ busy时不能发 但是不如就都不发）

#### L-R冒险

关PC 和IF_ID寄存器   不能向I$ 发送新的请求

L-R如果和ID跳转无纠缠 （实际上应该是没有的 但是如果代码 写得烂的话就会有）