---
name: andromeda-dev
description: Andromeda(魔兽世界 Lua 插件)项目的本地开发工具链。涉及 Lua 代码格式化(StyLua)、静态检查(luacheck)、多语言 locale 合并、生成 changelog、打包发布规则、以及适配新版本 WoW API 时使用。
---

# Andromeda 插件开发

Andromeda 是一个用 Lua 编写的魔兽世界(Retail)界面替换插件。本 skill 封装该项目的本地开发工作流。

## 项目布局

- `src/` — 插件源码,打包时映射为 `andromeda/`
  - `andromeda.toc` — 入口清单,通过 `_loader.xml` 链式加载 core/locales/modules/gui
  - `core/` `gui/` `modules/` — 主体代码
  - `locales/` — 多语言(enUS/ruRU/zhCN),**自动生成,勿手改**
  - `libraries/` — 第三方库,**不格式化、不检查**
  - `tests/` — 仅开发期加载(`#@do-not-package@` 包裹)
- `scripts/` — Python 构建脚本
- `.luacheckrc` `.stylua.toml` — 工具配置,以项目配置为准,勿覆盖

## 工具链

已安装在 `~/.local/bin`(用户 PATH,新终端可直接调用):

- **stylua** 2.5.2 — 格式化。配置 `.stylua.toml`:180 列宽、空格缩进、自动优先单引号、Unix 换行。忽略列表见 `.styluaignore`(.github/.vscode/assets/libraries/locales)
- **luacheck** 1.2.0 — 静态检查(自带 Lua 5.4 运行时)。配置 `.luacheckrc`:std=lua51,排除 libraries/locales
- **python** 3.7.9 + `slpp` 库 — 运行构建脚本

## 常用命令

均在仓库根目录 `D:\CodeFile\andromeda` 执行,除非另有说明。

### 格式化
```bash
stylua src/                 # 格式化全部源码(自动遵循 .stylua.toml 与 .styluaignore)
stylua --check src/         # 仅检查是否符合格式,不改动(CI/提交前用)
stylua src/modules/chat     # 格式化指定目录
```

### 静态检查
```bash
luacheck src                # 检查全部源码(自动读取 .luacheckrc)
luacheck src/core/core.lua  # 检查单个文件
```
注意:Windows 版 luacheck 传目录时**不要加尾部斜杠**(`luacheck src` 而非 `luacheck src/`),否则会报 "Permission denied"。

### 合并 locale(新增可翻译字符串后)
脚本扫描 `src/` 中所有 `L["..."]` 键,补齐到各语言文件。**必须在 `scripts/` 目录运行**(脚本内硬编码 `../src/`):
```bash
cd scripts && python merge-locales.py
```
注意:会重写 `src/locales/*.lua`,运行后用 git diff 复核。

### 生成 changelog
读取 `src/core/changelog/` 下的最新版本记录生成 `CHANGELOG.md`。**必须在 `src/` 目录运行**:
```bash
cd src && python ../scripts/generate-changelog.py
```

## 打包发布

打包由 GitHub Actions 自动完成(`BigWigsMods/packager`),本地通常无需手动打包。规则见 `.pkgmeta`:
- `src/` 内容映射为 `andromeda/`
- 打包时排除:`.vscode` `assets` `docs` `scripts` `utils`
- `tests/` 因 `#@do-not-package@` 标记不进入发布包
- 发布触发:推送 `*.*.*` tag 走正式 release,`*.*.*-*` 走 pre-release

## 提交前检查清单

1. `stylua --check src/` 通过(不通过则 `stylua src/` 修复)
2. `luacheck src/` 无 error
3. 若改动了 UI 文案 → `cd scripts && python merge-locales.py` 并复核 diff
4. 遵循项目约定式提交(commit message 会推送到 Discord)

## 注意事项

- 不要手改 `src/locales/` 下的文件,它们由 merge-locales 工具生成
- 不要格式化或检查 `src/libraries/`(第三方代码)
- 改 lint/格式规则时改 `.luacheckrc` / `.stylua.toml`,不要在命令行用参数覆盖,保持与 CI 一致

## 适配新版本 WoW API

适配新客户端版本(如 Patch 12.0.x)时,主要风险是 API 被移除/改名/迁移到 `C_` 命名空间。项目当前用 `@toc-version-retail@` 占位符,CI 通过 `Numynum/ToCVersions` 自动替换 Interface 号,无需手改 toc。

### 工具:wow-api MCP 服务器

`.mcp.json` 已配置 `wow-api` MCP 服务器(基于 ketho.wow-api 扩展数据),覆盖 8000+ 函数、90+ 弃用函数、260 个 C_ 命名空间、事件签名、枚举。**适配时优先用它查证,不要凭记忆判断 API 是否还在。** 可用查询:

- `lookup_api(name)` — 按名查函数,弃用的会标 `[DEPRECATED]` 并给替换方案与版本
- `search_api(query)` — 全文搜索
- `list_deprecated(filter?)` — 列弃用函数及替换(如 `list_deprecated("Spell")`)
- `get_namespace(name)` — 某个 C_ 命名空间下的全部函数
- `get_widget_methods(type)` — widget 类方法
- `get_enum(name)` / `get_event(name)` — 枚举值 / 事件参数

注意:MCP 服务器需 Claude Code 重启会话后才连接。数据更新靠 `code --install-extension ketho.wow-api` 升级扩展。

### 工具:Lua Language Server

`.luarc.json` 已配置 LuaLS 加载 ketho 注解(`workspace.library` 指向扩展的 Annotations 目录),runtime 设为 Lua 5.1,忽略 libraries/locales。VS Code 装了 `sumneko.lua` + `ketho.wow-api` 即生效:写代码时未知/弃用 API 会直接标出。

### 适配流程建议

1. 用 MCP `list_deprecated` 拉出当前版本的弃用清单
2. 在 `src/` 里 grep 这些函数名,定位受影响文件(注意排除 `libraries/`)
3. 逐个用 `lookup_api` 确认替换方案,改代码
4. 嵌入库(oUF、cargBags、Ace*、Lib*)通常需从上游同步新版,而非手改 —— 先查上游仓库有无对应版本更新
5. 改完跑 `stylua src` + `luacheck src` 验证
6. `.luacheckrc` 里手工维护了 WoW API 全局白名单,新增/删除 API 后需同步更新该列表,否则 luacheck 会误报 undefined global
