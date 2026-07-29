# 地图编辑器快速指南

编辑地图：`scenes/maps/cell_block_a2_tilemap.tscn`

1. 在场景树选择 `FloorLayer`、`WallLayer` 或 `DoorFrameLayer`。
2. 图集使用 `prison_tileset_atlas_material_48_v4.png`，它是 12×12 个严格的 48×48 单元。
3. `WallLayer` 瓦片自带碰撞和遮光；门洞在墙层留空，再在 `DoorFrameLayer` 放门框。
4. 使用 `Ctrl+S` 保存；运行时直接使用场景中保存的 TileMapLayer。

如果 Godot 已经打开 TileSet 面板，关闭并重新打开 `prison_tileset_v1.tres` 或重新打开地图场景，编辑器会读取新的外部纹理引用。
