extends CharacterBody2D

# ═══════════════════════════════════════════════════════════════
# 常量
# ═══════════════════════════════════════════════════════════════
const RUN_SPEED          := 160.0
const FLOOR_ACCELERATION := RUN_SPEED / 0.2
const AIR_ACCELERATION   := RUN_SPEED / 0.02
const JUMP_VELOCITY      := -420.0

const GLIDE_GRAVITY_MULT := 0.1        # 滑行重力倍率（正常重力的 30%）
const GLIDE_AIR_ACCEL    := 2.0        # 滑行时空中加速度倍率（1.0 为不变）

# ═══════════════════════════════════════════════════════════════
# 节点与变量
# ═══════════════════════════════════════════════════════════════
var gravity := ProjectSettings.get("physics/2d/default_gravity") as float

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_request_timer: Timer = $JumpRequestTimer

var is_gliding := false                # 是否正在滑行

# ═══════════════════════════════════════════════════════════════
# 输入处理（瞬时事件）
# ═══════════════════════════════════════════════════════════════
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump_request_timer.start()
		# 空中且未滑行时，按下空格开启滑行
		if not is_on_floor() and not is_gliding:
			is_gliding = true

	if event.is_action_released("jump"):
		# 可变跳跃高度：上升途中松手则降低上升速度
		if velocity.y < JUMP_VELOCITY / 2:
			velocity.y = JUMP_VELOCITY / 2
		# 空中松开空格则取消滑行
		if not is_on_floor() and is_gliding:
			is_gliding = false

# ═══════════════════════════════════════════════════════════════
# 物理与动画主循环
# ═══════════════════════════════════════════════════════════════
func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")

	# ── 水平移动 ──
	var acceleration := FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	if is_gliding:
		# 滑行时转向更灵活（可自行调整倍率）
		acceleration = AIR_ACCELERATION * GLIDE_AIR_ACCEL
	velocity.x = move_toward(velocity.x, direction * RUN_SPEED, acceleration * delta)

	# ── 重力 ──
	if is_gliding:
		velocity.y += gravity * GLIDE_GRAVITY_MULT * delta
	else:
		velocity.y += gravity * delta

	# ── 跳跃判断 ──
	var can_jump := is_on_floor() or coyote_timer.time_left > 0
	var should_jump := can_jump and jump_request_timer.time_left > 0
	if should_jump:
		velocity.y = JUMP_VELOCITY
		coyote_timer.stop()
		jump_request_timer.stop()
		is_gliding = false              # 跳跃立即结束滑行

	# ── 动画 ──
	if is_on_floor():
		var dir_input := Input.get_axis("move_left", "move_right")
		if is_zero_approx(dir_input) and is_zero_approx(velocity.x):
			animation_player.play("idle")
		else:
			animation_player.play("running")
	else:
		if is_gliding:
			#animation_player.play("glide")      # 需要准备名为 "glide" 的动画
			pass
		elif velocity.y < 0:
			animation_player.play("jump")
		else:
			animation_player.play("full")

	# ── 朝向翻转 ──
	if not is_zero_approx(direction):
		sprite_2d.flip_h = direction < 0

	# ── 移动与碰撞 ──
	var was_on_floor := is_on_floor()
	move_and_slide()

	# ── 状态变化处理（郊狼时间、滑行结束） ──
	if is_on_floor() != was_on_floor:
		# 离地时：非跳跃离地则启动郊狼计时器
		if was_on_floor and not should_jump:
			coyote_timer.start()
		else:
			coyote_timer.stop()

		# 落地时：关闭滑行
		if is_on_floor():
			is_gliding = false

#--------------原版-------------------#
#extends CharacterBody2D
#
#const RUN_SPEED := 160.0
#const FLOOR_ACCELERATION := RUN_SPEED / 0.2
#const AIR_ACCELERATION := RUN_SPEED / 0.02
#const JUMP_VELOCITY := -320.0
#
#var gravity := ProjectSettings.get("physics/2d/default_gravity") as float
#
#@onready var sprite_2d: Sprite2D = $Sprite2D
#@onready var animation_player: AnimationPlayer = $AnimationPlayer
#@onready var coyote_timer: Timer = $CoyoteTimer
#@onready var jump_request_timer: Timer = $JumpRequestTimer
#
#func _unhandled_input(event: InputEvent) -> void:
	#if event.is_action_pressed("jump"):
		#jump_request_timer.start()
	#if event.is_action_released("jump") and velocity.y < JUMP_VELOCITY / 2:
		#velocity.y = JUMP_VELOCITY / 2
#
#func _physics_process(delta: float) -> void:
	#var direction := Input.get_axis("move_left", "move_right")
	#var acceleration := FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	#velocity.x = move_toward(velocity.x, direction * RUN_SPEED, acceleration * delta)
	#velocity.y += gravity * delta
	#
	#var can_jump := is_on_floor() or coyote_timer.time_left > 0
	#var should_jump := can_jump and jump_request_timer.time_left > 0
	#if should_jump:
		#velocity.y = JUMP_VELOCITY
		#coyote_timer.stop()
		#jump_request_timer.stop()
		#
	#if is_on_floor():
		#if is_zero_approx(direction) and is_zero_approx(velocity.x):
			#animation_player.play("idle")
		#else:
			#animation_player.play("running")
	#elif velocity.y < 0:
			#animation_player.play("jump")
	#else:
			#animation_player.play("full")
		#
	#if not is_zero_approx(direction):
		#sprite_2d.flip_h = direction < 0
		#
	#var was_on_floor := is_on_floor()
	#move_and_slide()
	#
	#if is_on_floor() != was_on_floor:
		#if was_on_floor and not should_jump:
			#coyote_timer.start()
		#else:
			#coyote_timer.stop()


#-------------------------使用AI版本------------------------#
#extends CharacterBody2D
#
#const RUN_SPEED := 200.0
#const FLOOR_ACCELERATION := RUN_SPEED / 0.2
#const AIR_ACCELERATION := RUN_SPEED / 0.02
#const JUMP_VELOCITY := -350.0
#
#var gravity := ProjectSettings.get("physics/2d/default_gravity") as float
#
#@onready var sprite_2d: Sprite2D = $Sprite2D
#@onready var animation_player: AnimationPlayer = $AnimationPlayer
#@onready var coyote_timer: Timer = $CoyoteTimer
#@onready var jump_request_timer: Timer = $JumpRequestTimer
#
#
#func _unhandled_input(event: InputEvent) -> void:
	#if event.is_action_pressed("jump"):
		#jump_request_timer.start()
	#if event.is_action_released("jump") and velocity.y < JUMP_VELOCITY / 2:
		#velocity.y = JUMP_VELOCITY / 2
		#
#func _physics_process(delta: float) -> void: #delta：一帧几秒
	#var direction := Input.get_axis("move_left", "move_right")
	#var acceleration := FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	#velocity.x = move_toward(velocity.x, direction * RUN_SPEED, acceleration * delta) #第三个参数每帧的变化量 = 每秒的变化量 × 这一帧经过了多少秒
	#velocity.y += gravity * delta
	#
	#var can_jump := is_on_floor() or coyote_timer.time_left > 0
	#var should_jump := can_jump and jump_request_timer.time_left > 0
	#if should_jump:
		#velocity.y = JUMP_VELOCITY
		#coyote_timer.stop()
		#jump_request_timer.stop()
	#
	#if is_on_floor():
		#if is_zero_approx(direction):
			#animation_player.play("idle")
		#else:
			#animation_player.play("running")
	#else:
		#animation_player.play("jump")
		#
	#if not is_zero_approx(direction):
		#sprite_2d.flip_h = direction < 0
		#
	#var was_on_floor := is_on_floor()
	#move_and_slide()
	#
	#if is_on_floor() != was_on_floor:
		#if was_on_floor and not should_jump:
			#coyote_timer.start()
		#else:
			#coyote_timer.stop()


#------------------------未使用AI版本------------------------#
#extends CharacterBody2D
#
#const RUN_SPEED := 160.0
#const FLOOR_ACCELERATION := RUN_SPEED / 0.2
#const AIR_ACCELERATION := RUN_SPEED / 0.02
#const JUMP_VELOCITY := -320.0
#
#var gravity := ProjectSettings.get("physics/2d/default_gravity") as float
#
#@onready var sprite_2d: Sprite2D = $Sprite2D
#@onready var animation_player: AnimationPlayer = $AnimationPlayer
#@onready var coyote_timer: Timer = $CoyoteTimer
#@onready var jump_request_timer: Timer = $JumpRequestTimer
#
#
#func _unhandled_input(event: InputEvent) -> void:
	#if event.is_action_pressed("jump"):
		#jump_request_timer.start()
	#if event.is_action_released("jump") and velocity.y < JUMP_VELOCITY / 2:
		#velocity.y = JUMP_VELOCITY / 2
#
#func _physics_process(delta: float) -> void:
	#var direction := Input.get_axis("move_left", "move_right")
	#var acceleration := FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	#velocity.x = move_toward(velocity.x, direction * RUN_SPEED, acceleration * delta)
	#velocity.y += gravity * delta
	#
	#var can_jump := is_on_floor() or coyote_timer.time_left > 0
	#var should_jump := can_jump and jump_request_timer.time_left > 0
	#if should_jump:
		#velocity.y = JUMP_VELOCITY
		#coyote_timer.stop()
		#jump_request_timer.stop()
		#
	#if is_on_floor():
		#if is_zero_approx(direction) and is_zero_approx(velocity.x):
			#animation_player.play("idle")
		#else:
			#animation_player.play("running")
	#else:
		#animation_player.play("jump")
		#
	#if not is_zero_approx(direction):
		#sprite_2d.flip_h = direction < 0
		#
	#var was_on_floor := is_on_floor()
	#move_and_slide()
	#
	#if is_on_floor() != was_on_floor:
		#if was_on_floor and not should_jump:
			#coyote_timer.start()
		#else:
			#coyote_timer.stop()
			#
