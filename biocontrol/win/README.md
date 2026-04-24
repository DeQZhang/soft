# BioControl Windows 部署包

## 概述

本目录包含 BioControl 在 Windows x86_64/AArch64 平台上的完整部署包。

## 系统要求

- Windows 10/11 或 Windows Server 2016+
- MySQL 5.7+ 或 MariaDB 10.2+
- Docker Desktop（用于 Docker 部署）
- 最低 2GB 内存
- 10GB 可用磁盘空间

## 快速开始

### Docker 部署（推荐）

```powershell
Expand-Archive biocontrol-win.zip
cd win
Copy-Item .env.example .env
# 编辑 .env 填入数据库配置
.\start-docker.ps1
```

### 本机部署

```powershell
Expand-Archive biocontrol-win.zip
cd win
Copy-Item .env.example .env
# 编辑 .env 填入数据库配置
.\start-local.ps1
```

## 服务管理

### PowerShell 脚本

```powershell
.\start-local.ps1      # 启动
.\stop-local.ps1       # 停止
.\status-local.ps1     # 状态
.\logs-local.ps1       # 日志

.\start-docker.ps1     # Docker 启动
.\stop-docker.ps1      # Docker 停止
.\status-docker.ps1    # Docker 状态
.\logs-docker.ps1      # Docker 日志
```

### 安装为 Windows 服务

使用 NSSM 或 Windows Service Wrapper。

## 目录结构

```
win/
├── bin/                   # 后端可执行文件
│   ├── biocontrol-windows-amd64.exe      # x86_64
│   └── biocontrol-windows-arm64.exe       # ARM64
├── frontend/              # 前端静态文件
├── conf/                  # 配置文件
├── deploy/                # 部署脚本
├── logs/                  # 日志目录
├── data/                  # 数据目录
├── Dockerfile.*           # Docker 构建文件
├── docker-compose.yml     # Docker Compose 配置
├── start-*.ps1            # 启动脚本
├── stop-*.ps1             # 停止脚本
├── status-*.ps1           # 状态脚本
├── logs-*.ps1             # 日志脚本
└── install-service-*.ps1 # 服务安装脚本
```

## 端口

| 服务 | 端口 | 说明 |
|------|------|------|
| 前端 | 18080 | Web UI |
| 后端 | 18090 | API |

## 环境变量

编辑 `.env` 文件：

```bash
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=biocontrol
KEYGEN_URL=http://127.0.0.1:19090
JWT_SECRET=your_secret_key
FRONTEND_PORT=18080
BACKEND_PORT=18090
```

## 常见问题

### Q: PowerShell 执行策略限制

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Q: Docker Desktop 未启动

确保 Docker Desktop 已运行，再执行 Docker 相关脚本。

详见 `快速开始-中文.md`
