#!/bin/sh
# ============================================================
#  dsh-tools 安装脚本
#
#  用法:  sh install.sh                    装到 /usr/local/bin
#         sh install.sh --prefix ~/bin    装到别处
# ============================================================
set -eu

PREFIX="/usr/local/bin"
if [ "${1:-}" = "--prefix" ]; then
  PREFIX="${2:-}"
  [ -n "$PREFIX" ] || { echo "❌ --prefix 后面要跟目录" >&2; exit 1; }
fi

HERE=$(cd "$(dirname "$0")" && pwd)
VER=$(cat "$HERE/VERSION" 2>/dev/null || echo "?")

say() { printf '%s\n' "$*"; }

say "📦 dsh-tools $VER"
say "   安装到: $PREFIX"
say ""

mkdir -p "$PREFIX" 2>/dev/null || true
[ -w "$PREFIX" ] || { say "❌ $PREFIX 不可写。加 sudo，或换 --prefix ~/bin"; exit 1; }

INSTALLED=""
for f in dsh-backup dsh-restore dsh-repair dsh-strip dsh-doctor dsh-events dsh-recover; do
  # 包里缺这个就跳过，不要整个安装挂掉
  if [ ! -f "$HERE/bin/$f" ]; then
    say "   ⏭  $f（包里没有，跳过）"
    continue
  fi
  if [ -e "$PREFIX/$f" ]; then
    mv "$PREFIX/$f" "$PREFIX/$f.old"
    say "   💾 旧版存为 $f.old"
  fi
  cp "$HERE/bin/$f" "$PREFIX/$f"
  chmod 755 "$PREFIX/$f"
  INSTALLED="$INSTALLED $f"
  say "   ✅ $PREFIX/$f"
done

say ""
case ":$PATH:" in
  *":$PREFIX:"*) say "✅ 已在 PATH 里，直接敲 dsh-backup 就行" ;;
  *)             say "⚠️  $PREFIX 不在 PATH 里，加到 ~/.bashrc："
                 say "    export PATH=\"$PREFIX:\$PATH\"" ;;
esac
# 只提示实际装上的工具 —— 少装一个也不会指向不存在的命令
has() { case " $INSTALLED " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }

say ""
say "用法："
if has dsh-backup; then
  say "   dsh-backup                  备份到 /sdcard/Download/dsh-backup/"
fi
if has dsh-doctor; then
  say "   dsh-doctor                  体检全部（安全，先跑这个）"
  say "   dsh-doctor --fix            有问题的自动修"
  say "   dsh-doctor --rollback       修坏了就回退"
fi
if has dsh-restore; then
  say "   dsh-restore <包路径>         还原"
fi
if has dsh-repair; then
  say "   dsh-repair --check          查会话日志有没有断档"
fi
if has dsh-strip; then
  say "   dsh-strip --list <文件>     看会话里有哪些事件类型"
  say "   dsh-strip <文件> <类型...>   剥掉不认识的事件类型"
fi
if has dsh-events; then
  say "   dsh-events                  当前 harness 认识哪些事件类型"
fi

if has dsh-doctor; then
  say ""
  say "出了事的顺序："
  say "   1. dsh-doctor          先看有没有问题"
  say "   2. dsh-doctor --fix    有就自动修"
  say "   3. dsh-doctor --rollback  修坏了回退"
fi

say ""
say "已装：$(printf '%s' "$INSTALLED" | sed 's/^ *//')"
