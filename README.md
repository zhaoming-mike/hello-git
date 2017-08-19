# Git 内部原理
>Git 是如何管理文件的？又是如何保存不同时刻文件的版本信息的？   
>在这我们一步步揭开它神秘的面纱。

# 从一个文件说起
- [x] [内容的保存](#git-命令分类)
- [x] [目录的保存](#git-对象分类)
- [ ] 提交如何保存
- [ ] Git 如何创建 branch
- [ ] Git 如何创建 tag

# 写入内容到 Git
```shell
echo 'hello git' | git hash-object -w --stdin
```

```shell
d67
```


# 保存文件到 Git

# Git 命令分类
* Porcelain（简化【瓷器】命令：对内部命令集的封装）
* Plumbing （内部【棒槌】命令：git plumbing 是一组内部命令集）

# Git 对象分类
1. blob 对象（存放数据）
1. tree 对象（存放目录）
