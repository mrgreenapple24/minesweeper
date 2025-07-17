extends TileMapLayer

enum state {
	empty = -1,
	bomb, number_1, number_2, number_3, number_4, number_5, number_6, number_7, number_8
}

const unrevealedtile = Vector2i(0, 0)
const flagtile = Vector2i(1, 0)
const emptytile = Vector2i(3, 0)
const bombtile = Vector2i(2, 0)
const onetile = Vector2i(0, 1)
const twotile = Vector2i(1, 1)
const threetile = Vector2i(2, 1)
const fourtile = Vector2i(3, 1)
const fivetile = Vector2i(0, 2)
const sixtile = Vector2i(1, 2)
const seventile = Vector2i(2, 2)
const eighttile = Vector2i(3, 2)
const crossbombtile = Vector2i(1, 3)

const GRID_SIZE = Vector2i(32, 16)
const MINE_COUNT : int = 99

var cells : Array[int]
var surroundingCells: Array[int]
var offsetCoords: Vector2i
var gameEnded := false
var lastMove : Array[Vector2i]

func _ready() -> void:
	_init_grid()

func _init_grid() -> void:
	for y in range(GRID_SIZE.y):
		for x in range(GRID_SIZE.x):
			set_cell(Vector2i(x, y), 0, unrevealedtile, 0)
			cells.append(state.empty)

func setUpMines(avoid : Vector2i) -> void:
	for i in range(MINE_COUNT):
		cells[i] = 0
	
	cells.shuffle()
	while getSurroundingCells(avoid, 5).has(0):
		cells.shuffle()
	
	for y in range(GRID_SIZE.y):
		for x in range(GRID_SIZE.x):
			if not cells[getCellIndex(Vector2i(x, y))] == 0:
				var mineCount := 0
				for i in getSurroundingCells(Vector2i(x, y), 3):
					if i == 0:
						mineCount += 1
				
				if mineCount > 0:
					cells[getCellIndex(Vector2i(x, y))] = mineCount


func _input(event : InputEvent) -> void:
	if gameEnded == false:
		if event.is_action_pressed("reveal"):
			var cellAtMouse : Vector2i = local_to_map(get_local_mouse_position())
			lastMove = []
			if getAtlasCoords(cellAtMouse) != flagtile:
				if cells.has(0):
					lastMove.append(cellAtMouse)
					revealCell(cellAtMouse)
					
					# If clicked on a number cell
					if cells[getCellIndex(cellAtMouse)] >= 1:
						revealSurroundingCells(cellAtMouse, false)
					
					# If there was a mine revealed, end the game
					for i in lastMove:
						if cells[getCellIndex(i)] == 0:
							gameEnded = true
							revealAllMines(lastMove)
				else:
					setUpMines(cellAtMouse)
					revealCell(cellAtMouse)
		
		if event.is_action_pressed("flag"):
			var cellAtMouse : Vector2i = local_to_map(get_local_mouse_position())
			if getAtlasCoords(cellAtMouse) == unrevealedtile:
				set_cell(cellAtMouse, 0, flagtile, 0)
			elif getAtlasCoords(cellAtMouse) == flagtile:
				set_cell(cellAtMouse, 0, unrevealedtile, 0)


func revealCell(cellCoords : Vector2i) -> void:
	var cellIndex : int
	cellIndex = getCellIndex(cellCoords)
	
	var tile : Vector2i
	match cells[cellIndex]:
		state.empty: tile = emptytile
		state.bomb: tile = bombtile
		state.number_1: tile = onetile
		state.number_2: tile = twotile
		state.number_3: tile = threetile
		state.number_4: tile = fourtile
		state.number_5: tile = fivetile
		state.number_6: tile = sixtile
		state.number_7: tile = seventile
		state.number_8: tile = eighttile
	
	set_cell(cellCoords, 0, tile, 0)
	
	if cells[cellIndex] == state.empty:
		revealSurroundingCells(cellCoords, false)

func getCellIndex(cellCoords : Vector2i) -> int:
	if cellCoords.x < GRID_SIZE.x and cellCoords.y < GRID_SIZE.y:
		if cellCoords.x >= 0 and cellCoords.y >= 0:
			return cellCoords.y * GRID_SIZE.x + cellCoords.x
		else:
			return -1
	else:
		return -1


func getSurroundingCells(cellCoords : Vector2i, size : int) -> Array[int]:
	surroundingCells = []
	for y in range(-1, size-1):
		for x in range(-1, size-1):
			offsetCoords = cellCoords + Vector2i(x, y)
			if getCellIndex(offsetCoords) > -1:
				surroundingCells.append(cells[getCellIndex(offsetCoords)])
			else:
				surroundingCells.append(-1)
	return surroundingCells



func revealSurroundingCells(cellCoords : Vector2i, numberCanReveal : bool) -> void:
	var numberFlags := 0
	for y in range(-1, 2):
		for x in range(-1, 2):
			offsetCoords = cellCoords + Vector2i(x, y)
			
			if getCellIndex(offsetCoords) > -1:
				if cells[getCellIndex(cellCoords)] >= 1:
					if getAtlasCoords(offsetCoords) == Vector2i(1, 0):
						if numberCanReveal == false:
							numberFlags += 1
					else:
						if numberCanReveal == true:
							# If the cell isn't revealed yet
							if getAtlasCoords(offsetCoords) == Vector2i(0, 0):
								lastMove.append(offsetCoords)
								revealCell(offsetCoords)
				else:
					if getAtlasCoords(offsetCoords) == Vector2i(0, 0) or getAtlasCoords(offsetCoords) == Vector2i(1, 0):
						revealCell(offsetCoords)
	
	if cells[getCellIndex(cellCoords)] >= 1:
		if numberFlags == cells[getCellIndex(cellCoords)]:
			revealSurroundingCells(cellCoords, true)



func revealAllMines(avoid : Array[Vector2i]) -> void:
	var cellCoords : Vector2i
	for y in range(GRID_SIZE.y):
		for x in range(GRID_SIZE.x):
			cellCoords = Vector2i(x, y)
			if cells[getCellIndex(cellCoords)] == 0:
				if not avoid.has(cellCoords) && getAtlasCoords(cellCoords) != flagtile:
					set_cell(cellCoords, 0, bombtile, 0)
			else:
				if getAtlasCoords(cellCoords) == flagtile:
					set_cell(cellCoords, 0, crossbombtile, 0)


func getAtlasCoords(cellCoords : Vector2i) -> Vector2i:
	return get_cell_atlas_coords(cellCoords)
