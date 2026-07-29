# 地图 TileSet 素材切割记录 V6

更新时间：2026-07-29

## 根因

原始工业监狱图片 `prison_tileset_atlas_1024.png` 是 7×8 的素材联系表；其中上部结构素材与下部道具素材的行高不同。它不是等分 12×12 TileMap 图集。此前按统一 12×12 网格重采样，导致选择框与素材边界错位。

## 最终方案

- 原始美术保留不变，作为只读源文件。
- 使用 `scripts/tools/slice_prison_contact_sheet.gd` 按原图实际边界逐一裁出 56 张完整素材。
- 每张素材以最近邻方式缩放进 48×48 单元，重新排为 `prison_tileset_sliced_48_v6.png`。
- TileSet 只注册这一张 7×8 图集：56 个选择框、56 张完整原始素材，一格对应一物。
- `scripts/tools/audit_prison_tileset.gd` 会验证全部 56 格均可选，并验证 `cell_block_a2_tilemap.tscn` 可加载且三层已绘制。

这套方案不重新绘制、不替换、不合成原美术；只去掉联系表的空白间隔并做统一像素尺寸转换，使其可以稳定用于 Godot TileMap。
