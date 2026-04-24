# 通用许可证密码机运行目录

这个目录只放非源码运行文件，不放 Go 源码。

目录说明：

- bin/keygen-linux-amd64：Linux x86_64 运行文件
- bin/keygen-linux-arm64：Linux arm64 运行文件
- Dockerfile：运行时镜像定义
- docker-compose.yml：Linux Docker 一键启动配置
- install-docker.sh：一键安装并启动
- stop-docker.sh：停止容器
- status-docker.sh：查看状态
- logs-docker.sh：查看日志
- data：数据库与运行数据目录
- backups：同步前自动生成的历史运行数据备份目录
- BUILD_INFO.json：运行版构建标记文件

正式默认部署：

- 容器名：keygen-runtime
- 访问端口：19090

首次或源码更新后，请先在仓库根目录执行：

```bash
bash soft/keygen/sync_keygen_runtime.sh
```

这个同步命令会先备份当前运行数据到 soft/keygen/backups，然后重建运行版并按正式配置重启容器。

备份保留策略：

- 默认只保留最近 5 份备份
- 可以通过环境变量 KEYGEN_BACKUP_KEEP 覆盖，例如 KEYGEN_BACKUP_KEEP=10 bash soft/keygen/sync_keygen_runtime.sh
- 如果设置为 0，会清空旧备份后再按本次同步重新生成

Linux Docker 一键启动：

```bash
cd soft/keygen
bash install-docker.sh
```

如需改端口，可在 Linux 上这样启动：

```bash
cd soft/keygen
KEYGEN_PORT=19090 bash install-docker.sh
```

如需同时指定容器名：

```bash
cd soft/keygen
KEYGEN_PORT=19090 KEYGEN_CONTAINER_NAME=my-keygen-runtime bash install-docker.sh
```

默认访问地址：

```text
http://127.0.0.1:19090
```

页面与构建信息：

- 页面右上角显示当前管理员登录信息
- 页面支持“迁移数据”入口，可下载迁移包并上传恢复
- 页面导出说明与迁移包元信息会读取当前目录下的 BUILD_INFO.json
- 运行版显示的是运行版自己的构建标记
- 独立迁移手册见 soft/keygen/MIGRATION_GUIDE.md
- 运行版同步脚本见 soft/keygen/sync_keygen_runtime.sh

## 主机迁移

运行版已经支持前端直接迁移，换主机时不需要手工进入容器拷贝数据库。

### 推荐方式：前端迁移包

旧主机：

1. 登录运行版页面。
2. 点击右上角“迁移数据”。
3. 点击“下载迁移包”，保存 JSON 文件。

新主机：

1. 按本 README 的启动方式先把运行版部署起来。
2. 登录新主机运行版页面。
3. 点击右上角“迁移数据”。
4. 选择旧主机下载的 JSON 文件。
5. 点击“上传并恢复数据”。

迁移包包含：

- 产品
- 客户
- 授权记录
- 手动补时 / 扣时记录
- 导出时间、导出人、构建标记与数量摘要

重要说明：

- 导入会先清空当前运行版数据，再按迁移包恢复。
- 导入前建议先在当前主机也下载一份迁移包留档。
- 如果新主机当前已经有测试数据，导入后这些测试数据会被覆盖。

### 兜底方式：目录级迁移

如果不走前端迁移包，也可以直接搬运行目录中的数据文件。

关键目录：

- soft/keygen/data
- soft/keygen/backups

容器内默认数据库路径：

```text
/app/data/keygen.db
```

建议步骤：

1. 在旧主机先执行一次同步命令，自动生成最新备份。
2. 备份 soft/keygen/data 和 soft/keygen/backups。
3. 在新主机覆盖恢复这两个目录。
4. 重新执行 Docker 启动命令。

同步命令：

```bash
bash soft/keygen/sync_keygen_runtime.sh
```

如需单独把迁移流程发给运维或客户，直接使用：

- soft/keygen/MIGRATION_GUIDE.md
