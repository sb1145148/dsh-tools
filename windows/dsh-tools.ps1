# dsh-tools for Windows —— 一条命令包住全部子命令
#
# 用法（在仓库根目录或任意位置）：
#   .\windows\dsh-tools.ps1 list              # 列出子命令
#   .\windows\dsh-tools.ps1 doctor            # 体检
#   .\windows\dsh-tools.ps1 doctor --json     # 机器可读
#   .\windows\dsh-tools.ps1 backup            # 打包
#   .\windows\dsh-tools.ps1 events            # 看会话事件
#   .\windows\dsh-tools.ps1 relink            # 硬链接去重
#   .\windows\dsh-tools.ps1 restore D:\Backup\dsh-backups\xxx.tar.gz
#
# 原理见同目录 README.md：Git Bash 跑 POSIX shell 脚本，
# python3 用 shim 指向 DSH 自带 Python，libzstd 用 Git 自带 DLL。

param(
  [Parameter(Position = 0)][string]$Command = 'list',
  [Parameter(ValueFromRemainingArguments = $true)][string[]]$Rest
)

$ErrorActionPreference = 'Stop'

$Here   = $PSScriptRoot
$BinDir = Join-Path $Here 'bin'
$Runner = Join-Path $Here 'run-dsh-tool.sh'
$Bash   = 'C:\Program Files\Git\bin\bash.exe'

if (-not (Test-Path $Bash))   { throw "找不到 Git Bash: $Bash（先装 Git for Windows）" }
if (-not (Test-Path $BinDir)) { throw "找不到 $BinDir —— 先跑：python windows\patch-dsh-tools.py" }
if (-not (Test-Path $Runner)) { throw "找不到 $Runner" }

if ($Command -eq 'list') {
  Write-Host "可用子命令：" -ForegroundColor Cyan
  Get-ChildItem $BinDir | Sort-Object Name | ForEach-Object {
    Write-Host ("  " + ($_.Name -replace '^dsh-', ''))
  }
  Write-Host ""
  Write-Host "例子：" -ForegroundColor Cyan
  Write-Host "  .\windows\dsh-tools.ps1 doctor"
  Write-Host "  .\windows\dsh-tools.ps1 doctor --json"
  Write-Host "  .\windows\dsh-tools.ps1 backup"
  return
}

# 允许简写：doctor -> dsh-doctor
$name = $Command
if (-not (Test-Path (Join-Path $BinDir $name))) {
  $withPrefix = "dsh-$Command"
  if (Test-Path (Join-Path $BinDir $withPrefix)) { $name = $withPrefix }
  else { throw "没有这个子命令: $Command（用 list 看全部）" }
}

# 参数里出现 Windows 绝对路径时，转成 Git Bash 形式（restore 会用）
function To-UnixPath([string]$p) {
  $full  = [IO.Path]::GetFullPath($p)
  $drive = $full.Substring(0, 1).ToLower()
  $rest  = $full.Substring(2) -replace '\\', '/'
  return "/$drive$rest"
}

$converted = @()
foreach ($arg in $Rest) {
  if ($arg -match '^[A-Za-z]:\\') { $converted += (To-UnixPath $arg) } else { $converted += $arg }
}

& $Bash $Runner $name @converted
exit $LASTEXITCODE
