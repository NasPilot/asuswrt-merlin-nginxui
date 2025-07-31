# ASUSWRT-Merlin NginxUI

一个轻量级且高效的 Web UI 界面，用于在运行 ASUSWRT-Merlin 固件的路由器上管理 Nginx 服务。

<details>
    <summary>支持的设备</summary>
    一般来说，所有能够运行 Merlin-WRT 固件（`384.15` 或更高版本，`3006.102.1` 或更高版本）的设备都受支持。以下是已验证 NginxUI 可以正常工作的型号列表：

- RT-AC66U
- RT-AC68U
- RT-AX58U
- TUF-AX5400
- RT-AX92U
- RT-AX86U
- RT-AX88U
- GT-AX11000
- GT-AXE11000
- GT-AX6000
- RT-AX86U Pro
- RT-AX88U Pro
- GT-AX11000 Pro
- RT-BE88U
</details>

## 功能特性

### 🚀 核心功能
- **Web 界面管理**: 通过路由器 Web UI 直接管理 Nginx 服务
- **服务控制**: 启动、停止、重启、重载 Nginx 服务
- **配置管理**: 基础和高级配置模式
- **实时监控**: 服务状态、连接数、请求统计
- **日志查看**: 访问日志、错误日志、系统日志

### 📋 配置功能
- **基础模式**: 简单的服务器配置，适合初学者
- **高级模式**: 完整的 Nginx 配置选项
- **服务器块管理**: 多个虚拟主机配置
- **上游配置**: 负载均衡和反向代理
- **SSL/TLS 配置**: HTTPS 支持和证书管理

### 📊 监控和日志
- **实时状态监控**: CPU、内存、连接数
- **日志查看器**: 支持搜索、过滤、下载
- **统计信息**: 请求统计、错误统计
- **日志轮转**: 自动日志管理

### 🔧 管理功能
- **配置备份**: 自动备份和恢复
- **配置验证**: 实时配置语法检查
- **一键安装**: 自动安装和配置
- **多语言支持**: 中文和英文界面

## 系统要求

### 硬件要求
- 支持 ASUSWRT-Merlin 固件的 ASUS 路由器
- 至少 64MB 可用存储空间
- 建议 256MB 或更多 RAM

### 软件要求
- ASUSWRT-Merlin 固件 (推荐最新版本)
- 启用 JFFS 分区和自定义脚本
- Entware 包管理器
- Nginx (通过 Entware 安装)

### 支持的路由器型号
- RT-AX88U, RT-AX86U, RT-AX68U
- RT-AC88U, RT-AC86U, RT-AC68U
- RT-AX58U, RT-AC58U
- 其他支持 ASUSWRT-Merlin 的型号

## 安装指南

### SSH 访问

通过 SSH 访问您的路由器以执行安装命令。

### 前置条件

- [Merlin 固件](https://www.asuswrt-merlin.net/download) (`384.15` 或更高版本，`3006.102.1` 或更高版本)
- [Entware](https://github.com/Entware/Entware/wiki/Install-on-Asus-stock-firmware) 已安装
  - 您可以使用内置的 [amtm](https://diversion.ch/amtm.html) 工具来安装 `Entware`
- Nginx 服务 (通过 Entware 安装)

### 一键安装

要安装最新版本的 `ASUSWRT Merlin NginxUI`，只需在路由器的 SSH 终端中运行以下命令：

```shell
wget -O /tmp/asuswrt-merlin-nginxui.tar.gz https://github.com/NasPilot/asuswrt-merlin-nginxui/releases/latest/download/asuswrt-merlin-nginxui.tar.gz && rm -rf /jffs/addons/nginxui && tar -xzf /tmp/asuswrt-merlin-nginxui.tar.gz -C /jffs/addons && mv /jffs/addons/nginxui/webapp.sh /jffs/scripts/nginxui && chmod 0777 /jffs/scripts/nginxui && sh /jffs/scripts/nginxui install
```

### 如何卸载

要卸载并清理，请运行以下命令：

```shell
/jffs/scripts/nginxui uninstall
```

### 手动安装

如果您希望手动安装，请按照以下步骤操作：

1. **启用 JFFS 分区**
   - 登录路由器管理界面
   - 进入 `管理` -> `系统`
   - 启用 `JFFS 自定义脚本和配置`
   - 重启路由器

2. **安装 Entware**
   - SSH 连接到路由器
   - 运行 `amtm` 命令
   - 选择安装 Entware

3. **安装 Nginx**
   ```bash
   opkg update
   opkg install nginx nginx-mod-http-ssl nginx-mod-http-gzip
   ```

4. **下载安装包**
   ```bash
   cd /tmp
   wget https://github.com/NasPilot/asuswrt-merlin-nginxui/releases/latest/download/asuswrt-merlin-nginxui.tar.gz
   tar -xzf asuswrt-merlin-nginxui.tar.gz
   ```

5. **运行安装脚本**
   ```bash
   cd nginxui
   chmod +x install.sh
   ./install.sh
   ```

6. **访问 Web 界面**
   - 登录路由器管理界面
   - 导航到 `网络工具` -> `Nginx`

## 使用说明

### 安装后步骤

- **注销并重新登录**: 安装完成后，请从路由器的浏览器 UI 注销，然后重新登录。
- **访问 Nginx 选项卡**: 在路由器的 Web UI 中导航到 `网络工具` 菜单项，查找标有 `Nginx` 的新选项卡。

### 手动安装

1. **创建目录结构**
   ```bash
   mkdir -p /jffs/addons/nginxui
   mkdir -p /jffs/addons/nginxui/scripts
   mkdir -p /jffs/addons/nginxui/www
   ```

2. **复制文件**
   ```bash
   # 复制后端脚本
   cp src/backend/*.sh /jffs/addons/nginxui/scripts/
   
   # 复制 Web 文件
   cp dist/nginxui.js /jffs/addons/nginxui/www/
   cp dist/nginxui.css /jffs/addons/nginxui/www/
   cp dist/nginxui.asp /www/user/
   ```

3. **设置权限**
   ```bash
   chmod +x /jffs/addons/nginxui/scripts/*.sh
   ```

4. **启动服务**
   ```bash
   /jffs/addons/nginxui/scripts/nginxui start
   ```

## 使用指南

### 基础配置

1. **启用 Nginx 服务**
   - 在 Web 界面中切换到基础模式
   - 启用 Nginx 服务
   - 设置监听端口 (默认 80)
   - 配置服务器名称和文档根目录

2. **SSL 配置**
   - 启用 SSL 支持
   - 设置 SSL 端口 (默认 443)
   - 上传 SSL 证书和私钥
   - 配置 SSL 选项

### 高级配置

1. **服务器块管理**
   - 添加多个虚拟主机
   - 配置不同的域名和端口
   - 设置自定义配置指令

2. **上游配置**
   - 配置负载均衡
   - 添加后端服务器
   - 设置健康检查

3. **反向代理**
   - 配置代理规则
   - 设置代理头部
   - 配置缓存策略

### 监控和维护

1. **服务状态监控**
   - 查看服务运行状态
   - 监控连接数和请求数
   - 检查配置有效性

2. **日志管理**
   - 查看访问日志和错误日志
   - 搜索和过滤日志
   - 下载日志文件
   - 清理旧日志

3. **备份和恢复**
   - 创建配置备份
   - 恢复历史配置
   - 导出配置文件

## 配置文件

### 主配置文件
- `/jffs/addons/nginxui/shared/nginxui.conf` - NGINXUI 主配置
- `/opt/etc/nginx/nginx.conf` - Nginx 主配置
- `/opt/etc/nginx/conf.d/` - 额外配置目录

### 日志文件
- `/jffs/addons/nginxui/logs/nginxui.log` - NGINXUI 日志
- `/opt/var/log/nginx/access.log` - Nginx 访问日志
- `/opt/var/log/nginx/error.log` - Nginx 错误日志

### 备份目录
- `/jffs/addons/nginxui/backups/` - 配置备份目录

## 故障排除

### 常见问题

1. **无法访问 Web 界面**
   - 检查 JFFS 分区是否启用
   - 确认自定义脚本已启用
   - 检查文件权限

2. **Nginx 启动失败**
   - 检查配置文件语法
   - 查看错误日志
   - 确认端口未被占用

3. **SSL 证书问题**
   - 检查证书文件路径
   - 验证证书有效性
   - 确认私钥匹配

### 调试命令

```bash
# 检查服务状态
/jffs/addons/nginxui/scripts/nginxui status

# 测试 Nginx 配置
nginx -t

# 查看日志
tail -f /jffs/addons/nginxui/logs/nginxui.log
tail -f /opt/var/log/nginx/error.log

# 重启服务
/jffs/addons/nginxui/scripts/nginxui restart
```

### 日志级别
- `INFO`: 一般信息
- `WARN`: 警告信息
- `ERROR`: 错误信息

## 常见问题 (FAQ)

**Q: 如何配置 Nginx 反向代理？**

A: 在高级模式下，您可以配置上游服务器和代理规则。详细配置请参考 [Nginx 反向代理配置指南](https://github.com/NasPilot/asuswrt-merlin-nginxui/wiki/Nginx-Reverse-Proxy-Guide)。

**Q: 如何启用 SSL/HTTPS 支持？**

A: 在基础模式或高级模式下启用 SSL 选项，上传您的 SSL 证书和私钥文件，配置 SSL 端口（默认 443）。

**Q: 如果我已经有 Nginx 配置文件怎么办？**

A: 如果您已经有想要使用的 Nginx 配置文件，需要将其放置在以下位置：

```
/opt/etc/nginx/nginx.conf
```

文件放置后，ASUSWRT Merlin NginxUI 界面将自动反映这些更改。

**Q: 如何备份和恢复 Nginx 配置？**

A: NginxUI 提供自动备份功能，您可以在 Web 界面中创建配置备份，也可以从历史备份中恢复配置。

## 开发指南

### 项目结构
```
asuswrt-merlin-nginxui/
├── src/
│   ├── App.vue              # 主应用组件
│   ├── App.ts               # 应用入口
│   ├── App.html             # ASP 页面模板
│   ├── App.globals.scss     # 全局样式
│   ├── components/          # Vue 组件
│   ├── modules/             # 业务模块
│   ├── locales/             # 国际化文件
│   └── backend/             # 后端脚本
├── dist/                    # 构建输出
├── build.tar.sh             # 构建脚本
├── package.json             # 项目配置
├── vite.config.ts           # Vite 配置
└── tsconfig.json            # TypeScript 配置
```

### 构建项目

1. **安装依赖**
   ```bash
   npm install
   ```

2. **开发模式**
   ```bash
   npm run dev
   ```

3. **构建生产版本**
   ```bash
   npm run build
   ```

4. **创建发布包**
   ```bash
   ./build.tar.sh
   ```

### 贡献指南

1. Fork 项目
2. 创建功能分支
3. 提交更改
4. 推送到分支
5. 创建 Pull Request

## API 文档

### 后端 API

NGINXUI 使用 Shell 脚本作为后端，通过 ASP 页面处理前端请求。

#### 服务管理
- `action=service&service=nginx&operation=start` - 启动 Nginx
- `action=service&service=nginx&operation=stop` - 停止 Nginx
- `action=service&service=nginx&operation=restart` - 重启 Nginx
- `action=service&service=nginx&operation=reload` - 重载配置
- `action=service&service=nginx&operation=status` - 获取状态

#### 配置管理
- `action=config&operation=get` - 获取配置
- `action=config&operation=apply` - 应用配置
- `action=config&operation=test` - 测试配置

#### 日志管理
- `action=logs&type=access&lines=100` - 获取访问日志
- `action=logs&type=error&lines=100` - 获取错误日志
- `action=logs&operation=clear&type=all` - 清理日志

## 更新日志

### v1.0.0 (2024-01-XX)
- 初始版本发布
- 基础和高级配置模式
- 服务管理功能
- 日志查看器
- SSL 配置支持
- 多语言支持

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 致谢

- [ASUSWRT-Merlin](https://www.asuswrt-merlin.net/) - 优秀的路由器固件
- [Entware](https://entware.net/) - 软件包管理器
- [Nginx](https://nginx.org/) - 高性能 Web 服务器
- [Vue.js](https://vuejs.org/) - 渐进式 JavaScript 框架
- [Vite](https://vitejs.dev/) - 现代前端构建工具

## 支持

如果您遇到问题或有建议，请：

1. 查看 [FAQ](#常见问题-faq)
2. 搜索 [Issues](https://github.com/NasPilot/asuswrt-merlin-nginxui/issues)
3. 创建新的 Issue
4. 加入讨论 [Discussions](https://github.com/NasPilot/asuswrt-merlin-nginxui/discussions)

## 免责声明

本软件按 "原样" 提供，不提供任何明示或暗示的保证。使用本软件的风险由用户自行承担。作者不对因使用本软件而造成的任何损害负责。

请在使用前备份您的路由器配置，并确保您了解所进行的操作。