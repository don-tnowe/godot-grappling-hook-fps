class_name WeaponBase
extends Spatial


export var firing_cooldown := 0.0

var equipped := false
var firing := false
var last_fired := 0
var hero_node : KinematicBody


func equip(hero):
	hero_node = hero
	_set_equipped(true)


func unequip():
	_set_equipped(false)
	hero_node.disconnect("jumped", self, "_on_Hero_jumped")


func _set_equipped(v):
	visible = v
	equipped = v
	$"Crosshair".visible = v


func fire():
	firing = true
	if can_refire():
		last_fired = Time.get_ticks_msec()


func stop_firing():
	firing = false


func can_refire():
	return Time.get_ticks_msec() > last_fired + firing_cooldown * 1000
