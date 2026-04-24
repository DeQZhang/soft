# BioControl Linux 部署包（含 Logo）

## 概述

本目录包含 BioControl 在 Linux x86_64/AArch64 平台上的完整部署包，包括：
- 后端服务（Go）
- 前端界面（Vue.js）
- Nginx 配置
- systemd 服务配置

## 系统要求

- Linux x86_64 或 AArch64
- MySQL 5.7+ 或 MariaDB 10.2+
- Nginx 1.18+
- 最低 2GB 内存
- 10GB 可用磁盘空间

## 快速开始

### 方式一：Docker 部署（推荐）

```bash
# 解压部署包
tar -xzf biocontrol-linux.tar.gz
cd linux

# 配置环境变量
cp .env.example .env
# 编辑 .env 填入数据库配置

# 一键启动
bash start-docker.sh
```

### 方式二：本机部署

```bash
# 解压部署包
tar -xzf biocontrol-linux.tar.gz
cd linux

# 配置环境变量
cp .env.example .env
# 编辑 .env 填入数据库配置

# 一键启动
bash start-local.sh
```

## 服务管理

### systemd 服务

```bash
# 安装服务（需 root）
sudo bash install-service-local.sh

# 启动/停止
sudo systemctl start biocontrol-local
sudo systemctl stop biocontrol-local

# 查看状态
sudo systemctl status biocontrol-local
```

### 手动管理

```bash
# 启动
bash start-local.sh

# 停止
bash stop-local.sh

# 查看状态
bash status-local.sh

# 查看日志
bash logs-local.sh
```

## 目录结构

```
linux/
├── bin/
│   ├── biocontrol-linux-amd64      # 后端 x86_64
│   └── biocontrol-linux-arm64      # 后端 ARM64
├── frontend/                        # 前端静态文件
├── conf/                           # 配置文件
├── deploy/                         # 部署脚本
├── logs/                          # 日志目录
├── data/                          # 数据目录
├── .env                           # 环境变量
├── .env.example                   # 环境变量示例
├── Dockerfile.backend             # 后端 Docker 文件
├── Dockerfile.frontend            # 前端 Docker 文件
├── docker-compose.yml             # Docker Compose 配置
├── start-local.sh                 # 本机启动脚本
├── start-docker.sh                # Docker 启动脚本
├── stop-local.sh                  # 本机停止脚本
├── stop-docker.sh                 # Docker 停止脚本
├── status-local.sh                # 本机状态脚本
├── status-docker.sh               # Docker 状态脚本
├── logs-local.sh                  # 本机日志脚本
├── logs-docker.sh                 # Docker 日志脚本
└── systemd/                       # systemd 服务配置
```

## 端口

| 服务 | 端口 | 说明 |
|------|------|------|
| 前端 | 18080 | Web UI |
| 后端 | 18090 | API |

## 环境变量

编辑 `.env` 文件：

```bash
# 数据库配置
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=biocontrol

# 密码机地址
KEYGEN_URL=http://127.0.0.1:19090

# JWT 密钥
JWT_SECRET=your_secret_key

# 服务端口
FRONTEND_PORT=18080
BACKEND_PORT=18090
```

## 常见问题

详见 `快速开始-中文.md`
