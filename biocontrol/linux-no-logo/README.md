# BioControl Linux 部署包（无 Logo）

## 概述

本目录包含 BioControl 在 Linux x86_64/AArch64 平台上的完整部署包（无 Logo 版本）。

**无 Logo 版本与标准版本的区别：**
- 不显示 BioControl Logo
- 适用于定制化部署
- 功能完全相同

## 系统要求

- Linux x86_64 或 AArch64
- MySQL 5.7+ 或 MariaDB 10.2+
- Nginx 1.18+
- 最低 2GB 内存
- 10GB 可用磁盘空间

## 快速开始

### Docker 部署（推荐）

```bash
tar -xzf biocontrol-linux-no-logo.tar.gz
cd linux-no-logo
cp .env.example .env
# 编辑 .env 填入数据库配置
bash start-docker.sh
```

### 本机部署

```bash
tar -xzf biocontrol-linux-no-logo.tar.gz
cd linux-no-logo
cp .env.example .env
# 编辑 .env 填入数据库配置
bash start-local.sh
```

## 服务管理

### systemd 服务

```bash
sudo bash install-service-local.sh
sudo systemctl start biocontrol-local
sudo systemctl stop biocontrol-local
sudo systemctl status biocontrol-local
```

### 手动管理

```bash
bash start-local.sh    # 启动
bash stop-local.sh      # 停止
bash status-local.sh    # 状态
bash logs-local.sh      # 日志
```

## 目录结构

```
linux-no-logo/
├── bin/                   # 后端可执行文件
├── frontend/              # 前端静态文件（无 Logo）
├── conf/                  # 配置文件
├── deploy/                # 部署脚本
├── logs/                  # 日志目录
├── data/                  # 数据目录
├── Dockerfile.*           # Docker 构建文件
├── docker-compose.yml     # Docker Compose 配置
├── start-*.sh             # 启动脚本
├── stop-*.sh              # 停止脚本
├── status-*.sh            # 状态脚本
├── logs-*.sh              # 日志脚本
├── install-service-*.sh    # 服务安装脚本
└── systemd/              # systemd 服务配置
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

详见 `快速开始-中文.md`
