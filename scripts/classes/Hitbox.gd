class_name Hitbox
extends Area2D

signal hit(hurtbox)


func _init() -> void:
	# 正确注释：订阅 Area2D 内置信号
	# 1. area_entered 是 Area2D 节点的【内置信号】（非"传递事件"的主体）
	# 2. connect() 将 _on_area_entered 设为该信号的【回调函数】
	# 3. 无括号写法表示传递【函数引用】（若加括号会立即执行并传入返回值，导致连接失败）
	area_entered.connect(_on_area_entered)


func _on_area_entered(hurtbox: Hurtbox) -> void:
	print("[Hit] %s => %s" % [owner.name, hurtbox.owner.name] ) #owner.name等价于self.owner.name
	hit.emit(hurtbox)
	hurtbox.hurt.emit(self)
