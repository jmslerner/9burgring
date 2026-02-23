# 9BURGRING — Outrun-Style Car Select Screen Reference

## Overview
Recreate an **Outrun (1986 arcade)** style car selection screen in Godot 4.x. This is a pixel-art, retro-futuristic UI with neon colors, a sunset backdrop, scanlines, and an animated perspective grid floor.

---

## Visual Style Guide

### Color Palette (Hex Values)
| Name | Hex | Use |
|------|-----|-----|
| Neon Pink | `#ff2d95` | Highlights, taillights, accents |
| Neon Blue | `#00d4ff` | Windows, UI text, grid lines |
| Neon Purple | `#b537f2` | Badges, secondary accents |
| Neon Orange | `#ff6b2b` | Sun gradient, fire accents |
| Neon Yellow | `#ffe44d` | Headlights, driver names, sun top |
| Sunset Dark | `#1a0a2e` | Background top, deepest sky |
| Sunset Mid | `#3d1155` | Mid sky, card backgrounds |
| Road Dark | `#1a1a2e` | Road surface, wheel color |
| Grid Line | `rgba(0,212,255,0.3)` | Perspective grid on floor |

### Aesthetic Elements
1. **Sunset Background**: Vertical gradient from `#1a0a2e` (top) → `#3d1155` (mid) → `#ff2d95` (horizon)
2. **Sun**: Large circle with gradient `#ffe44d` → `#ff6b2b` → `#ff2d95`, horizontal scan lines across it, placed at ~15% from top center, with a pulsing glow
3. **Perspective Grid Floor**: Covers bottom ~40% of screen. A flat grid of cyan lines that scrolls toward the viewer to simulate movement. Use a `SubViewport` or shader for the perspective warp
4. **Scanline Overlay**: Faint horizontal lines across entire screen (every 2-4px), semi-transparent black
5. **Mountain Silhouettes**: Dark purple triangular shapes between sun and grid floor

### Typography
- Use a pixel font (e.g., "Press Start 2P" or similar bitmap font from Google Fonts)
- Title: Large, gradient-filled text (pink/orange/yellow)
- Subtitles: Neon blue with glow
- Stats labels: Small, dim white
- Driver names: Neon yellow with glow

---

## Car Data (All 8 Vehicles)

### Car 1: Myles — BMW Turbo
- **Type**: 4-Door
- **HP**: 400 | **Handling**: 3 | **Accel**: 4 | **Braking**: 3 | **Top Speed**: 150
- **Body Color**: `#e63946` (Red)
- **Accent Color**: `#c1121f` (Dark Red)
- **Window**: `#00d4ff` | **Trim**: `#333333` | **Wheels**: `#1a1a2e` | **Headlights**: `#ffe44d`

### Car 2: Jack — Ford ST
- **Type**: 4-Door
- **HP**: 350 | **Handling**: 3 | **Accel**: 3 | **Braking**: 3 | **Top Speed**: 135
- **Body Color**: `#2196f3` (Blue)
- **Accent Color**: `#1565c0` (Dark Blue)
- **Window**: `#00d4ff` | **Trim**: `#333333` | **Wheels**: `#1a1a2e` | **Headlights**: `#ffe44d`

### Car 3: Cameron — BMW V8
- **Type**: 2-Door
- **HP**: 400 | **Handling**: 2 | **Accel**: 4 | **Braking**: 4 | **Top Speed**: 160
- **Body Color**: `#222222` (Black)
- **Accent Color**: `#111111` (Deep Black)
- **Window**: `#00d4ff` | **Trim**: `#444444` | **Wheels**: `#1a1a2e` | **Headlights**: `#ff2d95`

### Car 4: Ari — Porsche GT3
- **Type**: 2-Door
- **HP**: 450 | **Handling**: 5 | **Accel**: 4 | **Braking**: 5 | **Top Speed**: 185
- **Body Color**: `#ffe44d` (Yellow)
- **Accent Color**: `#f4a700` (Gold)
- **Window**: `#00d4ff` | **Trim**: `#333333` | **Wheels**: `#1a1a2e` | **Headlights**: `#ffe44d`

### Car 5: Hrag — Audi R8
- **Type**: 2-Door
- **HP**: 450 | **Handling**: 4 | **Accel**: 4 | **Braking**: 4 | **Top Speed**: 175
- **Body Color**: `#b537f2` (Purple)
- **Accent Color**: `#8a2be2` (Deep Purple)
- **Window**: `#00d4ff` | **Trim**: `#333333` | **Wheels**: `#1a1a2e` | **Headlights**: `#00d4ff`

### Car 6: Ethan — Porsche Spyder
- **Type**: 2-Door
- **HP**: 420 | **Handling**: 4 | **Accel**: 4 | **Braking**: 5 | **Top Speed**: 165
- **Body Color**: `#ff6b2b` (Orange)
- **Accent Color**: `#d4500a` (Burnt Orange)
- **Window**: `#00d4ff` | **Trim**: `#333333` | **Wheels**: `#1a1a2e` | **Headlights**: `#ffe44d`

### Car 7: James — Shelby GT350
- **Type**: 2-Door
- **HP**: 525 | **Handling**: 3 | **Accel**: 5 | **Braking**: 3 | **Top Speed**: 160
- **Body Color**: `#e0e0e0` (Silver)
- **Accent Color**: `#aaaaaa` (Gray)
- **Window**: `#00d4ff` | **Trim**: `#1a3a5c` (Racing Blue) | **Wheels**: `#1a1a2e` | **Headlights**: `#ff2d95`

### Car 8: Henry — Honda Civic
- **Type**: 4-Door
- **HP**: 250 | **Handling**: 4 | **Accel**: 2 | **Braking**: 3 | **Top Speed**: 135
- **Body Color**: `#4caf50` (Green)
- **Accent Color**: `#2e7d32` (Dark Green)
- **Window**: `#00d4ff` | **Trim**: `#333333` | **Wheels**: `#1a1a2e` | **Headlights**: `#ffe44d`

---

## Pixel Art Car Blueprint (60×25 pixel grid)

Each car is drawn on a 60×25 pixel canvas. Here is the pixel layout structure:

```
Row 5:        [____ROOF (20px wide, accent color)____]
Row 6-7:      [___ROOF (24px wide, accent color)___]
Row 8-12:     [PILLAR|WINDOW LEFT|PILLAR|WINDOW RIGHT|PILLAR]  (cabin)
Row 13:       [___________BODY_UPPER___________]
Row 14-18:    [LIGHT|______BODY_MAIN (40px wide)______|LIGHT]
Row 19:       [______________BUMPER_______________]
Row 20:       [___WHEEL_L___|_____BODY_____|___WHEEL_R___]
Row 22-23:    [______________SHADOW_______________]
Row 24:       [____________REFLECTION_____________]
```

### Key Differences by Door Type
- **4-Door**: Extra B-pillar at x=23 and x=37 (1px wide, trim color), additional door lines at x=22 and x=37 on the body
- **2-Door**: Side vent marks at x=12 and x=45 (3px wide, accent color), no extra pillars

### Pixel Art Implementation in Godot
- Create a `Sprite2D` with a `Image.create(60, 25, false, Image.FORMAT_RGBA8)`
- Use `image.set_pixel(x, y, Color(hex))` to draw each pixel
- Set the sprite's `texture_filter` to `TEXTURE_FILTER_NEAREST` for crisp pixel art
- Scale up the sprite (4x-6x) for display
- Alternatively, create the sprites as `.png` files in an image editor and import them

---

## Stat Bars Configuration

| Stat | Max Value | Bar Color Gradient |
|------|-----------|-------------------|
| HP (Power) | 550 | `#ff2d95` → `#ff6b2b` |
| Handling | 5 | `#00d4ff` → `#b537f2` |
| Acceleration | 5 | `#ffe44d` → `#ff6b2b` |
| Braking | 5 | `#b537f2` → `#ff2d95` |
| Top Speed | 200 | `#00d4ff` → `#ffe44d` |

Each bar should have:
- Dark background (`rgba(0,0,0,0.5)`)
- Segmented look (vertical notches every 3-4px)
- Animated fill on card appear (tween from 0 to target width)
- Numeric value displayed at the right end

---

## Godot Scene Structure (Suggested)

```
CarSelectScreen (Control)
├── BackgroundLayer (CanvasLayer)
│   ├── SkyGradient (ColorRect with shader)
│   ├── Sun (Sprite2D or TextureRect with shader for glow + scanlines)
│   ├── Mountains (Sprite2D or polygon)
│   └── GridFloor (MeshInstance2D or SubViewport with perspective shader)
├── ScanlineOverlay (ColorRect with scanline shader, z_index high)
├── TitleSection (VBoxContainer)
│   ├── TitleLabel ("OUTRUN" — large pixel font, gradient shader)
│   ├── SubtitleLabel ("SELECT YOUR RIDE" — neon blue)
│   └── BlinkLabel ("▼ CLICK A CAR ▼" — blinking animation)
├── CarGrid (GridContainer, 2-4 columns)
│   ├── CarCard_Myles (PanelContainer)
│   │   ├── DoorBadge (Label)
│   │   ├── DriverName (Label)
│   │   ├── CarName (Label)
│   │   ├── PixelCar (Sprite2D)
│   │   ├── RoadStrip (ColorRect with dashed pattern)
│   │   └── StatsContainer (VBoxContainer)
│   │       ├── StatBar_HP
│   │       ├── StatBar_Handling
│   │       ├── StatBar_Accel
│   │       ├── StatBar_Braking
│   │       └── StatBar_TopSpeed
│   ├── CarCard_Jack (...)
│   └── ... (8 cards total)
└── Footer (Label)
```

---

## Shader Snippets for Godot

### Scanline Overlay Shader
```gdshader
shader_type canvas_item;
void fragment() {
    float line = mod(FRAGCOORD.y, 4.0);
    if (line < 2.0) {
        COLOR = vec4(0.0, 0.0, 0.0, 0.08);
    } else {
        COLOR = vec4(0.0, 0.0, 0.0, 0.0);
    }
}
```

### Sun Glow Pulse Shader
```gdshader
shader_type canvas_item;
uniform float time_scale = 1.0;
void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    float pulse = 0.5 + 0.5 * sin(TIME * time_scale);
    float glow = pulse * 0.3;
    COLOR = tex + vec4(glow, glow * 0.5, 0.0, 0.0);
}
```

### Perspective Grid Floor Shader
```gdshader
shader_type canvas_item;
uniform float scroll_speed = 0.5;
uniform vec4 line_color : source_color = vec4(0.0, 0.83, 1.0, 0.3);
uniform float grid_size = 80.0;

void fragment() {
    vec2 uv = UV;
    // Perspective warp
    float perspective = mix(0.1, 1.0, uv.y);
    vec2 grid_uv = vec2(
        (uv.x - 0.5) / perspective + 0.5,
        1.0 / (1.0 - uv.y + 0.01)
    );
    grid_uv.y += TIME * scroll_speed;

    // Grid lines
    vec2 grid = abs(fract(grid_uv * grid_size) - 0.5);
    float line = min(grid.x, grid.y);
    float mask = 1.0 - smoothstep(0.0, 0.02, line);

    // Fade with distance
    float fade = smoothstep(0.0, 0.5, uv.y);
    COLOR = line_color * mask * fade;
}
```

---

## Interaction & Animation Notes

1. **Card Hover**: Border glows neon pink, card lifts slightly (offset y by -4px), pink light sweep across card
2. **Card Select**: Border turns neon yellow, glow intensifies, driver name gets a blinking "◄" cursor
3. **Stat Bar Animation**: On card appearing, bars tween from width 0 to target width over ~1 second with `Tween` and `EASE_OUT`
4. **Cards Stagger In**: Each card fades/slides in with a 0.1s delay per card (use `AnimationPlayer` or `Tween` with delay)
5. **Grid Floor**: Continuously scrolls toward viewer
6. **Sun**: Subtle pulsing glow (scale shadow/glow intensity with sine wave)
7. **Blink Text**: "SELECT YOUR RIDE" prompt blinks on 0.5s interval

---

## Audio Files

Place all audio files in `res://audio/` in your Godot project.

### Sound Effects
| File | Trigger | Type | Notes |
|------|---------|------|-------|
| `Choose_your_driver.mp3` | Car select screen loads | Voice/Announcer SFX | Plays once automatically when the car selection screen appears. This is the welcome sound. |
| `Good_choice.mp3` | Player confirms a car selection | Voice/Announcer SFX | Plays once when the player clicks/confirms their chosen car. Should play before transitioning to the next screen. |

### Selectable Soundtracks (In-Game Music)
| File | Display Name | Artist |
|------|-------------|--------|
| `ZISO_-_White_Vacancy.mp3` | White Vacancy | ZISO |
| `2050_-_Turbo_Power.mp3` | Turbo Power | 2050 |

### Audio Implementation in Godot

#### Scene Tree Additions
```
CarSelectScreen (Control)
├── ... (existing nodes)
├── AudioPlayers
│   ├── AnnouncerPlayer (AudioStreamPlayer) — for Choose_your_driver / Good_choice
│   ├── MusicPreviewPlayer (AudioStreamPlayer) — for previewing soundtracks
│   └── (optional) BGMPlayer (AudioStreamPlayer) — ambient background music loop
├── SoundtrackSelector (HBoxContainer or VBoxContainer)
│   ├── SoundtrackLabel (Label) — "SELECT SOUNDTRACK" in neon blue
│   ├── Track1Button (Button/TextureButton) — "ZISO — WHITE VACANCY"
│   └── Track2Button (Button/TextureButton) — "2050 — TURBO POWER"
```

#### GDScript Audio Logic
```gdscript
# Preload audio
var choose_driver_sfx = preload("res://audio/Choose_your_driver.mp3")
var good_choice_sfx = preload("res://audio/Good_choice.mp3")
var soundtrack_white_vacancy = preload("res://audio/ZISO_-_White_Vacancy.mp3")
var soundtrack_turbo_power = preload("res://audio/2050_-_Turbo_Power.mp3")

var selected_soundtrack: AudioStream = null

func _ready():
    # Play "Choose your driver!" when screen loads
    $AudioPlayers/AnnouncerPlayer.stream = choose_driver_sfx
    $AudioPlayers/AnnouncerPlayer.play()

func _on_car_confirmed(car_data: Dictionary):
    # Play "Good choice!" when player confirms selection
    $AudioPlayers/MusicPreviewPlayer.stop()
    $AudioPlayers/AnnouncerPlayer.stream = good_choice_sfx
    $AudioPlayers/AnnouncerPlayer.play()
    # Wait for the sound to finish, then transition
    await $AudioPlayers/AnnouncerPlayer.finished
    # Transition to race/next screen with car_data and selected_soundtrack

func _on_track_selected(track: AudioStream, track_name: String):
    # Preview the selected soundtrack
    selected_soundtrack = track
    $AudioPlayers/MusicPreviewPlayer.stream = track
    $AudioPlayers/MusicPreviewPlayer.play()
    # Highlight the selected track button
```

#### Audio Flow
1. **Screen loads** → `Choose_your_driver.mp3` plays automatically (announcer voice)
2. **Player browses cars** → click cards to highlight them, optionally preview soundtracks
3. **Player selects a soundtrack** → track starts playing as a preview, button highlights in neon yellow
4. **Player confirms car** → `Good_choice.mp3` plays, music fades, transition to next scene with chosen car + soundtrack data

### Soundtrack Selector Styling
- Position below the car grid or as a bottom bar
- Each track button: dark panel with neon blue border, track name in pixel font
- Selected track: neon yellow border + glow, "♫ NOW PLAYING" label
- Hover: neon pink border (same as car cards)
- Consider showing a small animated equalizer bar (pixel style) next to the playing track

---

## Quick-Start Prompt for Claude Code

Copy-paste this into Claude Code to get started:

> Create a Godot 4.x car selection screen scene in the style of the 1986 Outrun arcade game. Use the reference document in `outrun_reference.md` for all car data, color palettes, pixel art specs, shader code, scene structure, and audio setup. The screen needs: 8 car cards in a scrollable grid (each with pixel art car sprite, driver name, car name, door badge, animated stat bars), sunset background with sun/mountains/perspective grid/scanlines, audio integration (announcer voice "Choose your driver" on load, "Good choice" on confirm), and a soundtrack selector with 2 tracks (White Vacancy by ZISO, Turbo Power by 2050). Audio files are in `res://audio/`. All specs are in the reference doc.
