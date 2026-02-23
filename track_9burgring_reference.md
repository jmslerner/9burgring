# 9BURGRING Race Track — Godot Implementation Reference

## Overview
The **9burgring** is based on **California State Route 9 (SR 9)**, a 35-mile winding mountain highway through the Santa Cruz Mountains in Northern California. It runs from SR 1 in Santa Cruz up to SR 17 in Los Gatos, passing through the San Lorenzo Valley and Saratoga Gap. The name "9burgring" is a homage to Germany's Nürburgring — coined by the NorCal car community who treat this road as their personal race track.

This is an **Outrun (1986) style** arcade racer, so the track should be a stylized, retro-pixel interpretation — not a realistic simulation. Think colorful, fast, and atmospheric.

---

## Real-World Route Data

### Key Stats
| Attribute | Value |
|-----------|-------|
| Total Length | ~35 miles (56 km) |
| Start Point | SR 1, Santa Cruz (sea level) |
| End Point | SR 17, Los Gatos |
| Highest Elevation | 2,608 ft (795 m) at Saratoga Gap |
| Road Type | Mostly 2-lane, undivided, winding mountain road |
| Direction for Game | South → North (Santa Cruz → Los Gatos) |

### Route Sections (use as race stages/checkpoints)

#### Stage 1: Santa Cruz → Felton (7 miles)
- **Elevation**: Sea level → ~300 ft
- **Character**: Urban exit, then winding through redwood forest
- **Road**: Starts as "River Street" in Santa Cruz, becomes 2-lane mountain road
- **Landmarks**: Henry Cowell Redwoods State Park, San Lorenzo River crossings
- **Scenery**: Coastal town → dense redwood canopy, river alongside road
- **Outrun Style**: Beach town buildings, palm trees transitioning to massive redwood trees, dappled sunlight

#### Stage 2: Felton → Boulder Creek (6 miles)
- **Elevation**: ~300 ft → ~480 ft
- **Character**: Small mountain towns, continued forest, river valley
- **Landmarks**: Ben Lomond, Brookdale (historic Brookdale Lodge), Boulder Creek town
- **Scenery**: Quaint mountain village streets, old-growth redwoods, wooden bridges
- **Outrun Style**: Rustic shops and signs flashing by, log cabins, misty redwood forest, vintage gas stations

#### Stage 3: Boulder Creek → Saratoga Gap — THE CLIMB (14 miles)
- **Elevation**: ~480 ft → 2,608 ft (the big ascent!)
- **Character**: This is the HEART of the 9burgring — steep, tight hairpins, relentless curves
- **Landmarks**: Castle Rock State Park, junction with SR 236, Saratoga Gap vista point
- **Scenery**: Dense mixed-evergreen forest, sandstone rock formations, fog rolling through trees, cliff edges
- **Outrun Style**: Dramatic elevation, guardrails flashing by, fog effects, steep drop-offs visible to the side, trees whipping past, occasional rocky outcrops
- **GAMEPLAY NOTE**: This is where the track gets hardest — tightest turns, most elevation change, highest risk/reward

#### Stage 4: Saratoga Gap → Los Gatos — THE DESCENT (8 miles)
- **Elevation**: 2,608 ft → ~400 ft
- **Character**: Fast downhill, sweeping curves, opens up toward suburbia
- **Road becomes**: "Congress Springs Road" in Saratoga, then "Saratoga-Los Gatos Road"
- **Landmarks**: Mountain Winery, vineyards, Saratoga village, downtown Los Gatos
- **Scenery**: Mountain ridge views of Silicon Valley/Bay Area, vineyards, upscale suburban streets
- **Outrun Style**: Sunset vista of the valley below, vineyard rows blurring past, fancy houses, finish line in Los Gatos with neon lights

---

## Track Design for Outrun-Style Gameplay

### Road Rendering (Pseudo-3D / Mode 7 Style)
Outrun uses a **pseudo-3D road** technique. The road is drawn as horizontal strips from bottom (near) to top (far) of the screen, with each strip offset to create curves and hills.

#### Core Concepts
- **Segments**: The road is divided into hundreds of segments, each with properties for curve, hill, and scenery
- **Curve**: Horizontal offset per segment (positive = right, negative = left)
- **Hill**: Vertical offset per segment (positive = uphill, negative = downhill)
- **Road Width**: Wider at bottom (near), narrower at top (far) — perspective scaling
- **Stripes**: Alternating road colors (dark/light) create the sense of speed
- **Rumble Strips**: Colored edges (red/white) on road shoulders

#### Road Color Palette
| Element | Color 1 | Color 2 (alternating) |
|---------|---------|----------------------|
| Road Surface | `#666666` | `#707070` |
| Lane Markings | `#FFFFFF` | (same as road for alt stripe) |
| Rumble Strip | `#FF2D95` (neon pink) | `#FFFFFF` |
| Grass/Shoulder (Redwoods) | `#2D5A27` | `#234D1F` |
| Grass/Shoulder (Mountain) | `#3A6B35` | `#2D5A27` |
| Grass/Shoulder (Vineyard) | `#8B7D3C` | `#7A6C2F` |

### Suggested Track Layout (Segment Curve/Hill Values)

```
STAGE 1 — SANTA CRUZ TO FELTON (Segments 0–200)
  Segments 0–30:    Straight, flat (city exit)
  Segments 30–60:   Gentle right curve, slight uphill
  Segments 60–90:   S-curve (left then right), flat
  Segments 90–130:  Long left curve, entering forest
  Segments 130–160: Straight through redwoods, gentle uphill
  Segments 160–200: Right curve into Felton, checkpoint

STAGE 2 — FELTON TO BOULDER CREEK (Segments 200–380)
  Segments 200–230: Town zone (straight, speed limit signs as scenery)
  Segments 230–270: Winding S-curves along river
  Segments 270–310: Long right curve, bridge crossing
  Segments 310–350: Left curve through Ben Lomond
  Segments 350–380: Into Boulder Creek, checkpoint

STAGE 3 — THE CLIMB (Segments 380–700) ★ HARDEST SECTION
  Segments 380–420: Steep uphill begins, gentle curves
  Segments 420–460: Tight left hairpin + uphill
  Segments 460–500: Short straight, steep uphill, cliff edge scenery
  Segments 500–540: Tight right hairpin
  Segments 540–580: S-curve, continued climb, fog starts
  Segments 580–620: Very tight left hairpin (Castle Rock)
  Segments 620–660: Sweeping right, uphill eases
  Segments 660–700: Final push to summit, Saratoga Gap checkpoint

STAGE 4 — THE DESCENT (Segments 700–900)
  Segments 700–740: Summit vista (straight, panoramic view moment)
  Segments 740–780: Fast right curve, steep downhill begins
  Segments 780–820: S-curves, downhill
  Segments 820–860: Long sweeping left, vineyard scenery
  Segments 860–880: Entering Saratoga, gentle curves
  Segments 880–900: Final straight into Los Gatos, FINISH LINE
```

---

## Roadside Scenery Objects (Sprites)

For each stage, place these pixel-art sprites alongside the road:

### Stage 1 — Santa Cruz / Redwoods
- Palm trees (Santa Cruz exit)
- Beach-style buildings (first few segments)
- Redwood trees (TALL, dark trunks, green canopy) — most common sprite
- Wooden fences
- "SR 9" road sign
- San Lorenzo River (blue strip alongside road)

### Stage 2 — Mountain Towns
- Small wooden buildings / shops
- Vintage gas station
- Log cabins
- Redwood trees (continued)
- Wooden bridge railings
- "Ben Lomond" / "Boulder Creek" town signs

### Stage 3 — The Climb
- Dense pine/redwood trees
- Rock formations (gray/brown boulders)
- Metal guardrails (critical on hairpins)
- Cliff edge (visible drop-off)
- Fog/mist particles
- "Castle Rock State Park" sign
- Elevation markers

### Stage 4 — The Descent
- Vineyard rows (green/purple)
- Upscale houses
- Oak trees (lighter green, wider canopy)
- Valley vista backdrop (Silicon Valley skyline in distance)
- Mountain Winery sign
- Finish banner / checkered flag

---

## Outrun Visual Effects

### Sky/Background per Stage
| Stage | Sky Gradient | Sun Position | Special |
|-------|-------------|-------------|---------|
| 1 - Santa Cruz | Light blue → white (coastal) | High, bright | Seagulls, ocean shimmer at start |
| 2 - Towns | Blue → golden (afternoon) | Mid-high | Light cloud wisps |
| 3 - The Climb | Purple → dark blue (dusk) | Low, orange | FOG rolling across road, dramatic |
| 4 - Descent | Orange → pink → purple (sunset) | Setting behind mountains | Full Outrun sunset, neon glow |

### Speed Effects
- Road stripe scroll speed increases with car speed
- Scenery objects fly past faster
- Screen shake on rumble strips
- Motion blur lines at top speed (>150 mph)

### Weather/Atmosphere
- Stage 3 should have intermittent FOG — reduce visibility, scenery objects fade
- Stage 1 can have brief ocean mist near start
- Stage 4 golden hour lighting — warm tint overlay

---

## Godot Implementation Approach

### Option A: Pseudo-3D (Classic Outrun Style) — RECOMMENDED
This is the authentic Outrun approach. The entire road is rendered as horizontal line strips.

#### Scene Structure
```
RaceScene (Node2D)
├── SkyBackground (Sprite2D or ColorRect with gradient shader)
├── MountainParallax (ParallaxBackground)
│   ├── ParallaxLayer1 — distant mountains
│   ├── ParallaxLayer2 — mid hills/trees
│   └── ParallaxLayer3 — near scenery silhouettes
├── RoadRenderer (Node2D + custom _draw() or shader)
│   └── Uses segment data to draw road strips each frame
├── ScenerySprites (Node2D)
│   └── Dynamically placed sprites based on current road position
├── PlayerCar (Sprite2D — centered at bottom of screen)
├── TrafficCars (Node2D — other pixel cars on the road)
├── HUD (CanvasLayer)
│   ├── SpeedDisplay
│   ├── LapTimer
│   ├── StageIndicator
│   ├── Minimap (optional)
│   └── Tachometer
├── AudioPlayers
│   ├── EngineSound (AudioStreamPlayer)
│   ├── SFXPlayer (AudioStreamPlayer)
│   └── MusicPlayer (AudioStreamPlayer) — plays selected soundtrack
└── CheckpointManager (Node) — handles stage transitions
```

#### GDScript Road Rendering Pseudocode
```gdscript
# Road segment data structure
class RoadSegment:
    var curve: float = 0.0      # horizontal curve (-1 to 1)
    var hill: float = 0.0       # vertical hill (-1 to 1)
    var scenery_left: String = ""   # sprite to show on left
    var scenery_right: String = ""  # sprite to show on right
    var is_checkpoint: bool = false
    var stage: int = 1

# Build road from segment definitions
var segments: Array[RoadSegment] = []
var player_position: float = 0.0  # position along track
var player_speed: float = 0.0
var player_x: float = 0.0  # lateral position on road (-1 to 1)

func _draw():
    var screen_h = get_viewport_rect().size.y
    var road_start_y = screen_h  # bottom of screen
    var draw_distance = 300  # how many segments ahead to draw

    var cam_x = 0.0
    var cam_y = 0.0

    # Draw from far to near (painter's algorithm)
    for i in range(draw_distance, 0, -1):
        var seg_index = int(player_position) + i
        if seg_index >= segments.size():
            continue

        var seg = segments[seg_index]

        # Calculate screen position with perspective
        var scale = 1.0 / (i + 1)
        var screen_y = screen_h * 0.4 + (screen_h * 0.6) * (1.0 - scale)

        cam_x += seg.curve * scale
        cam_y += seg.hill * scale

        var road_width = 2000 * scale
        var road_center_x = get_viewport_rect().size.x / 2 - cam_x * road_width

        # Alternating stripe colors
        var stripe = (seg_index / 3) % 2
        var road_color = Color("#666666") if stripe == 0 else Color("#707070")
        var grass_color = Color("#2D5A27") if stripe == 0 else Color("#234D1F")
        var rumble_color = Color("#FF2D95") if stripe == 0 else Color("#FFFFFF")

        # Draw grass (full width)
        draw_rect(Rect2(0, screen_y, get_viewport_rect().size.x, 2), grass_color)
        # Draw rumble strips
        draw_rect(Rect2(road_center_x - road_width/2 - 20*scale, screen_y, 20*scale, 2), rumble_color)
        draw_rect(Rect2(road_center_x + road_width/2, screen_y, 20*scale, 2), rumble_color)
        # Draw road
        draw_rect(Rect2(road_center_x - road_width/2, screen_y, road_width, 2), road_color)
        # Draw center line
        if stripe == 0:
            draw_rect(Rect2(road_center_x - 2*scale, screen_y, 4*scale, 2), Color.WHITE)
```

### Option B: 3D with Retro Shader
Use Godot's 3D engine with a MeshInstance3D road and apply a retro pixel shader.

This is more complex but allows camera angles. Only go this route if you're comfortable with 3D in Godot.

---

## Player Car Controls

```gdscript
# Basic arcade-style car controls
var max_speed: float = 200.0  # based on car's top_speed stat
var acceleration: float = 0.0  # based on car's accel stat
var handling: float = 0.0      # based on car's handling stat
var braking_power: float = 0.0 # based on car's braking stat

var speed: float = 0.0
var position_x: float = 0.0  # -1.0 (left edge) to 1.0 (right edge)

func _process(delta):
    # Acceleration
    if Input.is_action_pressed("accelerate"):
        speed = min(speed + acceleration * delta * 60, max_speed)
    elif Input.is_action_pressed("brake"):
        speed = max(speed - braking_power * delta * 60, 0)
    else:
        speed = max(speed - 0.5 * delta * 60, 0)  # natural deceleration

    # Steering (affected by handling stat)
    var steer = 0.0
    if Input.is_action_pressed("steer_left"):
        steer = -handling * 0.01
    elif Input.is_action_pressed("steer_right"):
        steer = handling * 0.01

    position_x += steer * (speed / max_speed) * delta * 60
    position_x = clamp(position_x, -1.2, 1.2)

    # Off-road penalty (slow down on grass)
    if abs(position_x) > 1.0:
        speed *= 0.97

    # Curve centrifugal force
    var current_segment = segments[int(player_position) % segments.size()]
    position_x += current_segment.curve * (speed / max_speed) * 0.02

    # Move forward
    player_position += speed * delta * 0.1
```

---

## Connecting to Car Selection Screen

When the player confirms their car on the selection screen, pass this data to the race scene:

```gdscript
# In your car selection screen, on confirm:
var race_data = {
    "driver": selected_car.driver,
    "car_name": selected_car.car,
    "hp": selected_car.hp,
    "handling": selected_car.handling,
    "accel": selected_car.accel,
    "braking": selected_car.braking,
    "top_speed": selected_car.topSpeed,
    "car_colors": selected_car.colors,
    "soundtrack": selected_soundtrack_path  # e.g. "res://audio/ZISO_-_White_Vacancy.mp3"
}

# Store globally (use an Autoload singleton)
GameData.race_data = race_data
get_tree().change_scene_to_file("res://scenes/race_9burgring.tscn")
```

---

## Input Map (set in Project → Project Settings → Input Map)

| Action | Keyboard | Gamepad |
|--------|----------|---------|
| accelerate | W / Up Arrow | Right Trigger |
| brake | S / Down Arrow | Left Trigger |
| steer_left | A / Left Arrow | Left Stick Left |
| steer_right | D / Right Arrow | Left Stick Right |

---

## Quick-Start Prompt for Claude Code

> Read the file `track_9burgring_reference.md` in this project. It contains the complete design for the 9burgring race track — a pseudo-3D Outrun-style course based on California's State Route 9 through the Santa Cruz Mountains. Build the race scene in Godot 4.x with: pseudo-3D road rendering using horizontal strips (classic Outrun technique), 4 stages with checkpoints (Santa Cruz → Felton → Boulder Creek → Saratoga Gap → Los Gatos), roadside pixel art scenery sprites per stage, parallax scrolling backgrounds that transition from coastal to redwoods to mountain summit to sunset valley, player car controls using car stats from the selection screen, a HUD with speed/timer/stage indicator, and the selected soundtrack playing during the race. Use the segment layout, color palettes, and GDScript pseudocode from the reference doc. Break the work into pieces — start with the road renderer, then add scenery, then controls, then HUD.
