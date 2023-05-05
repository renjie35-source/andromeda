# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

Andromeda 是一个《魔兽世界》(正式服 / Retail)的整体界面替换插件,用 Lua 编写。源码在 `src/`,打包时映射为名为 `andromeda` 的插件文件夹。许可证为 GPL-3.0。

## 本地工具链

工具已安装在 `~/.local/bin`(用户 PATH 内,新开终端可直接调用)。配置文件以项目内的为准,不要用命令行参数覆盖,以保持与 CI 一致。

```bash
stylua src                  # 格式化全部源码(遵循 .stylua.toml:180列、空格缩进、优先单引号、Unix 换行)
stylua --check src          # 仅检查格式,不改动(提交前 / CI 用)
luacheck src                # 静态检查(遵循 .luacheckrc,std=lua51)。注意:目录参数不要加尾部斜杠,否则报 Permission denied
luacheck src/core/core.lua  # 检查单个文件

cd scripts && python merge-locales.py          # 扫描 src 中所有 L["..."] 键,补齐到各语言文件(脚本内硬编码 ../src/,必须在 scripts/ 下运行)
cd src && python ../scripts/generate-changelog.py   # 由 src/core/changelog/ 生成 CHANGELOG.md(必须在 src/ 下运行;依赖 pip 包 slpp)
```

`.styluaignore` 与 `.luacheckrc` 都排除了 `libraries/` 和 `locales/`,这两个目录不要格式化或检查。

无单元测试框架。`src/tests/` 是开发期游戏内调试代码,被 `.toc` 中的 `#@do-not-package@` 标记排除出发布包,不参与本地构建。

## 打包发布

打包完全由 GitHub Actions(`BigWigsMods/packager`)在推送 tag 时自动完成,本地不需要也不应手动打包。规则见 `.pkgmeta`:`src/` 内容映射为 `andromeda/`,排除 `.vscode assets docs scripts utils`。`.toc` 中的 `@...@` 占位符(版本号、interface 版本、hash)由 CI 替换。推送 `*.*.*` tag 走正式 release,`*.*.*-*` 走 pre-release。

## 核心架构

### Engine 三元组 (F / C / L)

整个插件围绕一个共享的 `engine` 表组织,在 `src/core/init.lua` 创建:

- `engine[1]` = `F` — 函数库 / AceAddon 实例(混入 AceEvent / AceHook / AceTimer)
- `engine[2]` = `C` — 常量与配置(`C.DB`、`C.Assets`、`C.AddOnVersion` 等)
- `engine[3]` = `L` — AceLocale 本地化字符串表

每个源文件开头都用 `local F, C, L = unpack(select(2, ...))` 取出三元组。`engine` 还通过 `_G.ANDROMEDA` 暴露,供外部插件用 `unpack(_G.ANDROMEDA)` 访问。

### 加载机制

`.toc` 不直接列出每个 lua 文件,而是引用各目录的 `_loader.xml`,由 XML 链式 `<Script>` / `<Include>` 控制加载顺序。**新增 lua 文件必须手动加进对应的 `_loader.xml`**,否则不会被加载。加载顺序:`libraries → core/init → locales → core → modules → gui`。

### 模块系统

模块通过 `F:RegisterModule('Name')` 注册(返回模块表),用 `F:GetModule('Name')` 获取。模块定义自己的方法,典型写法 `function MODULE:SomeMethod()`。若模块定义了 `OnLogin` 方法,会在 `PLAYER_LOGIN` 时由 init.lua 的 initQueue 自动调用——这是模块的初始化入口。`src/modules/` 下每个子目录是一个功能域(actionbar、chat、unitframe、nameplate、tooltip 等)。

### 事件系统

不要直接用裸 frame 注册事件。用 `F:RegisterEvent(event, func, unit1, unit2)` / `F:UnregisterEvent(event, func)`(定义于 init.lua)。多个回调共享单一隐藏 frame 分发。特殊别名:`'CLEU'` 自动映射为 `COMBAT_LOG_EVENT_UNFILTERED` 并自动传入 `CombatLogGetCurrentEventInfo()`。

### 设置与 SavedVariables(三层)

- 默认设置定义在 `src/gui/configs.lua` 的 `C.AccountSettings` 与 `C.CharacterSettings`。**新增设置项从这里开始。**
- SavedVariables:`ANDROMEDA_ADB`(账号级)、`ANDROMEDA_CDB`(角色级)、`ANDROMEDA_PDB`(配置档,1-5)。
- 运行时活跃配置统一通过 `C.DB` 访问。在 `ADDON_LOADED` 时根据当前角色选择的 profile,把 `C.DB` 指向 `ANDROMEDA_CDB` 或某个 `ANDROMEDA_PDB[n]`(见 `src/core/core.lua`),并用 `InitialSettings` 把默认值补全。
- GUI 选项面板在 `src/gui/options.lua` 把设置项连到控件;新增设置后通常需要在这里加对应 UI。

### 命令入口

斜杠命令用 `F:RegisterSlashCommand`(定义于 `src/core/functions.lua`)注册。主命令 `/and` 在 `src/core/commands.lua`,分发到 GUI、安装向导(Tutorial)、解锁布局(Mover)、cheatsheet 等子功能。

## 版本适配注意事项

`.toc` 用 `## Interface: @toc-version-retail@` 占位符,由 CI 自动替换为当前正式服版本号,不要手填。代码中已有版本兼容模式,例如 `GetAddOnMetadata or C_AddOns.GetAddOnMetadata`——适配新版本被移除/改名的 API 时沿用这种回退写法。项目大量使用 `C_*` 命名空间 API,这些是版本变动时最易失效处。

## 约定

- 缩进 4 空格,LF 换行,UTF-8,行尾不留空白(见 `.editorconfig`)。
- `src/locales/*.lua` 由 merge-locales 工具生成,不要手改;改文案后跑该脚本并复核 git diff。
- 提交信息会被推送到 Discord(`commit-message.yml`),保持规范。
