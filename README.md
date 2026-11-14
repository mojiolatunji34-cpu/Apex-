# Apex Racing

Android-first 3D racing simulation prototype built with Godot 4.

## Current prototype

- Procedurally created red player car with collision and rigid-body physics.
- Acceleration, reverse, braking, steering torque and lateral tyre-grip approximation.
- Chase camera.
- Simple closed rectangular practice circuit with collision barriers.
- On-screen touch controls and speed readout.
- Keyboard controls for editor testing.

## Open on Android

1. Install the official Godot Android editor: https://godotengine.org/download/android/
2. Download this repository as a ZIP from GitHub, then extract it on your phone.
3. In Godot, choose **Import** and select the extracted `project.godot`.
4. Open the project and press **Run Project**.

## Controls

Touch:
- ◀ / ▶: steer
- ACCEL: accelerate
- BRAKE: brake

Keyboard:
- W / Up: accelerate
- S / Down: reverse
- A / Left and D / Right: steer
- Space: brake

## Important

This is the first playable foundation, not a finished realistic simulator. The current track and vehicle visuals are generated from primitives. Suspension travel, individual wheel contact, tyre temperature, gear ratios, damage, AI opponents, race rules, sound, and detailed 3D assets are planned for later milestones. Test on the target phone before increasing graphics quality.
