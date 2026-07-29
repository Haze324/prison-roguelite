# 地图编辑器快速指南

打开 `scenes/maps/cell_block_a2_tilemap.tscn` 后：

1. `FloorLayer` 只能选择图集第一行的两块完整地面。
2. `WallLayer` 选择横墙、竖墙或转角；这些瓦片带碰撞与遮光。
3. `DoorFrameLayer` 只放右下角门框，门洞本身应在墙层留空。
4. 结构图集为 3×2 个严格 48×48 单元，选择框与瓦片 1:1。
5. 灯具、管道、控制器属于独立装饰，不要放进 `FloorLayer`。

灰色房间底板已经从 `cell_block_a2` 的运行场景关闭；地面显示由 `FloorLayer` 的实际瓦片负责。
