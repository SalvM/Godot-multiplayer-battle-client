extends "res://scripts/Fighter.gd"

onready var healthBar = $HUD/HealthBar
onready var staminaBar = $HUD/StaminaBar
onready var dashBar = $HUD/DashBar
onready var playerLabel = $HUD2/Label

func _set_health(value):
	var prev_health = health
	health = clamp(value, 0, max_health)
	if health == 0:
	#	emit_signal("health_changed", 0)
		faint()
		healthBar.value = 0
	elif health != prev_health:
	#	emit_signal("health_changed", health_in_percentage(health))
		healthBar.value = health_in_percentage(health)

func _set_stamina(value):
	var prev_stamina = stamina
	stamina = clamp(value, 0, max_stamina)
	if stamina == 0:
	#	emit_signal("stamina_changed", 0)
		staminaBar.value = 0
	elif stamina != prev_stamina:
	#	emit_signal("stamina_changed", stamina_in_percentage(stamina))
		staminaBar.value = stamina_in_percentage(stamina)

func _set_dashes(value):
	._set_dashes(value)
	dashBar.value = dashes

func set_player_name():
	playerLabel.text = fighter_name

func faint():
	.faint()
	$HurtBox/Collision.disabled = true

func _on_AnimationPlayer_animation_finished(anim):
	._on_AnimationPlayer_animation_finished(anim)

func _on_StaminaTimer_timeout():
	._on_StaminaTimer_timeout()

func _on_DashTimer_timeout():
	speed_bonus = 1.0
	dash.stop()

func _on_ready():
	$StaminaTimer.start()
	$DashRegenTimer.start()
	hitBox.get_node("Collision").disabled = true
	$HUD2/Label.text = fighter_name
	# set_player_name()

func _on_HurtBox_area_entered(area):
	damage(10)

func _on_DashRegenTimer_timeout():
	_set_dashes(dashes + 1)