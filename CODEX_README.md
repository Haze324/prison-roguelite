# Codex 快速入门 — Prison Roguelite

## 项目信息

| 项 | 内容 |
|------|------|
| **项目名称** | prison-roguelite |
| **GitHub 仓库** | https://github.com/Haze324/prison-roguelite |
| **GitHub 账号** | 1084796802@qq.com（用户 Haze324） |
| **仓库可见性** | Public（MIT 许可证） |
| **游戏类型** | 2D 俯视角 Roguelite 恐怖战术射击 |
| **核心钩子** | 「噪声即资源」——开枪引怪，沉默求生 |
| **完整设计文档** | `game-design-decisions.md`（仓库根目录） |

## 开发环境

| 工具 | 版本要求 | 用途 |
|------|------|------|
| **Godot Engine** | 4.4+ | 游戏引擎 |
| **Godot 配置** | .NET 不启用，纯 GDScript | — |
| **Godot MCP** | 已配置 | Claude Code 通过 MCP 操控 Godot |
| **Git** | 最新 | 版本控制 |
| **操作系统** | Windows 11 | — |

## Claude Code 和你的分工

```
Claude Code（架构师 + Git 管理员）    Codex（执行层程序员）
├── 设计讨论 + GDD 修改                ├── 写 .gd Resource 类
├── 接口定义（函数签名+信号列表）        ├── 填 .tres 数值文件
├── project.godot 配置                 ├── 搭场景（拼节点+设属性）
├── Autoload 注册                      ├── AnimationPlayer 关键帧
├── 输入映射                            ├── UI 场景（HUD/背包/主菜单）
├── GDExtension 插件集成               ├── S0 几何形美术
├── 跨系统串联                          ├── 系统逻辑实现
├── Git add/commit/push                └── 所有 @export 写中文注释
├── 代码审查（是否符合接口约定）
└── 所有设计决策
```

**你不负责**：Git 任何操作 / 修改 project.godot / 修改 game-design-decisions.md / 决定设计。

## 文件结构

```
prison-roguelite/
├── CODEX_README.md              ← 你正在看
├── CODEX_STANDARDS.md           ← 编码规范+美术标准+色板
├── CODEX_DATA_DEFS.md           ← 全局枚举+每个 Resource 类完整字段
├── CODEX_SYSTEMS_REF.md         ← 数值表+伤害管线+状态机+按键+EventBus
├── CODEX_DESIGN_DECISIONS.md    ← 关键决策+废弃项+特殊规则
├── game-design-decisions.md     ← 完整设计文档（真相源）
├── .gitignore
│
├── scripts/data/     ← Resource 类 .gd 文件
├── scripts/core/     ← event_bus.gd, game_data.gd (Autoload)
├── scripts/systems/  ← 系统逻辑 .gd 文件
├── scripts/entities/ ← 玩家/怪物/子弹基类
│
├── resources/        ← .tres 数值文件（配参不碰代码）
├── scenes/           ← .tscn 场景文件
├── assets/           ← 美术/音频/字体
└── addons/           ← 第三方插件（Claude Code 管理）
```

## 工作流

```
1. Claude Code 告诉你这轮要做什么（任务 + 接口定义）
2. 你实现（.gd / .tres / .tscn）
3. 你自查：@export 有中文注释？没有硬编码数值？信号发到了 EventBus？
4. 你把文件路径或内容告诉 Claude Code
5. Claude Code 检查 → 集成 → Git 提交
```

## 有问题？

在当前对话中直接问 Claude Code。说清楚哪个文件、哪个字段、哪个逻辑不清楚。

## 五个交接文件总览

| 文件 | 什么时候看 |
|------|------|
| CODEX_README.md | 第一份看，了解全貌 |
| CODEX_STANDARDS.md | 写任何代码前看 |
| CODEX_DATA_DEFS.md | 写 Resource 类时对照 |
| CODEX_SYSTEMS_REF.md | 写系统逻辑时查数值/管线/信号 |
| CODEX_DESIGN_DECISIONS.md | 不确定"能不能做"时查 |
