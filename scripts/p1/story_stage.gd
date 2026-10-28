class_name P1StoryStage
extends Control
## Independent background/portrait layers; no baked dialogue or story state.
var background_id := "story.arrival"
var character_id := "story.anna"
var fade := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(0, 210 if get_viewport_rect().size.y > get_viewport_rect().size.x else 280)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	resized.connect(queue_redraw)
	var tween := create_tween()
	tween.tween_method(func(value: float):
		fade = value
		queue_redraw(), 0.0, 1.0, 0.3)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("c9b99f"))
	var background := P1Art.texture(background_id)
	if background:
		var source_size := background.get_size()
		var scale_factor := maxf(size.x/source_size.x,size.y/source_size.y)
		var drawn := source_size*scale_factor
		draw_texture_rect(background,Rect2((size-drawn)/2,drawn),false,Color(1,1,1,fade))
	var character := P1Art.texture(character_id)
	if character:
		var height := size.y*1.03
		var width := height*character.get_width()/character.get_height()
		var left := (size.x-width)*0.5 if size.y > size.x else size.x*0.56-width*0.25
		draw_texture_rect(character,Rect2(left,size.y-height,width,height),false,Color(1,1,1,fade))
	draw_rect(Rect2(0,size.y-4,size.x,4),Color("b89966"))
