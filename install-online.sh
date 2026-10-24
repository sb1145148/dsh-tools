#!/bin/sh
# ============================================================
#  dsh-tools 一键安装
#
#  用法:
#    curl -fsSL https://raw.githubusercontent.com/sb1145148/dsh-tools/main/install-online.sh | sh
#
#  它会：查最新版本 → 下载 → 解压到临时目录 → 跑 install.sh → 清理
#
#  下载有两条路（自动回退）：
#    ① Release 附件 dsh-tools-<ver>.tar.gz
#    ② 拿不到就退回仓库快照 codeload 的 tar.gz
# ============================================================
set -eu

REPO="sb1145148/dsh-tools"
API="https://api.github.com/repos/$REPO/releases/latest"

say() { printf '%s\n' "$*"; }
warn() { printf '⚠️  %s\n' "$*" >&2; }
die() { printf '❌ %s\n' "$*" >&2; exit 1; }

command -v curl >/dev/null 2>&1 || die "需要 curl"
command -v tar  >/dev/null 2>&1 || die "需要 tar"

say "🔍 查最新版本..."
JSON=$(curl -fsSL "$API" 2>/dev/null) || die "连不上 GitHub API（$API）"

TAG=$(printf '%s' "$JSON" | grep -o '"tag_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
[ -n "$TAG" ] || die "解析不到版本号。API 返回的前 200 字节：
$(printf '%s' "$JSON" | head -c 200)"
VER=${TAG#v}
say "   版本: $TAG"

TMP=$(mktemp -d "${TMPDIR:-/tmp}/dsh-tools-inst.XXXXXX")
trap 'rm -rf "$TMP"' EXIT INT TERM

PKG_URL="https://github.com/$REPO/releases/download/$TAG/dsh-tools-$VER.tar.gz"
SNAP_URL="https://codeload.github.com/$REPO/tar.gz/refs/tags/$TAG"

say "⬇️  下载..."
if curl -fsSL "$PKG_URL" -o "$TMP/pkg.tar.gz" 2>/dev/null; then
  say "   来自 Release 附件"
  tar -xzf "$TMP/pkg.tar.gz" -C "$TMP" || die "解压失败"
  SRC="$TMP/dsh-tools"
else
  warn "Release 附件拿不到（$PKG_URL）"
  say "   改用仓库快照..."
  curl -fsSL "$SNAP_URL" -o "$TMP/pkg.tar.gz" || die "仓库快照也拿不到（$SNAP_URL）"
  tar -xzf "$TMP/pkg.tar.gz" -C "$TMP" || die "解压失败"
  # 仓库快照解出来是 dsh-tools-<tag>/，里面就有 bin/ 和 install.sh
  SRC=$(find "$TMP" -maxdepth 1 -type d -name 'dsh-tools*' ! -path "$TMP" | head -1)
  [ -n "$SRC" ] || die "快照里找不到 dsh-tools 目录"
fi

[ -f "$SRC/install.sh" ] || die "$SRC 里没有 install.sh"

say "📂 安装..."
say ""
cd "$SRC"
sh install.sh "$@"
