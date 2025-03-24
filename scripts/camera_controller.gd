extends Camera2D

const TILE_SIZE := Globals.TILE_SIZE
const BOARD_SIZE := Vector2(8, 8)
const BUFFER_TILES := Vector2(2, 2)  # 2 tiles on each side
const VIEW_TILES := BOARD_SIZE + BUFFER_TILES * 2
const VIEW_SIZE := VIEW_TILES * TILE_SIZE
const VIEW_ORIGIN := -BUFFER_TILES * TILE_SIZE

func _ready():
	await get_tree().process_frame
	make_current()

	var screen_size = get_viewport_rect().size

	# ✅ Uniform zoom to preserve square tiles
	var zoom_scale = min(
		screen_size.x / VIEW_SIZE.x,
		screen_size.y / VIEW_SIZE.y
	)
	zoom = Vector2(zoom_scale, zoom_scale)

	# ✅ Camera position should be center of the visible area
	position = VIEW_ORIGIN

	print("📸 Camera ready")
	print("  Zoom:", zoom)
	print("  Position:", position)
	print("  Viewport:", screen_size)
	print("  View area:", VIEW_SIZE)
