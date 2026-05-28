class_name StateMachine
extends Node

var current_state: int = -1:
	set(v):#v:value
		owner.transition_state(current_state, v)
		current_state = v
		state_time = 0
		
var state_time: float #用来获取切换状态后过了多长时间，单位是秒


func _ready() -> void:
	await owner.ready
	current_state = 0


func _physics_process(delta: float) -> void:
	while true:
		var next := owner.get_next_state(current_state) as int
		if current_state == next:
			break
		current_state = next
		
	owner.tick_physics(current_state, delta)
	state_time += delta #delta是每帧持续的时间，_physics_process每帧触发
