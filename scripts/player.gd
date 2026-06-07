extends CharacterBody2D

enum State {
	IDLE,
	RUNNING,
	JUMP,
	FALL,
	LANDING,
	WALL_SLIDING,
	WALL_JUMP,
}

const GROUND_STATES := [State.IDLE, State.RUNNING, State.LANDING]
const RUN_SPEED := 160.0
const FLOOR_ACCELERATION := RUN_SPEED / 0.2
const AIR_ACCELERATION := RUN_SPEED / 0.1
const JUMP_VELOCITY := -320.0
const WALL_JUMP_VELOCITY := Vector2(400, -280)

var default_gravity := ProjectSettings.get("physics/2d/default_gravity") as float
var is_first_tick := false

@onready var graphcs: Node2D = $Graphcs
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_request_timer: Timer = $JumpRequestTimer
@onready var hand_checker: RayCast2D = $Graphcs/HandChecker
@onready var foot_checker: RayCast2D = $Graphcs/FootChecker
@onready var state_machine: StateMachine = $StateMachine

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump_request_timer.start()
	if event.is_action_released("jump") and velocity.y < JUMP_VELOCITY / 2:
		velocity.y = JUMP_VELOCITY / 2

func tick_physics(state: State, delta: float) -> void:#在_physics_process上修改的
	match state:
		State.IDLE:
			move(default_gravity, delta)
			
		State.RUNNING:
			move(default_gravity, delta)
			
		State.JUMP:
			move(0.0 if is_first_tick else default_gravity, delta)
			
		State.FALL:
			move(default_gravity, delta)
			
		State.LANDING:
			stand(default_gravity, delta) #下落动画播放时不接收玩家输入
			
		State.WALL_SLIDING:
			move(default_gravity / 3, delta)
			graphcs.scale.x = get_wall_normal().x #返回最近一次碰撞点的法线
			
		State.WALL_JUMP:
			if state_machine.state_time < 0.1: #0.1s，在60FPS时大概6帧
				stand(0.0 if is_first_tick else default_gravity, delta) #不接收玩家输入
				graphcs.scale.x = get_wall_normal().x #get_wall_normal()返回一个向量，表示角色当前接触的墙的法线方向
			else:
				move(default_gravity, delta)
			
	is_first_tick = false
			
func move(gravity: float, delta: float) -> void:#从_physics_process中分离出来的封装
	var direction := Input.get_axis("move_left", "move_right")
	var acceleration := FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x = move_toward(velocity.x, direction * RUN_SPEED, acceleration * delta)
	velocity.y += gravity * delta
	
	if not is_zero_approx(direction):
		graphcs.scale.x = -1 if direction < 0 else +1 #重设Sprite2D父节点后用graphcs.scale.x代替sprite_2d.flip_h
		
	move_and_slide()
	
func stand(gravity: float, delta: float) -> void:
	var acceleration := FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
	velocity.y += gravity * delta
	
	move_and_slide()
	
	
func can_wall_slide() -> bool:#玩家与墙碰撞且墙与头脚部碰撞才进入滑墙状态
	return is_on_wall() and hand_checker.is_colliding() and foot_checker.is_colliding()
	
func get_next_state(state: State) -> State:
	var can_jump := is_on_floor() or coyote_timer.time_left > 0
	var should_jump := can_jump and jump_request_timer.time_left > 0
	if should_jump:
		return State.JUMP
	
	var direction := Input.get_axis("move_left", "move_right")
	var is_still := is_zero_approx(direction) and is_zero_approx(velocity.x)
	
	match state:
		State.IDLE:
			if not is_on_floor():
				return State.FALL
			if not is_still:
				return State.RUNNING
			
		State.RUNNING:
			if not is_on_floor():
				return State.FALL
			if is_still:
				return State.IDLE
			
		State.JUMP:
			if velocity.y >= 0:
				return State.FALL
			
		State.FALL:
			if is_on_floor():
				return State.LANDING if is_still else State.RUNNING
			if can_wall_slide(): 
				return State.WALL_SLIDING
				
		State.LANDING:
			#if not is_still:
				#return	State.RUNNING #取消落地硬直
			if not animation_player.is_playing():
				return State.IDLE
				
		State.WALL_SLIDING:
			if jump_request_timer.time_left > 0:#可加 and state_machine.state_time > 3.0 / 60.0，在反复跳跃时不会跳过滑墙动画
				return State.WALL_JUMP
			if is_on_floor():
				return State.LANDING #切换成IDLE有些生硬
			if not is_on_wall():
				return State.FALL
				
		State.WALL_JUMP:
			if can_wall_slide() and not is_first_tick:
				return State.WALL_SLIDING
			if velocity.y >= 0:
				return State.FALL
				
	return state

func transition_state(from: State, to: State) -> void:
	#print("[%s] %s => %s" % [
		#Engine.get_physics_frames(),
		#State.keys()[from] if from != -1 else "<STATE>",
		#State.keys()[to],
	#])
	if from not in GROUND_STATES and to in GROUND_STATES:
		coyote_timer.stop()
	
	match to:
		State.IDLE:
			animation_player.play("idle")
			
		State.RUNNING:
			animation_player.play("running")
		
		State.JUMP:
			animation_player.play("jump")
			velocity.y = JUMP_VELOCITY
			coyote_timer.stop()
			jump_request_timer.stop()
			
		State.FALL:
			animation_player.play("full")
			if from in GROUND_STATES:
				coyote_timer.start()
				
		State.LANDING:
			animation_player.play("landing")
			
		State.WALL_SLIDING:
			animation_player.play("wall_sliding")
			
		State.WALL_JUMP:
			animation_player.play("jump")
			velocity = WALL_JUMP_VELOCITY
			velocity.x *= get_wall_normal().x
			jump_request_timer.stop()
			
	#if to == State.WALL_JUMP: #慢动作
		#Engine.time_scale = 0.3
	#if from == State.WALL_JUMP:
		#Engine.time_scale = 1.0
		
	is_first_tick = true
