# Setup HBX Action

`setup-hbx` 是一个 GitHub Action，用于在 Linux Runner 上快速还原 HBuilderX CLI 环境并构建 UniApp（Vite + Vue3）APP 产物。Action 内置多个 `core-*.zip/.tar.gz` 归档，按需解压到临时目录，执行 `core-install.sh` 安装依赖，最后运行 `node_modules/@dcloudio/vite-plugin-uni/bin/uni.js build -p app`。在本地需要 `npm run app` 的项目，在 GitHub Actions 中即可通过几行 YAML 完成同样的打包流程。

## 快速上手

在待打包的 UniApp 仓库中新增工作流（`username/setup_hbx` 请替换为实际仓库名/tag）：

```yaml
name: Build UniApp

on:
  push:
    branches: [ main ]

jobs:
  app-plus:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: 构建 App
        uses: username/setup_hbx@v1
        with:
          core_version: '4.86'
          uni_project_dir: .
          output_dir: uni-result

      - name: 上传产物
        uses: actions/upload-artifact@v4
        with:
          name: uni-result
          path: uni-result
```

Action 会自动：

1. 安装 Node.js 20 与 Yarn。
2. 根据 `core_version` 选择对应的 `core-*.zip/.tar.gz` 归档并解压。
3. 执行 `core-install.sh`（通过 `npm run setup` 同款逻辑）安装 HBuilderX 依赖。
4. 调用官方 CLI 生成 `output_dir` 指定的产物，并把绝对路径通过 `output-dir` 输出给后续步骤。

## 输入参数

| 参数 | 说明 | 默认值 |
| ---- | ---- | ------ |
| `core_version` | HBuilderX 核心版本或归档文件名，如 `4.86`、`core-3.9.5.zip` | `4.86` |
| `uni_project_dir` | UniApp 项目路径（基于 `GITHUB_WORKSPACE` 或绝对路径） | `.` |
| `output_dir` | 构建结果输出目录 | `result` |
| `node_env` | 传递给 `UNI_NODE_ENV` 的值 | `production` |

### 输出

| 输出 | 说明 |
| ---- | ---- |
| `output-dir` | 构建结果的绝对路径，可直接在后续步骤引用 |

示例：

```yaml
- name: Build with HBX
  id: hbx
  uses: username/setup_hbx@v1

- run: ls "${{ steps.hbx.outputs['output-dir'] }}"
```

## 支持的核心版本

仓库根目录自带以下归档，可直接通过 `core_version` 指定：

- `3.9.5` → `core-3.9.5.zip`
- `3.9.8` → `core-3.9.8.zip`
- `3.9.9` → `core-3.9.9.tar.gz`
- `4.0.7` → `core-4.0.7.tar.gz`
- `4.15.0` → `core-4.15.0.tar.gz`
- `4.86` → `core-4.86.tar.gz`

若需要其他版本，可将新的 `core-<version>.tar.gz` 或 `.zip` 放在仓库根目录，并在 workflow 中把 `core_version` 设置为对应版本号或完整文件名。

## 本地调试

虽然 Action 封装了全部步骤，仍可以在本地仓库中验证流程：

```bash
# 选择要测试的核心版本
CORE_DIR=$(RUNNER_TEMP=./.tmp GITHUB_ACTION_PATH=$PWD bash scripts/extract-core.sh 4.86)
export CORE_ROOT="$CORE_DIR"
npm install
npm run setup           # 初始化 HBuilderX 依赖
UNI_INPUT_DIR=/path/to/uni-app \
UNI_OUTPUT_DIR=$PWD/result \
HBX_PLUGIN_DIR="$CORE_ROOT/plugins/uniapp-cli-vite" \
npm run app
```

`scripts/run-app.js` 会自动切换到 `uniapp-cli-vite`，以 Linux 风格执行 `node node_modules/@dcloudio/vite-plugin-uni/bin/uni.js build -p app`。

## 仓库结构

```
core-*.zip / core-*.tar.gz   # 多个 HBuilderX 核心归档
scripts/
  ├─ extract-core.sh         # 按版本解压核心
  ├─ setup-core.sh           # 调用 core-install.sh 初始化依赖
  └─ run-app.js              # Linux 下的 npm run app 封装
core-install.sh              # 复用官方脚本，支持 CORE_ROOT 自动探测
action.yml                   # GitHub Action 定义
.github/workflows/uni-build.yml  # 演示 workflow，使用本仓库作为 Action
docs/说明书.md               # 中文说明文档
```

完成修改后，为仓库打 tag（如 `v1.0.0`），在业务项目中通过 `uses: username/setup_hbx@v1.0.0` 即可引用该 Action。
