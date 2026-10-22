# 更新日志

## 1.0.0 — 2026-10-22

首个版本。

- `dsh-backup`：打包会话、附件、插件、表情包、配置到 `/sdcard/Download/dsh-backup/`
- `dsh-restore`：还原纯数据，跳过状态文件，覆盖前自动备份
- 自动剔除指向归档根之外的软链（绕开 `ARCHIVE_LINK_ESCAPE`）
- `install.sh`：支持 `--prefix`，覆盖旧版时自动留 `.old`
