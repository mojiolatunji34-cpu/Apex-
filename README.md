# Apex Racing

An Android-first 3D racing simulator project built with Godot 4 and the GL Compatibility renderer.

## Current prototype systems

- Procedurally built test circuit with collision barriers and start/finish marking.
- Player vehicle with rigid-body movement, forward/reverse drive, braking, steering and handbrake.
- Approximate lateral tyre-grip forces and speed-dependent downforce.
- Rotating wheel visuals (visual animation only; not individual simulated wheel assemblies).
- Smooth chase camera.
- Touchscreen steering, accelerator, brake and handbrake controls.
- Keyboard controls for desktop testing.

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
| Steer | Left / Right | A,D / arrows |
| Handbrake | HANDBRAKE | Shift |
| Reverse | Reverse input | S / Down |

## Important development status

This is an early playable prototype, not a finished simulator. The current vehicle uses a single rigid body and approximate grip forces. The wheel meshes rotate for appearance but do not yet have independent suspension, tyre contact patches, tyre temperatures or per-wheel physics. There are no AI opponents, race timing, damage, audio, garage, career or finished production car/track assets yet.

## Planned milestones

1. Validate project import and runtime on a real Android device.
2. Implement and tune four-wheel raycast suspension and tyre forces.
3. Add race session flow, checkpoints, lap timing and reset/recovery.
4. Add AI opponents and opponent behaviour.
5. Add audio, vehicle setup, garage and track presentation.
6. Profile and optimise for target Android devices.
