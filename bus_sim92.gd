extends Node3D
## Slice 92 — BUS SIMULATION, part 19 (owner simulation direction
## 2026-10-23 11:31 + bus choice 11:32, part 19).
## STOP-REQUEST LAMP ON THE BUS: Slice 80 gave the driver a
## touch stop-request button + HUD label, but nothing ON
## the bus showed a request was active. Now an amber lamp
## above the door on the big bus exterior blinks (~2 Hz)
## while a stop request is active, and is dark otherwise.
## The lamp holds NO state of its own: every frame it
## recomputes from the Slice 80 flag (BusSim80
## request_stop80) AND the driving rule (player driving
## the big bus), so it can never disagree with the flag.
## It therefore follows exactly the Slice 80 lifecycle
## with no new lifecycle invented: it goes dark when
## the requested stop is served in order, on second-press
## cancel, on a service switch (Slice 79 recompute), and
## on leaving the bus — because in every one of those
## cases the flag clears (or driving ends) and this node
## reads the cleared value on the next frame.
## Placement (bus-local, from the Slice 74 build): the
## door group sits at (1.31, 1.5, 1.0) on the +x side
## with a 1.9 m panel (top 2.45); the side window top is
## 2.5 and the body top is 2.8. The lamp sits at
## (1.36, 2.62, 1.0), size (0.08, 0.22, 0.34): 0.06 above
## the door top, 0.01 above the window top, 0.07 below
## the body top, and 0.06 proud of the body side (1.3)
## so it reads from the stops side. One mesh, zero
## colliders (a MeshInstance3D carries none). The lamp
## is a child of the Bus node itself (not the sliding
## door group), so it stays above the door whether the
## door is open or closed, and it follows the bus for
## free. Display only: no new HUD label, no new text,
## no money, no economy, no new save key, session only.
## The minibus is NOT rewired (Slice 81 honest limit
## stands): it has no route/request system and gets no
## lamp — this node only ever looks up the node literally
## named "Bus". Seated riders (Slice 91) are untouched:
## this node never moves, hides, or re-seats any rider.

const LAMP_POS: Vector3 = Vector3(1.36, 2.62, 1.0)
const LAMP_SIZE: Vector3 = Vector3(0.08, 0.22, 0.34)
const BLINK_PERIOD: float = 0.5

# True while a request is active and the player is
# driving the big bus (the lamp's on-state, before the
# blink phase is applied). The world sim reads this.
var lamp_on92: bool = false
# Counts blink-phase flips while the lamp is on, so the
# world sim can prove blinking without sampling luck.
var blink_toggles92: int = 0
var _time: float = 0.0
var _prev_phase: bool = false


static func dress(world: Node3D) -> void:
	if world == null:
		return
	if world.get_node_or_null("BusSim92") != null:
		return
	var n := Node3D.new()
	n.name = "BusSim92"
	n.set_script(load("res://bus_sim92.gd"))
	world.call_deferred("add_child", n)


func _driving_bus(world: Node3D, bus: Node3D) -> bool:
	if world == null or bus == null:
		return false
	var player := world.get_node_or_null("Player")
	if player == null:
		return false
	return bool(player.get("driving")) and player.get("driving_vehicle") == bus


func _make_lamp(bus: Node3D) -> MeshInstance3D:
	var lamp := MeshInstance3D.new()
	lamp.name = "RequestLamp92"
	var box := BoxMesh.new()
	box.size = LAMP_SIZE
	lamp.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.65, 0.1, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.55, 0.0, 1.0)
	mat.emission_energy_multiplier = 3.0
	lamp.set_surface_override_material(0, mat)
	lamp.position = LAMP_POS
	lamp.visible = false
	bus.add_child(lamp)
	return lamp


func _process(delta: float) -> void:
	var world := get_parent() as Node3D
	if world == null:
		return
	var bus := world.get_node_or_null("Bus") as Node3D
	if bus == null:
		lamp_on92 = false
		return
	var lamp := bus.get_node_or_null("RequestLamp92") as MeshInstance3D
	if lamp == null:
		lamp = _make_lamp(bus)
	var node80 := world.get_node_or_null("BusSim80")
	var requested := node80 != null and int(node80.get("request_stop80")) >= 0
	lamp_on92 = requested and _driving_bus(world, bus)
	_time += delta
	var phase := fmod(_time, BLINK_PERIOD) < BLINK_PERIOD * 0.5
	if lamp_on92:
		if phase != _prev_phase:
			blink_toggles92 += 1
		_prev_phase = phase
		lamp.visible = phase
	else:
		lamp.visible = false
