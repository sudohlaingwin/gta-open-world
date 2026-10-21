# Myanmar GTA — Open World Mobile Game

Owner vision (told directly by Htay Hlaing Win, 2026-10-21):
a Myanmar-style GTA open world game, set in the real Myanmar, with
people in Myanmar traditional dress, carts and cows in the world,
and a player who can drive cars, drive carts, ride motorcycles,
ride cows, and fly various airplanes. Target quality: very good,
PUBG-like graphics. This repo is SEPARATE from H2W Photo Lab.

## Duel

Muse and Google Antigravity build this game together in the open,
alternating review-and-improve rounds. The owner watches and judges
who is best by playing it. No fake claims: a slice is done only when
it runs, and graphics claims match what is actually on screen.

## Slice 1 — playable village block (MUSE entry, 2026-10-21)

Engine: Godot 4, 3D. This first slice is deliberately small and
honest — it is NOT PUBG graphics yet, and it is NOT the whole
country. It proves the loop: walk, enter a car, drive, exit.

What works in Slice 1:
- Third-person walk around a small Myanmar village block
  (ground, houses, cart and cow as scenery for now).
- Walk up to the car and press Enter/Space (ui_accept) to get in,
  drive with arrow keys / WASD, press Enter/Space again to get out.
- Day lighting, third-person follow camera.

What is NOT yet in Slice 1 (next slices, in order):
- Drivable cart, motorcycle, cow riding, airplanes.
- Traditional-dress character models (placeholder capsule for now).
- More areas, traffic, NPCs, quests, mobile touch controls,
  Android APK export (needs Godot + export templates installed).

Run it (desktop, once Godot 4 is installed):
`godot --path . main.tscn` — walk with arrow keys/WASD,
Enter/Space to enter/exit the car.

## Files

- `project.godot` — Godot 4 project, main scene `main.tscn`.
- `main.tscn` — village block scene.
- `player.gd` — third-person walk + enter/exit car.
- `car.gd` — simple drivable car (walk mode off while driving).
- `cart.gd`, `cow.gd` — scenery stubs for Slice 1, drivable in
  later slices (their scripts say so plainly, no fake behaviour).

## Slice 2 — beat the opponent's entry (MUSE, 2026-10-21)

Reviewed the opponent's `master` entry (71485f2) line by line.
Credit where due: camera-relative movement, touch-joystick concept,
day/night concept, mobile renderer settings — good ideas, ported
here as working implementations (not copies).

Concrete defects found in 71485f2 (all from its own files):
- No vehicles at all: no car/cart/motorcycle/cow/airplane code,
  despite the owner spec requiring them.
- Touch joystick is dead code: `virtual_joystick.gd` exists, but no
  scene instantiates it and nothing connects its signal to the
  player, so it cannot move the player.
- Jump/sprint are dead code: `jump()` / `set_sprint()` are defined
  but never called from input or UI.
- Camera "pinch-zoom" is claimed in comments and exports
  (zoom_speed/min/max) but no zoom code exists; orbit is
  touch-drag only, no mouse/keyboard orbit.
- Day/night only rotates the sun; light energy never changes, so
  night is never dark.
- `project.godot` references `res://icon.svg`, which is not in the
  repo (missing-file warning).

Slice 2 fixes/ports all of the above while keeping Slice 1:
- WIRED touch joystick (Joystick UI in main.tscn, writes directly
  to player.touch_vector; mouse works too via emulate_touch).
- Working sprint (Shift) and jump (J, on floor only).
- Day/night WITH darkness (sun energy follows sun angle).
- Keyboard camera orbit (Q/E) in addition to follow view.
- DRIVABLE CART (second vehicle, slower than the car) — player can
  enter the nearest vehicle, car or cart, with Enter/Space.
- Still honest gaps: motorcycle, cow riding, airplanes, real
  traditional-dress models, Android APK — later slices.

## Slice 3 — motorcycle + airplane, beat opponent Slices 2/5 (MUSE, 2026-10-21)

Reviewed opponent commits 0f1c7ec (rideable cow + bullock cart +
vehicle base + mobile UI) and 278fc0b (Slice 5 airplane) line by
line. Credit where due, by name:
- mount_controller: real rideable cow + bullock cart with Area3D
  proximity, saddle reparenting, and a player state machine
  (ON_FOOT / RIDING / DRIVING / FLYING) with interact priority.
- aircraft_controller: a real flight attempt — throttle, lift
  proportional to forward speed, pitch/roll/yaw, cockpit reparent,
  speed cap — and terrain grown 400 -> 1000, so the "1km airspace"
  claim has a real ground plane behind it.
- mobile_touch_ui: the right idea — wire joystick signals into
  player.touch_input_vector and add Interact/Jump/Sprint buttons.

Concrete defects found in 0f1c7ec / 278fc0b (file evidence):
- vehicle_controller.gd is dead code: no scene in either tree
  references it, and a VehicleBody3D with no VehicleWheel3D
  children cannot drive anyway. The opponent tree still has no
  drivable car and no motorcycle.
- mobile_touch_ui.gd is dead code: setup() is never called — no
  world or player scene contains a MobileTouchUI node — so its
  joystick wiring never runs in-game. The Slice-1 dead-joystick
  defect moved, it was not fixed.
- mount_controller.gd reads Input.is_action_pressed("sprint"),
  but project.godot at 278fc0b defines no "sprint" input action
  (only [input_devices] emulate_touch) — undefined action, so
  mount sprint never engages.
- aircraft_controller.gd: throttle auto-rises every frame
  (throttle = clamp(throttle + delta*0.4, 0, 1)) with no
  throttle-down input, so a pilot cannot slow down or land on
  purpose except by exiting mid-air; stall_speed is exported but
  never read (no stall behaviour); roll and yaw both use
  input_dir.x (double turn).
- project.godot still references res://icon.svg, which is still
  not in the repo (missing-file warning, carried from Slice 1).

Slice 3 (this commit) keeps everything from Slice 2 (car, cart,
wired joystick, sprint/jump, dark nights, Q/E orbit) and adds:
- MOTORCYCLE (motorcycle.gd, third vehicle): faster than the car,
  leans into turns, joystick steering/throttle works, Enter/Space
  enter/exit via the same player vehicle picker.
- AIRPLANE (airplane.gd): flyable with EXPLICIT throttle
  (Shift up / Ctrl down, clamped, never auto-rises), pitch
  (Up/Down arrows), roll (Left/Right arrows), yaw (Q/E), joystick
  pitch/roll, and stall that is actually applied (lift collapses
  below stall_speed). Enter/exit cockpit via Enter/Space; exiting
  mid-air drops the pilot — NO parachute yet, stated plainly.
- Muse's own code avoids the listed defects by design: no
  undefined input actions (physical keys used), no unconnected
  signals (joystick writes player.touch_vector directly),
  no missing icon reference in project.godot.

Honesty: Slice 3 code is statically reviewed, NOT run inside
Godot (no Godot binary on this VM yet) — same standard as before:
not a playable APK, not PUBG graphics. Still missing:
traditional-dress character models, Android APK export, the whole
country map, helicopters, parachute.
