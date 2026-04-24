# BioControl macOS 部署包

## 概述

本目录包含 BioControl 在 macOS x86_64/AArch64 (Apple Silicon) 平台上的完整部署包。

## 系统要求

- macOS 10.15 (Catalina) 或更高版本
- MySQL 5.7+（可通过 Homebrew 安装）
- 最低 2GB 内存
- 10GB 可用磁盘空间

## 快速开始

### 方式一：Docker 部署（推荐）

```bash
tar -xzf biocontrol-mac.tar.gz
cd mac
cp .env.example .env
# 编辑 .env 填入数据库配置
bash start-docker.sh
```

### 方式二：本机部署

```bash
tar -xzf biocontrol-mac.tar.gz
cd mac
cp .env.example .env
# 编辑 .env 填入数据库配置
bash start-local.sh
```

## 服务管理

### 手动管理

```bash
bash start-local.sh    # 启动
bash stop-local.sh      # 停止
bash status-local.sh    # 状态
bash logs-local.sh      # 日志
```

### Docker 管理

```bash
bash start-docker.sh    # 启动
bash stop-docker.sh      # 停止
bash status-docker.sh    # 状态
bash logs-docker.sh      # 日志
```

### 安装为系统服务

macOS 不支持 systemd，可使用 launchd 或保持手动管理。

## 目录结构

```
mac/
├── bin/                   # 后端可执行文件
│   ├── biocontrol-darwin-amd64      # Intel Mac
│   └── biocontrol-darwin-arm64       # Apple Silicon
├── frontend/              # 前端静态文件
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
└── install-service-*.sh  # 服务安装脚本
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

### Q: Homebrew 安装 MySQL

```bash
brew install mysql
brew services start mysql
mysql_secure_installation
```

### Q: 端口被占用

```bash
# 查看端口占用
lsof -i :18080
lsof -i :18090

# 终止进程
kill -9 <PID>
```

详见 `快速开始-中文.md`
