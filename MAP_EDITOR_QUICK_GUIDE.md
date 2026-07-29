# 地图编辑器快速指南

打开 `scenes/maps/cell_block_a2_tilemap.tscn` 后：

1. `FloorLayer`、`WallLayer`、`DoorFrameLayer` 选择 TileSet 来源 0 的建筑素材。
2. `DecorationLayer` 选择 TileSet 来源 1 的标准化装饰素材。
3. 来源 1 对应原图第 5–11 行；每个素材都是透明、等比、居中的 48×48 单元。
4. 灯具、管道、终端和血迹不参与碰撞与遮光；墙体仍只使用来源 0 的结构瓦片。

当前灰色覆盖仍属于 Godot TileMap 编辑器的选择/绘制预览，不属于运行时地板材质。
