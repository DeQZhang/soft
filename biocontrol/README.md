# BioControl 生物发酵控制系统

## 概述

BioControl 是一款通用的生物发酵数据采集与控制系统，支持发酵罐、摇瓶、微孔板等多种培养设备的数据管理和实验设计。

## 目录结构

```
biocontrol/
├── linux/           # Linux x86_64/AArch64 部署包（含 Logo）
├── linux-no-logo/   # Linux x86_64/AArch64 部署包（无 Logo）
├── mac/             # macOS x86_64/AArch64 部署包
├── win/             # Windows x86_64/AArch64 部署包
└── packages/        # 打包文件（需手动生成）
```

## 功能特性

### 1. 数据采集与展示
- 发酵罐批次数据管理（温度、pH、溶氧、转速、气体分析等）
- 摇瓶实验数据记录
- 微孔板筛选数据管理
- 生长曲线可视化

### 2. 实验设计
- DOE 实验设计（析因设计、响应面设计等）
- 实验配方管理
- 实验执行跟踪

### 3. 数据分析
- 多批次数据对比
- 数据导出（Excel、PDF）
- 实时曲线监控

### 4. 系统管理
- 用户权限管理
- 权限组管理
- 许可证管理（集成密码机）

## 快速开始

### Linux/macOS

```bash
# 解压部署包
tar -xzf biocontrol-*.tar.gz
cd linux  # 或 linux-no-logo 或 mac

# 配置环境变量
cp .env.example .env
# 编辑 .env 文件，填入数据库配置

# 本机启动
bash start-local.sh

# 或 Docker 启动
bash start-docker.sh
```

### Windows

```powershell
# 解压部署包
Expand-Archive biocontrol-*.zip
cd win

# 配置环境变量
Copy-Item .env.example .env
# 编辑 .env 文件

# 本机启动
.\start-local.ps1

# 或 Docker 启动
.\start-docker.ps1
```

## 端口说明

| 服务 | 端口 | 说明 |
|------|------|------|
| 前端界面 | 18080 | Web UI |
| 后端 API | 18090 | REST API |

## 环境变量

| 变量名 | 必填 | 说明 | 默认值 |
|--------|------|------|--------|
| DB_HOST | 是 | MySQL 主机地址 | localhost |
| DB_PORT | 否 | MySQL 端口 | 3306 |
| DB_USER | 是 | MySQL 用户名 | root |
| DB_PASSWORD | 是 | MySQL 密码 | - |
| DB_NAME | 否 | 数据库名 | biocontrol |
| KEYGEN_URL | 否 | 密码机地址 | http://127.0.0.1:19090 |
| JWT_SECRET | 是 | JWT 密钥 | - |

## 服务管理

### systemd 服务安装（Linux）

```bash
# 安装本机服务
sudo bash install-service-local.sh

# 安装 Docker 服务
sudo bash install-service-docker.sh

# 查看状态
systemctl status biocontrol-local
systemctl status biocontrol-compose

# 启动/停止
sudo systemctl start biocontrol-local
sudo systemctl stop biocontrol-local
```

### macOS 服务

macOS 不支持 systemd，可使用 launchd 或手动管理进程。

```bash
# 查看状态
bash status-local.sh

# 启动/停止
bash start-local.sh
bash stop-local.sh
```

## 数据备份

建议定期备份以下目录：
- `./data/` - 应用数据
- `./logs/` - 日志文件
- MySQL 数据库

## 许可证管理

BioControl 需要有效的许可证才能运行。系统集成密码机进行许可证管理：

1. 安装并启动密码机（见 keygen 目录）
2. 首次安装后有 1 个月试用期
3. 试用期结束后，系统会显示服务器 MAC 地址
4. 联系管理员获取正式许可证

## 常见问题

详见各平台目录下的 `快速开始-中文.md` 和 `常见问题-中文.md`。

## 技术支持

- 文档更新日期：2026-04-24
- 版本：v1.0.0
