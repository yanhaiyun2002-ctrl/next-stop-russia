class_name P1CatVisual
extends RefCounted
## Two depth planes share one real-alpha sprite; movement remains in CatEncounter.
static func parts(anchor: Vector3, peek: bool) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var left := anchor.x - 0.62
	var right := anchor.x + 0.51
	var height := 0.72
	result.append(_part(left,right,anchor.y,anchor.y+height,anchor.z,Rect2(0,0,1,1),10))
	if peek:
		# The exposed head is in front of the bed, exactly as the original peek cue.
		result.append(_part(lerpf(left,right,0.64),right,anchor.y+height*0.36,anchor.y+height,anchor.z-0.75,Rect2(0.64,0,0.36,0.64),15))
	return result

static func _part(left: float,right: float,bottom: float,top: float,z: float,uv_rect: Rect2,tie: float) -> Dictionary:
	var points: Array[Vector3] = [Vector3(left,bottom,z),Vector3(right,bottom,z),Vector3(right,top,z),Vector3(left,top,z)]
	return {"points":points,"depth":z,"tie":tie,"color":Color.WHITE,"texture":"cat","uv":PackedVector2Array([Vector2(uv_rect.position.x,uv_rect.end.y),uv_rect.end,Vector2(uv_rect.end.x,uv_rect.position.y),uv_rect.position])}
