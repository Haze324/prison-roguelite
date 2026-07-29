# 地图编辑器快速指南

打开 `scenes/maps/cell_block_a2_tilemap.tscn`，选择需要绘制的 `TileMapLayer`。

1. 选择唯一的图集源 0。它显示 7 列 × 8 行，共 56 个完整素材。
2. 每个蓝色/黄色选择框固定为 48×48，且严格覆盖一张完整素材；不要再使用旧的 12×12 图集或旧的装饰源。
3. `FloorLayer` 只画地面；`WallLayer` 只画墙体和转角；`DoorFrameLayer` 只画门框；`DecorationLayer` 可放灯具、管线、格栅和血迹。
4. 装饰图块不带碰撞和遮光；地图边界与房间墙体仍使用结构图块。

编辑器里的灰色覆盖是 TileMap 的选择/绘制预览，不是游戏运行时的地板材质。
