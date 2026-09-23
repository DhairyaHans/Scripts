#!/usr/bin/env bash

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

# Output directory can be overridden:
#
#   OUTPUT_DIR=/tmp/lockscreen ./screenshot-lock-screen.sh
#
OUTPUT_DIR="${OUTPUT_DIR:-${1:-$HOME/Pictures/Screenshots/wallpapers}}"

# GNOME Lockscreen Extension
EXTENSION_ID="${EXTENSION_ID:-lockscreen-extension@pratap.fastmail.fm}"
EXTENSION_SCHEMA="${EXTENSION_SCHEMA:-org.gnome.shell.extensions.lockscreen-extension}"

EXTENSION_SCHEMA_DIR="${EXTENSION_SCHEMA_DIR:-$HOME/.local/share/gnome-shell/extensions/$EXTENSION_ID/schemas}"

# Maximum number of monitors supported by the extension.
MAX_MONITORS="${MAX_MONITORS:-4}"

# ------------------------------------------------------------------
# Monitor ordering
# ------------------------------------------------------------------
#
# The Lockscreen Extension uses GNOME Shell's:
#
#   Main.layoutManager.monitors
#
# while this script gets monitor information from:
#
#   xrandr --listactivemonitors
#
# These two monitor orders are not guaranteed to be identical.
#
# Supported values:
#
#   reverse - reverse xrandr order before assigning extension settings
#   normal  - use xrandr order directly
#
# Your current GNOME setup requires "reverse".
#
MONITOR_ORDER="${MONITOR_ORDER:-reverse}"

# ============================================================================
# Setup
# ============================================================================

mkdir -p "$OUTPUT_DIR"

TIMESTAMP="$(date '+%Y%m%d-%H%M%S')"

LOG_FILE="$OUTPUT_DIR/lock-$TIMESTAMP.log"
exec >> "$LOG_FILE" 2>&1

echo "[$TIMESTAMP] Starting lockscreen screenshot generation..."

# ============================================================================
# Dependency checks
# ============================================================================

require_command() {
    local command="$1"

    if ! command -v "$command" >/dev/null 2>&1; then
        echo "Error: Required command '$command' was not found."
        echo
        echo "Install the required dependencies before running this script."
        exit 1
    fi
}

require_command gnome-screenshot
require_command xrandr
require_command gsettings

# ============================================================================
# Find ImageMagick
# ============================================================================

if command -v magick >/dev/null 2>&1; then
    MAGICK="magick"
elif command -v convert >/dev/null 2>&1; then
    MAGICK="convert"
else
    echo "Error: ImageMagick was not found."
    echo "Install ImageMagick before running this script."
    exit 1
fi

# ============================================================================
# Validate configuration
# ============================================================================

case "$MONITOR_ORDER" in
    normal|reverse)
        ;;
    *)
        echo "Error: MONITOR_ORDER must be 'normal' or 'reverse'."
        echo "Current value: $MONITOR_ORDER"
        exit 1
        ;;
esac

if ! [[ "$MAX_MONITORS" =~ ^[1-9][0-9]*$ ]]; then
    echo "Error: MAX_MONITORS must be a positive integer."
    exit 1
fi

# ============================================================================
# Validate Lockscreen Extension
# ============================================================================

if [[ ! -d "$EXTENSION_SCHEMA_DIR" ]]; then
    echo "Error: Lockscreen Extension schema directory was not found:"
    echo
    echo "  $EXTENSION_SCHEMA_DIR"
    echo
    echo "Install and enable the Lockscreen Extension first."
    exit 1
fi

# ============================================================================
# Check X11
# ============================================================================

if [[ "${XDG_SESSION_TYPE:-}" != "x11" ]]; then
    echo "Error: This script currently requires an X11 session."
    echo
    echo "Current session:"
    echo "  XDG_SESSION_TYPE=${XDG_SESSION_TYPE:-unknown}"
    echo
    echo "This script uses xrandr and gnome-screenshot."
    exit 1
fi

# ============================================================================
# Temporary full-screen screenshot
# ============================================================================

FULL_SCREEN="$OUTPUT_DIR/.full-screen-$TIMESTAMP.png"

cleanup() {
    rm -f "$FULL_SCREEN"
}

trap cleanup EXIT

# ============================================================================
# Take full desktop screenshot
# ============================================================================

echo
echo "Taking full desktop screenshot:"
echo "  $FULL_SCREEN"

gnome-screenshot -f "$FULL_SCREEN"

# ============================================================================
# Get monitor information
# ============================================================================

MONITORS="$(xrandr --listactivemonitors | tail -n +2)"

if [[ -z "$MONITORS" ]]; then
    echo "Error: No active monitors detected."
    exit 1
fi

echo
echo "Detected monitors:"
echo "$MONITORS"

# ============================================================================
# Parse monitors
# ============================================================================

declare -a MONITOR_NAMES
declare -a MONITOR_WIDTHS
declare -a MONITOR_HEIGHTS
declare -a MONITOR_XS
declare -a MONITOR_YS

MIN_X=""
MIN_Y=""
MAX_X=""
MAX_Y=""

while read -r LINE; do

    [[ -z "$LINE" ]] && continue

    # Example:
    #
    # 0: +*eDP-1 1920/310x1080/170+1920+238  eDP-1

    NAME="$(echo "$LINE" | awk '{print $NF}')"

    RAW_GEOMETRY="$(echo "$LINE" | awk '{print $(NF-1)}')"

    # Convert:
    #
    # 1920/310x1080/170+1920+238
    #
    # to:
    #
    # 1920x1080+1920+238

    GEOMETRY="$(echo "$RAW_GEOMETRY" | sed -E 's#/([0-9]+)##g')"

    WIDTH="$(echo "$GEOMETRY" | cut -d'x' -f1)"
    HEIGHT="$(echo "$GEOMETRY" | cut -d'x' -f2 | cut -d'+' -f1)"
    X="$(echo "$GEOMETRY" | cut -d'+' -f2)"
    Y="$(echo "$GEOMETRY" | cut -d'+' -f3)"

    if ! [[ "$WIDTH" =~ ^[0-9]+$ &&
            "$HEIGHT" =~ ^[0-9]+$ &&
            "$X" =~ ^-?[0-9]+$ &&
            "$Y" =~ ^-?[0-9]+$ ]]; then

        echo "Error: Failed to parse monitor geometry:"
        echo "  $LINE"
        exit 1
    fi

    MONITOR_NAMES+=("$NAME")
    MONITOR_WIDTHS+=("$WIDTH")
    MONITOR_HEIGHTS+=("$HEIGHT")
    MONITOR_XS+=("$X")
    MONITOR_YS+=("$Y")

    RIGHT=$((X + WIDTH))
    BOTTOM=$((Y + HEIGHT))

    if [[ -z "$MIN_X" || "$X" -lt "$MIN_X" ]]; then
        MIN_X="$X"
    fi

    if [[ -z "$MIN_Y" || "$Y" -lt "$MIN_Y" ]]; then
        MIN_Y="$Y"
    fi

    if [[ -z "$MAX_X" || "$RIGHT" -gt "$MAX_X" ]]; then
        MAX_X="$RIGHT"
    fi

    if [[ -z "$MAX_Y" || "$BOTTOM" -gt "$MAX_Y" ]]; then
        MAX_Y="$BOTTOM"
    fi

done <<< "$MONITORS"

MONITOR_COUNT="${#MONITOR_NAMES[@]}"

echo
echo "Monitor count:"
echo "  $MONITOR_COUNT"

if [[ "$MONITOR_COUNT" -gt "$MAX_MONITORS" ]]; then
    echo
    echo "Error: $MONITOR_COUNT monitors detected."
    echo "The Lockscreen Extension configuration supports a maximum of $MAX_MONITORS."
    exit 1
fi

# ============================================================================
# Calculate virtual desktop
# ============================================================================

CANVAS_WIDTH=$((MAX_X - MIN_X))
CANVAS_HEIGHT=$((MAX_Y - MIN_Y))

echo
echo "Virtual desktop:"
echo "  Min X  : $MIN_X"
echo "  Min Y  : $MIN_Y"
echo "  Max X  : $MAX_X"
echo "  Max Y  : $MAX_Y"
echo "  Canvas : ${CANVAS_WIDTH}x${CANVAS_HEIGHT}"

# ============================================================================
# Show monitor-to-extension mapping
# ============================================================================

echo
echo "Monitor mapping:"
echo "  Monitor order mode: $MONITOR_ORDER"

for i in "${!MONITOR_NAMES[@]}"; do

    if [[ "$MONITOR_ORDER" == "reverse" ]]; then
        SETTINGS_INDEX=$((MONITOR_COUNT - i))
    else
        SETTINGS_INDEX=$((i + 1))
    fi

    echo "  xrandr monitor $i (${MONITOR_NAMES[$i]}) -> extension setting $SETTINGS_INDEX"

done

# ============================================================================
# Create per-monitor lockscreen images
# ============================================================================

for i in "${!MONITOR_NAMES[@]}"; do

    # ------------------------------------------------------------------
    # Determine extension settings index
    # ------------------------------------------------------------------

    if [[ "$MONITOR_ORDER" == "reverse" ]]; then
        SETTINGS_INDEX=$((MONITOR_COUNT - i))
    else
        SETTINGS_INDEX=$((i + 1))
    fi

    NAME="${MONITOR_NAMES[$i]}"
    WIDTH="${MONITOR_WIDTHS[$i]}"
    HEIGHT="${MONITOR_HEIGHTS[$i]}"
    X="${MONITOR_XS[$i]}"
    Y="${MONITOR_YS[$i]}"

    # Position relative to the virtual desktop origin.
    CROP_X=$((X - MIN_X))
    CROP_Y=$((Y - MIN_Y))

    MONITOR_IMAGE="$OUTPUT_DIR/lockscreen-${NAME}-${TIMESTAMP}.png"

    echo
    echo "Processing monitor:"
    echo "  xrandr index     : $i"
    echo "  Extension index  : $SETTINGS_INDEX"
    echo "  Name             : $NAME"
    echo "  Resolution       : ${WIDTH}x${HEIGHT}"
    echo "  Position         : ${X},${Y}"
    echo "  Screenshot crop  : ${WIDTH}x${HEIGHT}+${CROP_X}+${CROP_Y}"
    echo "  Output           : $MONITOR_IMAGE"

    # ------------------------------------------------------------------
    # Crop exact monitor area
    # ------------------------------------------------------------------

    "$MAGICK" "$FULL_SCREEN" \
        -crop "${WIDTH}x${HEIGHT}+${CROP_X}+${CROP_Y}" \
        +repage \
        "$MONITOR_IMAGE"

    # ------------------------------------------------------------------
    # Configure Lockscreen Extension
    # ------------------------------------------------------------------

    echo "  Configuring Lockscreen Extension..."

    gsettings \
        --schemadir "$EXTENSION_SCHEMA_DIR" \
        set "$EXTENSION_SCHEMA" \
        "user-background-${SETTINGS_INDEX}" \
        false

    gsettings \
        --schemadir "$EXTENSION_SCHEMA_DIR" \
        set "$EXTENSION_SCHEMA" \
        "background-image-path-${SETTINGS_INDEX}" \
        "file://$MONITOR_IMAGE"

    # Disable blur.
    gsettings \
        --schemadir "$EXTENSION_SCHEMA_DIR" \
        set "$EXTENSION_SCHEMA" \
        "blur-radius-${SETTINGS_INDEX}" \
        0

    # Use the full monitor image.
    gsettings \
        --schemadir "$EXTENSION_SCHEMA_DIR" \
        set "$EXTENSION_SCHEMA" \
        "background-size-${SETTINGS_INDEX}" \
        "cover"

done

# ============================================================================
# Show resulting configuration
# ============================================================================

echo
echo "Lockscreen Extension configuration:"

for i in "${!MONITOR_NAMES[@]}"; do

    if [[ "$MONITOR_ORDER" == "reverse" ]]; then
        SETTINGS_INDEX=$((MONITOR_COUNT - i))
    else
        SETTINGS_INDEX=$((i + 1))
    fi

    NAME="${MONITOR_NAMES[$i]}"

    echo
    echo "xrandr monitor $i ($NAME):"
    echo "  Extension setting: $SETTINGS_INDEX"

    echo -n "  user-background: "
    gsettings \
        --schemadir "$EXTENSION_SCHEMA_DIR" \
        get "$EXTENSION_SCHEMA" \
        "user-background-${SETTINGS_INDEX}"

    echo -n "  background-image: "
    gsettings \
        --schemadir "$EXTENSION_SCHEMA_DIR" \
        get "$EXTENSION_SCHEMA" \
        "background-image-path-${SETTINGS_INDEX}"

    echo -n "  background-size: "
    gsettings \
        --schemadir "$EXTENSION_SCHEMA_DIR" \
        get "$EXTENSION_SCHEMA" \
        "background-size-${SETTINGS_INDEX}"

    echo -n "  blur-radius: "
    gsettings \
        --schemadir "$EXTENSION_SCHEMA_DIR" \
        get "$EXTENSION_SCHEMA" \
        "blur-radius-${SETTINGS_INDEX}"

done

# ============================================================================
# Verify desktop wallpaper
# ============================================================================

echo
echo "Desktop wallpaper:"
gsettings get org.gnome.desktop.background picture-uri

# ============================================================================
# Verify generated images
# ============================================================================

echo
echo "Generated lockscreen images:"

for i in "${!MONITOR_NAMES[@]}"; do

    NAME="${MONITOR_NAMES[$i]}"
    MONITOR_IMAGE="$OUTPUT_DIR/lockscreen-${NAME}-${TIMESTAMP}.png"

    echo
    echo "$MONITOR_IMAGE"

    identify "$MONITOR_IMAGE"

done

echo
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Done."