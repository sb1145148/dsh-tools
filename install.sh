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

for f in dsh-backup dsh-restore dsh-repair dsh-strip; do
  if [ -e "$PREFIX/$f" ]; then
    mv "$PREFIX/$f" "$PREFIX/$f.old"
    say "   💾 旧版存为 $f.old"
  fi
  cp "$HERE/bin/$f" "$PREFIX/$f"
  chmod 755 "$PREFIX/$f"
  say "   ✅ $PREFIX/$f"
done

say ""
case ":$PATH:" in
  *":$PREFIX:"*) say "✅ 已在 PATH 里，直接敲 dsh-backup 就行" ;;
  *)             say "⚠️  $PREFIX 不在 PATH 里，加到 ~/.bashrc："
                 say "    export PATH=\"$PREFIX:\$PATH\"" ;;
esac
say ""
say "用法："
say "   dsh-backup                  备份"
say "   dsh-restore <包路径>         还原"
say "   dsh-restore --help          看还原帮助
   dsh-repair --check          检查会话日志有没有断档"
