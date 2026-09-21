DARK CAPED CREATURE — sprite pack (48x48 px frames)

Install: copy the "player" folder to res://sprites/player/ in your Godot 4 project.
Then set Project Settings > Rendering > Textures > Default Texture Filter = Nearest
(or the sprite node keeps texture_filter = Nearest, as in player.tscn).

Files
  player_sheet.png    all animations, one per row, 8 columns max, 48x48 cells
  player_frames.tres  SpriteFrames with every animation below already set up
  player.tscn         CharacterBody2D + AnimatedSprite2D + collision (feet on origin)
  frames/<anim>/      every frame as a separate PNG

Animations (name | frames | fps | loop)
  idle_right         4   5  loop
  idle_left          4   5  loop
  walk_right         6   9  loop
  walk_left          6   9  loop
  run_right          8  14  loop
  run_left           8  14  loop
  jump_right         3  10  once
  jump_left          3  10  once
  fall_right         2   8  loop
  fall_left          2   8  loop
  land_right         3  14  once
  land_left          3  14  once
  crouch_right       2   8  once
  crouch_left        2   8  once
  dash_right         2  14  loop
  dash_left          2  14  loop
  wall_slide_right   2   8  loop
  wall_slide_left    2   8  loop
  hurt_right         2  10  once
  hurt_left          2  10  once
  death_right        5   8  once
  death_left         5   8  once
  idle_front         4   5  loop
  idle_back          2   3  loop
  climb              4   8  loop

Left-facing animations are pixel-exact mirrors of the right-facing ones.
If you prefer, use only the *_right animations and set AnimatedSprite2D.flip_h = true when facing left.
Frame size 48x48, the feet touch the bottom edge (row 43); the sprite is centred horizontally.
