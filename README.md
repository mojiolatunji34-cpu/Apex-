# Apex Racing

Android-first 3D racing simulator prototype built with Godot 4 and the GL Compatibility renderer.

## Implemented prototype systems

- Procedurally generated rectangular test circuit, barriers and start/finish marking.
- Player vehicle with rigid-body chassis, four suspension raycasts and spring/damper forces.
- Per-wheel tyre lateral grip and rear-wheel drive forces, with braking and handbrake grip changes.
- Animated wheel meshes positioned from suspension ray hits.
- Smooth chase camera and touchscreen steering/pedals.
- Three-lap race session with a 3-2-1 start countdown, ordered checkpoints, race timer and best-lap display.
- Pause/resume, race completion panel and full race restart including AI rivals.
- Basic brake-light feedback, headlamp visuals and high-contrast track edge kerbs.
- Six-speed automatic gear/RPM simulation with live cockpit-style HUD readouts.
- Procedurally synthesized spatial engine sound for player and AI vehicles, with pitch and volume responding to RPM and throttle.
- Handbrake-triggered tyre smoke particle effect while sliding at speed.
- Collision damage model with impact thresholds, reduced engine output, visual paint wear and repair on vehicle reset.
- Lightweight procedural trackside trees and spectator grandstand scenery.
- Automated headless runtime smoke test for scene startup, player/rival spawning, HUD wiring and race restart.
- Two waypoint-following AI rival cars with adjustable cruise speeds.
- Vehicle reset button and keyboard controls for desktop testing.

## Open the project

1. Install Godot 4.3 or a compatible Godot 4.x Android editor.
2. Download this repository as a ZIP and extract it.
3. In Godot, choose **Import**, then select the extracted `project.godot`.
4. Open the project and run the main scene.

## Controls

| Action | Touchscreen | Keyboard |
|---|---|---|
| Accelerate | ACCEL | W / Up |
| Brake | BRAKE | Space |
| Reverse | REVERSE | S / Down |
| Steer | Left / Right | A,D / arrows |
| Handbrake | HANDBRAKE | Shift |
| Recover | RESET CAR | — |

## Development status

The four wheel assemblies now have raycast-based suspension and approximate tyre forces, but this is still an early physics model that needs tuning in a running game. It is not a validated professional vehicle simulator. Race timing and checkpoint logic are prototype systems. The AI and vehicle handling still need live playtesting and tuning. Multiple finished tracks and cars, engine/tyre audio, damage, garage, upgrades and production assets remain future work. The automatic gearbox and RPM display are gameplay approximations, not a detailed drivetrain simulation.
