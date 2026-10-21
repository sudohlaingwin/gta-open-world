# Open World Mobile Game (Godot 4 Engine)

သီးသန့် Open World Mobile Game Project ဖြစ်ပါသည်။

## Project တည်နေရာ
`D:\Downloads\open world mobile game\`

## ပါဝင်သော အဓိက စနစ်များ (Core Features)

1. **`project.godot`**
   - Mobile renderer (`mobile` / Vulkan Mobile / OpenGL ES fallback)
   - Touch emulation (`pointing/emulate_touch_from_mouse = true`)
   - Landscape orientation စီစဉ်မှု

2. **3D Character Controller (`scripts/player.gd` & `scenes/player.tscn`)**
   - 3rd-person character physics
   - Walk / Sprint / Jump စနစ်
   - Camera forward-relative movement
   - Smooth visual mesh rotation facing input direction

3. **Touch Camera Orbit (`scripts/camera_orbit.gd`)**
   - Screen ပေါ်တွင် swipe ဆွဲရုံဖြင့် 360-degree camera လှည့်ပတ်နိုင်ခြင်း
   - SpringArm3D collision detection (အရာဝတ္ထုများနှင့် ကင်မရာ မငြိအောင် ကာကွယ်ခြင်း)

4. **Mobile Virtual Joystick (`scripts/virtual_joystick.gd`)**
   - Mobile မျက်နှာပြင်ပေါ်တွင် ထိတွေ့ထိန်းချုပ်နိုင်သည့် dynamic touch joystick

5. **Open World Environment (`scenes/world.tscn` & `scripts/day_night_cycle.gd`)**
   - 200m x 200m open terrain ground
   - Dynamic Procedural Sky & Sun Light
   - Automatic Day/Night Cycle
