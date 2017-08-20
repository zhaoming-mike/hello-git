# Git 内部原理
>Git 是如何管理文件的？又是如何保存不同时刻文件的版本信息的？   
>在这我们一步步揭开它神秘的面纱。

# 从一个文件说起
- [x] [内容的保存](#git-命令分类)
- [x] [目录的保存](#git-对象分类)
- [ ] 提交如何保存
- [ ] Git 如何创建 branch
- [ ] Git 如何创建 tag

## 写入内容到 Git

```shell
$ echo 'hello git' | git hash-object -w --stdin # -w:写入到 .git/objects 不加 -w 仅返回 SHA-1 ，不会写入内容。
8d0e41234f24b6da002d962a26c2495ea16a425f
```

`.git/objects` 目录的变化：

```shell
├── objects
│   ├── 8d
│   │   └── 0e41234f24b6da002d962a26c2495ea16a425f
```

[取回数据](https://git-scm.com/docs/git-cat-file)：

```shell
$ git cat-file -p 8d0e41234f24b6da002d962a26c2495ea16a425f # -p:友好格式打印
hello git 
```

## 保存文件内容到 Git

```shell
$ echo 'mike test 1' > 1.txt
$ git hash-object -w 1.txt
86c83dd5aac33fc5817430360fac8dcace9037f6

$ echo 'mike test 2' > mike-tmp/2.txt
$ git hash-object -w mike-tmp/2.txt
aa4e1b6b680e8b06c1a998e2e8424dc62209071b
```

`.git/objects` 目录的变化：

```shell
├── objects
│   ├── 86
│   │   └── c83dd5aac33fc5817430360fac8dcace9037f6
│   ├── 8d
│   │   └── 0e41234f24b6da002d962a26c2495ea16a425f
│   ├── aa
│   │   └── 4e1b6b680e8b06c1a998e2e8424dc62209071b
```

[取回数据](https://git-scm.com/docs/git-cat-file)：

```shell
$ git cat-file -p aa4 # 可以缩写 SHA-1 ，但至少要4位，否则无法返回数据。😄
fatal: Not a valid object name aa4

$ git cat-file -p aa4e
mike test 2

$ git cat-file -t aa4e # -t: 查看数据的类型
blob

$ git cat-file -s aa4e # -s: 查看数据的大小（字符数还要外加一个LF）
12
```

# Git 命令分类
* Porcelain（简化【瓷器】命令：对内部命令集的封装）
* Plumbing（内部【棒槌】命令：git plumbing 是一组内部命令集）

# Git 对象分类
1. blob 对象（存放数据）
1. tree 对象（存放目录）
