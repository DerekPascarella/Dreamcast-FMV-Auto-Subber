# Dreamcast FMV Auto-Subber
A utility to batch re-encode Dreamcast SFD videos with baked-in subtitles.

It is designed to accept original SFD video files and accompanying SRT or ASS subtitle files as input. It will produce re-encoded SFD video files with the provided subtitles baked into them as output.

Dreamcast FMV Auto-Subber intelligently detects the source video's dimensions to properly scale the subtitles according to value of `aspect_ratio` set in the configuration INI. This is necessary due to many SFDs being encoded in a variety of dimensions and then scaled to a number of different aspect ratios when played back during the game. This process also ensures that the dimensions of the newly encoded SFD with subtitles matches those of the original source video.

When using ASS format, users must set font style and subtitle text placement settings using their tool of choice (e.g., Aegisub). This includes `font_face`, `font_size`, `outline_color`, `margin_vertical`, etc., all of which are to be defined in the ASS subtitle file itself.

See the [INI Configuration Options](#ini-configuration-options) section for details on which parameters only apply to SRT subtitle format.

Note that there is presently only support for SFDs that contain both an audio and video stream. However, there are plans to handle less common video-only SFDs in a future release.

## Current Version
Dreamcast FMV Auto-Subber is currently at version [1.6](https://github.com/DerekPascarella/Dreamcast-FMV-Auto-Subber/releases/download/1.6/Dreamcast.FMV.Auto-Subber.v1.6.zip).

## Changelog
- **Version 1.6 (2025-03-30)**
    - Added support for automatic subtitle scaling by aspect ratio when using the ASS format.
- **Version 1.5 (2025-03-30)**
    - Added ASS subtitle format support.
- **Version 1.4 (2025-03-24)**
    - Added `aspect_ratio` configuration option to manually define target aspect ratio at which video will be rendered by game software, which is used to calculate horizontal scaling of subtitles (was previously locked to `4:3`).
- **Version 1.3 (2025-01-14)**
    - Added error-handling when attempting to process SFDs with no audio stream.
    - Rewrote video dimension detection and scaling logic to intelligently account for videos of any resolution.
- **Version 1.2 (2024-11-01)**
    - Fixed bug where `font_face`, `font_color`, and `outline_color` configuration options could be erroneously flagged as invalid.
- **Version 1.1 (2024-10-01)**
    - Added option for custom subtitle text color.
    - Fixed bug preventing use of non-integer outline color value (e.g., `000000` was permitted but not `FFFFFF`).
    - Eliminated use of `ffprobe` to query video dimensions (now using `ffmpeg`).
- **Version 1.0 (2024-09-27)**
    - Initial release.

## INI Configuration Options
| Key              | Description                                                                             | Example Value(s)        |
|------------------|-----------------------------------------------------------------------------------------|----------------------|
| `aspect_ratio`   | Defines target aspect ratio at which video will be rendered by game software, used to calculate horizontal scaling of subtitles.| `4:3`, `5:4`, `3:2`, `16:9` |
| `font_face`      | Specifies the font family to use for subtitles. Note that this must be the full name of a valid font installed on the system running this program. Only applicable to SRT subtitle format.                                          | `Arial`              |
| `font_bold`      | Enables or disables bold text for subtitles. Accepts `yes` or `no`. Only applicable to SRT subtitle format.                     | `yes`                |
| `font_size`      | Defines the size of the subtitle font in points. Only applicable to SRT subtitle format.                                        | `16`                 |
| `font_color`  | Sets the color of the subtitle text using a hex color code (in BGR format). Only applicable to SRT subtitle format.          | `FFFFFF` (white)     |
| `outline_color`  | Sets the color of the subtitle outline using a hex color code (in BGR format). Only applicable to SRT subtitle format.          | `000000` (black)     |
| `outline_strength`| Determines the thickness of the subtitle outline. A higher number creates a thicker outline. Only applicable to SRT subtitle format.| `2`                  |
| `margin_vertical`| Adjusts the vertical margin between the bottom of the screen and the subtitles. Only applicable to SRT subtitle format.         | `30`                 |
| `margin_left`    | Adjusts the left margin between the subtitles and the left edge of the screen. Only applicable to SRT subtitle format.          | `25`                 |
| `margin_right`   | Adjusts the right margin between the subtitles and the right edge of the screen. Only applicable to SRT subtitle format.        | `25`                 |
| `bitrate`        | Specifies the video bitrate in bits per second. Controls the output video quality.       | `1250000` (good for CDIs), `3600000` (good for GDIs), but between 400-800 KB/s is SEGA's recommendation.|

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
![Example Output](https://raw.githubusercontent.com/DerekPascarella/Dreamcast-FMV-Auto-Subber/refs/heads/main/example_output.png)
