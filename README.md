# dsh-tools

两个命令，给 DSHA 做**能真的恢复回来**的备份。

```bash
dsh-backup          # 备份，10 秒
dsh-restore <包>    # 还原
```

[English](README.en.md) · 中文

---

## 🚀 最快用法（不用懂任何命令）

**打开 DSHA，把下面这一整段复制，粘进对话框，发送。**

```
帮我装一下 https://github.com/sb1145148/dsh-tools 这个备份工具，
装完立刻做一次备份，然后告诉我：
  1. 备份文件在哪
  2. 多大
  3. 有没有报"逃逸软链"
```

**AI 会自己下载、安装、跑备份。你只管看结果。**

看到类似这样的输出就成了：

```
✅ 完成
   文件: /sdcard/Download/dsh-backup-20261022-1244.tar.gz
   大小: 59M
   条目: 1019
   软链: 0（逃逸型 0）
```

---

## 📥 我下载好了，然后呢

如果你拿到的是一个 `dsh-tools-x.y.z.tar.gz`，**最省事的办法还是把上面那段发给 AI**，
它会帮你解压安装，你不用管路径。

---

### 一行命令（不用手动解压）

```bash
curl -fsSL https://raw.githubusercontent.com/sb1145148/dsh-tools/main/install-online.sh | sh
```

**它会自己查最新版、下载、解压、安装、清理。** 装完直接敲 `dsh-backup`。

---

**想完全手动的话，就三步：**

### 第 1 步：解开压缩包

手机上随便一个文件管理器都能解压，解出来是一个叫 `dsh-tools` 的文件夹。

> 解压不了？回到上面「最快用法」，让 AI 做。

### 第 2 步：安装

打开 DSHA 的终端（或者直接让 AI 做），执行：

```bash
cd dsh-tools && sh install.sh
```

**你会看到：**

```
📦 dsh-tools 2.1.0
   安装到: /usr/local/bin
   ✅ /usr/local/bin/dsh-backup
   ✅ /usr/local/bin/dsh-restore
✅ 已在 PATH 里，直接敲 dsh-backup 就行
```

**看到两个 ✅ 就装好了。**

### 第 3 步：备份

```bash
dsh-backup
```

**等 10 秒左右**，看到 `✅ 完成` 就好了。

---

## 📁 备份文件在哪

```
/sdcard/Download/dsh-backup-<日期>-<时间>.tar.gz
```

**用手机的文件管理器打开：**

```
文件管理 → Download
```

**文件名带时间，每次备份都是新文件，不会覆盖旧的。**

---

## 📱 换新手机怎么用

### 总览

```
旧手机                          新手机
───────────────────────────────────────────
① dsh-backup
   ↓ 传文件（互传 / 数据线 / 微信）
                              ② 重建环境（别导数据！）
                                   ↓
                              ③ 装工具
                                   ↓
                              ④ dsh-restore
                                   ↓
                              ⑤ 重启 Web
```


### ⚠️ 最容易做错的一步

**一定要先重建环境，再导数据。**

```
❌ 先导数据 → 环境坏了，导进去也跑不起来
✅ 先重建环境 → 跑通了再导数据
```

**怎么重建环境：**

```
设置 → 应用管理 → DSHA → 存储 → 清除数据
然后打开 App，让它自己装（3-10 分钟）
```

**装之前先把这几个打开**（不然装到一半会被系统杀掉）：

```
设置 → 电池 → 后台耗电管理 → DSHA → 允许后台高耗电
设置 → 应用管理 → DSHA → 电池 → 不受限制
设置 → 应用管理 → DSHA → 自启动 → 允许
```

---

## ❓ 常见问题

### 我下载了，但不知道放哪

**把这段发给 AI，让它处理：**

```
我下载了 dsh-tools 的压缩包，在 /sdcard/Download/ 里，
帮我解压并安装，然后做一次备份。
```

### 敲 `dsh-backup` 提示 `command not found`

安装没成功，或者装到了不在 PATH 里的位置。

**重新跑一次 `sh install.sh`，然后看最后一行是不是绿色的「已在 PATH 里」。**

### 备份完了，文件找不到

**让 AI 帮你找：**

```
帮我找一下刚才 dsh-backup 生成的备份文件，列出路径和大小。
```

### 还原后看不到旧对话

**大概率是 sessions 目录名对不上。**

让 AI 执行：

```bash
ls ~/.dsh/sessions/
```

把输出发出来，看目录名是不是 `--root-xxx--` 这种形式，
要和当前工作区路径对应。

### 还原之后，我之前修过的东西怎么回退了

**dsh-restore 默认不覆盖比备份新的文件。**

如果你用的是旧版本，或者就是想强制覆盖：加 `--force`。

**先看看会做什么：**

```bash
dsh-restore xxx.tar.gz --dry-run
```

**另外：** 每次还原都会把现有目录存成 `*.before-restore`，
所以「被覆盖掉的东西」通常还能从这里捞回来：

```bash
ls ~/.dsh/*.before-restore/
```

### 提示「逃逸软链」

如果 `dsh-backup` 输出里 `软链:` 不是 0，说明还有指向包外的链接。
**把输出发给 AI，让它看是哪几个。**

### 备份要多久

**10 秒左右。** 主要时间是压缩（数据 59 MB，取决于对话和附件多少）。

### 备份文件多大

```
只有代码和对话    约 10 MB
带附件和表情包    约 50-70 MB
```

### 会不会自动备份

**不会。** 这是个手动命令，你敲一次它跑一次。

**换机前跑一次就够了。**

---

## 🆘 在新设备上报错？按顺序查这四样

**换机时 90% 的问题都在这里。** 按顺序查，基本一次就定位到。

---

### ① 工具装了吗

```bash
command -v dsh-restore
```

**有输出**（比如 `/usr/local/bin/dsh-restore`）→ 装了，看 ②

**无输出** → **没装**，装一下：

```bash
curl -fsSL https://raw.githubusercontent.com/sb1145148/dsh-tools/main/install-online.sh | sh
```

> ⚠️ **每次「清除数据」重建环境之后，`/usr/local/bin` 会被清空。**
> 所以新手机上必须重新装一次 —— 旧手机装过不等于新手机有。

**这是最常见的一个**，报错长这样：

```
dsh-restore: not found
No such file or directory
```

---

### ② 文件在不在

```bash
ls -l /sdcard/Download/dsh-backup-*.tar.gz
```

**有输出** → 在。看大小对不对（约 **60 MB**）

**无输出** → 换个地方找：

```bash
find /sdcard/Download -maxdepth 2 -name "*.tar.gz" 2>/dev/null
```

> 💡 **文件管理器里的「手机存储」= 命令行里的 `/sdcard`。**
> 别把「手机存储」四个字打进命令里。

**常见坑：**

| 情况 | 症状 |
| --- | --- |
| 文件在子目录里 | 路径少写一层 |
| 传输没完成 | 大小对不上（比如只有几 MB） |
| 文件名有空格或中文 | 命令里**必须加引号** |
| **文件在，但读不了** | `ls` 列得出来，还原时报「读不出文件头」/`Permission denied` |

---

#### ⚠️ 特例：`ls` 看得到，但读不出来

**`/sdcard` 是 FUSE 挂载，带 SELinux 和 uid 限制。** 环境里的 root 不是真 root：

```
ls -l  →  只查目录读权限  →  ✅ 能列出
open() →  要真正打开文件  →  ❌ 被拒
```

**判断方法：**

```bash
ls -l "$F"                  # 有输出
head -c 1 "$F" >/dev/null   # 报 Permission denied 就是这个
```

**两个办法：**

1. **开权限**：设置 → 设备能力授权 → 打开文件访问
2. **绕过去**：先复制到工作区再还原

```bash
cp "$F" ~/ && dsh-restore ~/$(basename "$F")
```

**`~/` 在工作区内，不受 `/sdcard` 那层限制。**

---

### ③ 目录名对得上吗

**这是「还原明明成功了，但看不到旧对话」的原因。**

```bash
ls ~/.dsh/sessions/
```

应该输出**一个**目录，名字形如：

```
--root-deepseek-harness--
```

**这个名字必须和当前工作区路径对应。** 它把 `/root/deepseek-harness`
里的斜杠换成 `-` 得来的。

**对不上 → 旧对话不会出现在列表里。**

把这三条的输出一起发出来，就能定位：

```bash
ls ~/.dsh/sessions/     # 现在的目录名
pwd                     # 当前工作区
```

---

### ④ 打开会话报 seq gap

**应用里打开某个对话时报：**

```
stored session "session-xxx" is corrupt:
... has seq gap (expected 14467, got 14619)
```

**这是会话日志本身的 seq 不连续** —— 常见于「恢复会话」时计数器跳了。

**这不是备份的问题**，源文件本来就这样，备份只是如实复制。

**修法：**

```bash
apt-get install -y zstd      # 先装 zstd（修会话要用）
dsh-repair --check           # 看看哪个会话有断档
dsh-repair                   # 修掉
```

**然后重启 Web。**

原文件会存成 `.before-repair`，改坏了能回去。**内容一行不丢，只是重新编号。**

**⚠️ 别修正在用的那个会话** —— 应用还在往里写。先在应用里切到别的对话，或者重启 Web 再修。

---

### 📊 报错 → 对号入座

| 你看到的 | 对应哪一条 |
| --- | --- |
| `dsh-restore: not found` | **① 工具没装** |
| `bash: /sdcard/...: No such file` | **② 路径不对** |
| `❌ 找不到文件: /sdcard/...` | **② 路径不对** |
| 还原成功但没旧对话 | **③ 目录名不匹配** |
| 只输出了用法提示 | 参数被空格拆开了 → **加引号** |
| 打开会话报 `seq gap` | **④ 日志断档 → `dsh-repair`** |

---

## 🩺 每次 DSHA 更新后，跑一下自检

```bash
dsh-backup --check
```

```console
🩺 dsh-tools 1.2.0 自检

  DSHA 目录:     /root/.dsh
  应用版本:      0.2.1-rc.2-20261022.2100
  会话格式:      v4  ✅ 已知
  会话文件数:    9

  依赖:
                 tar      ✅
                 zstd     ✅（可选）

  事件类型:
                 37 种 / 15192 条
                 ✅ 全部认识

  上次备份:      2026-10-23 14:39:35
                 dsh-backup-20261023-1439.tar.gz  84M

  ✅ 可以正常备份
```

**「事件类型」这一项就是 1.3.0 补的。** 文件名里的 `v4` 只能说明大版本对得上，
真正的破坏往往在日志内部 —— 新版本加了一个事件类型，旧版本整份拒读。

**为什么需要这一步：**

DSHA 的会话文件叫 `session.v4.jsonl.zstd` —— `v4` 是格式版本。
如果哪天变成 `v5`，而工具照旧打包，**不会报错**，备份看起来也正常，
但恢复后应用读不了。

**静默失效最难查。** 所以工具现在会主动检测：

```
⚠️  会话格式是 v5，但本工具只认识: v4
❌ 已中止。确实要打包就加 --force
```

**不认识的格式直接停下，要越过得显式加 `--force`。**

## ⚠️ 最隐蔽的一类问题：帧布局

**症状：** 会话文件在磁盘上、大小也对、`zstd -dc` 能解、JSON 能解析 ——
但应用里就是看不到，**也不报任何错**。

**原因：** DSH 的读取器要求**首帧恰好是 header 这一行**：

```js
function assertZstdHeaderFrame(plaintext) {
  if (plaintext.length === 0 || plaintext.indexOf(10) !== plaintext.length - 1)
    throw new Error("first frame is not exactly one header line");
}
```

整份文件压成一个帧 → 判损坏 → **静默跳过**。

**谁会写坏它：** 任何"整份重压"的做法，比如 `zstd -f -o out in`。
它默认只出一个帧。

**怎么查：**

```bash
dsh-reframe
```

```console
🔍 检查 13 个会话...

  ✅ session-9441bf7c...    907 帧  首帧 230B  1735 行
  ❌ session-0df3b6aa...      1 帧  首帧 2018680B → 应用会静默跳过
     内容其实完好：2018680 字节 / 754 行
```

**怎么修：**

```bash
dsh-reframe --fix        # 重切帧，内容一行不动
dsh-reframe --rollback   # 回退
```

**实测 11 个坏会话全部救回，内容字节级一致。**

---

## 🩺 一条命令体检

```bash
dsh-doctor
```

```console
🩺 dsh-doctor 1.4.0

环境
  dsh 目录:   /root/.dsh
  应用版本:   0.2.1-rc.2-20261022.2100-dsh0.2.1-rc.2
  依赖:       ✅ 齐全

会话（11 个）
  格式:       v4 ✅
  读不了:     ✅ 0
  seq 断档:   ✅ 0
  未知事件:   ✅ 0

备份
  最近备份:   ✅ 0 天前  dsh-backup-20261023-1439.tar.gz

──────────────────────────────────────
✅ 没发现问题
```

**其它用法：**

```bash
dsh-doctor --fix         # 自动修能修的（seq 断档 / 未知事件）
dsh-doctor --json        # 机器可读
dsh-doctor --rollback    # 一键回退
```

**安全**：默认零写入；`--fix` 前先存 `*.before-doctor`；
检测到 Web 在跑会拦下来（会话文件是活的）。

### ⚠️ 它判断不了的事

工具只能确定两件事：**seq 断档**和**文件能不能解开**。

**「某个事件类型会不会让应用读不了」它判断不了** —— 因为：

| 来源 | 特征 |
| --- | --- |
| 插件产生的事件 | 不在 harness 核心表里 |
| 新版本引入的事件 | 也不在 harness 核心表里 |

**两者长得完全一样。**

所以它把不在核心表里的事件标成「非核心事件」，**只报告，不自动剥**。

真正确认只能看应用报的错：

```
contains event type "job/registered" (seq 14511)
unknown to this harness and not marked ignorable
```

把报错里的类型名交给 —— **只抄类型名，不要引号、不要 `(seq 14511)`**：

```bash
dsh-doctor --fix --strip-type job/registered --i-know
```

**下面这几种写法也能用**（工具会清理）：

```bash
dsh-doctor --fix --strip-type 'job/registered" (seq 14511)'   # 整段粘贴
```

但 `--strip-type` 和类型名之间**要有空格** —— 漏了会明确报错告诉你。

### dsh-events

想知道当前这份安装认识哪些事件类型：

```bash
dsh-events                      # 一行一个
dsh-events --count              # 个数
dsh-events --check job/registered   # 认不认识
```

**权威来源是 harness 里的 `SessionEventMap` 接口声明**，不是写死的列表。

---

## 🔪 降级后旧对话打不开？用 dsh-strip

**症状：**

```
failed to observe session "session-xxx":
contains event type "job/registered" (seq 14511)
unknown to this harness and not marked ignorable;
refusing to interpret the log
— it was likely written by a newer harness
```

**原因：日志是往前兼容、不往后兼容的。**

新版本加了一个事件类型，旧版本不认识 —— **不是跳过那一条，是整份拒读。**

---

**解法有两个，按顺序试：**

### ① 升回写这份日志的版本（推荐）

日志是它写的，它当然读得懂。

### ② 剥掉不认识的事件（必须留在旧版本时）

```bash
# 先看这个会话里有哪些事件类型
dsh-strip --list ~/.dsh/sessions/*/session-xxx/session.v4.jsonl.zstd

# 看看会删多少，不写盘
dsh-strip --dry-run <文件> job/registered job/settled

# 真删
dsh-strip <文件> job/registered job/settled
```

**它会删掉指定类型，把 seq 重排成连续的，其它一行不动。**

```console
🔪 剥离: job/registered job/settled
   保留 15041 行，剥离 142 行，重排 seq 1..15040
🗜  压缩...

✅ 完成
   大小: 5269859 字节（原 14138834）
   残留指定类型: 0
```

⚠️ **必须停 Web 再操作** —— 会话文件是活的，边读边写。

⚠️ **这是单向下坡** —— 以后升回去还得再处理一次。

---

## 🤔 为什么需要它

DSHA 自带的「备份与恢复」目前有个 bug：

```
备份  → ✅ 成功
恢复  → ❌ 报 ARCHIVE_LINK_ESCAPE
```

原因是它生成的 `portable.dshbak` 里保留了 `node_modules` 中指向归档根之外的软链
（实测 51 处），恢复时的安全检查拒绝它们，导致整个还原失败。

**结果就是换机迁移这条路完全走不通。**

这个工具在打包阶段就把这类链接剔掉，所以恢复能过。

---

## 🧰 九件工具

| 命令 | 干什么 |
| --- | --- |
| `dsh-backup` | 备份到 `/sdcard/Download/`（文件名带 `dsh-backup-` 前缀） |
| `dsh-restore` | 还原（不覆盖比备份新的文件） |
| `dsh-doctor` | 一体检：帧布局 / seq / 索引 / 事件类型 / 备份新鲜度 |
| `dsh-reframe` | 修帧布局（首帧必须恰好一行） |
| `dsh-repair` | 修 seq 断档 |
| `dsh-strip` | 给事件打 `ignorable` 标记（`--mark`，推荐）或剥离 |
| `dsh-recover` | 用备份原件救回被改坏的会话 |
| `dsh-reindex` | 对齐 `workspace.json` 的会话索引 |
| `dsh-events` | 列出当前 harness 认识哪些事件类型 |

**日常只用两个：**

```bash
dsh-backup     # 备份
dsh-doctor     # 体检
```

---

## 🚨 铁律：不要改会话目录名

**`~/.dsh/sessions/` 下面的路径是结构性信息，不是随便起的名字。**

```
sessions/
  --root-deepseek-harness--/        ← 由会话 header 的 cwd 推出来
    session-1aaf44ea-.../           ← 由 header 的 id 推出来
      session.v4.jsonl.zstd
```

**harness 会用 header 里的 `id` + `cwd` 反推「这个会话应该在的路径」，
再和实际路径比对。对不上就判 `corrupt`，然后——**

```
WorkspaceRegistry 加载失败
   ↓
WorkspaceController / SessionController 全部 pending
   ↓
对话列表空掉、打开文件夹也失败
```

**实测复现过。比原来的问题严重得多。**

**想「移出」某个会话，就搬到 `sessions/` 外面：**

```bash
mkdir -p /root/.dsh/_quarantine
mv "/root/.dsh/sessions/--root-deepseek-harness--/session-xxx" /root/.dsh/_quarantine/
```

**不要 `mv xxx xxx.disabled`。**

---

## ✅ 版本降级不可行

- 日志**只往前兼容**。旧版读新版写的日志 → `unknown event` 或静默跳过
- 旧版写回去的是**旧格式**，新版再读又坏
- 来回折腾只会让数据越来越乱

**正确做法：升到写这份日志的版本。**

`dsh-strip` 只用来处理「某个已知类型把日志卡住」，**不是降级手段**。

---

## 🔧 命令行速查（给懂的人）

```bash
# 一键安装（下载 + 解压 + 安装）
curl -fsSL https://raw.githubusercontent.com/sb1145148/dsh-tools/main/install-online.sh | sh

# 安装到别处
sh install.sh --prefix ~/bin

# 备份
dsh-backup

# 还原（默认不动状态文件，且不覆盖比备份新的文件）
dsh-restore /sdcard/Download/dsh-backup-xxx.tar.gz

# 先看看会做什么，不实际写（安全）
dsh-restore xxx.tar.gz --dry-run

# 强制覆盖，不管修改时间
dsh-restore xxx.tar.gz --force

# 连状态文件一起还原（谨慎）
dsh-restore xxx.tar.gz --all

# 回滚插件
rm -rf ~/.dsh/plugin-src
mv ~/.dsh/plugin-src.before-restore ~/.dsh/plugin-src

# 体检
dsh-doctor
dsh-doctor --fix --strip-type <类型>

# 修帧布局（首帧必须一行）
dsh-reframe
dsh-reframe --fix
dsh-reframe --rollback

# 修 seq 断档
dsh-repair --check
dsh-repair

# 给事件打 ignorable 标记（推荐）
dsh-strip --mark <文件> <类型>

# 救回被改坏的会话
dsh-recover
dsh-recover --fix

# 对齐工作区索引
dsh-reindex
dsh-reindex --fix
```

**带走：**

```
sessions/      对话记录
attachments/   对话里的图片和文件
plugin-src/    插件源码
meme-packs/    表情包
plugin-kits/   插件包
profiles/      配置档案
config/        配置（不含凭据）
home/          shell 配置和笔记
```

**不带：**

| 东西 | 原因 |
| --- | --- |
| 状态文件（`plugin-activations.json` 等） | 覆盖会让新环境起不来 |
| `.bridge_headers` 等凭据 | 不能外流 |
| `node_modules` / 缓存 / 日志 | 可重建 |
| 指向包外的软链 | 就是那个 bug 的来源 |
| 整个 Linux 环境 | 几 GB，跨设备必然失效 |

---

## 📋 兼容

- DSHA `0.2.21-*`（`session.v4.jsonl.zstd` 格式）
- GNU tar 1.35 起
- 只依赖 `sh` / `tar` / `find` / `cp`

---

## 📄 License

MIT
