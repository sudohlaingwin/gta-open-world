extends RefCounted
## Slice 97 camera-relative steering helper (owner video verdict
## 2026-10-23 ~19:56: joystick driving felt jerky, not
## PUBG-smooth — Slice 95 proved the cause for the car: walking
## is camera-relative since Slice 53 but vehicles were
## screen-fixed, so every camera orbit flipped the drive
## direction on screen. Slice 95 fixed the car only and left
## the other vehicles as next-round scope, stated. This file
## is that next round, shared so all vehicles use the SAME
## math as the proven Slice 95 car fix — no per-vehicle
## reinvention, no tuning change (smoothing rates, mode
## scales, accel/brake/coast are untouched in the callers).
##
## Pure math only (orbit_angle in, numbers out) so the sim can
## unit-test it without scene nodes. Camera convention copied
## from player.gd (Slice 53) and car.gd (Slice 95): joystick-up
## is the camera look direction, joystick-right is the camera
## right. Car-frame vehicles face (-sin ry, 0, -cos ry); the
## cow faces (sin ry, 0, cos ry) and gets desired_dir directly.
## Bus is EXCLUDED: the bus system is out of scope for this
## slice and the minibus is not rewired (standing rule), so
## the big bus stays screen-fixed — stated, not hidden.

## Camera-relative desired ground direction for a joystick
## vector tv (x = right, y = down, so up is -y) at orbit o.
## Returns an unnormalised vector; callers normalise after
## the 0.05 deadzone check, exactly like Slice 95 car.gd.
static func desired_dir(tv: Vector2, orbit: float) -> Vector3:
	var view_fwd := Vector3(-sin(orbit), 0.0, -cos(orbit))
	var view_rgt := Vector3(cos(orbit), 0.0, -sin(orbit))
	return view_rgt * tv.x + view_fwd * (-tv.y)

## Car-frame steering (car, cart, motorcycle, tuk-tuk, bicycle,
## boat, horse, elephant, helicopter). Replicates Slice 95
## car.gd exactly: forward steer is proportional to -sin of
## the heading error (full lock past ~30 deg off, sin never
## chatters at +/-180 deg); joystick-up/sideways always drives
## FORWARD (the car U-turns, never backs away from a forward
## command — the dot-product draft's antipodal stall, caught
## by the Slice 95 sim, is not repeated); joystick-down keeps
## the original brake/reverse behaviour via the rear error.
## Returns Vector2(steer_target, fwd) for the caller's existing
## move_toward smoothing and speed code.
static func ground_steer(tv: Vector2, orbit: float, rot_y: float) -> Vector2:
	var desired := desired_dir(tv, orbit)
	if desired.length() <= 0.05:
		return Vector2.ZERO
	desired = desired.normalized()
	if -tv.y >= 0.0:
		var want_rot := atan2(-desired.x, -desired.z)
		var diff := want_rot - rot_y
		return Vector2(clampf(-sin(diff) * 2.0, -1.0, 1.0), tv.length())
	var rear_want := atan2(desired.x, desired.z)
	return Vector2(clampf(sin(rear_want - rot_y) * 2.0, -1.0, 1.0), -tv.y)

## Airplane bank toward the camera-relative joystick direction.
## fwd_h is the plane's horizontal forward (flattened -basis.z).
## Pure sideways stick at orbit 0 reproduces the old raw roll
## exactly (tv.x = +/-1 -> +/-1, +/-0.25 -> +/-0.25); pure
## pitch banks nothing. Diagonal sticks bank proportionally
## to BOTH the lateral deflection and the heading error, so a
## mostly-forward stick banks gently instead of snapping.
## Near-vertical flight (flattened forward < 0.1) falls back to
## the old raw roll — no division by a degenerate heading.
## The visual-bank vs coordinated-yaw sign relationship is
## UNCHANGED from pre-existing behaviour (joystick right
## already gave roll +1 with yaw right); this slice only
## re-frames WHICH world direction "right" means.
static func plane_bank(tv: Vector2, orbit: float, fwd_h: Vector3) -> float:
	var desired := desired_dir(tv, orbit)
	if desired.length() <= 0.05:
		return tv.x
	var fh := Vector3(fwd_h.x, 0.0, fwd_h.z)
	if fh.length() < 0.1:
		return tv.x
	fh = fh.normalized()
	var want_rot := atan2(-desired.x, -desired.z)
	var head_rot := atan2(-fh.x, -fh.z)
	var diff := want_rot - head_rot
	return clampf(-sin(diff) * 2.0, -1.0, 1.0) * absf(tv.x)
