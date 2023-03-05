extends PanelContainer
var player_names = {}
@onready var players_scores = $MarginContainer/VBoxContainer/PlayersScores

func _process(delta):
	players_scores.text = str(player_names)
