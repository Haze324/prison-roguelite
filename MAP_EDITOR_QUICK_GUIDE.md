# 地图编辑器快速指南

打开 `scenes/maps/cell_block_a2_tilemap.tscn`，在 `TileMapLayer` 面板中选择下列层。

1. `FloorLayer`：源 0 的第 0 行地板。
2. `WallLayer`：源 0 的四向墙带、四个转角、T 口和十字口。房间顶/底/左/右边必须使用对应方向，不能旋转后凭感觉替代。
3. `DoorFrameLayer`：源 0 的 `(5,4)` 门框，放在墙体预留位置。
4. `DecorationLayer`：源 1 的透明小装饰。现在源 1 按实际 9×9 母图网格切割；大型终端、管线和跨格设备应使用独立场景，不要压缩进单格。

墙体验收标准：相邻单元的墙带连续、墙宽恒为 `32px`、转角同时接两条边、T 口同时接三条边。编辑器里的选择覆盖色不是运行时材质。

重建顺序：

`build_prison_wall_kit.gd` → `build_prison_tileset.gd` → `build_cell_block_a2_tilemap.gd` → `audit_prison_tileset.gd`。
