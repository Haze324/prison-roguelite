# 地图 TileSet 材质与网格修复记录 V5

更新时间：2026-07-29

## 修复内容

- 正式图集继续使用原有工业监狱素材，不使用简化的程序砖块图集。
- 原图按 12×12 网格切分，建筑源的 144 个格子全部保留为可选择的 48×48 图块。
- 原图第 5～11 行作为装饰源重新整理：普通素材占用 1×1；本身跨两格的横向格栅、管线与组件先合并，再注册为 2×1（96×48）图块。
- 所有可放置素材的选择框均为 48×48 的整数倍，不再出现“一个图块被两个选择框拆开”或无法选中的区域。
- TileSet：`resources/maps/prison_tileset_v1.tres`。
- 建筑源：`assets/generated/tilesets/industrial_prison/prison_tileset_atlas_material_48_v4.png`。
- 装饰源：`assets/generated/tilesets/industrial_prison/prison_props_normalized_48_v7.png`。

## 视觉与编辑原则

原始工业材质、锈蚀、裂纹、管线与警示色保持不变；尺寸规范和碰撞配置独立处理，不能为了编辑便利而替换已经确认的美术风格。装饰不参与碰撞与遮光，墙体图块才承担这两项功能。
