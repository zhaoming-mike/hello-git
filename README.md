# Git 内部原理
>Git 是如何管理文件的？又是如何保存不同时刻文件的版本信息的？   
>在这我们一步步揭开它神秘的面纱。

# 从一个文件说起
- [x] [内容的保存](#git-命令分类)
- [x] [目录的保存](#git-对象分类)
- [x] [提交如何保存](#提交如何保存)
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

$ git cat-file --batch-check --batch-all-object # --batch-check:不输出内容，仅显示 "<SHA-1> <type> <size> LF"
86c83dd5aac33fc5817430360fac8dcace9037f6 blob 12
8d0e41234f24b6da002d962a26c2495ea16a425f blob 10
aa4e1b6b680e8b06c1a998e2e8424dc62209071b blob 12

$ git cat-file --batch --batch-all-object # --batch:从 stdin 读 SHA-1 的交互模式 --batch-all-object:全量输出
86c83dd5aac33fc5817430360fac8dcace9037f6 blob 12
mike test 1

8d0e41234f24b6da002d962a26c2495ea16a425f blob 10
hello git

aa4e1b6b680e8b06c1a998e2e8424dc62209071b blob 12
mike test 2

```
# 保存树对象

```shell
$ touch 1.txt
$ echo "hello mike 1" > 1.txt
$ git hash-object -w 1.txt
243fd7fd14b11b461797817a77e855e454736049
```

```shell
├── objects
│   ├── 24
│   │   └── 3fd7fd14b11b461797817a77e855e454736049
```

```shell
$ git update-index --add --cacheinfo 100644 243fd7fd14b11b461797817a77e855e454736049 1.txt # 写入暂存
$ git write-tree # 将暂存区写入 ".git/objects"
d79fe6c438b12ce920210e61abcbf531838a7d4d
$ git cat-file -p d79f # tree 对象：模式（100644、100755、120000、040000、etc...）、类型、SHA-1、文件名
100644 blob 243fd7fd14b11b461797817a77e855e454736049	1.txt
$ git cat-file -t d79f
tree
```

```shell
$ echo "new file" > new.txt # 添加 new.txt 文件
$ echo "hello mike 2" > 1.txt # 修改 1.txt 文件
$ git hash-object -w 1.txt # 写入 ".git/objects"
da4d32c613775592eb6ace06fbff04253b57268a

$ git update-index 1.txt # 更新到暂存区
$ git update-index --add new.txt # 文件在工作空间可以不使用 --cacheinfo 的方式
$ git write-tree # 将此时的暂存区写入 ".git/objects"
1c7763f851c5d90469f81e4c5e210d368b54211d

$ git cat-file -p 1c77 # SHA-1 可以简写前四位
100644 blob da4d32c613775592eb6ace06fbff04253b57268a	1.txt
100644 blob fa49b077972391ad58037050f2a75f74e3671e92	new.txt

$ git read-tree --prefix=ver1 d79f # 将之前的一棵树对象读入当前树对象，并用 --prefix 参数指定一个目录名
$ git write-tree # 将此时的暂存区写入 ".git/objects"
e4ad8804815ba7ba689f8ecc82c83efd6ee729c3
$ git cat-file -p e4ad
100644 blob da4d32c613775592eb6ace06fbff04253b57268a	1.txt
100644 blob fa49b077972391ad58037050f2a75f74e3671e92	new.txt
040000 tree d79fe6c438b12ce920210e61abcbf531838a7d4d	ver1
```

# 提交如何保存

```shell
$ echo "commit 1" | git commit-tree d79f # 模拟一次 ver1 目录的提交
d3258f685a60528534c7cef572967e601da393b8
$ git cat-file -p d3258
tree d79fe6c438b12ce920210e61abcbf531838a7d4d
author Mike <zhaoming23@gmail.com> 1503236682 +0800
committer Mike <zhaoming23@gmail.com> 1503236682 +0800

commit 1

$ echo "commit 2" | git commit-tree 1c77 -p d3258 # 用 -p 参数指定本次提交的父提交对象（如果有的话）
cf93071001a41749d7317507d769ed303b33d4d7
$ echo "commit 3" | git commit-tree e4ad -p cf9307
c4073ce63780452cfcee86f926d719daa751538a
$ git log --stat c407 # 查看以上我们用底层命令实现的这几次提交信息，这跟用 git add 、git commit 效果是等价的
```

# 模拟的提交日志

```shell
commit c4073ce63780452cfcee86f926d719daa751538a
Author: Mike <zhaoming23@gmail.com>
Date:   Sun Aug 20 21:49:28 2017 +0800

    commit 3

 ver1/1.txt | 1 +
 1 file changed, 1 insertion(+)

commit cf93071001a41749d7317507d769ed303b33d4d7
Author: Mike <zhaoming23@gmail.com>
Date:   Sun Aug 20 21:47:34 2017 +0800

    commit 2

 1.txt   | 2 +-
 new.txt | 1 +
 2 files changed, 2 insertions(+), 1 deletion(-)

commit d3258f685a60528534c7cef572967e601da393b8
Author: Mike <zhaoming23@gmail.com>
Date:   Sun Aug 20 21:44:42 2017 +0800

    commit 1

 1.txt | 1 +
 1 file changed, 1 insertion(+)
```

# 此时 Git 数据库中保存的内容

```shell
├── objects
│   ├── 1c
│   │   └── 7763f851c5d90469f81e4c5e210d368b54211d # tree 1.txt new.txt commit 2
│   ├── 24
│   │   └── 3fd7fd14b11b461797817a77e855e454736049 # 1.txt => hello mike 1
│   ├── c4
│   │   └── 073ce63780452cfcee86f926d719daa751538a # commit 3 parent cf93
│   ├── cf
│   │   └── 93071001a41749d7317507d769ed303b33d4d7 # commit 2 parent d325
│   ├── d3
│   │   └── 258f685a60528534c7cef572967e601da393b8 # commit 1 no parent 
│   ├── d7
│   │   └── 9fe6c438b12ce920210e61abcbf531838a7d4d # tree for 1.txt hello mike 1
│   ├── da
│   │   └── 4d32c613775592eb6ace06fbff04253b57268a # 1.txt => hello mike 2
│   ├── e4
│   │   └── ad8804815ba7ba689f8ecc82c83efd6ee729c3 # tree fot 1.txt hello mike 2 new.txt ver1
│   ├── fa
│   │   └── 49b077972391ad58037050f2a75f74e3671e92 # new.txt => new file
```

# Git 命令分类
* Porcelain（简化【瓷器】命令：对内部命令集的封装）
* Plumbing（内部【棒槌】命令：git plumbing 是一组内部命令集）

# Git 对象分类
1. blob 对象（存放数据）
1. tree 对象（存放目录）

# 联系我
[我的二维码](https://github.com/zhaoming-mike/hello-git/issues/1)
