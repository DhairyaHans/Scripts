# screenshot-lock-screen.sh

A Bash script for creating a **dynamic GNOME lockscreen wallpaper from a full desktop screenshot**.

The script is designed for Ubuntu/GNOME multi-monitor setups where the normal desktop wallpaper remains unchanged while the lockscreen displays a screenshot of the current desktop.

The script uses the **GNOME Lockscreen Extension** to control the unlock-dialog background.

---

# 1. Features

The script:

1. Captures the entire desktop.
2. Detects all active monitors.
3. Detects each monitor's resolution and position.
4. Crops the full screenshot into one image per monitor.
5. Configures the GNOME Lockscreen Extension with those images.
6. Disables use of the normal desktop wallpaper for the lockscreen.
7. Disables lockscreen blur.
8. Preserves monitor X/Y offsets.
9. Supports up to four monitors.
10. Leaves the normal desktop wallpaper unchanged.
11. Creates timestamped logs.
12. Supports different monitor-order mappings without modifying the script.

---

# 2. How It Works

The intended behavior is:

```text
Desktop
│
└── Normal desktop wallpaper
        │
        └── unchanged


Lockscreen
│
└── Screenshot of current desktop
        │
        ├── Monitor 1 screenshot
        ├── Monitor 2 screenshot
        ├── Monitor 3 screenshot
        └── Monitor 4 screenshot
```

The script first captures the complete X11 desktop.

It then uses `xrandr` to determine the position and resolution of every active monitor.

Each monitor is cropped from the full screenshot and assigned to the corresponding monitor configuration in the GNOME Lockscreen Extension.

---

# 3. Requirements

The current implementation requires:

* Ubuntu or another Linux distribution with GNOME Shell
* GNOME Shell
* X11 session
* `gnome-screenshot`
* `xrandr`
* `gsettings`
* ImageMagick
* GNOME Lockscreen Extension

The current implementation is **not designed for Wayland**.

Check the session type:

```bash
echo "$XDG_SESSION_TYPE"
```

Expected:

```text
x11
```

Check GNOME:

```bash
gnome-shell --version
```

Example:

```text
GNOME Shell 46.0
```

---

# 4. Install Dependencies

On Ubuntu:

```bash
sudo apt update
sudo apt install gnome-screenshot imagemagick x11-xserver-utils
```

These packages provide:

```text
gnome-screenshot
    Desktop screenshot capture

imagemagick
    Image cropping and processing

x11-xserver-utils
    xrandr
```

`gsettings` is provided by the GNOME/GLib environment.

Verify the dependencies:

```bash
command -v gnome-screenshot
command -v xrandr
command -v gsettings
```

Verify ImageMagick:

```bash
command -v magick
```

If `magick` is unavailable, check:

```bash
command -v convert
```

The script supports both the modern ImageMagick command:

```text
magick
```

and the older:

```text
convert
```

---

# 5. Install the GNOME Lockscreen Extension

The script requires the **Lockscreen Extension** by Pratap Panabaka.

GNOME Extensions:

https://extensions.gnome.org/extension/7472/lockscreen-extension/

GitHub:

https://github.com/pratap-panabaka/gse-lockscreen-extension

Install the extension using the GNOME Extensions website.

Then verify:

```bash
gnome-extensions list | grep -i lock
```

Expected:

```text
lockscreen-extension@pratap.fastmail.fm
```

Enable it:

```bash
gnome-extensions enable lockscreen-extension@pratap.fastmail.fm
```

Verify:

```bash
gnome-extensions info lockscreen-extension@pratap.fastmail.fm
```

When the desktop is unlocked, the extension may report:

```text
Enabled: Yes
State: INACTIVE
```

This is expected for this extension because it operates during GNOME's `unlock-dialog` session mode.

---

# 6. Extension Schema

The extension's local GSettings schema is normally located at:

```text
~/.local/share/gnome-shell/extensions/lockscreen-extension@pratap.fastmail.fm/schemas/
```

The schema ID is:

```text
org.gnome.shell.extensions.lockscreen-extension
```

Because this schema is provided by the extension rather than installed globally, the script accesses it using:

```bash
gsettings --schemadir
```

You can inspect the schema with:

```bash
SCHEMA_DIR="$HOME/.local/share/gnome-shell/extensions/lockscreen-extension@pratap.fastmail.fm/schemas"

gsettings \
    --schemadir "$SCHEMA_DIR" \
    list-recursively \
    org.gnome.shell.extensions.lockscreen-extension
```

---

# 7. Extension Settings Used by the Script

The extension provides monitor-specific settings.

For example:

```text
user-background-1
background-image-path-1
background-size-1
blur-radius-1
```

and:

```text
user-background-2
background-image-path-2
background-size-2
blur-radius-2
```

up to monitor 4.

The script uses:

```text
user-background-N
background-image-path-N
background-size-N
blur-radius-N
```

---

# 8. `user-background-N`

This setting determines whether the extension uses the normal desktop wallpaper.

If:

```text
true
```

the extension uses the desktop background.

If:

```text
false
```

the extension uses:

```text
background-image-path-N
```

The script sets:

```text
user-background-N = false
```

for every detected monitor.

This keeps the desktop wallpaper and lockscreen wallpaper independent.

---

# 9. `background-image-path-N`

This setting specifies the image used for a lockscreen monitor.

Example:

```text
file:///home/user/Pictures/Screenshots/wallpapers/lockscreen-HDMI-1-20260916-153000.png
```

The script automatically generates and configures these paths.

---

# 10. `background-size-N`

The script sets:

```text
background-size-N = cover
```

Each generated image already has the exact resolution of its corresponding monitor, so the image normally fills the monitor widget correctly.

---

# 11. Blur

The extension supports a GNOME Shell blur effect.

The script explicitly sets:

```text
blur-radius-N = 0
```

which disables the blur effect.

---

# 12. Monitor Limit

The Lockscreen Extension provides four monitor-specific configurations.

Therefore the script supports:

```text
Monitor 1
Monitor 2
Monitor 3
Monitor 4
```

If more than four monitors are detected, the script exits with an error.

The limit can be configured through:

```bash
MAX_MONITORS
```

For example:

```bash
MAX_MONITORS=4 ./screenshot-lock-screen.sh
```

The extension itself must still provide enough monitor configuration keys for the requested number of monitors.

---

# 13. Monitor Ordering

This is an important implementation detail.

The script obtains monitor geometry using:

```bash
xrandr --listactivemonitors
```

The GNOME Lockscreen Extension obtains monitors internally through GNOME Shell's monitor layout.

These two monitor orders are **not guaranteed to be identical**.

For example, `xrandr` may report:

```text
0: eDP-1
1: HDMI-1
```

while GNOME Shell may internally use:

```text
0: HDMI-1
1: eDP-1
```

If these orders are different, the screenshots would appear on the wrong monitors.

To handle this, the script supports:

```bash
MONITOR_ORDER=normal
```

and:

```bash
MONITOR_ORDER=reverse
```

The default is:

```bash
MONITOR_ORDER=reverse
```

This matches configurations where GNOME's monitor order is the reverse of the `xrandr` order.

### Default

```bash
./screenshot-lock-screen.sh
```

is equivalent to:

```bash
MONITOR_ORDER=reverse ./screenshot-lock-screen.sh
```

### Use normal order

If the screenshots appear on the wrong monitors, test:

```bash
MONITOR_ORDER=normal ./screenshot-lock-screen.sh
```

The script prints the mapping it is using:

```text
Monitor mapping:
  Monitor order mode: reverse
  xrandr monitor 0 (eDP-1) -> extension setting 2
  xrandr monitor 1 (HDMI-1) -> extension setting 1
```

This makes the mapping visible in the log.

---

# 14. Monitor Detection

The script uses:

```bash
xrandr --listactivemonitors
```

Example:

```text
Monitors: 2
0: +*eDP-1 1920/310x1080/170+1920+238  eDP-1
1: +HDMI-1 1920/530x1080/300+0+0  HDMI-1
```

The script extracts:

```text
Monitor       Resolution       Position

eDP-1         1920x1080        +1920+238
HDMI-1        1920x1080        +0+0
```

The physical dimensions:

```text
1920/310x1080/170
```

are ignored.

Only:

```text
width
height
x
y
```

are required.

---

# 15. Virtual Desktop Geometry

The script calculates:

```text
MIN_X
MIN_Y
MAX_X
MAX_Y
```

from the monitor positions.

For example:

```text
HDMI-1: 1920x1080 +0+0
eDP-1:  1920x1080 +1920+238
```

the virtual desktop bounds are:

```text
MIN_X = 0
MIN_Y = 0
MAX_X = 3840
MAX_Y = 1318
```

Therefore:

```text
Virtual desktop = 3840x1318
```

---

# 16. Monitor Position Matters

Monitors do not necessarily form a perfectly aligned rectangle.

For example:

```text
┌──────────────────┬──────────────────┐
│                  │                  │
│     HDMI-1       │                  │
│    1920x1080     │     eDP-1        │
│                  │    1920x1080     │
│                  │        +238      │
└──────────────────┴──────────────────┘
```

The second monitor starts 238 pixels lower.

Therefore the script does not simply split the screenshot into equal halves.

Instead it calculates:

```text
CROP_X = monitor_x - MIN_X
CROP_Y = monitor_y - MIN_Y
```

This extracts the exact pixels belonging to each monitor.

---

# 17. Per-Monitor Output

For each monitor, the script creates:

```text
lockscreen-<monitor-name>-<timestamp>.png
```

For example:

```text
lockscreen-HDMI-1-20260916-153000.png
lockscreen-eDP-1-20260916-153000.png
```

Each image has the exact resolution of its monitor.

---

# 18. Why One Composite Image Is Not Used

The Lockscreen Extension creates a separate background widget for each monitor.

Conceptually:

```javascript
let monitor = Main.layoutManager.monitors[monitorIndex];

let widget = new St.Widget({
    x: monitor.x,
    y: monitor.y,
    width: monitor.width,
    height: monitor.height,
});
```

Therefore, assigning one complete virtual-desktop image to every monitor widget would cause the entire composite image to be rendered inside each monitor's widget.

Instead, the script generates:

```text
Monitor 1 resolution → Monitor 1 image
Monitor 2 resolution → Monitor 2 image
Monitor 3 resolution → Monitor 3 image
Monitor 4 resolution → Monitor 4 image
```

This preserves the original desktop content for each monitor.

---

# 19. Desktop Wallpaper Is Not Modified

The script does **not** modify:

```text
org.gnome.desktop.background.picture-uri
```

You can check the desktop wallpaper with:

```bash
gsettings get org.gnome.desktop.background picture-uri
```

The value should remain unchanged after running the script.

The script only modifies:

```text
org.gnome.shell.extensions.lockscreen-extension
```

---

# 20. GNOME Screensaver Settings

The script does not use:

```text
org.gnome.desktop.screensaver.picture-uri
```

or:

```text
org.gnome.desktop.screensaver.picture-options
```

The lockscreen background is controlled by the Lockscreen Extension instead.

---

# 21. Installation

Clone the repository:

```bash
git clone <repository-url>
cd <repository-directory>
```

Make the script executable:

```bash
chmod +x screenshot-lock-screen.sh
```

Optionally install it into `~/bin`:

```bash
mkdir -p "$HOME/bin"

cp screenshot-lock-screen.sh "$HOME/bin/screenshot-lock-screen.sh"

chmod +x "$HOME/bin/screenshot-lock-screen.sh"
```

---

# 22. Running the Script

Run with the default output directory:

```bash
~/bin/screenshot-lock-screen.sh
```

The default output directory is:

```text
~/Pictures/Screenshots/wallpapers
```

You can specify a different output directory:

```bash
~/bin/screenshot-lock-screen.sh /tmp/lockscreen
```

or:

```bash
OUTPUT_DIR=/tmp/lockscreen ~/bin/screenshot-lock-screen.sh
```

---

# 23. Monitor Order Configuration

Use the default configuration:

```bash
~/bin/screenshot-lock-screen.sh
```

This uses:

```text
MONITOR_ORDER=reverse
```

To use normal `xrandr` ordering:

```bash
MONITOR_ORDER=normal ~/bin/screenshot-lock-screen.sh
```

This setting is useful because monitor ordering between `xrandr` and GNOME Shell is not guaranteed to be identical across hardware/configurations.

---

# 24. Output Files

A successful run produces files similar to:

```text
~/Pictures/Screenshots/wallpapers/

├── lockscreen-HDMI-1-20260916-153000.png
├── lockscreen-eDP-1-20260916-153000.png
└── lock-20260916-153000.log
```

The temporary full-screen screenshot:

```text
.full-screen-YYYYMMDD-HHMMSS.png
```

is automatically deleted after processing.

---

# 25. Logs

Every execution creates a timestamped log:

```text
lock-YYYYMMDD-HHMMSS.log
```

Example:

```text
lock-20260916-153000.log
```

The script redirects its output to the log:

```bash
exec >> "$LOG_FILE" 2>&1
```

This includes:

* detected monitors
* monitor geometry
* monitor mapping
* generated images
* extension settings
* errors

View the latest logs with:

```bash
ls -t ~/Pictures/Screenshots/wallpapers/lock-*.log | head
```

Then:

```bash
cat ~/Pictures/Screenshots/wallpapers/lock-YYYYMMDD-HHMMSS.log
```

---

# 26. Locking the Session

The screenshot script intentionally only prepares the lockscreen.

To lock the session:

```bash
loginctl lock-session
```

Keeping these operations separate makes the screenshot script reusable.

A wrapper can be used to take the screenshot and then lock the session:

```bash
#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$SCRIPT_DIR/screenshot-lock-screen.sh"

loginctl lock-session
```

For example, save this as:

```text
~/bin/lock-screen.sh
```

Make it executable:

```bash
chmod +x ~/bin/lock-screen.sh
```

---

# 27. Using Win + L

GNOME can be configured to execute the wrapper script when pressing `Super + L`.

The custom shortcut command should point to:

```text
/home/<username>/bin/lock-screen.sh
```

A more portable command is:

```text
$HOME/bin/lock-screen.sh
```

if the desktop environment expands `$HOME` for custom shortcuts. Otherwise use the absolute path to the user's home directory.

The resulting flow is:

```text
Super + L
    │
    ▼
lock-screen.sh
    │
    ▼
screenshot-lock-screen.sh
    │
    ├── capture desktop
    ├── detect monitors
    ├── crop monitor images
    └── configure extension
    │
    ▼
loginctl lock-session
    │
    ▼
GNOME lockscreen
```

---

# 28. Verify Extension Configuration

Set:

```bash
SCHEMA_DIR="$HOME/.local/share/gnome-shell/extensions/lockscreen-extension@pratap.fastmail.fm/schemas"
```

Inspect all settings:

```bash
gsettings \
    --schemadir "$SCHEMA_DIR" \
    list-recursively \
    org.gnome.shell.extensions.lockscreen-extension
```

Check an individual monitor:

```bash
gsettings \
    --schemadir "$SCHEMA_DIR" \
    get \
    org.gnome.shell.extensions.lockscreen-extension \
    user-background-1
```

Check its image:

```bash
gsettings \
    --schemadir "$SCHEMA_DIR" \
    get \
    org.gnome.shell.extensions.lockscreen-extension \
    background-image-path-1
```

Expected:

```text
false
```

and:

```text
'file:///home/<username>/Pictures/Screenshots/wallpapers/lockscreen-...png'
```

---

# 29. Verify Generated Images

Use ImageMagick:

```bash
identify ~/Pictures/Screenshots/wallpapers/lockscreen-*.png
```

Example:

```text
lockscreen-HDMI-1-20260916-153000.png PNG 1920x1080
lockscreen-eDP-1-20260916-153000.png PNG 1920x1080
```

The generated dimensions should match the corresponding monitor resolutions.

---

# 30. Verify Monitor Geometry

Run:

```bash
xrandr --listactivemonitors
```

This is useful when diagnosing incorrect crops or monitor mapping.

---

# 31. Verify Desktop Wallpaper

Run:

```bash
gsettings get org.gnome.desktop.background picture-uri
```

The value should remain unchanged after running the script.

If it changes, another application, extension, or script is modifying the desktop wallpaper.

---

# 32. Troubleshooting

## Lock screen still shows the desktop wallpaper

Check:

```bash
SCHEMA_DIR="$HOME/.local/share/gnome-shell/extensions/lockscreen-extension@pratap.fastmail.fm/schemas"

gsettings \
    --schemadir "$SCHEMA_DIR" \
    get \
    org.gnome.shell.extensions.lockscreen-extension \
    user-background-1
```

It should be:

```text
false
```

Then check:

```bash
gsettings \
    --schemadir "$SCHEMA_DIR" \
    get \
    org.gnome.shell.extensions.lockscreen-extension \
    background-image-path-1
```

Make sure the referenced file exists.

---

## Wrong monitor image

First check:

```bash
xrandr --listactivemonitors
```

Then try:

```bash
MONITOR_ORDER=normal ~/bin/screenshot-lock-screen.sh
```

If that produces the correct mapping, use:

```bash
MONITOR_ORDER=normal
```

for that system.

If the default reverse mapping is correct, simply use:

```bash
MONITOR_ORDER=reverse
```

The script prints the actual mapping it uses, for example:

```text
Monitor mapping:
  Monitor order mode: reverse
  xrandr monitor 0 (eDP-1) -> extension setting 2
  xrandr monitor 1 (HDMI-1) -> extension setting 1
```

---

## Wrong crop

Check:

```bash
xrandr --listactivemonitors
```

For:

```text
1920x1080+1920+238
```

the script should calculate:

```text
CROP_X = 1920
CROP_Y = 238
```

The script dynamically calculates these values and does not use hardcoded monitor dimensions.

---

## Extension reports `INACTIVE`

Run:

```bash
gnome-extensions info lockscreen-extension@pratap.fastmail.fm
```

If it says:

```text
Enabled: Yes
State: INACTIVE
```

while the desktop is unlocked, this can be expected for this extension.

Test the lockscreen:

```bash
loginctl lock-session
```

---

## ImageMagick unavailable

Check:

```bash
command -v magick
command -v convert
```

Install:

```bash
sudo apt install imagemagick
```

---

## `gnome-screenshot` unavailable

Check:

```bash
command -v gnome-screenshot
```

Install:

```bash
sudo apt install gnome-screenshot
```

---

## `xrandr` unavailable

Check:

```bash
command -v xrandr
```

Install:

```bash
sudo apt install x11-xserver-utils
```

---

## Lockscreen Extension schema not found

Check:

```bash
ls "$HOME/.local/share/gnome-shell/extensions/lockscreen-extension@pratap.fastmail.fm/schemas"
```

If the directory does not exist, install the Lockscreen Extension.

The script also supports overriding the schema location:

```bash
EXTENSION_SCHEMA_DIR=/path/to/schemas \
    ~/bin/screenshot-lock-screen.sh
```

---

# 33. X11 Requirement

The current implementation uses:

```bash
xrandr --listactivemonitors
```

and:

```bash
gnome-screenshot
```

and is therefore designed for an **X11 GNOME session**.

Check:

```bash
echo "$XDG_SESSION_TYPE"
```

Expected:

```text
x11
```

If the result is:

```text
wayland
```

this implementation is not guaranteed to work.

---

# 34. Configuration Variables

The script supports the following environment variables.

## `OUTPUT_DIR`

Default:

```text
$HOME/Pictures/Screenshots/wallpapers
```

Example:

```bash
OUTPUT_DIR=/tmp/lockscreen ./screenshot-lock-screen.sh
```

## `EXTENSION_ID`

Default:

```text
lockscreen-extension@pratap.fastmail.fm
```

## `EXTENSION_SCHEMA`

Default:

```text
org.gnome.shell.extensions.lockscreen-extension
```

## `EXTENSION_SCHEMA_DIR`

Default:

```text
$HOME/.local/share/gnome-shell/extensions/lockscreen-extension@pratap.fastmail.fm/schemas
```

## `MAX_MONITORS`

Default:

```text
4
```

Example:

```bash
MAX_MONITORS=4 ./screenshot-lock-screen.sh
```

## `MONITOR_ORDER`

Default:

```text
reverse
```

Supported values:

```text
normal
reverse
```

Example:

```bash
MONITOR_ORDER=normal ./screenshot-lock-screen.sh
```

---

# 35. Manual Extension Configuration

If required, the extension can be configured manually.

Set:

```bash
SCHEMA_DIR="$HOME/.local/share/gnome-shell/extensions/lockscreen-extension@pratap.fastmail.fm/schemas"

SCHEMA="org.gnome.shell.extensions.lockscreen-extension"
```

Disable desktop wallpaper for monitor 1:

```bash
gsettings \
    --schemadir "$SCHEMA_DIR" \
    set "$SCHEMA" \
    user-background-1 \
    false
```

Set an image:

```bash
gsettings \
    --schemadir "$SCHEMA_DIR" \
    set "$SCHEMA" \
    background-image-path-1 \
    "file:///home/<username>/Pictures/example.png"
```

Disable blur:

```bash
gsettings \
    --schemadir "$SCHEMA_DIR" \
    set "$SCHEMA" \
    blur-radius-1 \
    0
```

---

# 36. Design Decisions

The script intentionally:

* Does not modify the desktop wallpaper.
* Does not use `org.gnome.desktop.screensaver.picture-uri`.
* Does not depend on GNOME's `spanned` screensaver option.
* Detects monitor geometry dynamically.
* Preserves monitor X/Y offsets.
* Creates one image per monitor.
* Uses the Lockscreen Extension's per-monitor settings.
* Supports up to four monitors by default.
* Disables lockscreen blur.
* Deletes the temporary full-screen screenshot.
* Keeps timestamped logs.
* Does not automatically install packages.
* Does not invoke `sudo`.
* Allows monitor-order configuration.
* Keeps screenshot generation separate from session locking.

---

# 37. Architecture

```text
                  ┌─────────────────────────┐
                  │   Desktop Screenshot    │
                  │   gnome-screenshot      │
                  └────────────┬────────────┘
                               │
                               ▼
                  ┌─────────────────────────┐
                  │ Full X11 Screenshot     │
                  └────────────┬────────────┘
                               │
                               ▼
                  ┌─────────────────────────┐
                  │        xrandr           │
                  │   Monitor geometry      │
                  └────────────┬────────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
              ▼                ▼                ▼
        Monitor 1 crop   Monitor 2 crop   Monitor N crop
              │                │                │
              ▼                ▼                ▼
       monitor-1.png    monitor-2.png    monitor-N.png
              │                │                │
              └────────────────┼────────────────┘
                               │
                               ▼
                GNOME Lockscreen Extension
                               │
                               ▼
                      GNOME Lock Screen
```

---

# 38. Expected Behavior

After running:

```bash
~/bin/screenshot-lock-screen.sh
```

the script generates monitor-specific lockscreen images and configures the extension.

The normal desktop wallpaper remains unchanged.

Then:

```bash
loginctl lock-session
```

locks the session and GNOME displays the generated monitor-specific screenshots.

For a keyboard shortcut setup, use:

```text
Super + L
    │
    ▼
lock-screen.sh
    │
    ▼
screenshot-lock-screen.sh
    │
    ├── Capture desktop
    ├── Detect monitors
    ├── Crop monitor images
    └── Configure Lockscreen Extension
    │
    ▼
loginctl lock-session
    │
    ▼
GNOME Lock Screen
```
