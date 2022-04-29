# Spyglass使用说明 

##### 具体安装方法等不再赘述，待之后添加

## 使用Shell的脚本

```shell
read_file -type verilog {/home/gitlab-runner/builds/p9qpxhkY/0/root/nontrival-cpu/Src/refactor/*}
read_file -type verilog {/home/gitlab-runner/builds/p9qpxhkY/0/root/nontrival-cpu/Src/refactor/*/*}
set_option enableSV yes
set_option incdir /home/gitlab-runner/builds/p9qpxhkY/0/root/nontrival-cpu/Src/refactor/
set_option incdir /home/gitlab-runner/builds/p9qpxhkY/0/root/nontrival-cpu/Src/refactor/*
set_option top mycpu_top
```

## 参考资料

[(37条消息) spyglass使用教程_qq_30843953的博客-CSDN博客_spyglass](https://blog.csdn.net/qq_30843953/article/details/109629618)

- 详细请查看上述文章查看相关使用方法