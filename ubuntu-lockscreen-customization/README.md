# my-lock-script.sh

A wrapper script for generating a per-monitor GNOME lockscreen image and then locking the current Linux session.

The script delegates screenshot generation and Lockscreen Extension configuration to:

```text
screenshot-lock-screen.sh
```

After the screenshot/configuration step completes successfully, it locks the current session using:

```bash
loginctl lock-session
```

---

## Features

* Runs `screenshot-lock-screen.sh`
* Supports configurable output directory
* Supports configurable monitor ordering
* Supports configurable GNOME Lockscreen Extension
* Supports configurable GSettings schema
* Supports configurable schema directory
* Supports configurable maximum monitor count
* Can generate/configure the lockscreen without actually locking
* Uses the directory containing the script to locate `screenshot-lock-screen.sh`
* Does not require running from a particular working directory

---

## Directory Structure

Keep the two scripts together:

```text
lockscreen/
├── screenshot-lock-screen.sh
└── my-lock-script.sh
```

Make both scripts executable:

```bash
chmod +x screenshot-lock-screen.sh
chmod +x my-lock-script.sh
```

---

# Finding Your Configuration Values

The script supports several optional parameters. You do **not** need to guess these values.

The following commands can be used to inspect your system and determine the appropriate values.

---

## 1. Find the Output Directory

`--output-dir` specifies where screenshots and logs are stored.

The default is:

```text
$HOME/Pictures/Screenshots/wallpapers
```

Check your home directory:

```bash
echo "$HOME"
```

Therefore, the default output directory is:

```bash
echo "$HOME/Pictures/Screenshots/wallpapers"
```

Check whether it already exists:

```bash
ls -ld "$HOME/Pictures/Screenshots/wallpapers"
```

If it does not exist, the script will create it automatically.

You can use a different directory if required:

```bash
./my-lock-script.sh --output-dir "$HOME/Pictures/lockscreen"
```

---

## 2. Find the Monitor Order

The script uses `xrandr` to detect monitors.

Run:

```bash
xrandr --listactivemonitors
```

Example:

```text
Monitors: 2
 0: +*HDMI-1 1920/509x1080/286+0+0 HDMI-1
 1: +eDP-1 1920/309x1080/174+1920+238 eDP-1
```

You can also inspect the complete monitor configuration:

```bash
xrandr --query
```

The order shown by:

```bash
xrandr --listactivemonitors
```

is the order used by the screenshot script.

### Normal order

```bash
./my-lock-script.sh --monitor-order normal
```

Mapping:

```text
xrandr monitor 0 → background-image-path-1
xrandr monitor 1 → background-image-path-2
...
```

### Reverse order

```bash
./my-lock-script.sh --monitor-order reverse
```

With two monitors:

```text
xrandr monitor 0 → background-image-path-2
xrandr monitor 1 → background-image-path-1
```

If the lockscreen images appear on the wrong monitors, try:

```bash
./my-lock-script.sh --monitor-order reverse
```

---

## 3. Find the GNOME Lockscreen Extension ID

List installed GNOME Shell extensions:

```bash
gnome-extensions list
```

Look for the Lockscreen Extension.

For example:

```text
lockscreen-extension@pratap.fastmail.fm
```

You can inspect a specific extension with:

```bash
gnome-extensions info lockscreen-extension@pratap.fastmail.fm
```

You can also list enabled extensions:

```bash
gnome-extensions list --enabled
```

The value after `--extension-id` should be the extension ID exactly as reported by GNOME:

```bash
./my-lock-script.sh \
    --extension-id "lockscreen-extension@pratap.fastmail.fm"
```

---

## 4. Find the Extension Schema

The extension's GSettings schema can be found by inspecting its schema files.

First, determine the extension directory:

```bash
EXTENSION_ID="lockscreen-extension@pratap.fastmail.fm"

echo "$HOME/.local/share/gnome-shell/extensions/$EXTENSION_ID"
```

Check the schema directory:

```bash
ls "$HOME/.local/share/gnome-shell/extensions/$EXTENSION_ID/schemas"
```

Look for a `.gschema.xml` file:

```bash
find "$HOME/.local/share/gnome-shell/extensions/$EXTENSION_ID/schemas" \
    -maxdepth 1 \
    -type f \
    -name "*.gschema.xml" \
    -print
```

For example:

```text
/home/user/.local/share/gnome-shell/extensions/lockscreen-extension@pratap.fastmail.fm/schemas/org.gnome.shell.extensions.lockscreen-extension.gschema.xml
```

The schema ID is normally the value of the `<schema id="...">` attribute.

You can extract it with:

```bash
grep -oP '<schema[^>]+id="\K[^"]+' \
    "$HOME/.local/share/gnome-shell/extensions/$EXTENSION_ID/schemas/"*.gschema.xml
```

Example output:

```text
org.gnome.shell.extensions.lockscreen-extension
```

Use that value with:

```bash
./my-lock-script.sh \
    --extension-schema "org.gnome.shell.extensions.lockscreen-extension"
```

You can also verify that GSettings recognizes the schema:

```bash
gsettings list-keys org.gnome.shell.extensions.lockscreen-extension
```

If the schema is available, this should list its keys.

---

## 5. Find the Extension Schema Directory

Once you know the extension ID, the default schema directory is:

```bash
echo "$HOME/.local/share/gnome-shell/extensions/<extension-id>/schemas"
```

For example:

```bash
echo "$HOME/.local/share/gnome-shell/extensions/lockscreen-extension@pratap.fastmail.fm/schemas"
```

Check that it exists:

```bash
ls -ld \
    "$HOME/.local/share/gnome-shell/extensions/lockscreen-extension@pratap.fastmail.fm/schemas"
```

You can also find schema directories automatically:

```bash
find "$HOME/.local/share/gnome-shell/extensions" \
    -type d \
    -name schemas \
    -print
```

Use the appropriate directory with:

```bash
./my-lock-script.sh \
    --extension-schema-dir \
    "$HOME/.local/share/gnome-shell/extensions/lockscreen-extension@pratap.fastmail.fm/schemas"
```

---

## 6. Find the Maximum Monitor Count

Check how many monitors are currently active:

```bash
xrandr --listactivemonitors
```

The first line contains the number of monitors.

For example:

```text
Monitors: 2
```

The maximum monitor count should be at least the number of monitors you want the script to support.

For two monitors:

```bash
./my-lock-script.sh --max-monitors 2
```

For up to four monitors:

```bash
./my-lock-script.sh --max-monitors 4
```

You can extract the current monitor count automatically:

```bash
xrandr --listactivemonitors | head -1 | awk '{print $2}'
```

For example:

```text
2
```

You can then use it directly:

```bash
./my-lock-script.sh \
    --max-monitors "$(xrandr --listactivemonitors | head -1 | awk '{print $2}')"
```

The underlying `screenshot-lock-screen.sh` validates the actual monitor count against this value.

---

# Quick Configuration Discovery

If you want to inspect all relevant values before running the script, run:

```bash
echo "=== Home Directory ==="
echo "$HOME"

echo
echo "=== Session Type ==="
echo "$XDG_SESSION_TYPE"

echo
echo "=== Active Monitors ==="
xrandr --listactivemonitors

echo
echo "=== Monitor Count ==="
xrandr --listactivemonitors | head -1 | awk '{print $2}'

echo
echo "=== GNOME Extensions ==="
gnome-extensions list

echo
echo "=== Enabled GNOME Extensions ==="
gnome-extensions list --enabled

echo
echo "=== Extension Directories ==="
find "$HOME/.local/share/gnome-shell/extensions" \
    -maxdepth 2 \
    -type d \
    -name schemas \
    -print

echo
echo "=== Extension Schema Files ==="
find "$HOME/.local/share/gnome-shell/extensions" \
    -type f \
    -name "*.gschema.xml" \
    -print

echo
echo "=== Extension Schema IDs ==="
grep -RhoP '<schema[^>]+id="\K[^"]+' \
    "$HOME/.local/share/gnome-shell/extensions"/*/schemas/*.gschema.xml \
    2>/dev/null || true

echo
echo "=== Default Output Directory ==="
echo "$HOME/Pictures/Screenshots/wallpapers"
```

This gives you the information needed to configure the optional parameters.

---

# Basic Usage

Run:

```bash
./my-lock-script.sh
```

This will:

1. Run `screenshot-lock-screen.sh`
2. Capture the desktop
3. Create per-monitor screenshots
4. Configure the GNOME Lockscreen Extension
5. Lock the current session

---

# Options

## `--output-dir`

Specify where generated screenshots and logs should be stored.

```bash
./my-lock-script.sh --output-dir /tmp/lockscreen
```

Short form:

```bash
./my-lock-script.sh -o /tmp/lockscreen
```

Default:

```text
$HOME/Pictures/Screenshots/wallpapers
```

The directory will be created automatically if it does not exist.

---

## `--monitor-order`

Controls how monitors detected by `xrandr` are mapped to the GNOME Lockscreen Extension settings.

Supported values:

```text
normal
reverse
```

### Normal

```bash
./my-lock-script.sh --monitor-order normal
```

The first monitor detected by `xrandr` is assigned to:

```text
background-image-path-1
```

The second monitor is assigned to:

```text
background-image-path-2
```

and so on.

### Reverse

```bash
./my-lock-script.sh --monitor-order reverse
```

The monitor ordering is reversed before assigning the extension settings.

For example, with two monitors:

```text
xrandr monitor 0 → extension setting 2
xrandr monitor 1 → extension setting 1
```

This can be useful because `xrandr` monitor ordering and GNOME Shell monitor ordering are not necessarily identical.

The default configured by `screenshot-lock-screen.sh` is used if this option is not specified.

---

## `--extension-id`

Specify the GNOME Shell extension ID.

```bash
./my-lock-script.sh \
    --extension-id "lockscreen-extension@pratap.fastmail.fm"
```

Default:

```text
lockscreen-extension@pratap.fastmail.fm
```

See [Finding the GNOME Lockscreen Extension ID](#3-find-the-gnome-lockscreen-extension-id) above to determine this value on your system.

---

## `--extension-schema`

Specify the GSettings schema used by the Lockscreen Extension.

```bash
./my-lock-script.sh \
    --extension-schema "org.gnome.shell.extensions.lockscreen-extension"
```

Default:

```text
org.gnome.shell.extensions.lockscreen-extension
```

See [Finding the Extension Schema](#4-find-the-extension-schema) above to determine this value.

---

## `--extension-schema-dir`

Specify the directory containing the extension's GSettings schemas.

Example:

```bash
./my-lock-script.sh \
    --extension-schema-dir \
    "$HOME/.local/share/gnome-shell/extensions/lockscreen-extension@pratap.fastmail.fm/schemas"
```

The default is derived from the extension ID:

```text
$HOME/.local/share/gnome-shell/extensions/<extension-id>/schemas
```

See [Finding the Extension Schema Directory](#5-find-the-extension-schema-directory) above.

---

## `--max-monitors`

Specify the maximum number of monitors supported by the Lockscreen Extension configuration.

Example:

```bash
./my-lock-script.sh --max-monitors 2
```

Or:

```bash
./my-lock-script.sh --max-monitors 4
```

Default:

```text
4
```

The underlying `screenshot-lock-screen.sh` validates the actual monitor count against this value.

To automatically use the number of currently active monitors:

```bash
./my-lock-script.sh \
    --max-monitors "$(xrandr --listactivemonitors | head -1 | awk '{print $2}')"
```

---

# `--no-lock`

By default, the wrapper locks the current session after configuring the lockscreen.

To only generate the screenshots and configure the extension without locking:

```bash
./my-lock-script.sh --no-lock
```

This is useful when testing the generated lockscreen images.

For example:

```bash
./my-lock-script.sh \
    --output-dir /tmp/lockscreen \
    --monitor-order reverse \
    --no-lock
```

After the command finishes, inspect the generated images before manually locking the session.

---

# `--help`

Display all available options:

```bash
./my-lock-script.sh --help
```

---

# Common Examples

## 1. Normal usage

```bash
./my-lock-script.sh
```

---

## 2. Custom output directory

```bash
./my-lock-script.sh \
    --output-dir "$HOME/Pictures/lockscreen"
```

---

## 3. Reverse monitor ordering

```bash
./my-lock-script.sh \
    --monitor-order reverse
```

---

## 4. Normal monitor ordering

```bash
./my-lock-script.sh \
    --monitor-order normal
```

---

## 5. Test without locking

```bash
./my-lock-script.sh \
    --no-lock
```

---

## 6. Test with a temporary output directory

```bash
./my-lock-script.sh \
    --output-dir /tmp/lockscreen \
    --no-lock
```

---

## 7. Configure two monitors explicitly

```bash
./my-lock-script.sh \
    --max-monitors 2 \
    --monitor-order reverse
```

---

## 8. Complete custom configuration

```bash
./my-lock-script.sh \
    --output-dir "$HOME/Pictures/lockscreen" \
    --monitor-order reverse \
    --extension-id "lockscreen-extension@pratap.fastmail.fm" \
    --extension-schema "org.gnome.shell.extensions.lockscreen-extension" \
    --extension-schema-dir "$HOME/.local/share/gnome-shell/extensions/lockscreen-extension@pratap.fastmail.fm/schemas" \
    --max-monitors 4
```

---

# How the Wrapper Works

The wrapper does not duplicate the screenshot logic.

The flow is:

```text
my-lock-script.sh
        │
        ▼
Parse command-line options
        │
        ▼
Validate screenshot-lock-screen.sh
        │
        ▼
Pass configuration as environment variables
        │
        ▼
screenshot-lock-screen.sh
        │
        ├── Capture full desktop
        ├── Detect monitors
        ├── Calculate monitor geometry
        ├── Crop per-monitor screenshots
        ├── Configure Lockscreen Extension
        └── Write logs
        │
        ▼
loginctl lock-session
```

When `--no-lock` is supplied, the final step is skipped.

---

# Configuration Mapping

The wrapper options map directly to environment variables understood by `screenshot-lock-screen.sh`.

| CLI option               | Environment variable   |
| ------------------------ | ---------------------- |
| `--output-dir`           | `OUTPUT_DIR`           |
| `--monitor-order`        | `MONITOR_ORDER`        |
| `--extension-id`         | `EXTENSION_ID`         |
| `--extension-schema`     | `EXTENSION_SCHEMA`     |
| `--extension-schema-dir` | `EXTENSION_SCHEMA_DIR` |
| `--max-monitors`         | `MAX_MONITORS`         |

This means the wrapper remains thin and the actual screenshot/monitor logic stays in `screenshot-lock-screen.sh`.

---

# Output

Assuming:

```bash
./my-lock-script.sh
```

the default output directory is:

```text
$HOME/Pictures/Screenshots/wallpapers
```

Files will look similar to:

```text
lock-20260923-130500.log
lockscreen-HDMI-1-20260923-130500.png
lockscreen-eDP-1-20260923-130500.png
```

The full temporary screenshot is removed after processing.

---

# Logs

A log file is created for each execution:

```text
lock-YYYYMMDD-HHMMSS.log
```

For example:

```text
lock-20260923-130500.log
```

The log contains:

* detected monitors
* monitor geometry
* monitor-to-extension mapping
* generated image paths
* Lockscreen Extension configuration
* final configuration values
* desktop wallpaper information

---

# Using It With a Keyboard Shortcut

If you want this script to behave like a custom lock command, assign:

```text
my-lock-script.sh
```

to your preferred keyboard shortcut.

For example, the command can be:

```bash
/home/<username>/bin/my-lock-script.sh
```

The wrapper will generate/configure the lockscreen first and then execute:

```bash
loginctl lock-session
```

---

# Testing

Before using it as your normal lock command, test without actually locking:

```bash
./my-lock-script.sh --no-lock
```

Then check the generated files:

```bash
ls -lh "$HOME/Pictures/Screenshots/wallpapers"
```

You can also inspect the latest log:

```bash
ls -t "$HOME/Pictures/Screenshots/wallpapers"/lock-*.log | head -1
```

---

# Important Notes

## Keep both scripts together

The wrapper locates the screenshot script relative to itself:

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
```

Therefore this works even when the script is launched from another directory.

For example:

```bash
cd /tmp

/home/user/bin/my-lock-script.sh
```

It will still find:

```text
/home/user/bin/screenshot-lock-screen.sh
```

---

## No `sudo`

The wrapper should normally be run as the logged-in desktop user.

Do not run it with:

```bash
sudo ./my-lock-script.sh
```

The script needs access to the user's:

* GNOME session
* `gsettings`
* display
* GNOME Shell extension configuration
* desktop screenshot

---

## X11

The underlying screenshot script currently requires an X11 session because it uses:

```bash
xrandr
gnome-screenshot
```

Check your session with:

```bash
echo "$XDG_SESSION_TYPE"
```

Expected:

```text
x11
```

---

# Recommended Daily Usage

Once everything is configured, the simplest command is:

```bash
./my-lock-script.sh
```

For a multi-monitor setup where the monitor mapping requires reversal:

```bash
./my-lock-script.sh --monitor-order reverse
```

For testing:

```bash
./my-lock-script.sh --monitor-order reverse --no-lock
```
