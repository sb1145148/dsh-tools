# dsh-tools for Windows

一条命令包住 dsh-tools 的全部子命令，让它在 **Windows + Git for Windows** 上跑起来。

```
windows/
├── dsh-tools.ps1         # 入口（PowerShell）
├── run-dsh-tool.sh       # bash 侧：配 PATH / 备份目录
├── patch-dsh-tools.py    # 给 ../bin 打 Windows 补丁，产物进 bin/ 和 shim/
├── bin/                  # 生成物（补丁后的脚本，不手改）
└── shim/python3          # 生成物（指向 DSH 自带 Python）
```

## 为什么需要适配

dsh-tools 原本面向 Android/Termux，有三处硬编码：

| 问题 | 表现 | 这里怎么改 |
| --- | --- | --- |
| `OUT_DIR="/sdcard/Download"` | 备份写入不存在的位置 | 改成 `${DSH_BACKUP_DIR:-$HOME/dsh-backups}` |
| `libzstd.so.1` 的 Linux 路径 | 帧布局检查报「读不到 libzstd」 | 候选里加入 Git 自带的 `libzstd.dll` |
| 脚本按 `python3` 调用 | Windows 上通常没有这个命令 | 生成 `shim/python3` 指向 DSH 自带 Python |

脚本本身是 POSIX shell + 内嵌 Python，所以只要有 bash 就能跑，不需要重写。

## 准备

需要两样东西：

1. **Git for Windows**（提供 `bash`、`tar`、`find`、`sed`，以及 `libzstd.dll`）
2. **Python**（DSH 自带的就够，`~/.dsh/dsh-runtimes/*/dependencies/python/python.exe`）

## 安装

```powershell
# 1) 生成补丁后的脚本和 python3 shim
python windows\patch-dsh-tools.py
#    找不到 Python 时手动指定：
#    python windows\patch-dsh-tools.py --python "C:/Users/你/.dsh/dsh-runtimes/xxx/dependencies/python/python.exe"

# 2) 给 shim 和 runner 加可执行位（Git Bash 里做）
bash -c "chmod +x windows/shim/python3 windows/run-dsh-tool.sh"
```

## 用法

```powershell
.\windows\dsh-tools.ps1 list              # 列子命令
.\windows\dsh-tools.ps1 doctor            # 体检
.\windows\dsh-tools.ps1 doctor --json     # 机器可读
.\windows\dsh-tools.ps1 backup            # 打包到 DSH_BACKUP_DIR
.\windows\dsh-tools.ps1 events            # 看会话事件
.\windows\dsh-tools.ps1 relink            # 硬链接去重
.\windows\dsh-tools.ps1 restore D:\Backup\dsh-backups\dsh-backup-xxxx.tar.gz
```

备份目录默认是 `$HOME/dsh-backups`（Git Bash 视角）。想换：

```powershell
$env:DSH_BACKUP_DIR = '/d/Backup/dsh-backups'
```

## 实测结果（Windows 11 + Git 2.51 + Python 3.12）

```
🩺 dsh-doctor 2.0.9
   会话（26 个） 格式: v4 ✅   seq 断档: 0 ✅
   帧布局: ✅ 全部合法            ← libzstd.dll 生效
   备份   最近备份: ✅ 0 天前

📦 dsh-tools backup
   收集 5 个目录 / 剔除 0 个逃逸软链 / 26 会话 seq 全部连续
   ✅ dsh-backup-20261107-0012.tar.gz  339.5 MB  1207 条目
```

## 已知限制

| 项 | 状态 | 说明 |
| --- | --- | --- |
| 事件表 | ❌ 不可用 | 需要额外索引，`dsh-reindex` 之后再试 |
| 工作区索引 | ⚠️ 可能报错 | 应用重置 `workspace.json` 后会出现，跑 `reindex` |
| 空会话判定 | ⚠️ 有误报可能 | 刚重装、历史被迁移时会多报 |

## 安全说明

- **补丁只改副本**：`../bin` 原文件不动，升级后重跑 `patch-dsh-tools.py` 即可
- `dsh-doctor --fix` 会**先停 Web 服务**再动会话文件，会中断正在运行的对话
- 备份包默认包含 attachments，体积较大（本例 339 MB）

## 许可

与原仓库一致（MIT）。
