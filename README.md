# dsh-tools

两个命令，给 [DSHA](https://github.com/) 做**能真的恢复回来**的备份。

```bash
dsh-backup                                    # 备份，约 10 秒
dsh-restore /sdcard/Download/.../xxx.tar.gz   # 还原
```

---

## 为什么需要它

DSHA 自带的「备份与恢复」目前有个 bug：备份能成功，**恢复报 `ARCHIVE_LINK_ESCAPE`**。

原因是它的 `portable.dshbak` 里保留了 `node_modules` 中指向归档根之外的软链，
恢复时的安全检查拒绝了这些链接，导致整个还原失败。

**结果就是换机迁移这条路完全走不通。**

这个工具在**打包阶段**就把这类链接剔掉，所以恢复能过。

---

## 安装

```bash
tar -xzf dsh-tools-1.0.0.tar.gz
cd dsh-tools
sh install.sh                  # 装到 /usr/local/bin
sh install.sh --prefix ~/bin   # 或者装到别处
```

只依赖 `sh` / `tar` / `find` / `cp`，不需要 node、python、rsync。

---

## 备份

```bash
dsh-backup
```

产物：`/sdcard/Download/dsh-backup/dsh-backup-<时间>.tar.gz`

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
| 指向包外的软链 | 就是那个 `ARCHIVE_LINK_ESCAPE` 的来源 |
| 整个 Linux 环境 | 几 GB，跨设备必然失效 |

---

## 还原

```bash
dsh-restore /sdcard/Download/dsh-backup/dsh-backup-20261022-1117.tar.gz
```

**默认行为：**

- 只还原纯数据，**不覆盖状态文件**
- 覆盖前自动把现有目录备份成 `*.before-restore`
- 配置只补缺，不覆盖已有的

**加 `--all`** 才连状态文件、`.bashrc` 一起还原。

还原完**要重启 Web** 才生效。

---

## 回滚

```bash
rm -rf ~/.dsh/plugin-src
mv ~/.dsh/plugin-src.before-restore ~/.dsh/plugin-src
```

---

## 实际输出

```console
$ dsh-backup
📦 准备打包...
   源: /root/.dsh
   ✅ 收集 7 个目录
🔗 检查软链...
   剔除: profiles/web/node_modules/dsh-web-mobile -> ../../../../dsha-web-mobile
   ...（自动剔掉 8 个逃逸链接）
🗜  压缩...

✅ 完成
   文件: /sdcard/Download/dsh-backup/dsh-backup-20261022-1117.tar.gz
   大小: 59M
   条目: 1018
   软链: 0（逃逸型 0）
```

---

## 换机流程

```
旧机：dsh-backup
   ↓  传文件（互传 / 数据线 / 网盘）
新机：装环境（重建，别导数据）
   ↓  等环境跑通、验证能对话
新机：dsh-restore <包>
   ↓  重启 Web
   ↓  确认旧对话在、表情包能用
```

**顺序别反：环境先重建，数据后导入。**

---

## 兼容

- DSHA `0.2.21-*`（`session.v4.jsonl.zstd` 格式）
- Android 上跑在 DSHA 的 Ubuntu 环境里
- GNU tar 1.35 起

---

## License

MIT
