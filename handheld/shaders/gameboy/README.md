Gameboy Shader v0.2.2
=======
This shader for RetroArch is intended to simulate the LCD screen of the original dot matrix Gameboy (DMG). It is still a work in progress, so there may be issues including limited compatibility among different GPU profiles. 

Instructions
--------------

In RetroArch's shader options, load the `gameboy_shader.glslp` file found in the `gameboy_shader/` directory.


Requirements
--------------

As of 0.9.9-wip1, the requisites for this shader to run properly are as follows:

+ `integer scaling` `disabled` under RetroArch's video settings (prevents the border from displaying properly)
+ the display window itself must be non-integer scaled in order for the border to display, for this you can:
 +  run RetroArch in fullscreen mode
 +  set RetroArch to run in windowed mode at a non-integer scale (ex. 5.5) under video settings
 +  drag the corner of the RetroArch window to increase its size an arbitrary amount

If you follow the above two restrictions and the shader still doesn't work, it's like a GPU incompatibility issue. These should be worked out in future commits.


Configuration options
--------------

There are configuration options throughout the .glsl files in the `gameboy_shader/shader_files/` directory that can be changed using any text editor to affect various visual effects. They can all be found under the "Config" header at the top of the files. Here's a list of configuration options and their default values:

+ `gameboy_shader/shader_files/gb_pass_0.glsl`
 
 +  `#define baseline_alpha 0.02 //the alpha value of dots in their "off" state, does not affect the border region of the screen - [0, 1]`
 +  `#define response_time 0.4 //simulate response time, higher values result in longer color transition periods - [0, 1]`
<br><br>
+ `gameboy_shader/shader_files/gb_pass_1.glsl`
 
 +  `#define blending_mode 0 //0 - only the space between dots is blending, 1 - all texels are blended`
 +  `#define adjacent_texel_alpha_blending 0.1255  //the amount of alpha swapped between neighboring texels`
<br><br>
+ `gameboy_shader/shader_files/gb_pass_4.glsl`
 
 +  `#define contrast 0.95 //analogous to the contrast slider on the original Gameboy, higher values darken the image - [0, 1]`
 +  `#define bg_smoothing 0.75 //higher values suppress changes in background color directly beneath the foreground to improve image clarity - [0, 1]`
 +  `#define shadow_opacity 0.65 //how strongly shadows affect the background, higher values darken the shadows - [0, 1]`
 +  `#define shadow_offset_x 1.0 //how far the shadow should be shifted to the right in pixels - [-infinity, infinity]`
 +  `#define shadow_offset_y 1.0 //how far the shadow should be shifted to down in pixels - [-infinity, infinity]`

Changing the palette and background images
--------------

You will find the files for the palette and background in the `gameboy_shader/resources/` directory. These files can be edited or replaced using any image editor as long as you keep the format the same and filetype intact.

+ Color palette
 + `gameboy_shader/resources/palette.png, 128x64`
 + Two horizontally aranged 64x64 squares filled in with the background color (left) and foreground color (right)
<br><br>
+ Background image
 + `gameboy_shader/resources/background.png, 2048x2048`<br>
 + The background will exactly equal the background color from the palette at 0.5 gray. Higher values in the background image will result in lighter colors while lower values will result in darker colors.

Issues
--------------

+ no known issues