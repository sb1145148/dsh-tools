# 更新日志

## 2.1.0 — 2026-10-25

**去掉演示图，README 重写。**

### 为什么去图

```
docs/backup-demo.png    216 KB
docs/restore-demo.png   108 KB
--------------------------------
合计                    324 KB   ← 占了整个包 360 KB 的 90%
```

**一个命令行工具，包体里九成是截图，说不过去。**

去掉后安装包从 **360 KB 降到约 32 KB**。

**代价**：README 里少了视觉示例。但那些演示本来就是把命令输出渲染成图片——
**同一个输出，README 的代码块里已经有了。**

### README 补了什么

**① 九件工具一览**

原来只提了 4 个，`dsh-recover`、`dsh-reindex`、`dsh-reframe` 都没出现。

**② 「不要改会话目录名」铁律**

这是实测出来的坑，之前只写在 CHANGELOG 里：

```
sessions/--root-deepseek-harness--/session-<id>/
      ↑ 由 cwd 推出            ↑ 由 id 推出
```

**改了名 → harness 反推的路径对不上 → 判 corrupt →
WorkspaceRegistry 挂 → 对话列表空掉、打开文件夹也失败。**

比原来的问题严重得多。

**③ 「版本降级不可行」单独成节**

**④ 修过时引用**

- `dsh-tools-1.0.2.tar.gz` → 不再写死版本号
- `📦 dsh-tools 1.0.1` → `2.1.0`
- `从 1.1.3 开始` → 去掉版本依赖的表述

**⑤ 命令行速查补齐**

从 5 条变成 15 条，覆盖全部九个工具。

## 2.0.9 — 2026-10-24

**我上一版建议的 `mv xxx xxx.disabled`，会把整个工作区服务弄挂。**

### 实测复现

在隔离实例里（另一个 DSH_HOME、另一个端口）把一个会话目录改成 `.disabled` 后启动：

```console
workspace (@deepseek-ai/dsh-workspace): Error: corrupt session log
  ".../session-9f36469e-....disabled/session.v4.jsonl.zstd":
  header id "session-9f36469e-..." and cwd identify
  ".../session-9f36469e-.../session.v4.jsonl.zstd"

session-controller: pending (waiting for service: workspaceRegistry)
```

**后果比原来的「空会话报错」严重得多：**

```
WorkspaceRegistry 加载失败
   ↓
WorkspaceController / SessionController 全部 pending
   ↓
对话列表空掉、打开文件夹也失败
```

### 原因

**harness 会用 header 里的 `id` + `cwd` 反推「这个会话应该在的路径」，再和实际路径比对。**

```
sessions/
  --root-deepseek-harness--/      ← 由 cwd 推出，不能改
    session-1aaf44ea-.../         ← 由 id 推出，不能改
      session.v4.jsonl.zstd
```

目录名是**结构的一部分**，不是随便起的。

### 三种方案实测

| 方案 | 结果 |
| --- | --- |
| **A** 改名改回来（`.disabled` → 原名） | ✅ `corrupt=0` `registry-pending=0` 正常启动 |
| **B** 搬到 `sessions/` 外面 | ✅ 正常启动 |
| **C** 原地不动 | ✅ 正常 |

**A 和 B 都能修，但 B 是正确做法。**

### 改法

`dsh-doctor` 的空会话建议从「改名」改成「搬出 `sessions/`」：

```bash
mkdir -p /root/.dsh/_quarantine
mv \
  "/root/.dsh/sessions/--root-deepseek-harness--/session-1aaf44ea-..." \
  "/root/.dsh/sessions/--root-deepseek-harness--/session-9f36469e-..." \
  /root/.dsh/_quarantine/
```

并且明确写了警告：

> ⚠️ 不要原地改名！harness 会用 header 里的 id + cwd 反推「应该在的路径」，
> 路径对不上就判 corrupt，连带把 workspaceRegistry 拖挂。

### 教训

**工具给出的「修复建议」本身可能造成比原问题更严重的损坏。**

以后凡是涉及改路径、改文件名的建议，都得先想清楚**谁会拿这个路径去校验**。

## 2.0.8 — 2026-10-24

**一键安装一直 404 —— v2.0.7 我忘了传附件。**

### 问题

```sh
URL="https://github.com/.../releases/download/v2.0.7/dsh-tools-2.0.7.tar.gz"
```

这个地址 404，因为 **v2.0.7 的 Release 只创建了、没有上传附件**。

发版脚本里上传那段漏掉了：

```python
call(.../releases, 'POST', {...})     # 建了 Release
subprocess.run(['tar','-czf', ...])   # 打了包
# ← 从来没有上传
```

对比前几个版本：

```
v2.0.4  dsh-tools-2.0.4.tar.gz  361888
v2.0.5  dsh-tools-2.0.5.tar.gz  362922
v2.0.6  dsh-tools-2.0.6.tar.gz  366000
v2.0.7  ❌ 没有附件
```

### 改法

**① 补传 v2.0.7 的附件**（老链接也能用了）

**② `install-online.sh` 加自动回退**

```
先试 Release 附件
   ↓ 404
改用仓库快照 codeload
   ↓
解压 → 找 dsh-tools-* 目录 → 跑 install.sh
```

**这样以后哪个版本忘了传附件，一键安装也不会死。**

实测（正好赶上 v2.0.7 没附件）：

```console
🔍 查最新版本...
   版本: v2.0.7
⬇️  下载...
⚠️  Release 附件拿不到（.../v2.0.7/dsh-tools-2.0.7.tar.gz）
   改用仓库快照...
📂 安装...

📦 dsh-tools 2.0.7
   ✅ /usr/local/bin/dsh-backup
   ✅ /usr/local/bin/dsh-restore
   ...（9 个全装上）
```

### 教训

**发版是个多步流程，漏一步不会报错、只会静默少东西。**

**以后发版后必须验证：**

```bash
curl -s https://api.github.com/repos/OWNER/REPO/releases/latest \
  | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['tag_name'], [a['name'] for a in d['assets']])"
```

**附件列表为空就是漏了。**

## 2.0.7 — 2026-10-24

**`dsh-doctor` 会把已经手工移出的会话又算一遍。**

### 现象

按提示把空会话改名成 `xxx.disabled` 之后：

```console
空会话:     ⚠️  4 个
   --root-deepseek-harness--/session-9f36469e-....disabled/session.v4.jsonl.zstd
   ...

处理：复制执行：
   for d in \
     ".../session-9f36469e-....disabled" \
   ; do mv "$d" "$d.disabled"; done        ← 会变成 .disabled.disabled
```

**改名没生效，而且建议的命令会把目录改成 `xxx.disabled.disabled`。**

### 原因

扫描用的是 `glob('**/session.v*.jsonl.zstd')`，**不区分目录名**。
`.disabled` 目录里的会话照旧被扫进来。

### 改法

扫描前先过滤：**路径里任何一段以 `.disabled` / `.deleted` 结尾的，跳过。**

```python
def _active(path):
    for p in path.split(os.sep):
        if p.endswith('.disabled') or p.endswith('.deleted'):
            return False
    return True
```

### 顺带

- 建议命令加了 `case` 判断，已经有 `.disabled` 后缀的不会再叠一层
- 「工作区索引」那栏的 `索引有、磁盘没有` 就是这些移出的会话，属于预期，不用管

## 2.0.6 — 2026-10-24

**加了「空会话」检测 —— 这类会话会让应用报错，但之前工具看不见。**

### 现象

`dsh-doctor` 全绿：

```console
  seq 断档:   ✅ 0
  帧布局:     ✅ 全部合法
✅ 没发现「确定的问题」
```

但应用打开时仍报：

```
stored session "session-9f36469e-..." is corrupt:
corrupt Zstandard session log: complete frame contains a torn JSONL record
```

### 原因

这类会话是「**点开新对话、一句话没说就关了**」留下的：

```
session → permission/preset(0) → sandbox/mode(1) → approval/policy(2)
```

**4 行，没有对话，也没有 session/end-seed。**

harness 读它时 `restore.decodeRow` 语义校验失败 → `committedBytes` 走不到末尾
→ 报「torn JSONL record」。

**内容本身是完整的**（帧对、JSON 能解析、seq 连续）——
所以我的字节级检查一个都抓不到。

### 改法

新增判定：**既没有对话事件、也没有 `session/end-seed`** → 空会话。

实测这条判定很准（13 个会话）：

| 会话 | 对话 | end-seed | 判定 |
| --- | --- | --- | --- |
| 9441bf7c | 有 | 有 | ✅ |
| 1aaf44ea | 无 | 无 | ⚠️ 空会话 |
| 4c9a6fea | 无 | 有 | ✅ |
| 9f36469e | 无 | 无 | ⚠️ 空会话 |
| a1bae420 | 无 | 无 | ⚠️ 空会话 |
| b62febf2 | 无 | 无 | ⚠️ 空会话 |
| c1b8dce0 | 有 | 无 | ✅ |
| fb1c1d2b | 无 | 有 | ✅ |

**有对话的，即使没 end-seed 也没问题。**

### 输出

```console
  空会话:     ⚠️  4 个（只有预设、没有对话、没正常结束）
```

并且**直接生成能复制执行的清理命令**（改名而不是删除，能反悔）：

```console
       处理：改名就等于让它们从列表消失，还能反悔。
       先停 Web，再复制执行：

         for d in \
           "/root/.dsh/sessions/--root-deepseek-harness--/session-1aaf44ea-..." \
           "/root/.dsh/sessions/--root-deepseek-harness--/session-9f36469e-..." \
           ... \
         ; do mv "$d" "$d.disabled"; done
```

### 局限

**工具仍然无法 100% 复现 harness 的语义校验**（`decodeRow` 那些规则）。

它现在能抓到的是「已知会导致失败的形态」。真遇到新的失败方式，
还是只能靠应用报的错。

## 2.0.5 — 2026-10-24

**`dsh-reindex` 的「Web 在跑」检测有两个 bug。**

### ① awk 引号不配对 → 检测直接失效

```sh
awk '... {print $1" "$2" "$3" "$4" "$5" "$6" "$7" }'
```

末尾那个 `" }` 引号不配对，awk 报：

```
awk: line 1: runaway string constant " } ...
```

**结果 `WEB_PROCS` 是空的，检测永远不触发。** 现在改成 `printf`：

```sh
awk '... {printf "%s  %s %s %s %s\n", $1, $3, $4, $5, $6}'
```

### ② 只说「检测到在运行」，不给证据

用户没法判断是真的还是误报。现在**把进程打出来**：

```console
⚠️  检测到 DSH Web 进程还在跑：
     23790  /usr/local/lib/node_modules/@deepseek-ai/dsh/lib/bin.js web --no-open --host
⚠️  
⚠️  workspace.json 是应用在管的，带 Web 改会被它覆盖回去。
⚠️  请先在应用里 停止 Web（或结束上面那个进程），再跑 dsh-reindex --fix
⚠️  
⚠️  如果你确认那个进程跟本设备无关、或者已经停住了：
⚠️    dsh-reindex --fix --i-know
```

**顺带把匹配收紧到「可执行文件就是 node」的那些行** —— proot 包装进程的命令行里
也会带 `bin.js web` 字样，但它不是 web 服务本身，匹配上会打出一大坨无用信息。

### 关于「界面关了但进程还在」

这是**真的会发生的**：在应用里点「停止」，node 进程不一定马上退出。

所以判断「Web 在不在跑」不能看界面，得看进程。现在能看到是哪个 pid 了。

## 2.0.4 — 2026-10-24

**`dsh-reindex` 的汇总自相矛盾。**

### 现象

```console
⚠️  --root-deepseek-harness-- 下有 12 个会话，但 workspace.json 里没有对应工作区
    （key 没法反推路径，去应用里打开一次那个目录就会自动建）

✅ 索引和磁盘一致
```

**上面说有问题，下面说一致。**

### 原因

`CHANGES` 只统计**能自动修**的那一类（索引缺会话）。
而「没有对应工作区」和「索引指向缺失文件」是**只报告、不计入**的。

于是只有这两类问题时 `CHANGES == 0` → 走到「✅ 索引和磁盘一致」。

### 改法

**分类统计，汇总如实说。**

```console
⚠️  没有能自动修的项，但有 23 处需要你处理：
   · 12 个会话所在的目录在 workspace.json 里没有对应工作区
   · 11 个索引项指向不存在的会话文件

工作区缺的那种，去应用里打开一次那个目录，应用会自己建。
建好之后再跑一次 dsh-reindex --fix。
```

**单位也对齐了** —— 以前上面写「11 个」、下面写「1 个」，
因为一个数路径、一个数条目。

### 三种情况实测

| 场景 | 输出 | 退出码 |
| --- | --- | --- |
| 完全对齐 | `✅ 索引和磁盘一致` | 0 |
| 索引缺会话 | `需要对齐 1 处…执行 dsh-reindex --fix` | 1 |
| 只有无法自动修的 | `⚠️ 没有能自动修的项，但有 N 处需要你处理` | 1 |

`--fix` 之后自动复查也是对的。

## 2.0.3 — 2026-10-24

**修一个误报：正在写入的会话被判「seq 断档」。**

### 现象

```console
$ dsh-doctor
  seq 断档:   ⚠️  1 个
     --root-deepseek-harness--/session-1d500e2a-.../session.v4.jsonl.zstd
```

但 `dsh-repair --check` 对同一个文件说：

```console
  ✅ session-1d500e2a-...   16612 行，连续
```

### 原因

**那个会话就是当前正在用的这个，文件一直在追加。**

`dsh-doctor` 扫到一半时，最后那个帧只写了半条记录 —— 这是**正常的进行态**，
不是损坏。而 seq 检查看到「最后一条不连续」就报了断档。

`dsh-repair` 跑得晚一点，读到的已经是完整状态，所以判定连续。

### 改法

**跳过 120 秒内被改过的会话**，并单独列出来：

```console
  会话（13 个）
    seq 断档:   ✅ 0
    帧布局:     ✅ 全部合法
    正在写入:   1 个（120 秒内改过，已跳过判定）
```

**不判它、也不假装它没问题** —— 就明说「这个被跳过了，因为它正在写」。

### 实测

造一个真断档（非活跃文件）验证检测没被削弱：

```console
$ dsh-doctor
  seq 断档:   ⚠️  1 个

$ dsh-repair
  ✅ 修好：1 处断档，50 个 seq 前移

$ dsh-doctor
  seq 断档:   ✅ 0
```

## 2.0.2 — 2026-10-24

**`dsh-repair` 是最后一个还在依赖 `zstd` 命令、并且还在写单帧的工具。**

### 问题

```sh
command -v zstd >/dev/null 2>&1 || die "需要 zstd。先装: apt-get install -y zstd"
...
' 2>"$tmp.stat" | zstd -q -f -o "$tmp" -
```

两件事同时错：

1. **要求 `zstd` 命令**，而它在有的环境里装不上
   （`apt-get install zstd` → `E: Unable to locate package zstd`）
2. **`zstd -o` 只出一个帧** → 会话被判损坏、静默跳过

### 改法

整个重写成 Python（`libzstd` + ctypes）：

- 不再需要 `zstd` 命令
- 写回时首帧只装 header 行、正文另起一帧
- 自检：解回来必须一致、首帧必须一行，否则不动原文件
- 顺带识别「帧布局不对」，不只是 seq 断档

实测：

```console
$ dsh-repair --check
  ⚠️  s1   1 处断档
      首个断点: seq 7 → 108

$ dsh-repair
      ✅ 修好：1 处断档，100 个 seq 前移（原件存为 .before-repair）

验证：11 条事件全保留  seq 1..11 连续  2 帧 首帧一行 ✅
```

### `dsh-backup` 也去掉了 `zstd` 依赖

`--check` 里的事件类型检查和 seq 检查改用 `libzstd`。

### 全量审计结果

| 工具 | 依赖 zstd 命令 |
| --- | --- |
| `dsh-backup` | ✅ 不依赖 |
| `dsh-restore` | ✅ |
| `dsh-repair` | ✅ |
| `dsh-strip` | ✅ |
| `dsh-reframe` | ✅ |
| `dsh-doctor` | ✅ |
| `dsh-events` | ✅ |
| `dsh-recover` | ✅ |
| `dsh-reindex` | ✅ |

**9 个工具全部只依赖 `python3` + `libzstd`。**

### 如果你之前被卡住

```bash
# 不用再装 zstd，直接升工具
dsh-install        # 或者用 release 包重装
```

装完 `dsh-repair` 就能跑了。

## 2.0.1 — 2026-10-24

**审查仓库里另外两个工具的切帧逻辑，修了两处。**

### ① `dsh-recover` 依赖 `zstd` 命令

```sh
have zstd || die "需要 zstd"
```

这个环境里 `zstd` 已被移除，它直接退出。改成用 `libzstd` + ctypes。

### ② `dsh-strip` 丢掉了 `--mark`

`dsh-recover` 靠 `dsh-strip --mark` 打 `ignorable` 标记，并且会先检查：

```sh
if ! dsh-strip --help | grep -q -- "--mark"; then
  die "dsh-strip 太旧，不支持 --mark。"
fi
```

2.0.0 把 `dsh-strip` 重写成 Python 时**漏了 `--mark`** —— 等于把 `dsh-recover` 弄瘸了。

**`--mark` 才是正确做法。** harness 的判定是：

```js
if (!KNOWN_SESSION_EVENT_TYPES.has(event.type) && event.ignorable !== true)
  throw unsupported(...)
```

给事件加 `"ignorable": true` 即可放行 —— **不删行、不动 seq**。

而 1.5.x 那种「删除 + 重排 seq」会让应用内部计数器失配，
之后它继续写又留下断档，会话再次从列表消失。

**所以 `dsh-strip` 现在默认推荐 `--mark`，删除模式降为兜底。**

实测：

```console
$ dsh-strip --mark s.zstd job/registered
🔖 打 ignorable 标记: job/registered
  共 10 行，打标 3 条，seq 一个没动

✅ 完成: s.zstd.stripped
   首帧一行 ✅  seq 未改动 ✅

验证：行数 10 → 10（一行没少）  seq 完全没动  3 条带 ignorable ✅
```

### ③ `dsh-doctor` 加了工作区索引检查

会话列表读的是 `workspace.json` 里的 `sessionIds`，**不是扫目录**。
索引缺了 → 文件在、列表空。这是帧布局之外的**第二个独立原因**。

```console
工作区索引:
             ⚠️  --root-deepseek-harness-- 下有 12 个会话，但 workspace.json 里没有对应工作区
```

### 审查结论

| 工具 | 写会话吗 | 切帧正确吗 |
| --- | --- | --- |
| `dsh-recover` | ✅ 间接（调 `dsh-strip --mark`） | ✅ 交给 `dsh-strip` |
| `dsh-reindex` | ❌ 只写 JSON | **不涉及** |

### 现在 9 个工具

`dsh-backup` / `dsh-restore` / `dsh-repair` / `dsh-strip` / `dsh-reframe` /
`dsh-doctor` / `dsh-events` / `dsh-recover` / `dsh-reindex`

## 2.0.0 — 2026-10-24

**修一个我自己造成的严重问题：工具把会话文件写坏了。**

### 问题

`dsh-strip` 和 `dsh-doctor --fix` 重写会话时用的是

```sh
zstd -q -f -19 -o out.jsonl.zstd in.jsonl
```

**这个命令默认只产生一个帧。**

而 DSH 的读取器要求（`session-persistence-jsonl`）：

```js
function assertZstdHeaderFrame(plaintext) {
  if (plaintext.length === 0 || plaintext.indexOf(10) !== plaintext.length - 1)
    throw new Error("corrupt Zstandard session log: first frame is not exactly one header line");
}
```

**首帧必须恰好是一行。** 整份一个帧 → 判损坏 → **静默跳过**。

于是：文件在、大小对、`zstd -dc` 能解、JSON 能解析，但应用里就是看不到，
**也不报任何错**。

实测：`dsh-backup-20261023-19439` 之前的备份全是合法布局，
`1951` 那次的 11 个会话**全部变成单帧**（首帧最大 51 MB）——
中间的差别就是跑了一次 `dsh-doctor --fix`。

### 修法

**① 所有重写会话的地方改用正确切帧**

```python
frame1 = compress(header_line)     # 首帧只装一行
frame2 = compress(rest)            # 正文另起
```

`dsh-strip` 整个重写成 Python（用 `libzstd` + ctypes），不再依赖 `zstd` 命令。

**② 新增 `dsh-reframe`** —— 把坏布局重切回去

```bash
dsh-reframe              # 检查
dsh-reframe --fix        # 修
dsh-reframe --rollback   # 回退
```

实测把 `1951` 那个备份的 11 个会话全部救回，**内容字节级一致**：

```console
$ dsh-reframe --fix
  ✅ session-0df3b6aa... → 首帧 262B（一行）2 帧   754 行
  ✅ session-195e16fb... → 首帧 262B（一行）2 帧  1897 行
  ✅ session-1d500e2a... → 首帧 202B（一行）2 帧 16414 行
  ...
✅ 修好 11 个

比对 11 个，内容不一致 0 个 ✅
```

**③ `dsh-doctor` 内置帧布局检查**

```console
  会话（13 个）
    帧布局:     ✅ 全部合法
```

坏的时候：

```console
    帧布局:     ❌ 1 个首帧不是一行（应用会静默跳过）
                修: dsh-reframe --fix
```

**④ `dsh-doctor` 不再依赖 `zstd` 命令**

扫描段改用 `libzstd` + ctypes。（这个环境里 `zstd` 命令被移除了，
旧版会直接 `❌ 需要 zstd` 退出。）

### 另一条结论：版本降级完全不可行

- 日志**只往前兼容**。旧版读新版写的日志 → `unknown event` 或静默跳过
- 旧版写回去的是**旧格式**，新版再读又坏
- 来回折腾只会让数据越来越乱

**正确做法：升到写这份日志的版本。**

`dsh-strip` 只用来处理「某个已知类型把日志卡住」这一种情况，**不是降级手段**。

### 现在 7 个工具

`dsh-backup` / `dsh-restore` / `dsh-repair` / `dsh-strip` / `dsh-reframe` / `dsh-doctor` / `dsh-events`

## 1.8.0 — 2026-10-24

**找到「还原完了但一个会话都看不到」的真正原因：不是文件，是索引。**

### 根因

应用的对话列表读的是 **`~/.dsh/storages/workspace.json` 里的 `sessionIds`**，
**不是扫目录**。

实测一台机器的状态：

```
磁盘上实际有:    11 个会话
workspace.json:   只登记了 4 个
                 ─────────────
                 7 个「文件在、列表空」
```

而 `dsh-restore` 默认**不还原 `workspace.json`**（当时把它归为「状态文件，
覆盖会弄坏新环境」）。所以：

```
还原 → 会话文件都搬过去了 ✅
     → 索引里没有它们   ❌
     → 应用列表空
```

**这也解释了「重开工作台会话消失」** —— 索引被重置，列表就空了，
哪怕磁盘上一个文件都没少。

### 新增 `dsh-reindex`

```bash
dsh-reindex            # 只报告：磁盘几个、索引几个、差哪些
dsh-reindex --fix      # 补进索引（要先停 Web）
```

**输出：**

```console
🗂  dsh-reindex 1.8.0

  ⚠️  /root/deepseek-harness    磁盘有、索引缺 7 个（索引 4）

需要对齐。执行：
  dsh-reindex --fix
```

**`--fix` 做三件事：**

1. 把磁盘上缺的会话 ID 追加到 `workspace.json`
2. 原文件存成 `workspace.json.before-reindex`
3. 已有的条目一条不动

**沙盒实测：**

```
补之前: sessionIds: ["session-aaa"]
补之后: sessionIds: ["session-aaa", "session-bbb"]
```

### 设计上的两个保守点

**① 路径只做正向映射**

```
/root/deepseek-harness  →  --root-deepseek-harness--
```

反过来推不行 —— 路径里的 `-` 和分隔符 `-` 分不清。
所以磁盘上有会话、但 `workspace.json` 里没有对应工作区时，**只报告不编造**。

**② 索引里有、磁盘没有的，也只报告不删**

### `dsh-restore` 的结束提示改了

现在会明确说：

```
⚠️  对话列表是空的？那多半是索引没跟上

   应用读的是 ~/.dsh/storages/workspace.json 里的 sessionIds，
   不是扫目录。还原只搬了会话文件，索引里没有它们。

   修法（先停 Web）：
     dsh-reindex
     dsh-reindex --fix
```

### 现在 8 个工具

`dsh-backup` / `dsh-restore` / `dsh-repair` / `dsh-strip` / `dsh-doctor` /
`dsh-events` / `dsh-recover` / `dsh-reindex`

### 一个反思

前面几轮我一直在查「事件类型」「seq 断档」，那些都是真问题，**但都不是
「一个都看不到」的原因**。

索引这一层被我在设计 `dsh-restore` 时就排除掉了 —— 我把 `workspace.json`
当成「状态文件，不能覆盖」。**它确实是状态文件，但不等于不能合并。**

**排除得太干净，反而制造了新问题。**

## 1.7.0 — 2026-10-24

**新增 `dsh-recover`：一条命令修好被改坏的会话。**

### 它解决什么

1.5.x 的 `dsh-strip` 会「删事件 + 重排 seq」，和应用的内部计数器不同步，
剥完之后会话会从列表消失。

`dsh-recover` 把整个补救流程包成一个命令：

```bash
dsh-recover          # 只检查，列出哪个会话坏了、能不能救
dsh-recover --fix    # 真的修（要先停 Web）
```

### 它做什么

```console
$ dsh-recover
🩺 dsh-recover 1.7.0

会话根: /root/.dsh/sessions

⚠️  session-1d500e2a-79b4-44de-8a2c-e160929a1b39
    当前: 15996 条，seq 1..16135，断点 1
    ✅ 可恢复: before-doctor: 15894 条 seq 0..15893 断点 0 [完整]

──────────────────────────────────────
发现 1 个有问题的会话
其中 1 个能自动恢复
```

**它自动：**

1. 扫描所有会话，找 seq 断档的
2. 在 `.before-doctor` / `.before-repair` / `.before-strip` 里挑最完好的备份
3. 用备份覆盖 + 打 `ignorable` 标记（**不删行、不重排**）
4. 复查一遍，报告结果

**不用记路径，不用手写会话 ID。**

### 安全

- **默认只读** —— 不带 `--fix` 什么都不改
- `--fix` 前把当前文件存成 `*.before-recover`
- **检测到 Web 在跑会拒绝动手**（会话文件是活的）
- 备份本身不连续时，拒绝使用它

### 实测

```console
$ dsh-recover --fix --i-know
    ▸ session-aaaa-bbbb
       🏷  打 ignorable 标记（不删、不重排）: job/registered job/settled
         保留 16 行，其中打了标记 5 条（没删任何行，seq 没动）
       ✅ 16 条  seq 0..15  断点 0  打标记 5 条
✅ 成功 1 个
```

### `dsh-strip` 补了 `--help`

之前 `--help` 只打印一行用法，看不到有哪些选项。
现在有完整的说明，包括 `--mark` 的用途和风险对比。

### `dsh-doctor` 同步更新

## 1.6.0 — 2026-10-24

**重大修正：`dsh-strip` 之前用的方法会破坏日志。**

### 我做错了什么

1.5.x 的 `dsh-strip` 是：**删掉事件 → 重排 seq → 写回**。

结果有用户剥完 `job/registered` 之后，**整个会话从列表里消失了**。

查下来：

```
原始   15894 行  seq 0..15893  连续
剥离后 15754 行  seq 1..15754  连续
应用打开后继续写，它的计数器还停在 15894
→ 追加的事件从 15894 开始，中间空 140 个号
→ seq 不连续 → 应用判定 corrupt → 会话不显示
```

**我的重编号和应用内部的计数器不同步。**

### 真正的解法：harness 自带放行机制

翻 harness 源码，校验逻辑是这样的：

```js
if (!KNOWN_SESSION_EVENT_TYPES.has(event.type) && event.ignorable !== true)
  throw unsupported(`contains event type "${event.type}" unknown to this harness`)
```

**`ignorable: true` 就是官方留的标记 —— 打上它，harness 就跳过这个事件。**

**根本不需要删任何行。**

### 改成 `--mark`

```bash
dsh-strip --mark <文件> job/registered    # 打标记（安全，现在的默认）
dsh-strip <文件> job/registered           # 删+重排（旧行为，别再用）
```

**实测对比：**

| | 删+重排（1.5.x） | 打标记（1.6.0） |
| --- | --- | --- |
| 删行 | 删 140 行 | **一条没删** |
| seq | 重排 1..15754 | **完全不动** |
| 内容 | 少了 | 全在 |
| 应用是否接受 | ❌ 会 corrupt | ✅ 官方支持 |

```console
$ dsh-strip --mark orig.zstd job/registered job/settled
🏷  打 ignorable 标记（不删、不重排）: job/registered job/settled
   保留 15895 行，其中打了标记 279 条（没删任何行，seq 没动）

验证: 原始 seq 0..15893 / 处理后 seq 0..15893  完全一致 ✅
```

### `dsh-doctor` 默认改用标记

```bash
dsh-doctor --fix --strip-type job/registered --i-know    # 默认打标记
dsh-doctor --fix --strip-type job/registered --remove    # 才真删
```

### 已经剥坏的怎么救

如果用过 1.5.x 的 `dsh-strip`，原文件还在 `*.before-doctor`：

```bash
# 停 Web，然后用原件恢复 + 只打标记
cp -a "$S/session.v4.jsonl.zstd.before-doctor" "$S/session.v4.jsonl.zstd"
dsh-strip --mark "$S/session.v4.jsonl.zstd" job/registered job/settled
mv "$S/session.v4.jsonl.zstd.stripped" "$S/session.v4.jsonl.zstd"
```

### 教训

**我在没读 harness 源码的情况下自己发明了修复方案。**
应用不接受某个东西时，应该先找它自己的放行机制，而不是绕过校验。

## 1.5.1 — 2026-10-24

**修 `--strip-type` 的三个使用问题。**

### 起因

有用户照着文档敲：

```bash
dsh-doctor --fix --strip-typejob/registered" (seq 14511)
```

报 `bash: syntax error near unexpected token '('`。

两处错：

1. **`--strip-type` 后面漏了空格**
2. **把应用报错整段抄进来了** —— `"` 和 `(seq 14511)` 让 bash 崩了

**文档只给了占位符 `xxx`，没给完整示例**，这是我的问题。

### 改了什么

**① 漏空格 → 明确告诉正确写法**

```console
❌ 选项没写对：--strip-typejob/registered
   是不是 --strip-type 后面漏了空格？应该是：
     dsh-doctor --fix --strip-type '类型名'
   例如：
     dsh-doctor --fix --strip-type job/registered
```

**② 整段粘贴 → 自动清理，并说清用了什么**

```console
ℹ️  参数里有多余内容，只用了第一个词
   你给的: job/registered" (seq 14511)
   用的:   job/registered
   （事件类型名不含空格，所以不会误判）
```

事件类型名不会含空格，所以取第一个词是安全的。

**③ 修了一个逻辑 bug**

`--fix` 在「没发现确定的问题」时直接退出了，**根本没走到剥离**：

```sh
# 以前
if [ "$TOTAL_PROB" -eq 0 ]; then exit 0; fi

# 现在
if [ "$TOTAL_PROB" -eq 0 ] && [ -z "$STRIP_TYPE" ]; then exit 0; fi
```

用户明确指定了要剥某个类型，那本身就是要做的事。

**④ 顺手修**

`die()` 在参数解析阶段调用，但那时函数还没定义 → `die: not found`。
改成 `printf` + `exit`。

### 实测

```console
$ dsh-doctor --fix --strip-type 'job/registered" (seq 14511)' --i-know
ℹ️  参数里有多余内容，只用了第一个词
   用的:   job/registered
...
  ▸ 剥指定事件类型: job/registered
       s1
           保留 3 行，剥离 1 行，重排 seq 1..3
            残留指定类型: 0
✅ 修复完成

验证: job/registered 剥掉 ✅
```

### 文档也改了

不再用 `xxx` 这种占位符，直接给能跑的命令：

```bash
dsh-doctor --fix --strip-type job/registered --i-know
```

并说明：**只抄类型名，不要引号、不要 `(seq 14511)`。**

## 1.5.0 — 2026-10-24

**修 `dsh-doctor` 的假阴性 —— 它会报「没问题」，但会话其实读不了。**

### 问题

1.4.x 里的事件类型列表是**硬编码**的，按 0.2.1 的会话统计出来：

```sh
KNOWN_EVENTS="... job/registered job/settled ..."
```

而 0.2.0 **不认识** `job/registered`。于是：

```
日志有 job/registered → 查硬编码列表 → 有 → 「✅ 全部认识」
                     → 但应用（0.2.0）不认识 → 照样读不了
```

**假阴性。用户以为没事。**

### 改法

**新增 `dsh-events`** —— 从**已安装的 harness** 里读事件注册表：

```bash
dsh-events --count                       # 53
dsh-events --check job/registered        # 0=认识 1=不认识
```

权威来源是 harness 里的 `SessionEventMap` 接口声明。
`dsh-doctor` 现在用它，并在输出里标出来源：

```
事件表:     取自已安装的 harness（53 种）
```

读不到才退回内置参考列表，并明确标「结论可能不准」。

### 但还有一层更麻烦的

改完发现：核心表只有 52 种，而实际日志里有 3000 多条事件不在表里
（`deliverables/presented`、`session-log-deepseek/delivery-accepted`、
`web/deepseek-search-llm-request` ……）。**这些是插件产生的事件。**

所以：

| 做法 | 结果 |
| --- | --- |
| 硬编码列表 | 假阴性（0.2.0 上漏报） |
| harness 核心表 | 假阳性（插件事件被当成问题） |

**都不准。**

### 所以改成「诚实报告」

```console
✅ 没发现「确定的问题」（seq 断档 0，文件都能解开）

ℹ️  但有 3151 条非核心事件（上面列了类型）。
   工具**无法**判断这些会不会让应用读不了 —— 插件事件和
   新版本事件长得一样。

   如果你确实打不开某个会话，看应用报的错：
     contains event type "xxx" unknown to this harness
   把那个 xxx 交给：
     dsh-doctor --fix --strip-type xxx
```

**「非核心事件」不再计入问题数。** 工具只对**它能确定的事**下结论。

### `--fix` 的行为也收紧了

```bash
dsh-doctor --fix                      # 只修 seq 断档（安全）
dsh-doctor --fix --strip-type xxx     # 再剥掉你点名的那个
```

**不再自动剥「所有不认识的事件」** —— 那会误伤插件事件。
类型名从应用报错里抄，那才是真凭据。

### 实测

造了带 `job/registered` + seq 断档的会话：

```console
$ dsh-doctor --fix --strip-type job/registered --i-know
      s1
          保留 6 行，剥离 2 行，重排 seq 1..6
           残留指定类型: 0
✅ 修复完成

验证: job/registered 剥掉 ✅  seq 连续 ✅
```

### 现在 6 个工具

`dsh-backup` / `dsh-restore` / `dsh-repair` / `dsh-strip` / `dsh-doctor` / `dsh-events`

## 1.4.1 — 2026-10-23

**修安装后的用法提示。**

### 问题

装完只显示三个命令：

```console
用法：
   dsh-backup                  备份
   dsh-restore <包路径>         还原
   dsh-restore --help          看还原帮助
   dsh-repair --check          检查会话日志有没有断档
```

**`dsh-strip` 和 `dsh-doctor` 一个字没提** —— 用户根本不知道有这两个命令。

而且那段字符串本身还是坏的（`看还原帮助` 后面跨了行）。

### 改法

**① 列出全部，而且按实际装了哪些动态显示**

缺哪个就不显示哪个，不会指向不存在的命令。

**② 加了「出了事的顺序」**

不只列命令，还告诉用户什么时候用哪个：

```console
出了事的顺序：
   1. dsh-doctor          先看有没有问题
   2. dsh-doctor --fix    有就自动修
   3. dsh-doctor --rollback  修坏了回退
```

**③ 修了一个健壮性问题**

`install.sh` 有 `set -eu`，包里缺某个工具时 `cp` 失败会**让整个安装中止**。
现在改成跳过并提示：

```console
⏭  dsh-strip（包里没有，跳过）
```

### 现在的输出

```console
用法：
   dsh-backup                  备份到 /sdcard/Download/dsh-backup/
   dsh-doctor                  体检全部（安全，先跑这个）
   dsh-doctor --fix            有问题的自动修
   dsh-doctor --rollback       修坏了就回退
   dsh-restore <包路径>         还原
   dsh-repair --check          查会话日志有没有断档
   dsh-strip --list <文件>     看会话里有哪些事件类型
   dsh-strip <文件> <类型...>   剥掉不认识的事件类型

出了事的顺序：
   1. dsh-doctor          先看有没有问题
   2. dsh-doctor --fix    有就自动修
   3. dsh-doctor --rollback  修坏了回退

已装：dsh-backup dsh-restore dsh-repair dsh-strip dsh-doctor
```

### 测了三种情况

| 场景 | 结果 |
| --- | --- |
| 全部装上 | ✅ 8 条用法全列出 |
| 只有 backup + doctor | ✅ 只显示这两组 |
| 只有 backup | ✅ 不显示空标题 |

## 1.4.0 — 2026-10-23

**一条命令体检 + 自动修。**

以前要查四件事得跑四个命令，现在：

```bash
dsh-doctor
```

### 输出

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

**真机跑 5.6 秒。**

### 四种模式

```bash
dsh-doctor               # 只体检，不写任何东西（默认）
dsh-doctor --fix         # 自动修能修的
dsh-doctor --json        # 机器可读
dsh-doctor --rollback    # 一键回退
```

### 能自动修的

| 问题 | 工具 |
| --- | --- |
| seq 断档 | `dsh-repair` |
| 未知事件类型 | `dsh-strip` |

**格式变了、文件解不开 —— 只报告，不擅自动。**

### 安全模型

- 默认零写入
- `--fix` 前每个会话先存 `*.before-doctor`
- `--rollback` 一键回退
- **检测到 Web 在跑就拦下来**（会话文件是活的，边读边写）

### 实测

造了 4 个坏会话：

| 会话 | 问题 | 结果 |
| --- | --- | --- |
| `s-gap` | seq 断 100 | ✅ 修好，内容完好 |
| `s-both` | seq 断 50 + job 事件 | ✅ 修好 |
| `s-unknown` | 3 条未知类型 | ✅ 剥掉，其他保留 |
| `s-broken` | 完全解不开 | ✅ **没被改动** |

**关键验证：只剥目标类型** —— 剥 `brand/new/type` 时 `job/registered` 3 条完整保留。

### 修了两个 bug

**① `grep -c` 双零**

```sh
X=$(grep -c ... || echo 0)   # 变成 "0\n0"，[: Illegal number
```

**② `dsh-strip` 残留检查写死了类型**

原来硬编码 `job/registered|job/settled`，剥别的类型时误报「残留 3」。
改成用实际剥离的类型。

## 1.3.0 — 2026-10-23

**新增 `dsh-strip`，并补上格式检查的盲区。**

### 背景：日志是往前兼容、不往后兼容的

有人从 0.2.1 降回 0.2.0，打开旧对话时报：

```
failed to observe session "session-1d500e2a-...":
contains event type "job/registered" (seq 14511)
unknown to this harness and not marked ignorable;
refusing to interpret the log
— it was likely written by a newer harness
```

**0.2.1 加了一个事件类型 `job/registered`（后台任务登记）。
0.2.0 不认识它，而它没被标记成「可忽略」——于是整份日志被拒绝解释。**

**注意：不是跳过那一条，是整份拒读。**

### ① 新增 `dsh-strip`

```bash
dsh-strip --list session.v4.jsonl.zstd              # 看有哪些事件类型
dsh-strip --dry-run session.v4.jsonl.zstd job/registered job/settled
dsh-strip session.v4.jsonl.zstd job/registered job/settled
```

**做法**：删掉指定类型的事件，把剩下的 seq 重排成连续的，其它一行不动。

**实测（真实会话，15,176 行 / 14 MB）：**

```console
🔪 剥离: job/registered job/settled
   保留 15041 行，剥离 142 行，重排 seq 1..15040
      job/settled: 71 条
      job/registered: 71 条
🗜  压缩...

✅ 完成
   大小: 5269859 字节（原 14138834）
   残留指定类型: 0
```

**验证**：非 `job/*` 的事件数 **0 个不一致**，seq 连续 1..15040。

**⚠️ 必须停 Web 再操作** —— 会话文件是活的，边读边写。

### ② 补上格式检查的盲区

1.2.0 只查文件名里的 `v4`。**这次的坑不在文件名，在日志内部。**

`dsh-backup --check` 现在会解开最近改动的那个会话，扫一遍事件类型：

```console
  事件类型:
                 37 种 / 15192 条
                 ✅ 全部认识
```

遇到不认识的：

```console
  事件类型:
                 6 种 / 6 条
                 ⚠️  有不认识的类型:
                   brand/new/type（1 条）
                 降级后这个会话可能整份读不了 → 用 dsh-strip
```

### ③ `install.sh` 现在装 4 个工具

`dsh-backup` / `dsh-restore` / `dsh-repair` / `dsh-strip`

### 建议的解法顺序

1. **升回写这份日志的版本** —— 正统做法
2. 必须留在旧版本时，才用 `dsh-strip`

**剥掉事件是单向下坡，以后升回去还得再处理一次。**

## 1.2.0 — 2026-10-23

**加格式检测。官方关了 issue，这个工具得自己扛。**

### 背景

开发者没有任何修复计划，把 issue 全关了。也就是说：

- `ARCHIVE_LINK_ESCAPE` 不会修了
- 这套工具从「临时补丁」变成「唯一方案」
- **DSHA 每次更新，都得自己确认工具还能用**

### 最危险的东西：会话格式静默失效

DSHA 的会话文件叫 `session.v4.jsonl.zstd` —— `v4` 是格式版本。

如果哪天变成 `v5`，而我们照旧打包：

```
备份  → ✅ 看起来成功
恢复  → ✅ 看起来也成功
打开  → ❌ 应用读不了
```

**不会报错，这才是最麻烦的。**

所以加了主动检测：**不认识的格式直接停下，要越过得显式加 `--force`。**

### 三处改动

**① `dsh-backup` 打包前检查格式**

```console
⚠️  会话格式是 v5，但本工具只认识: v4
⚠️    DSHA 可能改了会话格式。照旧打包出来的备份，恢复后应用可能读不了。
❌ 已中止。确实要打包就加 --force
```

**② `dsh-restore` 还原前对比两边的格式**

```console
⚠️  格式不一致：包内 v4，现场 v5
⚠️    直接覆盖会让现场变成 v4，应用可能读不了。
❌ 已中止。确实要还原就加 --force
```

**③ 备份里记录环境信息**

新增 `ENVIRONMENT.json`：

```json
{
  "dsh_tools": "1.2.0",
  "dsha_version": "0.2.1-rc.2-20261022.2100-dsh0.2.1-rc.2",
  "session_format": "v4",
  "known_formats": "v4",
  "session_files": 9,
  "backup_format": 2
}
```

以后版本变了，一比就知道；出问题时也有据可查。

### 新增自检命令

```bash
dsh-backup --check
```

```console
🩺 dsh-tools 1.2.0 自检

  DSHA 目录:     /root/.dsh
  应用版本:      0.2.1-rc.2-20261022.2100-dsh0.2.1-rc.2
  会话格式:      v4  ✅ 已知
  会话文件数:    9

  依赖:
                 tar      ✅
                 zstd     ✅（可选）

  上次备份:      2026-10-23 05:30:11
                 dsh-backup-20261023-0530.tar.gz  72M

  ✅ 可以正常备份
```

**每次 DSHA 更新后跑一遍，几秒就知道工具还能不能用。**

### 实测

10 项全部通过：

| 场景 | 结果 |
| --- | --- |
| v4 → v4 正常 | ✅ |
| 包内 v5 | ✅ 中止，现场不动 |
| 格式不一致（v4 vs v5） | ✅ 中止，现场不动 |
| 备份遇 v5 | ✅ 中止 |
| `--force` 都能越过 | ✅ |
| `--check` | ✅ |

### 修了一个自己引入的 bug

`dsh-restore` 里调了 `warn()` 但没定义 —— 报 `warn: not found`。
测试时发现的，已补。

## 1.1.3 — 2026-10-23

**修 `dsh-restore` 用旧备份覆盖新数据的问题。**

### 现象

```
1. 某个会话日志有 seq 断档，打不开
2. dsh-repair 修好了（7.7 MB，断档被剔除）
3. dsh-restore 还原了一个「修复之前」的备份
4. 修复结果被 13.5 MB 的旧版覆盖，会话又打不开了
```

**数据没丢**（`sessions.before-restore` 里有），但用户不知道去哪找。

### 根因

`restore_dir` 里是这一行：

```sh
cp -a "$src/." "$dst/"     # 无条件覆盖
```

**它不判断哪边更新。** 备份是过去某一刻的快照，现场数据可能比它新
（修过会话、又聊了几句、补了几张图），一律覆盖就等于**倒退**。

### 改法

逐文件比 mtime：

```sh
if [ "$(stat -c %Y "$dst/$rel")" -gt "$(stat -c %Y "$src/$rel")" ]; then
  # 现场更新 → 跳过
fi
```

输出会明确告诉你跳过了什么：

```console
♻️  还原中...
   💾 已备份现有 sessions → sessions.before-restore
   ✅ sessions（写入 2，跳过 1 个比备份新的）
      跳过: W/sess-A/session.v4.jsonl.zstd
```

### 顺带加了两个开关

- `--force` —— 强制覆盖，不管修改时间
- `--dry-run` —— 只看会做什么，不实际写盘

### 实测

造了三个场景验证：

| 场景 | 结果 |
| --- | --- |
| 现场比备份新（A） | ✅ 跳过，保留修复版 |
| 现场比备份旧（B） | ✅ 用包里版本覆盖 |
| 现场没有（C） | ✅ 补上 |
| `--force` | ✅ 强制覆盖 |

`--dry-run` 也确认过：只打印计划，不创建任何目录。
## 1.1.2 — 2026-10-23

修 `dsh-repair` 两个 bug。

**① `zstd -o` 拒绝覆盖 `mktemp` 建的空文件**

```
zstd: /tmp/dsh-repair.eEfTxQ already exists; not overwritten
❌ 处理失败
```

`mktemp` 会先创建文件，`zstd -o` 默认不覆盖。加 `-f`。

**② `--check` 不接受路径参数**

```sh
case "${1:-}" in
  --check)   MODE="check" ;;   # $1 是 --check
  *)         TARGET="$1" ;;    # 永远走不到
esac
```

`dsh-repair --check /某个目录` 里那个目录被忽略，扫的是全部会话。

改成遍历所有参数：

```sh
for arg in "$@"; do
  case "$arg" in
    -h|--help) MODE="help" ;;
    --check)   MODE="check" ;;
    *)         [ -z "$TARGET" ] && TARGET="$arg" ;;
  esac
done
```

现在选项和路径可以任意顺序。

**实测：**

```
【修前】⚠️  14677 行，1 处断档  seq 14466 → 14619（断了 152）
【修】  ✅ 修好：1 处断档，152 个 seq 前移
【修后】✅  14677 行，连续
【完整性】修复前后解压都是 48,349,715 字节 ✅
```

## 1.1.1 — 2026-10-23

`dsh-backup` 现在会主动检查会话连续性。

**为什么加**：会话日志的 seq 断档，以前只有等用户打开那个会话、应用报
`stored session is corrupt` 才发现。备份时顺手查一遍更省事。

**输出：**

```
🩺 检查会话连续性...
   ⚠️  有会话日志断档（打开时会报 corrupt）:
      session-1d500e2a-79b4-44de-8a2c-e160929a1b39
        14620 行，1 处断档，首个: seq 14466 → 14619（断了 152 个）

   修法（重启 Web 之后执行）:
      dsh-repair
```

**全连续时：**

```
🩺 检查会话连续性...
   ✅ 7 个会话，seq 全部连续
```

**汇总也带一行：**

```
   会话: 全部连续 ✅
   会话: 1 个有断档 ⚠️（用 dsh-repair 修）
```

**没有 zstd 时跳过**，不影响备份本身：

```
   ⏭  跳过（没装 zstd 或 python3）
      想检查就装: apt-get install -y zstd
```

**耗时**：7 个会话共约 2 秒（最大那个 13 MB / 48 MB 解压后）。

---

**顺手修了个 bug**：大小显示成 `0`。

`/sdcard` 是 FUSE 挂载，`tar` 刚写完时 `stat` 可能还读到 0。
现在会重试最多 5 次，并改用字节数换算：

```
   大小: 59.1 MB（61945694 字节）
```

以前是 `du -h` → `59M`。
## 1.1.0 — 2026-10-23

新增 `dsh-repair` —— 修会话日志的 seq 断档。

**症状（应用里打开某个会话时）：**

```
stored session "session-xxx" is corrupt:
invalid committed event at line 14468:
released v2 row 14467 has seq gap (expected 14467, got 14619)
```

**调查过程：**

用 `zstd -dc` 解开日志，逐行查 `seq` 字段：

```
第 14468 行: {"type":"session/end-seed","seq":14466,"time":1792684329911}
第 14469 行: {"type":"tool/result",   "seq":14619,"time":1792726490423}
```

两侧时间差 **11.7 小时** —— 是一次「恢复会话」时 seq 计数器跳了，
中间 152 个事件写去了别处。

**这不是备份造成的问题** —— 源文件本身就是这样，`dsh-backup` 只是如实复制。

**做法：**

把断点之后的 `seq` 整体前移（14619 → 14467），让序列重新连续。
**内容一行不丢，只是重新编号。**

`sourceEventSeqs` 里指向断点之后的引用也同步平移。

**实测：**

```
原始: 14,576 行  seq 0~14713  1 处断档（14466 → 14619）
修复: 14,574 行  seq 0~14573  0 处断档 ✅
解压后大小: 两边都是 47,982,721 字节（内容完整）
```

**用法：**

```bash
dsh-repair --check      # 只检查
dsh-repair              # 修所有会话
dsh-repair <session 目录>  # 修指定的
```

原文件会存成 `.before-repair`。

**⚠️ 两个注意：**

1. **需要 zstd** —— `apt-get install -y zstd`
2. **别修正在使用的会话** —— 应用还在往里写，先重启 Web 或换台机器

## 1.0.7 — 2026-10-23

补上「文件在，但读不了」这个情况。

**症状**：`ls -l` 明明列出了文件（大小也对），还原却报
「读不出文件头 / Permission denied」。

**原因**：`/sdcard` 是 FUSE 挂载，带 SELinux 和 uid 限制。
环境里的 root **不是真 root** ——

```
ls -l   → 只需要目录读权限  →  ✅ 能列出
open()  → 要真正打开文件    →  ❌ 被拒
```

**改动：**

- `dsh-restore` 加主动检查：`[ -r "$PKG" ]` + 实际读一个字节
- `gzip -t` / `tar` 的报错里加 `Permission denied` 分支
- 错误信息直接给出两条出路：
  1. 设置 → 设备能力授权 → 打开文件访问
  2. `cp "$PKG" ~/ && dsh-restore ~/xxx.tar.gz`（绕开 /sdcard）

- 中英文 README 的「先查这三样」里，② 加了这个特例

## 1.0.6 — 2026-10-23

修一个我自己在 1.0.5 引入的 bug：**没装 `od` 的环境会误报「读不出文件头」**。

**原来的代码：**

```sh
MAGIC=$(od -An -tx1 -N2 "$PKG" 2>/dev/null | tr -d ' \n')
case "$MAGIC" in
  ...
  "")  die "读不出文件头（大小 $BYTES 字节）。文件可能是空的或被占用。" ;;
esac
```

`od` 不是每个环境都有。没有它的时候命令直接失败，`MAGIC` 是空的，
于是走了 `""` 分支 —— 用户看到的是「文件可能是空的或被占用」，
**但文件其实是好的**。

**改法：**

- 魔数检查改成**可选**：`command -v od` 有就查，没有就跳过
- **`gzip -t` 作为权威判断** —— 它不依赖任何额外工具
- 加了 `[ -r "$PKG" ]` 检查可读性
- `gzip -t` 失败时按报错分类给建议：
  - `not in gzip format` → 格式不对
  - `unexpected end of file` → 传输中断
  - 其它 → 把报错发给 AI

**实测（把 od 屏蔽掉模拟）：**

```
正常包 → 完整性 ✅ → 还原完成 ✅
坏包   → gzip: unexpected end of file → 「多半是传输中断，重新传一次」
```

## 1.0.5 — 2026-10-23

修 `dsh-restore` 的报错问题 —— **以前只会说「包可能损坏」，不说为什么**。

**原来的代码：**

```sh
tar -xzpf "$PKG" -C "$STAGE" 2>/dev/null || die "解压失败（包可能损坏）"
```

`2>/dev/null` 把 tar 的原始报错丢掉了。用户看到的只有一句笼统提示，
完全不知道该重传、该清空间、还是文件格式不对。

**现在分四步查，每步给具体原因：**

| 检查 | 失败时说什么 |
| --- | --- |
| 文件大小 | 「只有 N 字节，肯定没传完。重新传一次。」 |
| 魔数 | 「这不是 gzip 文件（魔数 504b = zip）。试试 unzip」 |
| gzip -t | 「包不完整。多半是传输中断，重新传一次。」+ **原始报错** |
| 磁盘空间 | 「解压要 N MB，/tmp 只剩 M MB」 |

**解压失败时也会打印 tar 的原始报错**，并且按错误类型给建议：

```
No space left  → 清一下 /tmp，或用 TMPDIR=... 重试
Cannot open    → 检查路径和权限
not in gzip    → 检查是不是改了格式
其它           → 把上面的报错发给 AI
```

**实测四种坏包：**

```
截断（30/59 MB）  → gzip: unexpected end of file → 「重新传一次」
zip 伪装          → 魔数 504b → 「试试 unzip」
空文件            → 「0 字节，肯定没传完」
不存在的文件      → 「找不到文件: /path」
```

正常还原的流程不变，实测 7 会话 / 85 附件 / 6 插件 / 5 表情包。

## 1.0.4 — 2026-10-22

新增「在新设备上报错？先查这三样」。

**这个建议来自一次真实迁移** —— 在新手机上还原时，报的是
`No such file or directory`，排查了半天才发现是**工具根本没装**：
旧手机装过，但新手机「清除数据」重建环境时把 `/usr/local/bin` 清空了。

所以文档里补了这一节，按顺序查三样：

**① 工具装了吗** —— `command -v dsh-restore` 有输出吗
　最常见的一个，报错长这样：`dsh-restore: not found`

**② 文件在不在** —— `ls -l /sdcard/Download/dsh-backup-*.tar.gz`
　顺带说明「文件管理器里的『手机存储』= 命令行里的 `/sdcard`」

**③ 目录名对得上吗** —— `ls ~/.dsh/sessions/`
　这是「还原成功了但看不到旧对话」的原因

最后附一张「报错 → 对号入座」表。

中英文同步。

顺手修了 README.md 两处标题层级错（`##` 应该是 `###`）。

## 1.0.3 — 2026-10-22

三件事：截图演示、英文文档、一键安装。

**① 截图演示**

`docs/backup-demo.png` 和 `docs/restore-demo.png` —— 把真实的命令输出
渲染成终端风格图片，放在 README 开头。

用 HTML + Playwright 渲染的（环境里没有 GUI 可以截），内容就是脚本的实际输出。

**② 英文文档**

`README.en.md`，和中文版互链。

**③ 一键安装**

```bash
curl -fsSL https://raw.githubusercontent.com/sb1145148/dsh-tools/main/install-online.sh | sh
```

`install-online.sh` 会自己查最新版、下载、解压、调用 `install.sh`、清理临时目录。
不用手动解压，不用管路径。

**没改 dsh-backup / dsh-restore。**

## 1.0.2 — 2026-10-22

README 重写，让不懂命令的人也能用。

**问题**：原来的文档假设读者会用命令行。但 DSHA 的用户面对的是聊天框，
不是终端 —— 你给他 `cd dsh-tools && sh install.sh`，他不知道在哪儿敲。

**改动**：

- 开头改成「把这段复制给 AI」—— 不用懂任何命令
- 补上「我下载好了，然后呢」三步走，每步都写了「你会看到什么」
- 补上「备份文件在哪」—— 用文件管理器的路径，不是命令行路径
- 补上「换新手机怎么用」的流程总览和「最容易做错的一步」
- 补上 8 条常见问题（找不到文件 / command not found / 看不到旧对话 等）
- 「为什么需要它」挪到后面 —— 先解决怎么用，再讲为什么
- 技术细节收进「命令行速查」，给懂的人看

**没改代码。**

## 1.0.1 — 2026-10-22

修两处代码问题（不影响功能，但确实是错的）：

- 删掉一个死变量 `removed=0` —— 它在 `| while read` 的子 shell 里
  永远累加不出去，实际没被用到
- 顺手把它改成有用的东西：剔除结果先写临时文件，再统计个数，
  现在会输出「共剔除 8 个逃逸软链」
- 删掉一句放错位置的注释（`# 回收站不备份` 落在了 `cp` 后面，
  实际逻辑在下面排除 `.sessions-trash` 那一行）

## 1.0.0 — 2026-10-22

首个版本。

- `dsh-backup`：打包会话、附件、插件、表情包、配置到 `/sdcard/Download/dsh-backup/`
- `dsh-restore`：还原纯数据，跳过状态文件，覆盖前自动备份
- 自动剔除指向归档根之外的软链（绕开 `ARCHIVE_LINK_ESCAPE`）
- `install.sh`：支持 `--prefix`，覆盖旧版时自动留 `.old`
