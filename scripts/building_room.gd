class_name BuildingRoom
extends VBoxContainer
## Only the two temporary P0 rooms share this small local interaction.
signal return_requested

@export var heading: String
@export var description: String
@export var action_text: String
@export var result_text: String

var interaction_count := 0
var action_button: Button
var back_button: Button
var feedback: Label

func _ready() -> void:
	add_theme_constant_override("separation", 16)
	var title := Label.new()
	title.text = heading
	title.add_theme_font_size_override("font_size", 28)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(title)
	var body := Label.new()
	body.text = description
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(body)
	var space := Control.new()
	space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(space)
	action_button = Button.new()
	action_button.name = "Interaction"
	action_button.text = action_text
	action_button.custom_minimum_size.y = 64
	action_button.pressed.connect(interact)
	add_child(action_button)
	feedback = Label.new()
	feedback.text = "这是临时独立场景，仅验证交互与返回。"
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback.custom_minimum_size.y = 72
	add_child(feedback)
	back_button = Button.new()
	back_button.name = "BackToMap"
	back_button.text = "← 返回地图"
	back_button.custom_minimum_size.y = 64
	back_button.pressed.connect(func(): return_requested.emit())
	add_child(back_button)

func interact() -> void:
	interaction_count += 1
	feedback.text = "%s（本次交互 %d 次）" % [result_text, interaction_count]
