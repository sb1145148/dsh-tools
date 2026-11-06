"""把 bin/ 复制进 windows/bin/ 并打上 Windows 适配补丁。

补丁内容：
  1. libzstd：在候选 DLL 列表里加上 Git for Windows 自带的 libzstd.dll
  2. /sdcard/Download → 可配置的 DSH_BACKUP_DIR（默认 $HOME/dsh-backups）
  3. 顺带生成 windows/shim/python3（指向 DSH 自带的 Python）

用法（在仓库根目录）：
  python windows/patch-dsh-tools.py
  python windows/patch-dsh-tools.py --python "C:/path/to/python.exe"
"""
import argparse
import glob
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(os.path.dirname(HERE), "bin")
DST = os.path.join(HERE, "bin")
SHIM = os.path.join(HERE, "shim")

GIT_DLL = [
    r"C:\Program Files\Git\mingw64\bin\libzstd.dll",
    r"C:\Program Files\Git\usr\bin\msys-zstd-1.dll",
]
BACKUP_DIR_DEFAULT = "$HOME/dsh-backups"


def patch_zstd(text: str) -> str:
    needle = "ctypes.util.find_library('zstd'),"
    if needle not in text:
        return text
    extra = "".join(f"\n              r'{p}'," for p in GIT_DLL)
    return text.replace(needle, needle + extra, 1)


def patch_paths(text: str) -> str:
    text = text.replace(
        'OUT_DIR="/sdcard/Download"',
        'OUT_DIR="${DSH_BACKUP_DIR:-%s}"' % BACKUP_DIR_DEFAULT,
    )
    text = text.replace(
        "/sdcard/Download/dsh-backup-*.tar.gz",
        "${DSH_BACKUP_DIR:-%s}/dsh-backup-*.tar.gz" % BACKUP_DIR_DEFAULT,
    )
    text = text.replace(
        "/sdcard/Download/dsh-backup/dsh-backup-*.tar.gz",
        "${DSH_BACKUP_DIR:-%s}/dsh-backup-*.tar.gz" % BACKUP_DIR_DEFAULT,
    )
    return text


def find_dsh_python() -> str:
    """在 DSH 的运行时目录里找 python.exe，返回 Git Bash 形式的路径。"""
    home = os.path.expanduser("~")
    pattern = os.path.join(home, ".dsh", "dsh-runtimes", "*", "dependencies", "python", "python.exe")
    hits = glob.glob(pattern)
    if not hits:
        raise SystemExit(
            "找不到 DSH 自带的 Python。\n"
            "请用 --python 指定，例如：\n"
            '  python windows/patch-dsh-tools.py --python "C:/Users/me/.dsh/dsh-runtimes/x/dependencies/python/python.exe"'
        )
    win_path = hits[0].replace("\\", "/")
    # C:/Users/... → /c/Users/...
    return "/" + win_path[0].lower() + win_path[2:]


def write_shim(python_unix: str) -> None:
    os.makedirs(SHIM, exist_ok=True)
    content = f'#!/bin/sh\nexec "{python_unix}" "$@"\n'
    path = os.path.join(SHIM, "python3")
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(content)
    # Git Bash 需要可执行位；在 Windows 上 chmod 由用户手动跑（见 README）
    print(f"  shim/python3 -> {python_unix}")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--python", help="DSH 自带 python.exe 的路径（默认自动查找）")
    args = ap.parse_args()

    if not os.path.isdir(SRC):
        raise SystemExit(f"找不到源目录: {SRC}（请在仓库根目录运行）")

    os.makedirs(DST, exist_ok=True)
    for name in sorted(os.listdir(SRC)):
        src_file = os.path.join(SRC, name)
        if not os.path.isfile(src_file):
            continue
        text = open(src_file, encoding="utf-8").read()
        before = text
        text = patch_zstd(text)
        text = patch_paths(text)
        with open(os.path.join(DST, name), "w", encoding="utf-8", newline="\n") as f:
            f.write(text)
        print(f"  {name:<16} {'已改' if text != before else '原样'}")

    write_shim(args.python or find_dsh_python())
    print("\n完成。下一步：")
    print('  bash -c "chmod +x windows/shim/python3 windows/run-dsh-tool.sh"')
    print("  powershell -File windows/dsh-tools.ps1 doctor")


if __name__ == "__main__":
    main()
