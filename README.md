# portable-python

在当前目录生成全功能, 便携式的 python.

可以运行 pip.

所谓便携式, 是指可以将其拷贝到任何计算机的任何路径下, 都可以正常使用.

只支持 windows.

## 使用

在希望创建环境的目录用 PowerShell 执行:

```
irm "https://raw.githubusercontent.com/one-click-run/portable-python/main/init.ps1" | iex
```

也可以直接指定版本:

```
$env:ONE_CLICK_RUN_PORTABLE_PYTHON_SELECTEDMATCH = 'python-3.10.11-amd64.zip'; irm 'https://raw.githubusercontent.com/one-click-run/portable-python/main/init.ps1' | iex
```

## 注意

当环境目录发生变化时, 应当执行修复脚本.

## 说明

本仓库提供的 zip 包是使用官方 python 安装程序进行安装, 然后将安装目录打包得到的.
