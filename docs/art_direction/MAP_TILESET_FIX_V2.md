# 地图 TileSet 材质与网格修复记录 V4

更新时间：2026-07-29

## 修复内容

- 正式图集恢复原先的工业监狱材质，不再使用简化的程序化砖块图集。
- 原始材质图实际为 12×12 网格，已逐格裁切为固定的 48×48 像素。
- 正式图集：`assets/generated/tilesets/industrial_prison/prison_tileset_atlas_material_48_v4.png`。
- TileSet：`resources/maps/prison_tileset_v1.tres`。
- 地图墙体仍由 `TileMapLayer` 负责，墙体瓦片负责碰撞和遮光，门框层只负责视觉。
- 旧的 `prison_tileset_atomic_48_v3.png` 保留为回退参考，不再作为运行时材质源。

## 视觉原则

材质、锈蚀、裂纹、管道、灯具和警示色以原工业监狱图集为准；网格尺寸和碰撞配置独立处理，不能为了方便编辑而牺牲原始美术质量。
