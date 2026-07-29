# TileSet 瓦片图例

正式图集：`assets/generated/tilesets/industrial_prison/prison_tileset_atlas_material_48_v4.png`

- 原始美术图实际是 12×12 个材质单元，不是 16×16。
- 正式 TileSet 将每个材质单元裁切、缩放为严格的 48×48 像素。
- 图集总尺寸为 576×576，Godot 选择框与一个瓦片严格 1:1。
- TileSet 资源：`resources/maps/prison_tileset_v1.tres`。

| 用途 | 图集坐标（列, 行） | 使用层 | 碰撞/遮光 |
|---|---:|---|---|
| 普通地面 | `(0, 0)` | `FloorLayer` | 否 |
| 走廊地面 | `(1, 0)` | `FloorLayer` | 否 |
| 横向墙 | `(0, 2)` | `WallLayer` | 是 |
| 纵向墙 | `(1, 3)` | `WallLayer` | 是 |
| 房间角点 | `(2, 3)` | `WallLayer` | 是 |
| 门框装饰 | `(3, 4)` | `DoorFrameLayer` | 否 |

坐标从左上角开始，列和行都从 0 开始；每个源矩形均为 `(列 × 48, 行 × 48, 48, 48)`。
