# 地图模块化环境素材记录 V7

更新时间：2026-07-29

## 目标

建立可从任意方向拼接的工业监狱环境套件：地板、墙体、内外转角、门、灯具和管线均遵循同一 48×48 网格与同一材质边缘规则。

## 最终结构

- `prison_modular_structure_raw_v1.png`：AI 生成的结构母版。
- `prison_modular_structure_48_v4.png`：正式 16×8 结构图集。直墙被派生为四个方向；四个角的两条连接边从对应直墙复制并锁定。
- `prison_modular_props_48_v1.png`：正式 8×8 透明装饰图集。红灯、青灯、管线等不再携带任何墙面或地面背景。
- `prison_modular_seam_preview_v4.png`：四方向房间闭合验收图。
- `cell_block_a2_modular_preview_v1.png`：完整地图拼接验收图。

## 验收规则

1. 横墙接横墙、竖墙接竖墙、转角接两侧直墙均不得出现黑缝、透明缝、重复外框或厚度跳变。
2. 墙体只由源 0 负责；源 1 的装饰只能作为透明覆盖物。
3. 地板仅由 `FloorLayer` 绘制；门框仅由 `DoorFrameLayer` 绘制。
4. `audit_prison_tileset.gd` 必须通过：结构 128 格、装饰 64 格、地图三层均可加载。
