# BioControl 许可证密码机（运行版）

## 概述

密码机是 BioControl 系统的许可证管理服务器，用于生成和验证软件许可证。

## 目录结构

```
keygen/
├── bin/                    # 可执行文件
│   ├── keygen-linux-amd64    # Linux x86_64
│   └── keygen-linux-arm64    # Linux ARM64
├── data/                   # 数据目录（SQLite 数据库）
├── backups/                # 数据备份目录
├── BUILD_INFO.json         # 构建信息
├── Dockerfile              # Docker 构建文件
├── docker-compose.yml      # Docker Compose 配置
├── install-docker.sh       # Docker 安装脚本
├── INTEGRATION_GUIDE.md    # 集成指南
├── MIGRATION_GUIDE.md      # 迁移指南
└── README.md               # 本文档
```

## 快速开始

### Docker 部署（推荐）

```bash
# 一键安装
bash install-docker.sh

# 或手动启动
docker-compose up -d
```

### 本机运行

```bash
# 安装 Go 1.21+
go version

# 启动服务
go run . -web -addr 127.0.0.1:19090 -db ./data/keygen.db
```

### 自定义配置

```bash
# 修改端口
KEYGEN_PORT=29090 bash install-docker.sh

# 修改容器名
KEYGEN_CONTAINER_NAME=my-keygen bash install-docker.sh
```

## 端口说明

| 服务 | 端口 | 说明 |
|------|------|------|
| Web 界面 | 19090 | 管理界面 |
| API 接口 | 9090 | 内部 API（Docker 内部）|

## 端口映射

Docker 部署时，将容器内部 9090 端口映射到宿主机 19090 端口。

## 数据管理

### 备份

```bash
# 手动备份
./sync_keygen_runtime.sh

# 或备份 SQLite 数据库文件
cp data/keygen.db backups/keygen-$(date +%Y%m%d).db
```

### 恢复

```bash
# 停止服务
bash stop-docker.sh

# 替换数据库
cp backups/keygen-*.db data/keygen.db

# 重启服务
bash install-docker.sh
```

## 与 BioControl 集成

在 BioControl 的 `.env` 文件中配置：

```
KEYGEN_URL=http://127.0.0.1:19090
```

## Web 界面

启动后访问 http://127.0.0.1:19090 进入管理界面：

- 查看当前许可证状态
- 生成新许可证
- 管理许可证列表
- 查看系统日志

## 服务管理

### Docker

```bash
# 启动
bash install-docker.sh
# 或
docker-compose up -d

# 停止
bash stop-docker.sh
# 或
docker-compose down

# 查看状态
bash status-docker.sh

# 查看日志
bash logs-docker.sh
```

## 常见问题

### Q: 忘记了管理员密码怎么办？

A: 重置数据库后重新初始化。备份 data/keygen.db，然后删除该文件，重新启动服务。

### Q: 如何迁移到新服务器？

A: 详见 MIGRATION_GUIDE.md

### Q: Docker 启动失败？

A: 检查端口是否被占用：
```bash
lsof -i :19090
```

## 技术支持

- 文档更新日期：2026-04-24
- 版本：v1.0.0
