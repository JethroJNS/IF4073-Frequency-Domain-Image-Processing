# F - Motion Blur Restoration

Parameter motion blur:
- astronaut_color_motion_L19_A20.png → length 19, angle 20°
- astronaut_color_motion_L19_A20_gaussian_noise.png → length 19, angle 20°, + Gaussian noise
- retina_color_motion_L15_A-25.png → length 15, angle -25°
- retina_color_motion_L15_A-25_gaussian_noise.png → length 15, angle -25°, + Gaussian noise
- coins_gray_motion_L23_A35.png → length 23, angle 35°
- brick_gray_motion_L17_A0.png → length 17, angle 0°

Gunakan parameter tersebut untuk membentuk PSF/fungsi degradasi untuk inverse
filtering dan Wiener filtering.
