# TileSet 瓦片图例

运行时图集：`assets/generated/tilesets/industrial_prison/prison_tileset_atlas_material_48_v4.png`

- 完整图集为 12×12，共 144 个素材单元。
- 每一个单元都按相同标准裁切、规范化为 48×48 像素。
- TileSet 的选择框严格等于一个素材单元；灯具、管道、墙体、地板均使用同一 48×48 网格。

| 图集坐标 | 用途 | 使用层 | 碰撞/遮光 |
|---:|---|---|---|
| `(0, 0)` | 普通地面 | `FloorLayer` | 否 |
| `(1, 0)` | 走廊地面 | `FloorLayer` | 否 |
| `(0, 2)` | 横向墙 | `WallLayer` | 是 |
| `(1, 3)` | 纵向墙 | `WallLayer` | 是 |
| `(2, 3)` | 房间转角 | `WallLayer` | 是 |
| `(3, 4)` | 门框 | `DoorFrameLayer` | 否 |

其余素材也是标准 48×48 单元。灯具、管道、通风口和血迹应放在独立的装饰层，不能用于 `FloorLayer` 或 `WallLayer` 的结构碰撞。
