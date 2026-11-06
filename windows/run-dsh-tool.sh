#!/bin/sh
# windows/run-dsh-tool.sh —— bash 侧入口
# 由 windows/dsh-tools.ps1 调用：负责配好 PATH 和备份目录，再转交真正的脚本。
#
# 不写死任何绝对路径：HERE 就是本脚本所在目录。

HERE=$(cd "$(dirname "$0")" && pwd)

# python3 shim（指向 DSH 自带 Python）、补丁后的 bin、Git 的 mingw64（libzstd.dll）
export PATH="$HERE/shim:$HERE/bin:/c/Program Files/Git/mingw64/bin:/usr/bin:/bin:$PATH"

# Windows 上没有 /sdcard，默认放到 $HOME/dsh-backups
export DSH_BACKUP_DIR="${DSH_BACKUP_DIR:-$HOME/dsh-backups}"
mkdir -p "$DSH_BACKUP_DIR" 2>/dev/null

cmd="$1"
shift

if [ -z "$cmd" ]; then
  echo "用法: run-dsh-tool.sh <子命令> [参数...]" >&2
  echo "子命令: $(ls "$HERE/bin" | tr '\n' ' ')" >&2
  exit 2
fi

if [ ! -f "$HERE/bin/$cmd" ]; then
  echo "没有这个子命令: $cmd" >&2
  echo "可用: $(ls "$HERE/bin" | tr '\n' ' ')" >&2
  exit 2
fi

exec sh "$HERE/bin/$cmd" "$@"
