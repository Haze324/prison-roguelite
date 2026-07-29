# 地图编辑器快速指南

打开 `scenes/maps/cell_block_a2_tilemap.tscn`，在 `TileMapLayer` 面板中选择下列层。

1. `FloorLayer`：选择源 0 的第 0 行地板，不要在该层放墙或装饰。
2. `WallLayer`：选择源 0 的四向直墙与四角。房间顶边使用上侧横墙、底边使用下侧横墙、左/右边使用对应竖墙；四个角必须使用各自专用角块。
3. `DoorFrameLayer`：使用源 0 的 `(4,1)` 门框，放在预留墙洞内。
4. `DecorationLayer`：选择源 1。灯具、管线、终端和血迹都只放在此层；它们具有透明背景，会叠加到已有墙体或地板上，绝不替换结构墙面。

编辑器里的灰色覆盖是选择/绘制预览，不是运行时材质。若修改原始图集，依次运行：

`build_modular_prison_environment_atlases.gd` → `build_prison_modular_canonical_atlas.gd` → `build_prison_tileset.gd` → `build_cell_block_a2_tilemap.gd`。
