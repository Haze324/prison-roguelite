# TileSet 瓦片图例

运行时结构图集：`assets/generated/tilesets/industrial_prison/prison_structure_atlas_48_v5.png`

该图集固定为 3×2 格，总尺寸 144×96；每一格严格为 48×48 像素。它只包含可用于 TileMap 的完整结构瓦片，避免灯具、管道等跨格装饰混进地板工具。

| 图集坐标 | 用途 | 使用层 | 碰撞/遮光 |
|---:|---|---|---|
| `(0, 0)` | 普通地面 | `FloorLayer` | 否 |
| `(1, 0)` | 走廊地面 | `FloorLayer` | 否 |
| `(2, 0)` | 横向墙 | `WallLayer` | 是 |
| `(0, 1)` | 纵向墙 | `WallLayer` | 是 |
| `(1, 1)` | 房间转角 | `WallLayer` | 是 |
| `(2, 1)` | 门框 | `DoorFrameLayer` | 否 |

完整 12×12 原材质图集 `prison_tileset_atlas_material_48_v4.png` 仅作视觉参考和后续独立装饰来源；红灯、青灯、管道等不允许绘制到 `FloorLayer`。
