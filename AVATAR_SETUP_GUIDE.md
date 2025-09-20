# Avatar Setup Guide

This guide explains how to set up the avatar images for the profile screen.

## Avatar Files Required

You need to place 8 JPG images in the `assets/avatars/` directory:

1. `avatar_1.jpg` - Casual Young Man
2. `avatar_2.jpg` - Modern Woman  
3. `avatar_3.jpg` - Business Professional
4. `avatar_4.jpg` - Casual Young Man
5. `avatar_5.jpg` - Teen Girl
6. `avatar_6.jpg` - Senior Man
7. `avatar_7.jpg` - Student
8. `avatar_8.jpg` - Professional Woman

## File Format Requirements

- **Format**: JPG (JPEG) format only
- **Size**: Recommended 150x150 pixels or larger
- **Quality**: Good quality images for clear display
- **Background**: Preferably with transparent or neutral backgrounds

## Converting from PNG to JPG

If you have PNG images, convert them to JPG format:

1. Use any image editing software (Photoshop, GIMP, etc.)
2. Open the PNG file
3. Export/Save As JPG format
4. Choose quality setting (80-95% recommended)
5. Save with the correct filename (avatar_1.jpg, avatar_2.jpg, etc.)

## File Placement

1. Navigate to your project directory
2. Go to `assets/avatars/` folder
3. Replace the placeholder files with your actual JPG images
4. Ensure filenames match exactly: `avatar_1.jpg` through `avatar_8.jpg`

## Testing

After placing the images:
1. Run `flutter clean`
2. Run `flutter pub get`
3. Build and test the app
4. Navigate to Profile screen
5. Tap on the avatar to open selection screen
6. Verify all 8 avatars display correctly

## Troubleshooting

- **Images not showing**: Ensure files are JPG format and placed in correct directory
- **App not updating**: Run `flutter clean` and rebuild
- **File size issues**: Compress images if they're too large (keep under 1MB each)
- **Quality issues**: Use higher resolution source images
