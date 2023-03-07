extends PanelContainer
@onready var players = $"../../Players"
@onready var item_list = $MarginContainer/VBoxContainer/ItemList
var scores = []

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	item_list.clear()
	scores.clear()
	var all_players = players.get_children()
	for child in all_players:
		scores.append([child.coins,child.user_name])
	scores.sort_custom(sort_scores)
	for child in scores:
		item_list.add_item(child[1] + '  :  ' + str(child[0]))

func sort_scores(a, b):
	if a[0] > b[0]:
		return true
	return false
