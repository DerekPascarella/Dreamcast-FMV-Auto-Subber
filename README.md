# Dreamcast FMV Auto-Subber
A utility to batch re-encode Dreamcast SFD videos with baked-in subtitles.

It is designed to accept original SFD video files and accompanying SRT subtitle files as input. It will produce re-encoded SFD video files with the provided subtitles baked into them as output.

Dreamcast FMV Auto-Subber is capable of intelligently detecting both resolutions found in Dreamcast SFD video files (320x224 and 320x448). It will scale subtitle text accordingly to ensure that it's proportional.

## Current Version
Dreamcast FMV Auto-Subber is currently at version [1.0](https://github.com/DerekPascarella/Saturn-15bpp-Graphics-Converter/releases/download/1.0/Saturn.15bpp.Graphics.Converter.v1.0.zip).

## Changelog
- **Version 1.0 (2024-09-27)**
    - Initial release

## INI Configuration Options
| Key              | Description                                                                             | Example Value        |
|------------------|-----------------------------------------------------------------------------------------|----------------------|
| `font_face`      | Specifies the font family to use for subtitles. Note that this must be the full name of a valid font installed on the system running this program.                                          | `Arial`              |
| `font_bold`      | Enables or disables bold text for subtitles. Accepts `yes` or `no`.                      | `yes`                |
| `font_size`      | Defines the size of the subtitle font in points.                                         | `16`                 |
| `outline_color`  | Sets the color of the subtitle outline using a hex color code (in BGR format).           | `000000` (black)     |
| `outline_strength`| Determines the thickness of the subtitle outline. A higher number creates a thicker outline. | `2`                  |
| `margin_vertical`| Adjusts the vertical margin between the bottom of the screen and the subtitles.          | `30`                 |
| `margin_left`    | Adjusts the left margin between the subtitles and the left edge of the screen.           | `25`                 |
| `margin_right`   | Adjusts the right margin between the subtitles and the right edge of the screen.         | `25`                 |
| `bitrate`        | Specifies the video bitrate in bits per second. Controls the output video quality.       | `1250000`            |

## Usage
The following folder structure will be created after extracting the release package.
```
.
├── autosubber.exe
├── config.ini
├── helper_utilities
│   ├── adxencd.exe
│   ├── demux.exe
│   ├── ffmpeg.exe
│   ├── ffprobe.exe
│   ├── legaladx.exe
│   ├── Sfdmux.dll
│   └── sfdmux.exe
├── input
└── output
```
Original SFD video files should be placed in the `input` folder, along with their accompanying SRT subtitle files. Note that Dreamcast FMV Auto-Subber expects the base file name for both the SFD and SRT files to be identical. For example, a video named `INTRO.SFD` should have a subtitle file named `INTRO.SRT`.

Once all original SFD video files and their accompanying SRT subtitle files are placed in the `input` folder, `autosubber.exe` can be launched. The program will display status updates as it performs the re-encoding of each video file.

Once complete, all new SFD video files will be placed in the `output` folder, ready for use.

## Example Output
```
Dreamcast FMV Auto-Subber 1.0
A utility to batch re-encode Dreamcast SFD videos with baked-in subtitles.

Written by Derek Pascarella (ateam)

2 videos found in "input" folder.

-> G1AEBSRQ.SFD
   - Constructing ffmpeg command...
   - Demuxing original SFD...
   - Converting audio stream to WAV...
   - Converting WAV to SFA...
   - Encoding new video with subtitles...
   - Re-muxing new video with original audio stream...
   - Moving new SFD to "output" folder...
-> G1DKWZXF.SFD
   - Constructing ffmpeg command...
   - Demuxing original SFD...
   - Converting audio stream to WAV...
   - Converting WAV to SFA...
   - Encoding new video with subtitles...
   - Re-muxing new video with original audio stream...
   - Moving new SFD to "output" folder...

Process complete!

Press Enter to exit.
```