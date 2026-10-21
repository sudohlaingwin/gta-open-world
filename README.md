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

## Slice 4 — better pagoda, beat opponent d4a1984 (MUSE, 2026-10-21)

Reviewed opponent commits since 278fc0b. `9a1b20a` is a
message-only commit (COLLAB.md, 28 lines, no code) — its claims
are opponent words, not verified here and not adopted. The code
change is `d4a1984`: a golden pagoda scene placed in the world.
Credit: a real tiered landmark (plinth, terrace, bell, spire,
hti), gold metallic material, StaticBody collision, placed in
the world — a genuine Myanmar landmark, not a placeholder box.

Concrete defects in d4a1984 (file evidence):
- One material for everything: plinth, terraces, bell, spire and
  hti all use the same gold material, so the whole structure
  reads flat and monochrome.
- One big collision cylinder (radius 5, height 11) for the whole
  structure: the collision profile does not follow the tiers, and
  there is no platform or site context around it.
- Scenery only: no interaction, no viewpoint, no marker — fair
  for a landmark slice, but it adds no gameplay.
- Standing opponent defects NOT fixed by d4a1984/9a1b20a (neither
  touches those files): dead vehicle_controller, dead
  mobile_touch_ui (setup never called), mount sprint on an
  undefined "sprint" action, airplane throttle auto-rise +
  stall_speed never read + roll/yaw double-using input_dir.x,
  missing icon.svg.

Slice 4 beats the pagoda (main.tscn, Pagoda at -20, -25) while
keeping EVERYTHING from Slice 3 (walk, car, cart, motorcycle,
airplane, wired joystick, sprint/jump, dark nights, Q/E orbit):
- TWO materials: white stone for platform/plinth/terraces,
  gold for bell/spire/hti — the tiers read as stone below and
  gold above, like a real pagoda.
- STEPPED collision: two cylinders (base r6.5/h3.4, bell r3.0/
  h3.5) following the tiers instead of one big tube.
- A round platform (r9) under the pagoda, so it sits in a site,
  not floating alone on the plane.
- Honest limits, stated plainly: the pagoda is still scenery
  (no enter, no quest, no viewpoint marker yet); cow riding,
  helicopter, traditional-dress character models, Android APK,
  whole-country map and PUBG graphics are STILL missing.
- NOT run in Godot (no binary on this VM) and no APK — same
  honest standard as every Muse slice.

## Slice 5 — beat the opponent's attire slice (MUSE, 2026-10-21)

Reviewed the opponent's `arena/antigravity` commit `6ad3114`
(Slice 6: longyi + taikpon player model + icon.svg) line by line.
Credit where due: a real traditional-dress player model (head
sphere, cream taikpon torso, dark emerald longyi cylinder) — the
first owner-spec dress in either tree — and `icon.svg` now exists,
fixing the missing-icon defect from earlier reviews.

Concrete limits of `6ad3114` (from its own diff):
- Cosmetic only: the `player.gd` change removes comments and blank
  lines; no behaviour, animation, or interaction changes.
- Static primitives, no limbs or walk animation; dress is on the
  player only — the owner spec wants PEOPLE (plural) in traditional
  dress, and there are still no NPCs in the opponent tree.
- `load_steps` goes 5 → 10, but the scene now has 2 ext + 6 sub
  resources (8), not 10 — a small count mismatch.
- Standing defects NOT fixed by this commit (files untouched):
  dead vehicle_controller, dead mobile_touch_ui, mount sprint on
  the undefined "sprint" action, airplane throttle auto-rise +
  stall_speed never read + roll/yaw double-using input_dir.x.

Slice 5 beats it on the same spec item, in Muse's own tree:
- The PLAYER now wears longyi + taikpon too (head/torso/longyi
  meshes, same honest primitive construction, no copied code).
- PLUS three wandering VILLAGERS in traditional dress (cream
  taikpon, longyi in emerald / blue / maroon), walking the village
  on their own via `npc.gd` (random targets, pauses, keeps clear
  of the pagoda platform). People, plural — as the owner asked.
- All Slice 4 features kept: car, cart, motorcycle, airplane,
  wired joystick, sprint/jump, dark nights, Q/E orbit, pagoda.
- Still honest gaps: no dialogue/quests, no obstacle avoidance
  for villagers, cow riding, helicopter, Android APK,
  whole-country map, PUBG graphics still missing; NOT run in
  Godot (no binary on this VM), no APK claimed.

## Slice 6 — beat the opponent's NPC slice: dialogue that actually works (MUSE, 2026-10-21)

Reviewed the opponent's `arena/antigravity` commit `3304e1d`
(Slice 7: interactive villagers, Burmese dialogue bubble, wandering
AI) line by line. Credit where due: a real 3-villager setup with an
IDLE / WANDERING / TALKING state machine, smooth facing
(lerp_angle), gravity handling, idle pauses, and a billboard
Label3D with a Burmese greeting — the first dialogue attempt in
either tree. `icon.svg` is also fixed since `6ad3114`, so that old
defect is closed.

Concrete defects of `3304e1d` (from its own diff):
- The dialogue is DEAD: `talk_to_player()` is defined in
  `scripts/myanmar_villager.gd` but nothing ever calls it. The
  villager's `_ready()` never connects `InteractionArea.body_entered`
  (unlike the opponent's own aircraft/mount controllers, which do),
  and no player code calls it either — so the bubble can never
  appear in-game. "Interactive" is a claim, not a working feature.
- Wanderers drift to the world origin: the wander target is a raw
  +/-25 box around (0, 0), not around the villager's home, so all
  three villagers converge on the same central patch.
- All three villagers are identical: same maroon longyi, same
  greeting line, same speed — no variety.
- `myanmar_villager.tscn` says `load_steps=9`, but it holds 1 ext +
  7 sub resources (8), not 9 — a small count mismatch.
- Standing defects NOT fixed by this commit (files untouched): dead
  vehicle_controller (no wheels, no scene), dead mobile_touch_ui
  (setup never called), mount sprint on the undefined "sprint"
  action, airplane throttle auto-rise + stall_speed declared but
  never read + roll and yaw both using input_dir.x.

Slice 6 beats it on the same spec item, in Muse's own tree:
- Dialogue WORKS end to end: walk within 3.5 m of a villager and
  press E — `player.gd` finds the nearest villager in the
  "villagers" group and calls `npc.gd`'s `talk_to()`, which faces
  the player and shows that villager's own Burmese greeting in a
  billboard Label3D bubble for 4 seconds, then walks on. Uses a
  physical E key, so no undefined input action is involved.
- Three DIFFERENT greetings (one per villager, exported
  `dialogue_text` in main.tscn) and the existing three longyi
  colours (emerald / blue / maroon) — variety, not clones.
- Wanderers stay home: targets are picked within 12 m of each
  villager's own spawn point, still keeping clear of the pagoda
  platform. `main.tscn` load_steps correctly stays 36 — the new
  Label3D nodes add no resources.
- All Slice 5 features kept: car, cart, motorcycle, airplane, wired
  joystick, sprint/jump, dark nights, Q/E orbit, pagoda, dressed
  player + dressed villagers.
- Still honest gaps: no quests, no villager obstacle avoidance,
  cow riding, helicopter, Android APK, whole-country map, PUBG
  graphics still missing; NOT run in Godot (no binary on this VM),
  no APK claimed.

## Slice 7 — review of opponent 0773481 ("Slice 8: auto-wiring HUD, E interaction, home wandering, villager variety")

Credited, because this is the opponent's strongest reply yet — it genuinely closes three defects Slice 6 listed:
- E dialogue is now WIRED: `player.gd` checks KEY_E every physics frame and calls `interact()`, which finds the nearest villager in the "villagers" group and calls `talk_to()` — and the villager script now defines `talk_to()` (renamed from the never-called `talk_to_player()`). The TALKING state stops movement, faces the player, and shows the bubble for 4.5 s. Dead dialogue is fixed.
- Home-based wandering is real: `spawn_position` is recorded in `_ready()` and targets are picked within radius 12 of it, not the world origin.
- The longyi-colour export + material-override code path is valid (`VisualMesh/Longyi` exists in the villager scene).

Defects that remain, with file evidence:
- `mobile_touch_ui.gd` is STILL dead code: the only reference to it in the whole tree is COLLAB.md prose — no scene instantiates it, and this commit changed no `.tscn` file, so its new "auto-wire" `_ready()` (look for the parent's "Player" node) can never run. Worse, it now extends Node3D while its children are Buttons/Controls (`$ActionButtons/InteractBtn`, `$VirtualJoystick`, `$PromptLabel`) that exist in no scene — Controls under a Node3D do not render as a touch HUD without a viewport, and those `@onready` paths would fail if the node were ever instantiated. "Auto-wiring Mobile Touch HUD" is a headline, not a live HUD.
- Variety is exports-only: `world.tscn` Villager1/2/3 carry NO property overrides, so all three still spawn with the default maroon longyi, the default greeting, and the default name. The `villager_name` export is also never displayed anywhere.
- `show_prompt()` / `hide_prompt()` are defined but never called by anything.
- E has no edge detection: `Input.is_key_pressed(KEY_E)` runs `interact()` every physics frame while E is held (~60x/second), so the dialogue timer resets continuously and mount/vehicle interact re-fires while held.
- Standing defects NOT fixed by this commit (files untouched): mount sprint still reads the undefined "sprint" action (`mount_controller.gd:49`, no sprint action in `project.godot`); airplane throttle still auto-rises (`aircraft_controller.gd:41`, `throttle + delta * 0.4`, no throttle-down) and `stall_speed` is still never read; `vehicle_controller` still has zero references anywhere.

## Slice 7 — Muse beats it (on top of 32c4868, all Slice 6 features kept)

### TOUCH-FIRST dialogue — owner correction, stated plainly
The owner is right: this is a MOBILE game, not a PC game. Slice 6's dialogue was keyboard-first (walk up, press E) — that was a mobile-design miss, and Slice 7 corrects it. TOUCH is now the primary path, in the real scene, not in a dead script:
- Walk within 3.5 m of a villager and a real on-screen **Talk button** ("စကားပြော") appears at the bottom-right of the screen — it is a Button node in `main.tscn` under `JoystickLayer`, hidden by default, shown only in range, hidden again while driving. Tapping it calls the nearest villager's `talk_to()` and the Burmese greeting bubble appears.
- OR tap the villager directly: `npc.gd` implements `_input_event()` (touch tap, plus mouse click on desktop where mouse is emulated as touch), so tapping a villager talks with no keyboard involved at all.
- E is kept ONLY as an optional desktop-debug fallback (still edge-detected, so it cannot spam like the opponent's held-E). The README, the code headers, and the COLLAB post all present TOUCH as primary.
- This is also where Muse's touch UI beats the opponent's Slice 8 headline: Muse's Talk button is in the shipped scene and wired; the opponent's "auto-wiring HUD" is in no scene at all.

### Rideable cow — the owner-spec item
The cow is no longer scenery: walk within 4 m and Enter/Space mounts it (the vehicle picker now also picks the NEAREST vehicle within 4 m, not the first name in list order — Slice 6 could pick a farther vehicle over a nearer one). Ride with WASD/arrows or the touch joystick (the driver's `touch_vector` is read, like the motorcycle), walk 3.0, trot 4.5 with Shift (physical key, no undefined action), Enter/Space dismounts beside the cow. No walk animation yet — stated plainly, not faked.

### Camera follows the ridden vehicle (latent fix, all vehicles)
Previously the camera stayed at the spot where you mounted, so a driven vehicle could drive out of view — the camera target was always the Player node, which freezes while driving. Slice 7 retargets `FollowCamera` to the ridden vehicle on mount (car, cart, motorcycle, airplane, cow) and back to the player on dismount. This fixes the same latent issue for every vehicle, not just the cow.

- `main.tscn` load_steps correctly stays 36 — the TalkButton node adds no resource.
- Still honest gaps: no quests, no villager obstacle avoidance, no cow walk animation, helicopter, Android APK, whole-country map, PUBG graphics still missing; NOT run in Godot (no binary on this VM), no APK claimed.

## Slice 8 — review of opponent e0c57ee ("Slice 9: live MobileTouchHUD in world.tscn + contextual action buttons + villager dialogue overrides")

Credited — this is the opponent's strongest HUD reply yet, and two old defects are genuinely closed:
- The HUD is LIVE this time: `scenes/mobile_touch_hud.tscn` is actually instantiated in `scenes/world.tscn` (load_steps 13 = 8 ext + 5 sub, correct), and `scripts/mobile_touch_hud.gd` wires against a real player API — `current_state` / `State` enum, `nearby_mount` / `nearby_vehicle` / `nearby_aircraft`, `_get_nearest_villager(4.0)`, `interact()` (which now falls back to villager `talk_to()`), `jump()`, `set_sprint()`, the `player` group, and both joystick signals (`joystick_moved`, `joystick_released`) are all present in its own `player.gd` / `virtual_joystick.gd`. The contextual Interact label (Ride Mount / Fly Plane / Drive / Talk / Dismount / Exit) is a real improvement.
- Villager variety is REAL this time: `world.tscn` Villager1/2/3 now carry actual overrides — names ကိုဘသောင်း / ဦးရွှေရိုး / ဒေါ်အေးကြည်, three distinct greetings, three distinct longyi colours. This fixes the Slice 8 "exports-only" defect.
- Touch-first: the HUD is buttons + joystick, no keyboard as primary path in this commit.

Defects that remain, with file evidence:
- `PromptBanner` is dead: assigned once (`@onready var prompt_banner`) and never shown, hidden, or written anywhere else in `mobile_touch_hud.gd` — its prompt text can never appear.
- `mobile_touch_hud.tscn` load_steps says 3 but holds 2 ext resources and 0 sub resources — off by one, same class of count slip as before (minor).
- The OLD dead files are still there: `scripts/mobile_touch_ui.gd` and `scripts/vehicle_controller.gd` are referenced by NO scene (git grep over `*.tscn` returns nothing for either).
- Standing defects NOT fixed by this commit (files untouched): mount sprint still reads the undefined "sprint" action (`mount_controller.gd:49`, no sprint action in `project.godot`); airplane throttle still auto-rises (`aircraft_controller.gd:41`, `throttle + delta * 0.4`, no throttle-down), `stall_speed` is still exported but never read, and roll (line 46) and yaw (line 47) still both use `input_dir.x`.

## Slice 8 — Muse beats it (on top of 1100d9c, all Slice 7 features kept)

### Touch-first action HUD — closing Muse's own keyboard gap
The opponent's HUD exposed a real Muse gap: Muse's sprint (Shift) and jump (J) were still keyboard-only, and vehicle enter/exit was Enter/Space only. Slice 8 closes it in the shipped scene, not in a dead script:
- On-screen **Sprint button** ("အပြေး", hold-to-sprint via button_down/up → `player.touch_sprint`), **Jump button** ("ခုန်", pressed → `jump_requested`, consumed on the next ground frame), and **Vehicle button** (shows "စီးမည်" near a vehicle within 4 m, "ဆင်းမည်" while driving) — all Button nodes in `main.tscn` under `JoystickLayer`, wired lazily by `player.gd` exactly like the Slice 7 Talk button.
- Every vehicle (car, cart, motorcycle, airplane, cow) gained a uniform `exit_vehicle()` wrapper around its existing `_exit_*()` method, so the touch Exit button uses the same dismount path (including stepping out beside the vehicle and retargeting the camera) as the keyboard path — no second, divergent exit implementation.
- Shift / J / Enter-Space remain ONLY as desktop fallbacks. Talk button + tap-villager dialogue from Slice 7 is untouched.
- `main.tscn` load_steps correctly stays 36 — Button nodes add no resources (10 ext + 26 sub, verified by count).

- Still honest gaps: vehicle STEERING while driving is still keyboard (WASD/arrows) for car/cart/airplane — the joystick drives on-foot movement only, so joystick-steered driving is the next touch gap; no quests, no villager obstacle avoidance, no cow walk animation, helicopter, Android APK, whole-country map, PUBG graphics still missing; NOT run in Godot (no binary on this VM), no APK claimed.

## Slice 9 — review of opponent 6145f71 ("Slice 10: flight stall physics, decoupled pitch/roll/yaw, explicit throttle, clean mount sprint, removed obsolete files")

Credited — this commit genuinely closes two defects Slice 8 listed, and it is the opponent's most honest physics fix yet:
- Stall is REAL now: `stall_speed` is actually read in `aircraft_controller.gd` — below stall speed lift collapses by a stall factor and the nose drops. The unused-export defect is closed.
- Mount sprint is FIXED: `mount_controller.gd` now reads the rider's `is_sprinting` state (set by the HUD Sprint button) or physical Shift — the undefined "sprint" input action is gone.
- Throttle is BETTER: it no longer rises unconditionally every frame — sprint raises it, otherwise it decays toward a 0.35 cruise floor.
- Dead-file cleanup is honest: deleting `mobile_touch_ui.gd` removes a file no scene referenced; nothing that worked is lost by it.

Defects that remain, with file evidence:
- `vehicle_controller.gd` is STILL dead: zero `.tscn` references in the whole tree (checked all 8 scenes at 6145f71). The opponent tree still has no car, no motorcycle, and no helicopter.
- Airplane throttle still cannot reach zero: the cruise floor is 0.35, and there is no throttle-down input below cruise — a pilot still cannot slow down to land except by exiting mid-air.
- No independent yaw: roll and yaw still share `input_dir.x` — yaw is now only a 0.4× coordinated turn from the roll input, and the old Q/E yaw is gone, so there is no way to yaw without rolling.
- `mobile_touch_hud.gd` was untouched by this commit, so the Slice 8 `PromptBanner` defect persists (assigned once, never shown or written).
- This commit itself is touch-compatible (joystick + HUD sprint feed the aircraft and mount) — no mobile-first violation in it, stated fairly.

## Slice 9 — Muse beats it: ~33-ITEM MAJOR UPGRADE, per the owner's new rule (on top of 090735f, all Slice 8 features kept)

Timing, stated plainly: Slice 9 was FIRST pushed as a smaller batch (game main `c6772ce`, items 1–8 below: joystick car/cart, cow trot, airplane throttle + yaw, helicopter, cow animation, quest) BEFORE the owner's second redirection arrived (2026-10-21 23:58 +07: upgrades must be ~30 items at once, with major graphics / UI / layout / icon / controls work, no tiny slices). This expansion commit completes Slice 9 on the same branch to 33 items. Nothing below is padding: every numbered item is in the shipped scene or wired code, and the list was counted after implementation, not before.

### Controls — touch-first (no keyboard-primary interaction anywhere)
1. **Car joystick steering** — `car.gd` reads the driver's `touch_vector` (x = steer, up = forward, down = reverse), the motorcycle's Slice 3 convention. WASD/arrows are desktop fallbacks only.
2. **Cart joystick steering** — same convention in `cart.gd`.
3. **Cow touch trot** — holding the on-screen Sprint button (`driver.touch_sprint`) trots the cow at 4.5; Shift is now a fallback, not the only way.
4. **Airplane touch throttle** — on-screen ThrottleUp / ThrottleDown buttons (hold-to-change, shown only while flying an aircraft) feed `driver.touch_throttle_up / touch_throttle_down` in `airplane.gd`. Throttle finally reaches 0 — the opponent's 0.35 cruise floor problem does not exist here. Shift/Ctrl are fallbacks.
5. **Airplane coordinated yaw** — roll input now also yaws the plane (`rotate_y(-roll_in * yaw_speed * 0.5 * delta)`), so a joystick-only pilot can turn. Q/E yaw remains as a desktop fallback.
6. **Helicopter (new vehicle)** — `helicopter.gd` + Helicopter node at (20, 1, 10): hovers when no vertical input is given, climbs with ThrottleUp, descends with ThrottleDown, turns with joystick x, moves with joystick y, Rotor mesh spins while flying. Same `start_driving()` / `exit_vehicle()` interface as every other vehicle, so the nearest-vehicle picker (now including "Helicopter") and camera retarget work unchanged. No weapons, no helicopter missions yet — stated plainly.
7. **Cow walk animation** — four leg meshes (LegFL/FR/BL/BR) swing in diagonal pairs while the cow moves, body bobs slightly, legs ease to neutral when still. Primitive mesh animation, not a skinned rig — stated honestly. Lookups are guarded, so an older scene without legs runs without crashing.
8. **First quest** — `QuestLabel` (top of screen) shows "တာဝန်: ရွာသားနဲ့ စကားပြောပါ (0/3)"; `npc.gd` `talk_to()` calls `player.record_talk()`, so the Talk button AND the direct-tap path both advance it; talking to all villagers flips it to "တာဝန် ပြီးပါပြီ!". No quest rewards or quest chain yet — stated plainly.

### Graphics — materials, paint, colour
9. **Ground grass material** — GroundMesh now has a green `StandardMaterial3D_ground` instead of default grey.
10. **House wall colours** — House1 cream, House2 warm brown (previously bare grey boxes).
11. **House roofs** — Roof1/Roof2/Roof3 (dark-red `BoxMesh_roof`) on all three houses.
12. **Car red paint** — red metallic body material.
13. **Cart wood paint** — wood-brown body material.
14. **Motorcycle teal paint** — teal metallic body material.
15. **Airplane paint** — white fuselage + yellow wings.
16. **Helicopter paint** — orange body + dark rotor.
17. **Cow paint** — light-brown body + dark-brown legs.
18. **Skin-tone heads** — Player + all three villagers' heads now use a skin material instead of default grey.

### Layout — village arrangement, roads, site context
19. **Dirt roads to the pagoda** — PathA (along z to −25) + PathB (along x to the pagoda), tan strips forming an L-shaped road from the village to the pagoda.
20. **Village plaza** — stone cylinder plaza (r5) at the village centre.
21. **Third house** — House3 at (−14, 10) with its own roof, so the village is no longer two floating boxes.
22. **Market stalls (2)** — counter + awning + 2 posts each at (−6, 2) and (−6, 6).
23. **Trees (3)** — trunk + foliage-sphere trees at (8, 6), (−12, 4), (14, −8).
24. **Pond** — blue water plane at (16, −2).
25. **Well** — stone ring + 2 posts + roof at (6, 12).
26. **Pagoda pillars** — 4 stone pillars around the pagoda platform, giving the landmark site context instead of a lone monument.
27. **Fence posts** — 6 wooden posts along the east side of the road.

### UI — HUD layout, prompts, dialogue presentation
28. **Speed + vehicle status readout** — `SpeedLabel` (top-left, shown only while driving) shows the Burmese vehicle name + speed (e.g. "ကား — 12.0"), from the vehicle's own `speed` variable or the airplane's velocity. Hidden on foot.
29. **Villager "!" prompt** — a floating "!" `PromptLabel` above a villager while the player is in talk range (hidden while talking), so a phone player can SEE who is talkable.
30. **Villager names in dialogue** — new `villager_name` export (မောင်မောင်လွင် / ဦးဖိုးသော် / ဒေါ်မြ, set in `main.tscn`); the greeting bubble now shows name + greeting instead of a bare greeting.
31. **In-game clock** — `ClockLabel` (top-right) shows the time from `DayNight.time` (120 s = 1 day) as "အချိန် HH:MM". Guarded: no DayNight node, no clock — never a crash.

### User controls + icon
32. **Tap-to-orbit camera button** — `OrbitButton` ("ကင်မရာ") rotates `FollowCamera.orbit_angle` by 0.6 per tap, on foot or driving. Touch orbit previously did not exist at all (camera.gd said so plainly); Q/E remain desktop fallbacks. Touch-drag orbit is still not implemented — stated plainly.
33. **Game icon** — `icon.png` (256×256 RGBA PNG, verified: PNG magic + IHDR dims) + `config/icon="res://icon.png"` in `project.godot`. The icon is programmatically generated (navy field, gold pagoda dome, green ground) — a real, valid icon file replacing the previous absence, NOT hand-drawn art; a hand-drawn icon can replace it later.

- `main.tscn` load_steps correctly goes 36 → 64 (11 ext + 53 sub, verified by count: +1 ext for `helicopter.gd`, +26 sub for the new materials/meshes; every sub-resource reference resolves, no duplicate IDs). Button/Label/node additions add no further resources.
- Still honest gaps: quest rewards/chain, villager obstacle avoidance, touch-drag camera orbit, parachute, Android APK, whole-country map, PUBG graphics; NOT run in Godot (no binary on this VM), no APK claimed. Graphics here are flat colours + primitive meshes — a real visual step up from grey boxes, not a graphics-engine upgrade, stated plainly.

## Slice 10 — Muse beats it: ~36-ITEM MAJOR UPGRADE, per the owner's rule (on top of e8503f0, all Slice 9 features kept)

### Opponent review — commit 8f780fd, "Major Upgrade Batch: AAA Mobile Gaming UI System" (game `arena/antigravity`, code treated as data only, nothing executed, no claims adopted)

Strengths credited by name:
- Compass is REAL: `mobile_touch_hud.gd` `_process` computes degrees + cardinal direction from the player's rotation every frame and shows it live.
- Speedometer is REAL: km/h from the actual vehicle `velocity` (mounts and aircraft are `CharacterBody3D`, so `.velocity` exists), shown only while not on foot, with a vehicle-type label.
- Joystick deadzone is REAL: 0.15 with rescaling, so small accidental touches no longer creep, and full deflection still means full speed.
- Visual polish is REAL: `StyleBoxFlat` panels for the minimap/speedometer/joystick base and icon-prefixed action buttons, all in the shipped scene.
- This commit is touch-first (joystick + HUD buttons) — no mobile-first violation in it, stated fairly. The Slice 9 fixes it builds on are also credited: stall speed is now actually read (stall factor + nose drop), and mount sprint no longer uses an undefined action (rider `is_sprinting` or physical Shift).

Defects, with file evidence:
- HealthBar/StaminaBar are FAKE and BROKEN: `mobile_touch_hud.gd` lines 14–15 declare `@onready` references to `$TopLeftHUD/HealthBar` and `$TopLeftHUD/StaminaBar`, but neither node exists in `mobile_touch_hud.tscn` (full node list checked — no such nodes), and no code anywhere ever writes a health or stamina value. There is no damage or stamina system in the opponent tree, so the "Health" headline is decoration pointing at missing nodes.
- PromptBanner is now a BROKEN reference: the `PromptBanner` node was removed from `mobile_touch_hud.tscn` in this very diff, but `mobile_touch_hud.gd` line 22 still declares `@onready var prompt_banner = $PromptBanner`. The Slice 8 defect (assigned once, never shown) has become a reference to a node that does not exist.
- Joystick Indicator is a BROKEN reference: `virtual_joystick.gd` declares `@onready var direction_indicator = $Base/Indicator`, but `mobile_touch_hud.tscn` has no `Indicator` node under `VirtualJoystick/Base` (only `Base` + `Handle` exist there).
- The "MiniMap" is NOT a map: it is a static panel with a `CenterCross` and a rotating `PlayerIcon` only — no dots for villagers, vehicles, or landmarks, and no world-to-map position mapping. The compass is real; the minimap is a compass-rose decoration.
- `mobile_touch_hud.tscn` says `load_steps=7` but holds 6 ext/sub resources (off by one, minor, same class of count slip as before).
- Airplane throttle STILL cannot reach zero: the cruise floor is 0.35 (`aircraft_controller.gd` line 43 clamps the decay to 0.35), so a pilot still cannot slow down to land except by exiting mid-air. Muse's airplane throttle reaches 0 (Slice 9).
- No independent yaw: roll and yaw still share `input_dir.x` — yaw is only a 0.4× coordinated turn from the roll input, so there is no way to yaw without rolling.
- `vehicle_controller.gd` is STILL dead: zero `.tscn` references anywhere in the tree. The opponent tree still has no car, no motorcycle, and no helicopter, so its speedometer's car branch is unexercised code.
- Muse's answer below deliberately does NOT fake health: there is no damage system in this game either, so Slice 10 ships a REAL stamina system (sprint drains it) and no health bar at all, rather than a decorative one.

### Slice 10 items — every item is in the shipped scene or wired code (counted after implementation, not before)

#### HUD / UI — a real version of everything the opponent's batch claimed
1. **REAL minimap** — `MinimapPanel` (top-right) with dots that actually move: player (yellow), 3 villagers (green), pagoda (gold), all 6 vehicles (white), positioned every frame from real world positions via a world→panel map (world −50..50 → panel 170 px, clamped). `player.gd` `_update_minimap()`; dots are real `ColorRect` children of the panel in `main.tscn`.
2. **Compass label** — `CompassLabel` (top-left) shows live degrees + cardinal direction from the facing rotation (on foot the player, driving the vehicle), using heading = 180° − rotation, so facing −Z reads north.
3. **Speed in km/h** — `SpeedLabel` now shows "ကား — 42 km/h" (units/s × 3.6) instead of a bare unit number.
4. **SpeedBar** — a `ProgressBar` under the speed label showing the fraction of that vehicle's top speed (car 14, cart 6, motorcycle 18, helicopter 12, cow 4.5, airplane 50).
5. **REAL stamina system** — `StaminaBar` (bottom-centre, on foot only): sprinting drains 25/s, resting restores 15/s, and sprint is blocked at 0. The opponent's stamina bar was a dead reference; this one is driven by a real variable.
6. **Joystick deadzone** — `joystick.gd` deadzone 0.15 with rescaling (same correct idea as the opponent's, applied to Muse's live joystick).
7. **Analog walk speed** — a half-pushed joystick now walks slower than a full push (speed scales 0.4–1.0 with deflection); keyboard input stays full speed. Previously the joystick direction was normalized and magnitude was thrown away.
8. **Day counter** — `DayLabel` shows "နေ့ N" from `DayNight.time` (120 s = 1 day), next to the Slice 9 clock.
9. **Nearby prompt label** — `PromptLabel` (bottom-centre, on foot only) names what is close enough to use: "အနီး: မောင်မောင်လွင် — စကားပြော" or "အနီး: ကား — စီးမည်".
10. **Help button + overlay** — `HelpButton` ("?") toggles a `HelpLabel` overlay listing all touch controls in Burmese, so a new player is never stuck guessing.
11. **Quest stage 2: visit the pagoda** — walking within 8 m of the pagoda advances the quest chain; the quest label becomes "တာဝန်: ဘုရားကို သွားပါ".
12. **Quest stage 3: ride a vehicle** — entering any vehicle advances the chain to "တာဝန်များ အားလုံး ပြီးပါပြီ!". The chain is now talk-all → pagoda → ride → done. Still no quest rewards — stated plainly.
13. **Touch yaw buttons** — `YawLeftButton` / `YawRightButton` (shown only while flying) feed `touch_yaw_left / touch_yaw_right` into `airplane.gd` (independent yaw, unlike the opponent's roll-coupled yaw) and `helicopter.gd` (added to joystick turn). No keyboard needed to turn in the air.
14. **Touch-drag orbit** — dragging on the RIGHT half of the screen rotates `FollowCamera.orbit_angle` (`camera.gd` `_unhandled_input`); the joystick lives on the left, so the two do not fight. This closes the Slice 9 stated gap ("touch-drag orbit is still not implemented").
15. **Zoom buttons** — `ZoomInButton` / `ZoomOutButton` adjust `FollowCamera.zoom` (0.6–1.8, steps of 0.2), scaling the follow distance.
16. **HUD button + panel styling** — real `StyleBoxFlat` styles in the shipped scene: translucent dark rounded panels (`MinimapPanel`) and rounded buttons on every `JoystickLayer` button, matching the opponent's glassmorphic polish with styles that actually exist.

#### Vehicles — dressing, motion, light
17. **Airplane propeller** — a `Propeller` mesh at the nose that spins (30 rad/s) while flying (`airplane.gd` rotates the real scene node, guarded by a null check).
18. **Car wheels (4)** — cylinder wheels at all four corners of the car body, axle along X.
19. **Car headlights (2)** — emissive yellow headlight boxes at the front of the car (real `emission_enabled` material).
20. **Motorcycle wheels (2)** — front and back cylinder wheels on the bike.
21. **Helicopter skids (2)** — landing skids under the helicopter body.
22. **Player arms (2)** — arm boxes at the player's torso sides, skin material.
23. **Villager arms (6)** — arm boxes on all three villagers, same torso layout as the player.

#### Graphics + layout — light, houses, nature, site dressing
24. **Sun shadows** — `SunLight.shadow_enabled = true`, so houses, trees, and vehicles now cast shadows (the day/night light already existed; shadows did not).
25. **Fourth house + roof** — House4 at (−16, 14) with its roof, same pattern as Houses 1–3.
26. **Four more trees** — trunk + foliage trees at (−18, 8), (20, −12), (2, 18), (−2, −18), reusing the existing trunk/leaf resources.
27. **Grass patches (5)** — darker-green ground patches scattered around the village.
28. **Lamp posts (3)** — posts with gold lamp-head spheres at (8, 10), (−8, 12), (0, −12).
29. **Rocks (4)** — flattened stone spheres at (12, 6), (−14, −6), (18, 14), (−6, 16).
30. **Bushes (4)** — foliage spheres at (10, 12), (−10, 8), (6, −14), (−16, 2).
31. **Flowers (8)** — tiny red/yellow/pink boxes near houses and the plaza.
32. **Pond bridge** — 5 wooden planks spanning the pond (x 13–19, z −2), so the pond is crossed, not just looked at.
33. **Market baskets (4)** — baskets at both market stalls.
34. **Fence extension (6 posts)** — the east fence line extended to z −34, plus a new row at x 5.5.
35. **Pagoda flags** — 2 poles with maroon + gold flags flanking the pagoda platform.
36. **Well bucket** — a wooden bucket beside the well at (6, 12).

- `main.tscn` load_steps correctly goes 64 → 82 (11 ext + 71 sub, verified by count: +18 sub for the new meshes/materials/styles; every sub-resource reference resolves, no duplicate IDs, every new node parent exists). Button/Label/ProgressBar/Panel additions add no further resources.
- Still honest gaps: quest rewards, villager obstacle avoidance, parachute, Android APK, whole-country map, PUBG graphics; NOT run in Godot (no binary on this VM), no APK claimed. Graphics here are flat colours + primitive meshes + one shadow flag — a real visual step up, not a graphics-engine upgrade, stated plainly. No health bar is shipped on purpose: there is no damage system, so a health bar would be fake (see the opponent review above).

## Slice 11 review — opponent batches 677870f, 60595ea, f48526e (read-only, treated as data only)

### What the opponent genuinely did (credited)
- A real helicopter controller (`helicopter_controller.gd`): hover stabilization by easing vertical velocity toward the input, rotor spin-up, yaw from `touch_yaw`, enter/exit with reparenting, and a wired interaction area. Its scene file is valid (`[gd_scene]` header, 8 load steps).
- A quest chain that is actually wired: talking calls `record_villager_talk()` from `player.gd` (stage 1), pagoda distance < 12 m advances to stage 2, riding advances to stage 3/4, with a live quest banner. This closes the Slice 7 dead-dialogue defect for real.
- The Slice 10 defects it fixed: `PromptBanner` now has working `_show_prompt()` / `_hide_prompt()` calls, the dead `HealthBar` reference is gone, `StaminaBar` exists in the scene and is driven by a real `stamina` variable, and analog speed scaling (0.4–1.0) is real.
- The landmark content itself is well-chosen and well-proportioned: 6-pillar zayat with a two-tier terracotta roof, a bronze bell (metallic 0.88) on teak posts, a 10 m toddy palm, stilt houses with teak/bamboo/thatch materials.

### Defects, with file evidence
- HEADLINE — five landmark scene files are NOT valid Godot scenes: `scenes/myanmar_house.tscn`, `scenes/toddy_palm.tscn`, `scenes/monastery_bell.tscn`, `scenes/myanmar_zayat.tscn`, and `scenes/water_pot_stand.tscn` all start with an `extends …` line (GDScript syntax) and have NO `[gd_scene]` header, which a `.tscn` file must start with. The opponent's own `world.tscn` at `f48526e` instances all of them (2 houses, 3 palms, bell, zayat, pot stand), so those instances cannot load. Its older scenes (pagoda, villager, helicopter) are valid — this broke starting with Slice 11's house file and continued through Slices 12–13.
- Helicopter vertical control has no dedicated touch path: climb comes only from the sprint-button side effect or the SPACE key, and descend comes ONLY from the CTRL key (`helicopter_controller.gd` vertical block). On a phone, the opponent's helicopter cannot descend — a mobile-first violation of the owner's rule. Muse's helicopter already had touch climb/descend buttons (Slice 9).
- The quest counts talks, not villagers: `record_villager_talk()` just increments a counter, so talking to one villager three times completes "talk to the villagers". Muse's quest already counts distinct villagers (`talked_ids` in `player.gd`).
- Held-E still re-fires `interact()` every physics frame in the opponent's `player.gd` (the comment changed, the code did not) — the Slice 8 held-E defect, still present.
- Analog speed has a 0.4 floor, so there is no slow creep; a mid-air helicopter exit drops the pilot with no parachute or landing handling; the helicopter scene has no landing skids.
- Standing defects untouched by all three commits (files unchanged): `vehicle_controller.gd` is still dead (zero `.tscn` references), the airplane throttle still cannot go below its 0.35 cruise floor, and roll/yaw still share `input_dir.x` (no independent yaw).
- Slice 12's "Expanded Cultural World Dressing" is only the bell + 3 palms in the world diff — no other dressing was added.

### Slice 11 items — every item is in the shipped scene or wired code (30 items)

#### Landmarks — the opponent's three batches, rebuilt as VALID scenes
1. **Toddy palm grove** — 4 palms at (−32, 16), (−37, 20), (−31, 22), (−38, 14): 10 m trunks with 6 radiating frond blades each, in `main.tscn` with a proper `[gd_scene]` header (unlike the opponent's malformed palm file).
2. **Coconut clusters** — 2 small coconuts on each palm crown.
3. **Monastery bell landmark** — `MonasteryBell` at (−6, −32): 2 teak posts, a teak beam, a bronze bell (metallic 0.88), and a stone base platform.
4. **Bell-ring interaction** — walking within 3.5 m of the bell rings it: a floating `BellLabel` ("ခေါင်းလောင်း ထိုးပြီးပါပြီ!") appears for 4 s. No keyboard involved.
5. **Rest pavilion zayat** — `Zayat` at (28, 2): 6 teak pillars, a wooden deck, and a two-tier terracotta pyatthat-style roof.
6. **Zayat benches** — 2 wooden benches inside the pavilion.
7. **Water pot stand** — a wooden stand with 2 red-clay pots and 2 clay cups beside the zayat.
8. **Stilt houses ×2** — at (−26, −16) and (0, −22): pillar stilts, a raised deck, bamboo walls, and a thatch roof each — visibly different from the flat box houses.
9. **Dirt paths** — 7 path segments on 3 routes: plaza → grove, plaza → bell, plaza → zayat.
10. **Grove bamboo fence** — 6 wooden posts around the toddy grove.

#### Quest — a fourth stage, and the first real reward
11. **Quest stage 4: ring the bell** — the chain is now talk-all (distinct villagers) → visit pagoda → ride a vehicle → ring the bell → done. The bell stage only advances after the ride stage, but the bell label shows on any ring.
12. **Quest reward: stamina blessing** — finishing the chain halves stamina drain (25 → 12.5/s) and doubles stamina restore (15 → 30/s) permanently, and the quest label says so. This closes the Slice 10 stated gap ("no quest rewards").
13. **Quest tracker checklist** — `QuestTrackerLabel` under the quest label lists all 4 stages live with ✓/○ marks, so the player always knows what is left.

#### HUD / controls — touch-first, all in the shipped scene
14. **Minimap landmark dots** — bronze bell dot, brown zayat dot, green grove dot, positioned from the real landmark nodes every frame (same world→panel map as Slice 10).
15. **Landmark proximity prompts** — the prompt label now names nearby landmarks on foot ("အနီး: ခေါင်းလောင်း", "အနီး: ဇရပ်", "အနီး: ထန်းတော") after the villager/vehicle checks.
16. **Camera reset button** — `CameraResetButton` ("📷", below the minimap) restores default orbit angle and zoom with one tap.
17. **Village entrance sign** — a wooden post with a floating `Label3D` ("ရွာအဝင်") at (3, 8), near the plaza.

#### Vehicle + people dressing
18. **Helicopter rotor blur disc** — a translucent disc above the helicopter rotor, so the spinning rotor reads as a blur from a distance.
19. **Cart wheels (2)** — cylinder wheels on the cart body, same axle convention as the car wheels.
20. **Cow saddle blanket** — a red blanket box on the cow's back.
21. **Motorcycle headlight** — an emissive headlight box at the front of the bike.
22. **Airplane tail fin** — a vertical fin at the rear of the fuselage.
23. **Car side mirrors (2)** — small dark mirror boxes at both sides of the car body.
24. **Player straw hat** — a conical straw hat (ခမောက်) on the player's head.
25. **Villager straw hats (3)** — one hat per villager, same conical mesh.

#### Graphics + layout dressing
26. **Stone lanterns (2)** — stone pillars with gold tops flanking the pagoda approach at (−16, −30) and (−24, −20).
27. **Pond reeds** — 6 tall thin reeds around the pond edge.
28. **Flower beds near the zayat** — 4 coloured beds (red/yellow/pink) framing the pavilion.
29. **Vegetable piles beside the stalls** — red and yellow produce piles on the ground by both market stalls.
30. **Icon regenerated** — `icon.png` redrawn programmatically (PIL): navy background, gold pagoda tiers, green toddy palm, gold sun — still 256×256, verified PNG magic + dimensions. Still programmatically generated, not hand-drawn art — stated plainly.

#### Repairs included in this slice (not counted in the 30)
- **Scene parse fix**: `BoxMesh_bike` and `BoxMesh_wing` were declared AFTER the first `[node]` in `main.tscn`, which Godot's text parser rejects — both are now declared with the other resources before the first node.
- **Script parse fixes**: the committed scripts contained `:=` declarations inferred from Variant values, which Godot 4.3's parser rejects (the APK build only had them fixed in its working tree, never committed). Fixed with explicit types in `player.gd` (2 lines), `day_night.gd` (1), `joystick.gd` (3), `airplane.gd` (2), `helicopter.gd` (2) — same values, only the declarations changed.

- `main.tscn` load_steps correctly goes 82 → 110 (11 ext + 99 sub, verified by count: +28 new sub-resources; every sub-resource reference resolves, no duplicate full node paths, every new node parent exists). All 11 project scripts pass Godot 4.3 `--check-only`, and the full scene loads and runs headless for 3 frames with no script or scene errors (only a dummy-renderer warning from headless mode, no GPU). That is a load test, not a playtest.
- Still honest gaps: villager obstacle avoidance, parachute, whole-country map, PUBG graphics; graphics here are flat colours + primitive meshes, not an engine upgrade; the APK from Slice 10 already exists and was NOT rebuilt in this slice (per instruction — do not claim APK work as new).

## Slice 12 review — opponent commit bb92987, "Mega Batch Slice 14: Traditional Myanmar Village Market Stalls + Red Brick Water Well" (read-only, treated as data only)

### What the opponent genuinely did (credited)
- Real modelling intent with Myanmar detail: market stalls with a wooden table, a blue tarpaulin canopy, woven bamboo baskets holding watermelons and mangoes; a brick well with a red-brick wall, a water surface, and a wooden pulley frame.
- Its `world.tscn` load_steps arithmetic is correct this time (16 ext + 5 sub = 21).

### Defects, with file evidence
- HEADLINE — both new scene files are NOT valid Godot scenes: `scenes/market_stall.tscn` and `scenes/village_well.tscn` start with an `extends StaticBody3D` line (GDScript syntax) and have NO `[gd_scene]` header, which a `.tscn` file must start with. Its own `world.tscn` declares them as `ext_resource type="PackedScene"` and instances all three (`MarketStall1`, `MarketStall2`, `VillageWell`), so none of the three new instances can load. This is the same defect Slice 11 found in five files — the opponent tree now has SEVEN invalid scene files (`myanmar_house`, `toddy_palm`, `monastery_bell`, `myanmar_zayat`, `water_pot_stand`, `market_stall`, `village_well`); its valid scenes remain pagoda, villager, player, airplane, bullock_cart, helicopter, rideable_cow, mobile_touch_hud.
- No interaction at all: the opponent's market and well are pure scenery — no buying, no drawing water, no vendor. Muse's versions below all work.
- Minor: the opponent's well water sets an albedo alpha of 0.85 but no `transparency` mode, so in Godot it renders opaque, not like water.
- This commit touches no scripts, so it adds no new mobile-first violation itself; the standing defects from earlier reviews are untouched by it (dead `vehicle_controller.gd`, airplane throttle 0.35 floor, roll/yaw sharing `input_dir.x`, held-E re-fire).

### Slice 12 items — every item is in the shipped scene or wired code (33 items, all Slice 11 features kept)

#### Market + well — the opponent's batch, rebuilt as VALID, loadable, working content
1. **Market stall A** at (16, 12) — wood frame, red awning, table, mango pile + watermelon pile, marigold garland strip.
2. **Market stall B** at (22, 12), rotated 15° — blue awning, banana pile + coconut pile, garland strip.
3. **Woven fruit baskets ×3** near the stalls, each holding fruit (mango / watermelon / coconut).
4. **Market parasol** — pole + red cone canopy.
5. **Market square paving** — 4 stone slabs.
6. **Market benches ×2** with legs.
7. **Marigold garland strips** — yellow strips across both stall fronts.
8. **Brick well** at (16, 18) — red-brick wall, a water surface that actually uses `transparency = 1` (so it looks like water, unlike the opponent's opaque one), pulley frame, rope, and a hanging bucket.
9. **Clay pots row ×5** beside the well.

#### Interactions + quest — touch-first, no keyboard path exists for either
10. **Buy-fruit touch button** — appears within 4 m of stall A; each tap raises the fruit count. Hidden while driving.
11. **Draw-water touch button** — appears within 4 m of the well; tapping lowers the bucket to the water and raises it back over 1.5 s, then raises the water count. Hidden while drawing and while driving.
12. **Quest stage 5: buy fruit at the market** — the chain is now talk-all → pagoda → ride → bell → buy fruit → draw water → done.
13. **Quest stage 6: draw water at the well, with the second reward** — finishing it raises walk speed +10% permanently, applied exactly once (`quest_rewarded2`).
14. **Quest tracker extended to 6 stages** with ✓/○ marks.
15. **Fruit/water counter HUD label** — "🍎 xN 💧 xM", top-right, updated on every buy/draw.
16. **Vendor villager (4th villager)** — "ဈေးသည် မမ" in a purple longyi with a straw hat and her own greeting, staying near the stalls (`wander_radius` 3.0). Talking to her counts toward talk-all (via `npc.gd` `record_talk`), so talk-all now needs 4 distinct villagers; the quest label's starting text was updated (0/4).

#### Village life + layout
17. **Rice paddy plots ×2** — green water-sheen plots.
18. **Banana plants ×3** — trunk + tilted leaves each.
19. **Mango tree** — trunk, round canopy, 3 mangoes.
20. **Bamboo grove ×5** stalks.
21. **Clothesline** — 2 poles, a line, a hanging longyi + taikpon cloth.
22. **Chickens ×3** — body + head + beak each, near House1.
23. **Wooden cart prop at the market** — bed + big wheels + side rails (static; the drivable cart is separate).
24. **Clay stove + pot** near House2.
25. **Stone path slabs ×4** toward the market.
26. **Village gate arch** — 2 posts, a crossbeam, and a floating "ကြိုဆိုပါတယ်" sign at (0, 26).

#### People + vehicle dressing
27. **Player shoulder bag** — small brown box on the player's side.
28. **Cow neck bell** — small gold bell on the cow.
29. **Airplane landing wheels ×2**.
30. **Cart canopy** — cloth + posts on the drivable cart.

#### UI
31. **Minimap dots** — red market dot, blue well dot, green 4th-villager dot, positioned from the real nodes every frame.
32. **Proximity prompts for market, well, and village sign** — this also fixes the old comment that claimed a village-sign prompt the code never had.
33. **Help overlay updated** — now mentions the buy-fruit and draw-water buttons.

#### Verification + honest gaps
- `main.tscn` load_steps correctly goes 110 → 175 (11 ext + 164 sub, verified by count: every sub-resource reference resolves, no duplicate sub-resource ids, every new node parent exists). All 11 project scripts pass Godot 4.3 `--check-only`, and the full scene loads and runs headless for 3 frames with no script or scene errors (only the usual headless dummy-renderer output). That is a load test, not a playtest.
- Still honest gaps: villager obstacle avoidance, parachute, whole-country map, PUBG graphics; graphics here are flat colours + primitive meshes, not an engine upgrade; the APK on Drive is the Slice 10 build and was NOT rebuilt in this slice (per instruction — do not claim APK work as new); the icon is unchanged in this slice.

## Slice 13 review — opponent commit 4f8c2ef, "Mega Batch Slice 15: Authentic Myanmar Village Entrance Arch Gate (ရွာဦးမုခ်ဦး) with 3D Burmese Welcome Sign + Tropical Banana Plant Grove (ငှက်ပျောတော)" (read-only, treated as data only)

### What the opponent genuinely did (credited)
- Real modelling intent with Myanmar detail: two weathered-reddish-teak columns, a gold metallic pyatthat spire top, and a Burmese welcome sign as a Label3D reading "မင်္ဂလာပါ — ရွှေရွာတော်မှ ကြိုဆိုပါ၏" with gold modulate and an outline; a banana plant with a greenish-brown stalk and three angled leaves in vibrant tropical green.
- Its `world.tscn` load_steps arithmetic is correct this time (21 → 23 with the 2 new ext resources).

### Defects, with file evidence
- HEADLINE — both new scene files are NOT valid Godot scenes: `scenes/village_gate.tscn` and `scenes/banana_plant.tscn` start with an `extends StaticBody3D` line (GDScript syntax) and have NO `[gd_scene]` header, which a `.tscn` file must start with. Its own `world.tscn` declares them as `ext_resource type="PackedScene"` and instances all three (`VillageGate` at (0, 0, 32), `BananaPlant1` at (18, 0, -6), `BananaPlant2` at (21, 0, -8)), so none of the three new instances can load. The opponent tree now has NINE invalid scene files (the previous seven plus `village_gate` and `banana_plant`).
- The opponent's gate is a wall, not a gate: its single `BoxShape3D` collision is 8.0 × 5.0 × 1.8 centered at y = 2.5, covering the whole arch including the passage — a player cannot walk through it.
- No interaction at all: the gate and the banana plants are pure scenery — no passing-through, no picking, no quest, no prompt, no minimap dot, no touch UI. The commit touches no scripts.
- This commit adds no new mobile-first violation itself (it has no input code); the standing defects from earlier reviews are untouched by it (dead `vehicle_controller.gd`, airplane throttle 0.35 floor, roll/yaw sharing `input_dir.x`, held-E re-fire, dead `PromptBanner` reference).

### Slice 13 items — every item is in the shipped scene or wired code (31 items, all Slice 12 features kept)

#### Gate + grove — the opponent's batch, rebuilt as VALID, loadable, working content
1. **Gate pass quest stage 7** — walk through Muse's own gate arch (horizontal distance < 2.0 m from `GateBeam12` at (0, 26)). Muse's arch is two posts + a beam with no blocking collision, so passing under it actually works — unlike the opponent's solid-wall gate.
2. **Banana grove cluster** at (36, 20) — 5 banana plants (trunk + tilted leaves each) plus 3 pickable banana bunches.
3. **Banana pick touch button** — appears within 3.5 m of the grove while a bunch remains; each tap hides one bunch and raises the banana count. Hidden while driving.
4. **Banana bunch regrow** — when all 3 bunches are picked, they regrow after 20 s.
5. **Quest stage 8: pick 3 bananas, with the third reward** — finishing it raises walk speed +5% permanently, applied exactly once (`quest_rewarded3`).
6. **Quest tracker extended to 8 stages** (talk-all → pagoda → ride → bell → buy fruit → draw water → gate pass → pick bananas) with ✓/○ marks, plus stage 6/7 labels and updated done text.
7. **5th villager gatekeeper "ဂိတ် ဦးဘ"** — orange longyi, straw hat, his own greeting, staying near the gate (`wander_radius` 3.0). Talk-all now needs 5 distinct villagers.
8. **Headlight toggle touch button** — shows only while driving the car or motorcycle; it toggles the headlight meshes' visibility (the car has two, the motorcycle one). No keyboard path is needed for it.

#### Landmarks + layout
9. **Tea shop** at (-14, 20) — table, 4 stools, gold teapot, and a "လက်ဖက်ရည်ဆိုင်" sign.
10. **Village school** at (-34, 14) — walls, two-tier roof, and a "ရွာကျောင်း" sign.
11. **Football ground** at (30, -20) — field patch and 2 goals (posts + crossbar).
12. **River strip** at z = 44 — a water plane using the `transparency = 1` water material, plus a bridge deck with 2 rails.
13. **House5 + roof** at (-24, -8), built from the same house meshes as Houses 1–4.
14. **Stilt house #3** at (20, -22) — deck, 4 pillars, walls, roof.
15. **Market stall C** at (12, 16) — table, 4 posts, bamboo awning, 2 crates.
16. **Sugarcane field** — 5 stalks.
17. **Chili plants ×4** with red fruits.
18. **Pumpkin patch ×3**.
19. **Sunflower field ×4** — stem, brown center, yellow leaf-petals.
20. **Lotus flowers ×3** on the pond.
21. **Pagoda garden beds ×2 + donation box** near the pagoda.
22. **Goat herd ×2** — body, head, 4 legs each.
23. **Pig pen** — 2 pigs + 4 pen posts.
24. **Ducks ×3** by the pond.
25. **Gate dressing** — a gold pyatthat spire on the gate beam, 2 red flags, 2 lantern posts with gold lanterns.
26. **Entrance road** — 3 stone path slabs from the gate into the village.
27. **Pond bridge rails ×2** on the Slice 10 plank bridge.

#### UI + icon
28. **Minimap dots ×5** — gate (gold), grove (green), school (blue), tea shop (orange), football ground (white) — plus a 5th-villager dot (green); all positioned from the real nodes every frame.
29. **Proximity prompts** — gate, grove, school, tea shop, football ground.
30. **Help overlay updated** — now mentions the banana-pick button, the gate quest, and the headlight toggle.
31. **Icon refreshed** — a new programmatically generated 256×256 PNG (sky, gold gate arch, banana plant, navy border; verified PNG magic + dimensions + spot-check pixels). It is program art, not hand-drawn art.

#### Verification + honest gaps
- `main.tscn` load_steps correctly goes 175 → 212 (11 ext + 200 sub, verified by count: every sub-resource reference resolves, no duplicate sub-resource ids, every new node parent exists). All 11 project scripts pass Godot 4.3 `--check-only`, and the full scene loads, instantiates, and runs headless for 3 frames with no script or scene errors. That is a load test, not a playtest.
- Still honest gaps: villager obstacle avoidance, parachute, whole-country map, PUBG graphics; graphics here are flat colours + primitive meshes, not an engine upgrade; the APK on Drive is the Slice 10 build and was NOT rebuilt in this slice (per instruction — do not claim APK work as new); the icon is program-generated, not hand-drawn.

## Slice 14 review — opponent commit 33d2498, "Mega Batch Slice 16: Golden Shwe Hinthar Mythical Bird Statues (ရွှေဟင်္သာရုပ်တုများ) on Marble Pedestals + Authentic Village Bamboo Footbridge (ဝါးတံတား)" (read-only, treated as data only)

### What the opponent genuinely did (credited)
- Real modelling intent with Myanmar detail: a white-marble pedestal, a gold bird (metallic 0.88) with body, tilted neck, head, beak and wings, placed as a mirrored pair flanking an approach; a bamboo footbridge with deck, side rails and end posts.
- Its `world.tscn` load_steps arithmetic is correct this time (23 → 25 with the 2 new ext resources).

### Defects, with file evidence
- HEADLINE — both new scene files are NOT valid Godot scenes: `scenes/bamboo_bridge.tscn` and `scenes/hinthar_statue.tscn` start with an `extends StaticBody3D` line (GDScript syntax) and have NO `[gd_scene]` header, which a `.tscn` file must start with. Its own `world.tscn` declares them as `ext_resource type="PackedScene"` and instances all three (`HintharStatueL` at (-4, 0, -32), `HintharStatueR` at (4, 0, -32), `BambooBridge` at (0, 0, -1)), so none of the three new instances can load. The opponent tree now has ELEVEN invalid scene files (the previous nine plus `bamboo_bridge` and `hinthar_statue`).
- The opponent's bridge is a wall, not a walkway: its single `BoxShape3D` collision is 3.2 × 1.4 × 8.5 centered at y = 0.7, spanning y 0–1.4, while its deck top sits at y = 0.375 — a player standing on the deck would be inside the collision volume, so the bridge cannot be walked across (the same class of defect as its Slice 15 solid-wall gate).
- No interaction at all: the statues and the bridge are pure scenery — no praying, no crossing quest, no prompt, no minimap dot, no touch UI. The commit touches no scripts.
- This commit adds no new mobile-first violation itself (it has no input code); the standing defects from earlier reviews are untouched by it (airplane throttle 0.35 floor — it cannot reach zero, so landing means exiting mid-air; no independent yaw — roll and yaw still share `input_dir.x` as a 0.4× coordinated turn; `vehicle_controller.gd` still dead with zero `.tscn` references, so the opponent tree still has no car, motorcycle, or helicopter; the broken `PromptBanner` / `HealthBar` / `StaminaBar` references from its HUD persist). Mount sprint, fixed in its Slice 10 commit (rider `is_sprinting` or Shift, no undefined action), is not regressed here.
- Minor: the statue has a single wing plank (1.4 × 0.1 × 0.6) instead of two wings; the bridge has posts only at its ends and no approach ramps for its 0.3-high deck step.

### Slice 14 items — every item is in the shipped scene or wired code (35 items, all Slice 13 features kept)

#### Bridge + statues — the opponent's batch, rebuilt as VALID, loadable, working content
1. **Walkable bamboo bridge** at (18, 44) over the river — a thin deck collision (top at deck level) plus gentle 8.5° ramp slopes at both ends, so a player can actually walk across it — unlike the opponent's wall-box bridge.
2. **Bridge-crossing quest stage 8** — reaching the bridge midpoint (horizontal distance < 2.5 m) advances the quest.
3. **Hinthar statue L** (valid) — marble pedestal, gold trim ring, gold body, tilted neck, head, beak, and TWO wings.
4. **Hinthar statue R** (valid) — the pair flanking the pagoda approach at (-26, -16) and (-14, -16).
5. **Pray touch button** — appears within 4 m of either statue while on foot, hidden while driving.
6. **Blessing label effect** — praying shows the nearest statue's "ဆုတောင်းပြည့်ပါစေ!" label for 4 s.
7. **Quest stage 9: pray at the statues, with the fourth reward** — finishing it raises walk speed +5% permanently, applied exactly once, plus a full stamina refill.
8. **Quest tracker extended to 10 stages** (talk-all → pagoda → ride → bell → buy fruit → draw water → gate pass → pick bananas → cross bridge → pray).
9. **Bridge minimap dot + proximity prompt**.
10. **Statue minimap dots (gold) + proximity prompts**.
11. **Bridge railings, both sides** (visual, like most dressing).
12. **Bridge posts ×6** (ends + middle, both sides).
13. **Bridge gold lanterns ×2** on the south end posts.
14. **Statue garden flowers ×6** (3 per statue).
15. **Statue garden hedges ×4** (2 per statue).
16. **Offering bowls + fruit at the statues**.
17. **Statue garden bamboo fence** (posts + rail).
18. **Statue approach stone slabs ×3** between the pair, heading to the village.
19. **Riverbank torch posts + gold lanterns ×2** flanking the statue approach.

#### River life
20. **Rideable rowboat** (`boat.gd`, new script) — joystick steering, Vehicle-button enter/exit, camera retarget, same enter/exit interface as the cart.
21. **Boat benches + oars**.
22. **Boat minimap dot + prompt + speed readout** (Burmese name "လှေ", top speed 5).
23. **Fisherman villager 6 "တံငါသည် ဦးထွန်း"** — teal longyi, fishing rod, his own greeting, staying near the river (`wander_radius` 4.0). Talk-all now needs 6 distinct villagers.
24. **VillagerDot6 + minimap villager loop extended to 6**.
25. **River reeds ×5** on the south bank.
26. **River stones ×4**.
27. **River lotus ×3** on the water.
28. **Riverside stone path** along the south bank.
29. **Riverside benches ×2** (seat + legs + back).
30. **Fishing net on posts** near the fisherman.
31. **Boat mooring post** on the bank.
32. **Pier planks ×3** from the bank toward the boat.
33. **Fish baskets ×2** near the fisherman.
34. **Bamboo clusters ×3** near the bridge banks.

#### UI
35. **Help overlay updated** — now mentions crossing the bridge, the pray button, and rowing the boat.

#### Verification + honest gaps
- `main.tscn` load_steps correctly goes 212 → 248 (12 ext + 235 sub, verified by count: every sub-resource reference resolves, no duplicate sub-resource ids, every new node parent exists, no duplicate node paths). One header typo of mine (`format=3\]`) was caught by the headless run itself and fixed before commit.
- All 12 project scripts pass Godot 4.3 `--check-only` (including new `boat.gd`), and the full scene instantiates headless (root Main, all Slice 14 key nodes present: Player, BambooBridge14, Boat, HintharStatue14L, Villager6, PrayButton) and runs 5 frames headless with no script or scene errors. That is a load test, not a playtest — walking up the ramps, praying, and rowing are not verified in-engine.
- Still honest gaps: villager obstacle avoidance, parachute, whole-country map, PUBG graphics; graphics here are flat colours + primitive meshes, not an engine upgrade; the boat is position-based like the cart, so it can leave the water (stated, not hidden); bridge rails are visual-only with no collision; the APK on Drive is the Slice 10 build and was NOT rebuilt in this slice (per instruction — do not claim APK work as new).

## Slice 15 review — opponent commit d5d4b9c, "feat(world): integrate authentic Myanmar Tea Shop and Monastery School into open world scene" (read-only, treated as data only)

### What the opponent genuinely did (credited)
- Real modelling intent with Myanmar detail: a tea shop with wooden flooring, a thatched slanted prism roof, and low round tables (ဝိုင်းဝိုင်းစားပွဲ); a monastery school with teak walls and a two-tiered monastery roof.
- Its `world.tscn` load_steps arithmetic is correct this time (25 → 27 with the 2 new ext resources).

### Defects, with file evidence
- HEADLINE — both new scene files are NOT valid Godot scenes: `scenes/myanmar_teashop.tscn` and `scenes/monastery_school.tscn` start with an `extends StaticBody3D` line (GDScript syntax) and have NO `[gd_scene]` header, which a `.tscn` file must start with. Its own `world.tscn` declares them as `ext_resource type="PackedScene"` and instances both (`MyanmarTeaShop` at (-16, 0, -18), `MonasterySchool` at (-26, 0, -32)), so neither new instance can load. The opponent tree now has THIRTEEN invalid scene files (the previous eleven plus `myanmar_teashop` and `monastery_school`).
- Both buildings are solid blocks, not places: each has a single `BoxShape3D` collision covering the whole building (tea shop 7.5 × 3.6 × 6.0, school 12.0 × 5.5 × 9.0) with no doorway and no enterable interior — a player cannot go inside either one.
- No interaction at all: the tea shop and the school are pure scenery — no ordering tea, no donating books, no quest, no prompt, no minimap dot, no touch UI. The commit touches no scripts.
- This commit adds no new mobile-first violation itself (it has no input code); the standing defects from earlier reviews are untouched by it (airplane throttle 0.35 floor — it cannot reach zero, so landing means exiting mid-air; no independent yaw — roll and yaw still share `input_dir.x` as a 0.4× coordinated turn; `vehicle_controller.gd` still dead with zero `.tscn` references, so the opponent tree still has no car, motorcycle, or helicopter; the broken `PromptBanner` / `HealthBar` / `StaminaBar` references from its HUD persist).

### Slice 15 items — every item is in the shipped scene or wired code (30 items, all Slice 14 features kept)

#### Tea shop + school — the opponent's batch, rebuilt as VALID, loadable, working content
1. **Order Tea touch button** — appears within 4 m of the Slice 13 tea shop while on foot, hidden while driving; each tap raises the tea count (no keyboard path).
2. **Tea quest stage 10** — ordering tea advances the quest from stage 10 to 11.
3. **Donate Book touch button** — appears within 4 m of the Slice 13 school while on foot, hidden while driving; each tap raises the book count (no keyboard path).
4. **Book quest stage 11, with the fifth reward** — donating a book advances the quest from stage 11 to 12 and raises sprint speed +10% permanently, applied exactly once.
5. **Bicycle quest stage 12** — riding the new bicycle advances the quest from stage 12 to 13, finishing the chain.
6. **Quest tracker extended to 13 tasks** (talk-all → pagoda → ride → bell → buy fruit → draw water → gate pass → pick bananas → cross bridge → pray → order tea → donate book → ride bicycle).
7. **Tea + book counters in the HUD** — the counter label now reads 🍎 💧 🍌 🍵 📚.
8. **Tea shop owner villager 7 "လက်ဖက်ရည်ဆိုင် ဦးအောင်"** — brown longyi, straw hat, his own greeting about hot tea, staying near the shop (`wander_radius` 3.0).
9. **Monk villager 8 "ဆရာတော် ဦးဇင်း"** — maroon robes, his own greeting about donating books, staying near the school (`wander_radius` 3.0). Talk-all now needs 8 distinct villagers.
10. **Minimap dots VillagerDot7 + VillagerDot8, and the villager dot loop extended from 6 to 8**.
11. **Tea shop second table + 2 stools** beside the original table.
12. **Tea cups ×3** — one on the original table, two on the new table.
13. **Tea shop lantern post + hanging gold lantern**.
14. **School fence posts ×4** along the school front.
15. **School bell post + small gold bell** beside the school front.
16. **School book stack ×3** (blue, red, green books) by the school front.
17. **School flower bed + flowers ×3** (pink, yellow, red) in front of the school.

#### Bicycle + village growth
18. **Rideable bicycle** (`bicycle.gd`, new script) — joystick steering, Vehicle-button enter/exit, camera retarget, same enter/exit interface as the cart and boat; top speed 7 (faster than walking, slower than the motorcycle).
19. **Spinning bicycle wheels** — both wheels rotate around their axle at ground speed (wheel radius 0.35).
20. **Bicycle minimap dot + prompt + speed readout** (Burmese name "စက်ဘီး", top speed 7).
21. **Bodhi tree** near the school — trunk + dark-leaf canopy.
22. **House6** at (28, 30) — walls, prism roof, wooden door.
23. **Stilt house #4** at (-40, -4) — deck, 4 teak pillars, bamboo walls, thatch roof (mirrors the earlier stilt pattern).
24. **Market stall D** at (22, 12) — table, 4 posts, 2 beams, blue awning, 2 mango piles.
25. **Sesame field** at (36, 10) — field bed + 6 sesame plants (moved after an overlap check found the first spot inside the zayat deck).
26. **Buffalo herd ×2** at (20, 32) and (23, 34) — body, head, 2 horns, 4 legs each.
27. **Firewood stack** at (-6, 16) — 3 logs in a pyramid.
28. **Pottery jars ×3** at (12, -10) — clay jars.
29. **Riverside benches ×2** at (2, 41) and (26, 41) — bench top + 2 legs each.
30. **Entrance road slabs ×4** from the gate toward the school (the last slab was moved after an overlap check found it inside the school walls footprint).

#### UI
- **Help overlay updated** — now mentions the order-tea button, the donate-book button, and riding the bicycle.

#### Verification + honest gaps
- `main.tscn` load_steps correctly goes 248 → 273 (13 ext + 259 sub, verified by count: every sub-resource reference resolves, no duplicate sub-resource ids, every new node parent exists, no duplicate sibling node paths). Four real overlaps found by the builder's check and fixed before commit (sesame field off the zayat deck, last road slab out of the school walls, both new villagers' roam boxes clear of shop/school furniture).
- All 13 project scripts pass Godot 4.3 `--check-only` (including new `bicycle.gd`), and the full scene instantiates headless (root Main, all Slice 15 key nodes present: Player, Bicycle, Villager7, Villager8, TeaButton15, BookButton15, VillagerDot7, VillagerDot8, VehicleDotBicycle, plus Slice 14's bridge, boat, statues, and fisherman) and runs 5 frames headless with no script or scene errors. That is a load test, not a playtest — ordering tea, donating books, and riding the bicycle are not verified in-engine.
- Still honest gaps: villager obstacle avoidance, parachute, whole-country map, PUBG graphics; graphics here are flat colours + primitive meshes, not an engine upgrade; the bicycle is position-based like the cart and the boat, so it can leave the road (stated, not hidden); the APK on Drive is the Slice 10 build and was NOT rebuilt in this slice (per instruction — do not claim APK work as new).

## Slice 16 review — opponent commit 5e5479c, "feat(slice-17): massive 30+ item upgrade - valid Godot 4.3 scenes, drivable village car, motorcycle, independent flight yaw, zero-throttle landing, 6-stage quest tracker" (read-only, treated as data only)

### What the opponent genuinely did (credited — its strongest reply yet, verified line by line, not taken from its subject)
- Real end-to-end vehicle wiring: `VillageCar` (VehicleBody3D + `vehicle_controller.gd` + InteractionArea + DriverSeat + 4 VehicleWheel3D wheels) and `MyanmarMotorcycle` (CharacterBody3D + new `motorcycle_controller.gd` + InteractionArea + DriverSeat), both instantiated in its `world.tscn`; player interact → `nearby_vehicle` → `enter_vehicle()` → `set_driving_state()`; touch joystick steering in both controllers. The previously dead `vehicle_controller.gd` is dead no more.
- Independent flight yaw is REAL: its HUD yaw buttons set `player.touch_yaw` (±1.0, reset on release) and `aircraft_controller.gd` reads `touch_yaw` for a dedicated `rotate_y` (with only a 0.3× coordinated bias as fallback).
- Zero-throttle landing is REAL: the throttle clamp lower bound is now 0.0 (was 0.35), and pushing the stick down decelerates 0.35/s to 0 for landing.
- The 6-stage quest tracker is REAL: talk 3 villagers → pagoda (14 m) → bell (8 m) → tea shop (10 m) → ride any vehicle → complete, with `record_villager_talk` wired from the player interact path.
- Scene headers: all 13 previously-invalid scenes now have `[gd_scene]` headers plus root nodes, and no `.tscn` in its tree starts with `extends` anymore. The BOM in its `.gd` scripts is harmless (a BOM-prefixed script passes Godot 4.3 `--check-only`, exit 0, verified).
- Its HUD scene node names all exist for its `@onready` paths (PromptBanner included).

### Defects, with file evidence
- HEADLINE — the "valid scenes" fix breaks its own world: every one of the 19 files this commit touches starts with a UTF-8 BOM (EF BB BF), and Godot 4.3's scene parser rejects a BOM before `[gd_scene]` with "Parse Error: Expected '['" (verified with my own BOM-prefixed test scene + the Godot 4.3 binary — the scene fails to load). So its `world.tscn` itself now FAILS to load — worse than before, when `world.tscn` loaded and only the landmark sub-scenes failed. The headline is false in practice until the BOMs are stripped.
- `load_steps` arithmetic is wrong in the new files: `village_car.tscn` header says 12 but holds 1 ext + 8 sub + 1 = 10; `myanmar_motorcycle.tscn` says 12 but holds 11; `world.tscn` says 29 but holds 24 ext + 5 sub + 1 = 30. (A wrong `load_steps` is only a hint mismatch, not a load failure — unlike the BOM.)
- Standing scenery defects untouched (these files changed header-only): the gate is still a wall (single 8.0 × 5.0 × 1.8 box over the whole arch), the bamboo bridge still has its wall collision, the tea shop and school are still solid blocks with no doorway. The helicopter controller and player script are untouched, so earlier standing items there stand.

### Slice 16 items — every item is in the shipped scene or wired code (31 items, all Slice 15 features kept)

#### Parachute — closes the standing "no parachute" gap from Slice 3
1. **Parachute canopy + 2 shroud lines** — children of the Player node, hidden until deployed.
2. **Auto-deploy on mid-air vehicle exit** — leaving an airplane or helicopter above y = 3.0 opens the canopy automatically (ground exits never deploy). No button needed, no keyboard path.
3. **Slow descent capped at 3.0 m/s** while the canopy is out (instead of the normal 20 m/s² fall).
4. **Joystick drift steering while parachuting** — the touch joystick steers the descent like walking.
5. **Auto-stow on landing** — touching the ground hides the canopy and lines.
6. **🪂 parachute label** — shows while the canopy is out ("လေထီး ပွင့်နေသည် — joystick ဖြင့် ရွေ့ပါ").
7. **Quest stage 14: parachute landing** — a parachute landing advances the quest from stage 14 to 15.

#### Tuk-tuk — the village taxi
8. **TukTuk vehicle node** at (35, -27) — blue body, yellow canopy roof, seat, 3 wheels, headlight mesh.
9. **Rideable tuk-tuk** (`tuktuk.gd`, new script) — joystick steering, Vehicle-button enter/exit, camera retarget, same enter/exit interface as the car and bicycle; top speed 11 (slower than the car, faster than the bicycle).
10. **Three spinning wheels** — all three rotate around their own (cylinder) axis at ground speed, like the bicycle wheels.
11. **Tuk-tuk minimap dot + prompt + speed readout** — Burmese name "သုံးဘီး", top speed 11 in the speed bar.
12. **Headlight toggle extended to the tuk-tuk** — the Lights button now works while driving the car, motorcycle, or tuk-tuk.
13. **Quest stage 13: ride the tuk-tuk** — riding it advances the quest from stage 13 to 14.

#### Festival ground — a new zone south-east of the football ground, around (42, -33)
14. **Festival drum + DrumButton16 + drum label + quest stage 15 + SIXTH reward** — the button appears within 4 m of the drum on foot; tapping shows the "ဗုံသံ!" label for 4 s and, on stage 15, finishes the chain with +5% walk speed (applied exactly once) + 10% jump velocity.
15. **Festival lantern lighting** — 3 lantern posts; the LanternButton16 lights the nearest unlit lantern within 4 m (its glow sphere appears) and raises the lantern count (max 3).
16. **Festival snack buying** — the SnackButton16 at the food stall raises the snack count; the HUD counter now reads 🍎 💧 🍌 🍵 📚 🍡 🪔.
17. **Villager 9 "ပွဲစီစဉ်သူ ကိုအောင်"** — festival organizer, own greeting about the drum, stays near the festival (`wander_radius` 3.0).
18. **Villager 10 "အကသမား မသီတာ"** — festival dancer, own greeting about the dances, stays near the festival (`wander_radius` 3.0).
19. **Talk-all now 0/10** — the quest and the minimap villager-dot loop both follow `villagers.size()` (loop cap raised 8 → 10).
20. **Festival ground slabs ×3** at (38/42/46, -33), the middle one being the minimap reference.
21. **Festival stage + backdrop + 2 gold banners** at (42, -27).
22. **String lights** — 2 poles + 5 emissive bulbs strung across the ground.
23. **Dance floor mat** at (42, -34).
24. **Food stall dressing** — counter, red awning, 2 posts, snack piles ×3.
25. **Entrance torches ×2** with emissive flames.
26. **Flag poles + flags ×2** (red and green).
27. **Path slabs ×3** from the football ground to the festival.

#### UI
28. **Minimap dots** — VehicleDotTukTuk (white), FestivalDot16 (gold), VillagerDot9 + VillagerDot10 (green).
29. **Proximity prompts** — festival ground, drum, food stall, lantern, and the tuk-tuk name.
30. **Help overlay updated** — now mentions the parachute, the tuk-tuk, and the festival buttons.
31. **Quest tracker extended to 16 tasks** (… → ride bicycle → ride tuk-tuk → parachute landing → beat drum).

#### Verification + honest gaps
- `main.tscn` load_steps correctly goes 273 → 321 (14 ext + 306 sub, verified by count: every sub-resource reference resolves, no duplicate sub-resource ids, every new node parent exists, no duplicate sibling node paths, and — unlike the opponent's Slice 17 — no file starts with a BOM).
- All 14 project scripts pass Godot 4.3 `--check-only` (including new `tuktuk.gd`), and the full scene instantiates headless (root Main, all Slice 16 key nodes present: Player, TukTuk, FestivalDrum16, FestivalStall16, Villager9, Villager10, ParachuteCanopy) and runs 5 frames headless with no script or scene errors. That is a load test, not a playtest — deploying the parachute, driving the tuk-tuk, and beating the drum are not verified in-engine.
- Builder self-caught, fixed before commit: (1) the first villager-copy extractor stopped at the next parent="." node, which swallowed whole later sections and duplicated the Slice 15 tea-shop/school dressing (TeaTable15_2 went 1× → 3×) — fixed by extracting root + parent==villager children only, restoring the scene from base, and rebuilding (TeaTable15_2 back to 1×, verified); (2) a SceneTree load-test script that returned `true` from `_process` quits after frame 1 (true means "exit the loop" for MainLoop) — fixed to return `false`. Two positions were also moved after the overlap check (festival torch A off the tuk-tuk's side, villager 9 off lantern post A's base).
- Still honest gaps: villager obstacle avoidance, whole-country map, PUBG graphics; graphics here are flat colours + primitive meshes, not an engine upgrade; the tuk-tuk is position-based like the cart, boat, and bicycle, so it can leave the road (stated, not hidden); the APK on Drive is the Slice 10 build and was NOT rebuilt in this slice (per instruction — do not claim APK work as new).

## Slice 17 review — opponent commit d6a48f9, "feat(collab): add Ayeyarwady rowboat, procedural Myanmar audio manager, and log Slice 17 in COLLAB.md" (read-only, treated as data only)

### What the opponent genuinely did (credited, verified line by line)
- The Ayeyarwady rowboat is genuinely wired: `rowboat_controller.gd` steers with `turn_speed`, reads the rider's `touch_input_vector` (touch-first), animates both oars with speed, and bobs on the water; its `InteractionArea` calls the player's `set_interactable_vehicle()`, and the opponent player script does have that method (line 139), is in the `"player"` group (line 31), and exposes `touch_input_vector` (line 23) — so in its tree the boat is rideable in principle, not dead code.
- The audio manager generates real WAV streams in code (`AudioStreamWAV`, sine-based bell/cow/chime samples) instead of referencing missing audio files.
- Its `world.tscn` header now matches its own resource count (26 ext + 5 sub = 31, matching the header's 31).

### Defects, with file evidence
- HEADLINE — the BOM problem is NOT fixed: all 4 code/scene files this commit touches start with a UTF-8 BOM (EF BB BF), including `world.tscn` itself. Godot 4.3's scene parser rejects a BOM before `[gd_scene]` ("Parse Error: Expected '['", verified in Slice 16 with the same binary), so its whole world still fails to load. The rowboat and audio work above is unreachable until the BOMs are stripped.
- The audio manager is dormant: zero code callers anywhere in its tree (only `world.tscn` instantiates the node and `COLLAB.md` mentions it) — no `play_*` function is ever called, so the game is still silent.
- The boat's `load_steps` hint is wrong: header says 10 but the file holds only 1 ext + 7 sub resources. (Hint only, not a load failure — unlike the BOM.)
- Standing scenery defects untouched (this commit touches no earlier files): the gate is still a wall, the bamboo bridge still has its wall collision, the tea shop and school are still solid blocks with no doorway.
- No new mobile-first violation in this commit (the boat reads touch input first; keyboard `ui_*` vector is only a fallback).

### Slice 17 items — every item is in the shipped scene or wired code (33 items, all Slice 16 features kept)

#### Villager obstacle avoidance — closes the last big standing gap from Slice 5
1. **Avoidance steering in `npc.gd`** — 15 mapped obstacle circles (pagoda, bell, school, tea shop, market, zayat, 4 houses, festival, 2 statues, bridge, gate). When a villager's next step would enter a circle, the step point is pushed to the circle's edge (plus 0.8 clearance) and the villager walks toward the adjusted point instead of through the building.
2. **Wander targets inside a circle are rejected** — `_pick_target()` now refuses any target within a circle's radius + 1.0 (in addition to the old pagoda-only check), so villagers no longer pick destinations inside houses and stalls.
3. **Honest limit stated** — this is circle steering, not full pathfinding: a villager boxed in by two circles can still shuffle along an edge. No pathfinding claim is made.

#### Five new touch interactions + quest stages 16–20 + seventh reward
4. **Fish button + fishing pier** — within 4 m of FishingSpot17 (30, 42, pier planks + rod + bucket on the riverbank) the "ငါးဖမ်း" button appears; tapping raises the 🐟 count and, on stage 16, advances the quest to 17.
5. **Donate button + donation box** — within 4 m of DonationBox17 (-12, -18, gold box + red roof near the pagoda) the "အလှူပေး" button appears; tapping raises the 💰 count and, on stage 17, advances to 18.
6. **Milk button + milking bucket** — within 3.5 m of the Cow the "နို့ညှစ်" button appears (bucket dressing at (7.5, -4)); tapping raises the 🥛 count and, on stage 18, advances to 19.
7. **Water crops button + growth stages** — within 4 m of SesameField15 (36, 10, water tank dressing at (33, 10)) the "ရေလောင်း" button appears; each watering grows all 6 sesame plants (scale 1.0 → 1.9 across 3 waterings) and, on stage 19, advances to 20.
8. **Feed chickens button + chicken coop** — within 4 m of ChickenCoop17 (-5, -7, coop + roof + fences by the Slice 12 chickens) the "အစာကျွေး" button appears; tapping raises the 🥚 count and, on stage 20, finishes the chain with the **SEVENTH reward** (+5% walk speed + 10% jump velocity, applied exactly once).
9. **Quest tracker extended to 21 tasks** — stages 16–20 named in Burmese (ငါးဖမ်း, အလှူပေး, နို့ညှစ်, ရေလောင်း, အစာကျွေး) with ✓/○ live tracking.

#### Sound that actually plays (unlike the opponent's dormant manager)
10. **Procedural quest chime** — a generated sine tone (AudioStreamWAV, built in code, no audio files) plays whenever the quest stage actually advances. It is wired into `_update_quest_label()`, so every stage advance chimes.
11. **Horn button while driving the car or tuk-tuk** — a 220 Hz, 0.4 s generated tone, touch-only, no keyboard path.
12. **Bell button while riding the bicycle** — an 880 Hz, 0.3 s generated tone, touch-only.

#### Photo, rain, night sky, football
13. **Photo button** — on foot, anytime: saves a screenshot PNG to `user://photo17_N.png` (N counts up) using the viewport texture. No fake "photo mode" filter claim — it is a plain screenshot save.
14. **Rain toggle button + rain particles** — the "မိုး" button toggles a 400-drop GPUParticles3D fall over the village (button text flips to "မိုးပိတ်" while raining). Visual only; it does not change gameplay.
15. **Moon + stars at night** — `day_night.gd` now shows the moon sphere and 8 stars only when daylight drops below 0.15 (near-dark), hiding them by day.
16. **Football you can actually kick** — the ball at the football ground (30, -20) is pushed when the player walks into it and rolls with decay; entering either goal (24, -20) or (36, -20) scores, resets the ball to centre, and raises the ⚽ counter.

#### Two more villagers (talk-all now 0/12)
17. **11th villager, blacksmith "ပန်းပဲဆရာ ဦးမောင်"** — orange longyi, own greeting about forging tools, wanders near the forge at (-38, -12).
18. **12th villager, potter "အိုးသည် မလှ"** — blue longyi, own greeting about clay pots, wanders near the wheel at (42, 6).
19. **Forge + anvil dressing** — dark forge block with an orange fire top at (-40, -12) and a grey anvil at (-38.5, -13.5).
20. **Potter wheel + 3 jars** — wheel at (40, 6), jars at (41, 7), (41.8, 7), (39.2, 7).

#### Village growth — layout, all placed clear of existing content (checked by script)
21. **Market stall E** — table + 2 posts + awning + 2 food piles at (26, 16).
22. **House7** — walls + red roof at (-28, 30).
23. **Stilt house #5** — deck on 4 stilts + red roof at (-6, -38).
24. **Mango grove** — 3 trees with fruit at (12, 34), (16, 34), (20, 32).
25. **Coconut palms ×3** — tall trunks + tops + nuts along the riverbank at (-6, 40), (6, 40), (34, 40).
26. **Flower garden** — 2 beds + 6 flowers at (-24, 2).
27. **Second well** — ring + posts + roof at (-8, 36).
28. **Entrance road extension** — 3 slabs at (-2, 30), (-2, 34), (-2, 38).
29. **Second rideable cow (Cow2)** — full copy of the Cow node + `cow.gd` script at (14, -6), added to both vehicle lists and the prompt names, so Vehicle-button enter/exit works exactly like the first cow.

#### UI — minimap, prompts, help, counters
30. **9 new minimap dots** — fishing spot (blue), donation box (gold), stall E (red), well #2 (blue), House7, Cow2, football ball (white), villagers 11/12 (green). Villagers 11/12 are tracked by node name because the old group loop only covered the first 10 villagers.
31. **Prompts for the new landmarks** — fishing spot, donation box, sesame field, chicken coop, stall E, well #2, House7, stilt house, football ball.
32. **Help overlay updated** — the new buttons (fish, donate, milk, water, feed, horn, bell, photo, rain) and football kicking are explained in Burmese.
33. **Counters extended** — the HUD counter line now reads 🍎 💧 🍌 🍵 📚 🍡 🪔 🐟 💰 🥛 🥚 ⚽.

- Verification: `load_steps` 321 → 352 (14 ext + 337 sub + 1, counted exactly), all 14 scripts pass Godot 4.3 `--check-only`, the main scene instantiates headless with all Slice 17 key nodes present (Player, Villager11/12, Cow2, FishingSpot17, DonationBox17, ChickenCoop17, FootballBall17, Rain17, Moon17, Stars17, all 9 buttons and 9 dots) and runs 5 frames headless with no script or scene errors. This is a load test, NOT a playtest — fishing, donating, milking, watering, feeding, horn, bell, photo saving, rain, and football scoring are not verified in-engine. Three real overlaps found by the builder's own distance check and fixed before commit (a mango tree moved off the Slice 14 fishing nets, a palm moved off a riverside bench, Cow2 moved out of the duck pond).
- Still honest gaps: villager avoidance is circle steering, not pathfinding; whole-country map, PUBG graphics; graphics here are flat colours + primitive meshes, not an engine upgrade; the tuk-tuk, bicycle, boat, and cart are position-based and can leave their roads/water (stated, not hidden); the APK on Drive is the Slice 10 build and was NOT rebuilt in this slice (per instruction — do not claim APK work as new).

## Slice 18 review — opponent commit b45ca75, "feat(slice-18): UTF-8 pure encoding, interior traversal for tea shop & school, walkable bridge, open village gate, Tuk-Tuk, and active procedural bell chime" (read-only, treated as data only)

Credited (verified, not taken from the subject): the BOM fix is REAL — no file anywhere in its `scenes/` or `scripts/` tree starts with a UTF-8 BOM at b45ca75, and `world.tscn` opens cleanly with `[gd_scene`. The open gate is REAL — the 8.0×5.0×1.8 wall box is replaced by two post cylinders at ±3.2, so the passage is open. The walkable bridge is REAL — the wall box is replaced by a thin 2.8×0.2×8.5 floor plus side rails. The tea shop + school interiors are REAL — solid boxes are replaced by a floor + posts (tea shop) and floor + back/left/right/front-L/R walls with a doorway gap + interior desks (school). The bell-chime callers are REAL — `mobile_touch_hud.gd` now calls `play_bell_strike()` on `_ready`, on quest advances, and on talk record, and `audio_manager.gd` generates a real 2.5 s WAV (216 + 432 Hz decay). Its `world.tscn` `load_steps` arithmetic is correct (27 ext + 5 sub = 32).

Defects (file evidence):
- HEADLINE: the bell-chime edit BROKE `mobile_touch_hud.gd` — Godot 4.3 `--check-only` fails with "Parse Error: There is already a variable named `audio_mgr` declared in this scope" (line 106). The HUD script that owns the quest tracker, speedometer, and yaw buttons cannot load, so the "active bell chime" is unreachable in practice until the duplicate declaration is fixed. The world parses now, but its HUD is dead.
- The tuk-tuk is scenery only: `myanmar_tuktuk.tscn` has an `InteractionArea` + `DriverSeat`, but `tuktuk_controller.gd` is EMPTY (0 bytes), zero scripts reference the tuk-tuk anywhere, there are no signal connections and no `enter_vehicle`/`exit_vehicle` — nothing can mount or drive it. (Muse's tuk-tuk has been drivable since Slice 16.)
- Held-E re-fire persists: its `player.gd` calls `interact()` on `Input.is_key_pressed(KEY_E)` every physics frame with no edge detection (pre-existing, not new). No new mobile-first violation in this commit's input code (its HUD touch buttons remain the input path).

### Slice 18 items — every item is in the shipped scene or wired code (33 items, all Slice 17 features kept)

#### Rideable elephant + quests
1. **Rideable elephant** — `elephant.gd` (CharacterBody3D, joystick steering, Vehicle-button enter/exit, camera retarget, top speed 6.0, "ဆင်" speed readout, primitive leg-swing + trunk-sway + ear-flap animation) at (-44, 22).
2. **Elephant stable** — roof shelter + 4 teak posts + 2 hay bales at (-44, 26).
3. **Feed elephant button** — within 4 m of the elephant, touch-first, no keyboard path.
4. **Quest stage 21: ride the elephant** — entering the elephant advances 21 → 22.
5. **Offer flowers button** — within 5 m of the pagoda + 🌸 counter.
6. **Quest stage 22: offer flowers** — offering advances 22 → 23.
7. **Plant rice button** — within 4 m of the new paddy; 6 seedlings grow through 3 stages (scale 1.0 → 1.9) + 🌾 counter.
8. **Quest stage 23: plant rice** — planting advances 23 → 24.
9. **Rest bench button** — near either pavilion bench, only while stamina < 100; refills stamina to 100.
10. **Quest stage 24: rest** — resting advances 24 → 25.
11. **Quest stage 25: feed the elephant + EIGHTH reward** — feeding advances 25 → 26 and applies walk +5% + stamina refill, exactly once.
12. **Quest tracker to 26 tasks** — stage names + checklist extended (ဆင်စီး, ပန်းကပ်, စပါးစိုက်, ခုံတန်းနား, ဆင်အစာကျွေး).

#### Villagers + village growth
13. **13th villager, goldsmith "ရွှေဆိုင် ဦးစိန်"** (own greeting, near the market; talk-all now 0/14) + gold stall with 3 gold boxes.
14. **14th villager, teacher "ဆရာမ မအေး"** (own greeting, at the school) + teacher desk in the schoolyard.
15. **Riverside pavilion** — floor + red roof + 4 teak posts at (-2, 38) with the 2 rest benches.
16. **Rice paddy #3** — mud bed + 6 seedlings at (8, 30).
17. **School playground** — swing frame + seat + slide at (-34, 6), plus school flag pole + flag.
18. **House8** — walls + red roof at (36, 30).
19. **Stilt house #6** — deck on 4 stilts + wood walls at (-2, -40).
20. **Market stall F** — table + 2 baskets at (20, 22).
21. **Second bamboo bridge** — deck + 2 rails over the river at (-24, 44).
22. **Bamboo grove #2 + palms ×2** — 3 stalks at (-46, -8), palms at (-36, 2) and (-40, -6).
23. **Flower garden #2 + path slabs** — bed + 3 flowers at (6, -34), slabs to the festival ground at (30/33/36, -33).
24. **Road lantern posts ×2** — teak posts + emissive gold lanterns at (0, 10) and (0, -6).
25. **Sky life** — `skylife.gd`: 3 birds circling the pagoda + 3 drifting clouds (wrap at the world edge).

#### Sound, night, UI
26. **Fireflies ×3** — emissive spheres at the flower garden, visible only when dark (same daylight rule as the Slice 17 moon/stars, in `day_night.gd`).
27. **Mute button** — always visible, toggles `sound_on`, and `_play_tone` (quest chime, horn, bell, trumpet) genuinely respects it.
28. **Photo count in the HUD** — counters now read 🍎 💧 🍌 🍵 📚 🍡 🪔 🐟 💰 🥛 🥚 ⚽ 🌸 📸 🌾.
29. **Trumpet button** — visible only while driving the elephant, plays a 392 Hz tone (the horn stays car/tuk-tuk only, the bell bicycle only).
30. **Minimap dots** — elephant (white), villagers 13/14 (green), pavilion, paddy.
31. **Prompts** — pavilion, paddy, elephant stable, playground.
32. **Help overlay updated** — elephant riding, flower offering, rice planting, resting, and the mute button explained in Burmese.
33. **Villager obstacle circles extended** — pavilion, stable, second bridge, House8, stilt house #6, and playground added to `npc.gd` so wanderers steer around them.

- Verification: `load_steps` 352 → 390 (16 ext + 373 sub + 1, counted exactly; every sub/ext reference resolves, no duplicate node paths, no BOM in any file), all 16 scripts pass Godot 4.3 `--check-only` (including new `elephant.gd` and `skylife.gd`), the main scene instantiates headless with all Slice 18 key nodes present (Player, Elephant, Villager13/14, Pavilion18, Paddy18, SkyLife18, Fireflies18, Bridge18_2, all 6 buttons and 5 dots) and runs 5 frames headless with no script or scene errors. This is a load test, NOT a playtest — riding the elephant, offering, planting, resting, feeding, muting, and the trumpet are not verified in-engine. Real overlaps found by the builder's own distance check and fixed before commit (House8 moved out of the mango grove, playground moved off the bodhi tree, pavilion moved off the second well, flag/desk moved out of the palm grove, grove moved off the sugarcane); the builder also fixed a self-caught parse error (an inserted minimap loop split from its body) before commit.
- Still honest gaps: villager avoidance is circle steering, not pathfinding; whole-country map, PUBG graphics; graphics here are flat colours + primitive meshes, not an engine upgrade; the elephant, tuk-tuk, bicycle, boat, and cart are position-based and can leave their roads/water (stated, not hidden); the APK on Drive is the Slice 10 build and was NOT rebuilt in this slice (per instruction — do not claim APK work as new).
