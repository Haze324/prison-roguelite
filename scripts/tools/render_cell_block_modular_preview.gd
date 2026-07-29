extends SceneTree

## Raster preview of the authored TileMap, used to inspect seams before opening Godot.
const TILEMAP_SCENE_PATH: String = "res://scenes/maps/cell_block_a2_tilemap.tscn"
const STRUCTURE_PATH: String = "res://assets/generated/tilesets/industrial_prison/prison_modular_structure_48_v4.png"
const PROPS_PATH: String = "res://assets/generated/tilesets/industrial_prison/prison_modular_props_48_v1.png"
const OUTPUT_PATH: String = "res://assets/generated/tilesets/industrial_prison/cell_block_a2_modular_preview_v1.png"
const TILE_SIZE: int = 48
const GRID_SIZE: Vector2i = Vector2i(35, 23)

func _initialize() -> void:
	var scene: PackedScene = load(TILEMAP_SCENE_PATH) as PackedScene
	var structure_atlas: Image = Image.load_from_file(ProjectSettings.globalize_path(STRUCTURE_PATH))
	var props_atlas: Image = Image.load_from_file(ProjectSettings.globalize_path(PROPS_PATH))
	if scene == null or structure_atlas == null or structure_atlas.is_empty() or props_atlas == null or props_atlas.is_empty():
		push_error("Could not load modular cell block preview inputs")
		quit(1)
		return
	var root: Node2D = scene.instantiate() as Node2D
	var output: Image = Image.create(GRID_SIZE.x * TILE_SIZE, GRID_SIZE.y * TILE_SIZE, false, Image.FORMAT_RGBA8)
	output.fill(Color("101214"))
	_draw_layer(output, structure_atlas, root.get_node("FloorLayer") as TileMapLayer, 0)
	_draw_layer(output, structure_atlas, root.get_node("WallLayer") as TileMapLayer, 0)
	_draw_layer(output, structure_atlas, root.get_node("DoorFrameLayer") as TileMapLayer, 0)
	_draw_layer(output, props_atlas, root.get_node("DecorationLayer") as TileMapLayer, 1)
	root.free()
	var error: Error = output.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
	if error != OK:
		push_error("Could not save modular cell block preview")
		quit(1)
		return
	print("CELL BLOCK MODULAR PREVIEW BUILT: " + OUTPUT_PATH)
	quit(0)

func _draw_layer(output: Image, atlas: Image, layer: TileMapLayer, source_id: int) -> void:
	for cell in layer.get_used_cells():
		if layer.get_cell_source_id(cell) != source_id:
			continue
		var coords: Vector2i = layer.get_cell_atlas_coords(cell)
		var tile: Image = atlas.get_region(Rect2i(coords * TILE_SIZE, Vector2i(TILE_SIZE, TILE_SIZE)))
		if source_id == 1:
			output.blend_rect(tile, Rect2i(Vector2i.ZERO, tile.get_size()), cell * TILE_SIZE)
		else:
			output.blit_rect(tile, Rect2i(Vector2i.ZERO, tile.get_size()), cell * TILE_SIZE)
