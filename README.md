# portable-python

在当前目录生成全功能, 便携式的 python.

可以运行 pip.

所谓便携式, 是指可以将其拷贝到任何计算机的任何路径下, 都可以正常使用.

只支持 windows.

## 使用

在你希望创建环境的目录用 PowerShell 执行:

```
irm "https://raw.githubusercontent.com/lsby/portable-python/main/init.ps1" | iex
```

## 细节

使用原版 python 安装程序进行安装, 然后将安装目录打包, 就得到了便携式的 python 环境.

然后使用该环境创建虚拟环境, 就得到了一个简单易用的 python 环境.
