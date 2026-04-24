# 通用许可证密码机 — 新软件接入指南

本文档详细说明如何将一个新的软件产品接入密码机许可证体系，实现 **MAC 地址绑定 + AES-256-GCM 加密** 的离线授权。

---

## 目录

1. [整体架构](#1-整体架构)
2. [在密码机注册新产品](#2-在密码机注册新产品)
3. [新软件接入许可证验证](#3-新软件接入许可证验证)
4. [Go 项目接入（推荐）](#4-go-项目接入推荐)
5. [非 Go 项目接入](#5-非-go-项目接入)
6. [前端 UI 集成](#6-前端-ui-集成)
7. [完整对接流程清单](#7-完整对接流程清单)
8. [安全注意事项](#8-安全注意事项)
9. [常见问题](#9-常见问题)

---

## 1. 整体架构

```
┌────────────────────────────────┐
│          密码机 (keygen)        │
│  - 管理多个产品                 │
│  - 每个产品有独立的 SecretSeed  │
│  - 生成 / 验证许可证密钥        │
│  - Web UI + CLI                │
└─────────┬──────────────────────┘
          │ 生成许可证密钥（加密字符串）
          ▼
┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐
│ 产品 A (Go)     │   │ 产品 B (Python) │   │ 产品 C (...)    │
│ SecretSeed = X  │   │ SecretSeed = Y  │   │ SecretSeed = Z  │
│ 内置解密 + 校验  │   │ 内置解密 + 校验  │   │ 内置解密 + 校验  │
└─────────────────┘   └─────────────────┘   └─────────────────┘
```

**核心原理：**

1. 密码机为每个产品分配一个唯一的 **SecretSeed**（密钥种子）
2. 生成许可证时：`SecretSeed → SHA256 → AES-256-GCM 密钥 → 加密(MAC + 套餐 + 时间)`
3. 产品软件内置**相同的 SecretSeed**，收到密钥后解密、校验 MAC 和有效期
4. SecretSeed 不同的产品之间的许可证**互不通用**

---

## 2. 在密码机注册新产品

### 方式一：Web 界面（推荐）

1. 访问密码机 Web 界面 `http://127.0.0.1:9090`
2. 登录（账号 `zdq`）
3. 切换到 **产品管理** 标签页
4. 点击 **添加产品**，填写：

   | 字段 | 说明 | 示例 |
   |------|------|------|
   | 产品名称 | 显示名称 | `DataVision 数据分析` |
   | 产品代码 | 唯一标识符，建议用英文 | `datavision` |
   | 密钥种子 | AES 加密种子，点击「自动生成」按钮 | `datavision-license-2026-a8f3...` |
   | 描述 | 可选备注 | `数据可视化分析平台` |

5. 点击保存

> **重要：** 记下 **密钥种子（SecretSeed）**，后续需要写入新软件的代码或配置中。

### 方式二：API

```bash
TOKEN="你的登录token"

curl -X POST http://127.0.0.1:9090/api/products \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "DataVision 数据分析",
    "code": "datavision",
    "secret_seed": "datavision-license-2026-自定义种子字符串",
    "description": "数据可视化分析平台"
  }'
```

### 方式三：CLI

```bash
./keygen -mac AA:BB:CC:DD:EE:FF -plan 1y -seed "datavision-license-2026-自定义种子字符串"
```

---

## 3. 新软件接入许可证验证

新软件需要实现以下功能：

| 功能 | 说明 |
|------|------|
| 获取本机 MAC | 读取服务器物理网卡地址 |
| 解密许可证 | 使用 SecretSeed 派生的 AES-256 密钥解密 |
| 校验 MAC | 比对许可证中的 MAC 与本机 MAC |
| 校验有效期 | 检查是否过期 |
| 持久化存储 | 将许可证密钥保存到文件 |
| 前端 UI | 显示状态、提供激活入口 |

### 许可证密钥格式

密钥是一个 Base64 URL 编码的字符串，内部结构：

```
Base64URL( nonce + AES-256-GCM( JSON({mac, plan, issued_at, expires_at}) ) )
```

解密后的 JSON 结构：

```json
{
  "mac": "FA:5F:9F:76:E8:CF",
  "plan": "1y",
  "issued_at": 1745078721,
  "expires_at": 1776614721
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `mac` | string | 目标服务器 MAC 地址（大写，冒号分隔） |
| `plan` | string | 套餐代码：`1m` / `3m` / `1y` / `permanent` |
| `issued_at` | int64 | 签发时间（Unix 秒） |
| `expires_at` | int64 | 过期时间（Unix 秒），`0` 表示永久 |

---

## 4. Go 项目接入（推荐）

如果新软件也是 Go 项目，可以直接复用 `license` 包，最少改动即可完成接入。

### 步骤 4.1：复制 license 包

将本项目的 `source/keygen-source/internal/license/license.go` 复制到新项目中：

```bash
# 在新项目中创建目录
mkdir -p internal/license

# 复制文件
cp /path/to/source/keygen-source/internal/license/license.go 新项目/internal/license/license.go
```

修改文件顶部的 `package` 和 `secretSeed`：

```go
package license

// 修改为该产品在密码机中注册时使用的密钥种子
var secretSeed = "datavision-license-2026-你的种子字符串"
```

或者不修改源码，在编译时通过 `-ldflags` 注入：

```bash
go build -ldflags "-X 你的模块路径/internal/license.secretSeed=你的种子字符串" -o 新软件
```

### 步骤 4.2：添加 API 路由

新软件后端需要提供 3 个 HTTP 接口：

```go
// GET /api/license/status  — 获取许可证状态
// POST /api/license/activate — 激活许可证
// GET /api/license/mac — 获取本机 MAC 地址
```

参考实现（标准库 `net/http`）：

```go
package main

import (
    "encoding/json"
    "net/http"
    "你的模块/internal/license"
)

func main() {
    http.HandleFunc("/api/license/status", handleLicenseStatus)
    http.HandleFunc("/api/license/activate", handleLicenseActivate)
    http.HandleFunc("/api/license/mac", handleLicenseMAC)
    // ... 其他路由
    http.ListenAndServe(":8080", nil)
}

func handleLicenseStatus(w http.ResponseWriter, r *http.Request) {
    mgr := license.DefaultManager()
    st := mgr.Load()
    json.NewEncoder(w).Encode(map[string]interface{}{
        "success": true,
        "data":    st,
    })
}

func handleLicenseActivate(w http.ResponseWriter, r *http.Request) {
    var req struct {
        Key string `json:"key"`
    }
    json.NewDecoder(r.Body).Decode(&req)
    
    mgr := license.DefaultManager()
    st := mgr.Activate(req.Key)
    if !st.Valid {
        w.WriteHeader(http.StatusBadRequest)
    }
    json.NewEncoder(w).Encode(map[string]interface{}{
        "success": st.Valid,
        "data":    st,
    })
}

func handleLicenseMAC(w http.ResponseWriter, r *http.Request) {
    mac, err := license.GetMAC()
    if err != nil {
        w.WriteHeader(http.StatusInternalServerError)
        json.NewEncoder(w).Encode(map[string]interface{}{
            "success": false,
            "error":   err.Error(),
        })
        return
    }
    json.NewEncoder(w).Encode(map[string]interface{}{
        "success": true,
        "data":    map[string]string{"mac": mac},
    })
}
```

### 步骤 4.3：添加许可证拦截中间件（可选）

在需要保护的路由上添加中间件，未授权时返回 `403`：

```go
func licenseGuard(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        mgr := license.DefaultManager()
        if !mgr.IsValid() {
            w.WriteHeader(http.StatusForbidden)
            json.NewEncoder(w).Encode(map[string]interface{}{
                "success": false,
                "error":   "系统未授权，请先激活许可证",
            })
            return
        }
        next.ServeHTTP(w, r)
    })
}
```

### 步骤 4.4：许可证文件存储

`license.Manager` 默认查找 `conf/license.key` 文件。确保新软件的工作目录下有 `conf/` 目录：

```bash
mkdir -p conf
```

激活时，密钥会自动写入 `conf/license.key`（权限 `0600`）。

---

## 5. 非 Go 项目接入

如果新软件使用其他语言（Python、Java、Node.js 等），需要自行实现解密逻辑。核心算法如下：

### 算法说明

```
输入: license_key (Base64 URL 编码字符串), secret_seed (字符串)

1. aes_key = SHA256(secret_seed)              // 32 字节
2. raw = Base64URL_Decode(license_key)         // 二进制数据
3. nonce = raw[0:12]                           // GCM nonce，前 12 字节
4. ciphertext = raw[12:]                       // 密文+tag
5. plaintext = AES-256-GCM_Decrypt(aes_key, nonce, ciphertext)
6. payload = JSON_Parse(plaintext)             // {mac, plan, issued_at, expires_at}
7. 校验: payload.mac == 本机MAC && (expires_at==0 || expires_at > 当前时间)
```

### Python 参考实现

```python
import json, hashlib, base64, uuid
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

SECRET_SEED = "datavision-license-2026-你的种子字符串"

def derive_key(seed: str) -> bytes:
    return hashlib.sha256(seed.encode()).digest()

def decrypt_license(token: str, seed: str = SECRET_SEED) -> dict:
    # Base64 URL 解码
    # 补齐 padding
    token = token.replace('-', '+').replace('_', '/')
    padding = 4 - len(token) % 4
    if padding != 4:
        token += '=' * padding
    raw = base64.b64decode(token)
    
    key = derive_key(seed)
    nonce = raw[:12]
    ciphertext = raw[12:]
    
    aesgcm = AESGCM(key)
    plaintext = aesgcm.decrypt(nonce, ciphertext, None)
    return json.loads(plaintext)

def get_mac() -> str:
    mac = uuid.getnode()
    return ':'.join(f'{(mac >> i) & 0xFF:02X}' for i in range(40, -1, -8))

def validate_license(token: str) -> dict:
    import time
    try:
        payload = decrypt_license(token)
    except Exception as e:
        return {"valid": False, "message": f"解密失败: {e}"}
    
    local_mac = get_mac()
    if payload["mac"] != local_mac:
        return {"valid": False, "message": "许可证与当前服务器不匹配"}
    
    if payload["expires_at"] == 0:
        return {"valid": True, "message": "许可证有效（永久授权）", **payload}
    
    if payload["expires_at"] < time.time():
        return {"valid": False, "message": "许可证已过期"}
    
    return {"valid": True, "message": "许可证有效", **payload}
```

### Node.js 参考实现

```javascript
const crypto = require('crypto');
const os = require('os');

const SECRET_SEED = 'datavision-license-2026-你的种子字符串';

function deriveKey(seed) {
  return crypto.createHash('sha256').update(seed).digest();
}

function decryptLicense(token, seed = SECRET_SEED) {
  // Base64 URL → 标准 Base64
  let b64 = token.replace(/-/g, '+').replace(/_/g, '/');
  while (b64.length % 4) b64 += '=';
  const raw = Buffer.from(b64, 'base64');

  const key = deriveKey(seed);
  const nonce = raw.subarray(0, 12);
  const ciphertext = raw.subarray(12);

  // GCM tag 是最后 16 字节
  const authTag = ciphertext.subarray(ciphertext.length - 16);
  const encrypted = ciphertext.subarray(0, ciphertext.length - 16);

  const decipher = crypto.createDecipheriv('aes-256-gcm', key, nonce);
  decipher.setAuthTag(authTag);
  const plaintext = Buffer.concat([decipher.update(encrypted), decipher.final()]);
  return JSON.parse(plaintext.toString());
}

function getMAC() {
  const ifaces = os.networkInterfaces();
  for (const name of Object.keys(ifaces)) {
    for (const iface of ifaces[name]) {
      if (!iface.internal && iface.mac !== '00:00:00:00:00:00') {
        return iface.mac.toUpperCase();
      }
    }
  }
  throw new Error('未找到可用网卡');
}

function validateLicense(token) {
  try {
    const payload = decryptLicense(token);
    const localMAC = getMAC();
    if (payload.mac !== localMAC) {
      return { valid: false, message: '许可证与当前服务器不匹配' };
    }
    if (payload.expires_at === 0) {
      return { valid: true, message: '许可证有效（永久授权）', ...payload };
    }
    if (payload.expires_at < Date.now() / 1000) {
      return { valid: false, message: '许可证已过期' };
    }
    return { valid: true, message: '许可证有效', ...payload };
  } catch (e) {
    return { valid: false, message: `解密失败: ${e.message}` };
  }
}
```

---

## 6. 前端 UI 集成

新软件的前端需要一个「系统授权」页面。以 Vue 3 为例：

```vue
<template>
  <div class="license-panel">
    <h3>系统授权</h3>

    <!-- 状态显示 -->
    <div v-if="status">
      <p>状态：{{ status.valid ? (status.is_trial ? '试用中 ✓' : '已激活 ✓') : '未激活 ✗' }}</p>
      <p v-if="status.valid">套餐：{{ status.plan_label }}</p>
      <p v-if="status.valid">到期：{{ status.expires_at }}</p>
      <p v-if="status.valid">剩余：{{ status.remaining }}</p>
      <p>物理地址（MAC）：{{ mac }}</p>
    </div>

    <!-- 激活表单 -->
    <div v-if="!status?.valid">
      <textarea v-model="licenseKey" placeholder="粘贴许可证密钥" />
      <button @click="activate">激活</button>
    </div>

    <p v-if="message" :class="{ error: !status?.valid }">{{ message }}</p>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import axios from 'axios';

const status = ref(null);
const mac = ref('');
const licenseKey = ref('');
const message = ref('');

onMounted(async () => {
  const [st, m] = await Promise.all([
    axios.get('/api/license/status'),
    axios.get('/api/license/mac'),
  ]);
  status.value = st.data.data;
  mac.value = m.data.data.physical_address || m.data.data.mac;
});

async function activate() {
  try {
    const res = await axios.post('/api/license/activate', {
      key: licenseKey.value.trim(),
    });
    status.value = res.data.data;
    message.value = res.data.data.message;
  } catch (e) {
    message.value = e.response?.data?.error || '激活失败';
  }
}
</script>
```

---

## 7. 完整对接流程清单

按照以下顺序完成新软件接入：

### 第一步：密码机端

- [ ] 在密码机 Web 界面 **产品管理** 中添加新产品
- [ ] 记录产品的 **密钥种子（SecretSeed）**

### 第二步：新软件后端

- [ ] 复制或实现 license 解密模块（参考第 4/5 节）
- [ ] 将 SecretSeed 写入代码 / 配置 / 编译参数
- [ ] 添加 3 个 API 接口：
  - `GET /api/license/status` — 获取许可证状态
  - `POST /api/license/activate` — 激活（接收 `key` 字段）
  - `GET /api/license/mac` — 返回服务器物理地址（MAC）
- [ ] 添加首次安装后 1 个月试用期的持久化逻辑
- [ ] （可选）添加许可证拦截中间件，在试用结束且未激活后阻止业务接口

### 第三步：新软件前端

- [ ] 添加「系统授权」页面（参考第 6 节）
- [ ] 显示物理地址（MAC）供用户发送给管理员
- [ ] 显示试用期状态与剩余时间
- [ ] 提供密钥输入框 + 激活按钮
- [ ] 显示授权状态（试用 / 有效 / 过期 / 未激活）

### 第四步：验证

- [ ] 启动密码机，为新产品生成一个测试许可证
- [ ] 在新软件中激活，确认状态正确
- [ ] 测试过期场景：生成一个已过期的许可证，确认被拒绝
- [ ] 测试 MAC 不匹配：用其他 MAC 生成的密钥，确认被拒绝
- [ ] 测试跨产品：用产品 A 的密钥尝试在产品 B 上激活，确认被拒绝

### 第五步：部署

- [ ] 新软件编译/打包时确保 SecretSeed 已注入
- [ ] `conf/license.key` 文件路径可写
- [ ] 密码机仅在管理员机器上运行，**不随产品分发**

---

## 8. 安全注意事项

| 要点 | 说明 |
|------|------|
| SecretSeed 保密 | 每个产品的 seed 只存在于密码机和该产品的编译产物中，不要明文写在配置文件里 |
| 推荐编译注入 | 使用 `-ldflags` 在编译时注入 seed，源码中留空或使用默认占位符 |
| 许可证文件权限 | `conf/license.key` 应为 `0600`，仅运行用户可读写 |
| 密码机不外传 | keygen 可执行文件和数据库 **绝不发送给客户** |
| 产品间隔离 | 不同产品使用不同的 SecretSeed，密钥互不通用 |
| HTTPS | 如果通过网络传输许可证密钥，确保使用 HTTPS |

---

## 9. 常见问题

### Q: 修改 SecretSeed 后旧许可证还能用吗？

**不能。** 修改 seed 等于更换加密密钥，所有旧许可证都会失效。需要重新生成。

### Q: 一台服务器能同时运行多个授权软件吗？

**可以。** 每个软件独立校验自己的许可证，互不影响。它们共享同一个 MAC 地址，但使用不同的 SecretSeed 和 `license.key` 文件。

### Q: 客户更换了服务器（MAC 变了）怎么办？

需要用新 MAC 重新生成许可证。旧许可证在新服务器上无法激活。

### Q: 能否支持多网卡？

当前实现只取第一个非回环、已启用的物理网卡 MAC。如果服务器有多个网卡，确保许可证绑定的 MAC 与软件检测到的一致。可通过 `/api/license/mac` 接口查看。

### Q: 密码机数据库丢失了怎么办？

已发出的许可证仍然有效（许可证是自包含的加密令牌，不依赖数据库）。丢失的只是生成记录，可以重新开始生成。

### Q: 如何测试不同产品的许可证互不通用？

在密码机中注册两个产品（不同 seed），分别生成许可证，然后在软件中用另一个产品的密钥尝试激活，应返回「解密失败」。
