#!/bin/sh
# ============================================================
#  dsh-tools 一键安装
#
#  用法:
#    curl -fsSL https://raw.githubusercontent.com/sb1145148/dsh-tools/main/install-online.sh | sh
#
#  它会：查最新版本 → 下载 → 解压到临时目录 → 跑 install.sh → 清理
# ============================================================
set -eu

REPO="sb1145148/dsh-tools"
API="https://api.github.com/repos/$REPO/releases/latest"

say() { printf '%s\n' "$*"; }
die() { printf '❌ %s\n' "$*" >&2; exit 1; }

command -v curl >/dev/null 2>&1 || die "需要 curl"
command -v tar  >/dev/null 2>&1 || die "需要 tar"

say "🔍 查最新版本..."
JSON=$(curl -fsSL "$API") || die "连不上 GitHub API"

# 没装 jq，用 grep 抠字段
TAG=$(printf '%s' "$JSON" | grep -o '"tag_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
[ -n "$TAG" ] || die "解析不到版本号"
VER=${TAG#v}
say "   版本: $TAG"

URL="https://github.com/$REPO/releases/download/$TAG/dsh-tools-$VER.tar.gz"
TMP=$(mktemp -d "${TMPDIR:-/tmp}/dsh-tools-inst.XXXXXX")
trap 'rm -rf "$TMP"' EXIT INT TERM

say "⬇️  下载 dsh-tools-$VER.tar.gz ..."
curl -fsSL "$URL" -o "$TMP/pkg.tar.gz" || die "下载失败: $URL"

say "📂 解压..."
tar -xzf "$TMP/pkg.tar.gz" -C "$TMP" || die "解压失败"

[ -f "$TMP/dsh-tools/install.sh" ] || die "包里没有 install.sh"

say ""
cd "$TMP/dsh-tools"
sh install.sh $@
