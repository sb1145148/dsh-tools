# 更新日志

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
