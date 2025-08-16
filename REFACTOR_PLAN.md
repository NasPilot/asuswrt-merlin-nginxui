# NginxUI 项目重构计划

基于 XrayUI 成功经验的项目结构优化方案

## 1. 当前项目结构分析

### 1.1 现有问题

#### 后端架构问题
- **复杂的模块导入**: 手动循环导入多个模块，缺乏统一的导入机制
- **错误处理不一致**: 使用 `set -e` 和 `trap` 但在不同模块间处理方式不统一
- **锁文件管理复杂**: 手动管理锁文件，容易出现死锁或清理不当
- **日志系统分散**: 日志函数分布在不同文件中，缺乏统一管理

#### 前端构建问题
- **缺乏开发模式**: 没有类似 xrayui 的 `watch` 模式进行实时开发
- **构建配置复杂**: vite.config.ts 过于复杂，包含过多自定义逻辑
- **缺乏同步机制**: 没有自动同步到路由器的功能
- **调试困难**: 缺乏本地预览和调试支持

#### 项目组织问题
- **配置文件分散**: 多个配置文件缺乏统一管理
- **脚本结构不清晰**: 后端脚本职责划分不明确
- **依赖管理复杂**: 模块间依赖关系复杂，难以维护

### 1.2 XrayUI 优势对比

#### XrayUI 的成功经验
1. **简洁的模块导入**: 使用统一的 import 机制
2. **事件驱动架构**: 通过 service_event 统一处理各种操作
3. **简化的构建流程**: 清晰的 watch 和 build 模式
4. **完善的开发支持**: 本地预览和实时同步
5. **统一的配置管理**: 集中的配置文件和环境变量

## 2. 重构方案

### 2.1 后端架构重构

#### 2.1.1 简化主控制脚本
```bash
#!/bin/sh
# 简化的 nginxui.sh 主脚本

# 版本信息
NGINXUI_VERSION="1.0.0"

# 设置脚本目录
export NGINXUI_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 导入核心模块
. "$NGINXUI_SCRIPT_DIR/_globals.sh"
. "$NGINXUI_SCRIPT_DIR/_helper.sh"

# 统一的服务事件处理
service_event() {
    case "$1" in
        "start") start_nginxui ;;
        "stop") stop_nginxui ;;
        "restart") restart_nginxui ;;
        "status") check_status ;;
        "install") install_nginxui ;;
        "uninstall") uninstall_nginxui ;;
        "config") handle_config "$2" "$3" ;;
        "webapp") handle_webapp "$2" ;;
        *) show_usage ;;
    esac
}

# 主入口
if [ $# -eq 0 ]; then
    show_usage
else
    service_event "$@"
fi
```

#### 2.1.2 统一的模块导入机制
```bash
# _helper.sh 中的导入函数
import() {
    local module="$1"
    local module_path="$NGINXUI_SCRIPT_DIR/$module.sh"
    
    if [ -f "$module_path" ]; then
        . "$module_path"
    else
        log_error "Module $module not found at $module_path"
        return 1
    fi
}

# 批量导入模块
import_modules() {
    for module in "$@"; do
        import "$module" || return 1
    done
}
```

#### 2.1.3 改进的错误处理和日志系统
```bash
# 统一的错误处理
setup_error_handling() {
    set -e
    trap 'handle_error $? $LINENO' ERR
}

handle_error() {
    local exit_code=$1
    local line_number=$2
    log_error "Script failed with exit code $exit_code at line $line_number"
    cleanup_on_error
    exit $exit_code
}

# 统一的日志系统
setup_logging() {
    mkdir -p "$(dirname "$NGINXUI_LOG")"
    exec 3>&1 4>&2
    exec 1> >(tee -a "$NGINXUI_LOG")
    exec 2> >(tee -a "$NGINXUI_LOG" >&2)
}
```

### 2.2 前端构建优化

#### 2.2.1 简化的 vite.config.ts
```typescript
import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';
import { resolve } from 'path';

// 简化的 shell 文件监听
function watchShellFiles() {
  return {
    name: 'watch-shell-files',
    buildStart() {
      // 监听后端 shell 文件变化
      this.addWatchFile(resolve(__dirname, 'src/backend'));
    }
  };
}

export default defineConfig(({ mode }) => ({
  plugins: [
    vue(),
    watchShellFiles()
  ],
  build: {
    outDir: 'dist',
    rollupOptions: {
      input: {
        app: resolve(__dirname, 'src/main.ts')
      },
      output: {
        entryFileNames: 'app.js',
        assetFileNames: '[name].[ext]'
      }
    },
    minify: mode === 'production'
  },
  define: {
    __DEV__: mode === 'development'
  }
}));
```

#### 2.2.2 添加 watch 和同步功能
```json
{
  "scripts": {
    "dev": "vite",
    "build": "vue-tsc && vite build",
    "watch": "vite build --watch --mode development",
    "watch-prod": "vite build --watch --mode production",
    "preview": "vite preview",
    "sync": "node vite.sync.js"
  }
}
```

#### 2.2.3 创建同步脚本 vite.sync.js
```javascript
// 基于 xrayui 的同步机制
import { readFileSync } from 'fs';
import { Client } from 'ssh2';

const config = {
  host: process.env.ROUTER_HOST || '192.168.1.1',
  username: process.env.ROUTER_USER || 'admin',
  password: process.env.ROUTER_PASS || '',
  remotePath: '/www/user/nginxui/'
};

function syncFiles() {
  const conn = new Client();
  
  conn.on('ready', () => {
    console.log('Connected to router, syncing files...');
    // 同步逻辑
  }).connect(config);
}

if (process.env.NODE_ENV !== 'production') {
  syncFiles();
}
```

### 2.3 项目结构重组

#### 2.3.1 推荐的目录结构
```
asuswrt-merlin-nginxui/
├── src/
│   ├── frontend/           # 前端源码
│   │   ├── components/
│   │   ├── views/
│   │   ├── modules/
│   │   ├── styles/
│   │   └── main.ts
│   ├── backend/            # 后端脚本
│   │   ├── nginxui.sh      # 主控制脚本
│   │   ├── _globals.sh     # 全局变量和配置
│   │   ├── _helper.sh      # 辅助函数
│   │   ├── modules/        # 功能模块
│   │   │   ├── service.sh
│   │   │   ├── config.sh
│   │   │   ├── webapp.sh
│   │   │   └── install.sh
│   │   └── hooks/          # 系统钩子
│   │       ├── firewall-start
│   │       ├── post-mount
│   │       └── services-start
│   └── shared/             # 共享资源
│       ├── templates/
│       └── configs/
├── dist/                   # 构建输出
├── tools/                  # 开发工具
├── docs/                   # 文档
└── tests/                  # 测试文件
```

#### 2.3.2 配置文件统一
```bash
# .env.example
ROUTER_HOST=192.168.1.1
ROUTER_USER=admin
ROUTER_PASS=
NGINXUI_DEBUG=0
NGINXUI_AUTO_SYNC=1
```

### 2.4 开发体验优化

#### 2.4.1 本地预览支持
```html
<!-- preview.html -->
<!DOCTYPE html>
<html>
<head>
    <title>NginxUI Preview</title>
    <script>
        // 模拟路由器环境
        window.nginxui = {
            version: '1.0.0',
            status: 'running',
            config: {}
        };
    </script>
</head>
<body>
    <div id="app"></div>
    <script type="module" src="./dist/app.js"></script>
</body>
</html>
```

#### 2.4.2 开发调试脚本
```bash
#!/bin/sh
# dev-server.sh
echo "Starting NginxUI development server..."
npm run watch &
python3 -m http.server 8080 &
echo "Preview available at: http://localhost:8080/preview.html"
```

## 3. 实施步骤

### 阶段一：后端重构
1. 重构主控制脚本 nginxui.sh
2. 简化模块导入机制
3. 统一错误处理和日志系统
4. 重组模块结构

### 阶段二：前端优化
1. 简化 vite.config.ts
2. 添加 watch 模式和同步功能
3. 创建本地预览环境
4. 优化构建流程

### 阶段三：整合测试
1. 集成测试所有功能
2. 性能优化
3. 文档更新
4. 部署验证

## 4. 预期收益

### 4.1 开发效率提升
- 实时开发和预览
- 简化的构建流程
- 更好的错误提示

### 4.2 维护性改善
- 清晰的模块结构
- 统一的代码风格
- 简化的依赖关系

### 4.3 用户体验优化
- 更快的构建速度
- 更稳定的运行
- 更好的错误恢复

## 5. 风险评估

### 5.1 兼容性风险
- 现有配置文件可能需要迁移
- 部分自定义脚本可能需要调整

### 5.2 迁移风险
- 需要充分测试确保功能完整性
- 建议分阶段实施，逐步迁移

### 5.3 缓解措施
- 保留原有文件作为备份
- 提供迁移脚本和文档
- 充分的测试覆盖

---

*本重构计划基于 XrayUI 的成功经验，旨在提升 NginxUI 项目的开发效率、维护性和用户体验。*