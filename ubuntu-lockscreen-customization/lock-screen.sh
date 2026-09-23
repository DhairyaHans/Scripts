```bash
#!/usr/bin/env bash

set -euo pipefail

# ============================================================================
# Usage
# ============================================================================
#
#   ./my-lock-script.sh [OPTIONS]
#
# This script:
#
#   1. Runs screenshot-lock-screen.sh
#   2. Configures the GNOME Lockscreen Extension
#   3. Locks the current session using loginctl
#
# ============================================================================


# ============================================================================
# Defaults
# ============================================================================

OUTPUT_DIR=""
MONITOR_ORDER=""
EXTENSION_ID=""
EXTENSION_SCHEMA=""
EXTENSION_SCHEMA_DIR=""
MAX_MONITORS=""

LOCK_SESSION=true


# ============================================================================
# Script directory
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SCREENSHOT_SCRIPT="$SCRIPT_DIR/screenshot-lock-screen.sh"


# ============================================================================
# Usage
# ============================================================================

usage() {
    cat <<EOF

Usage:
  $(basename "$0") [OPTIONS]

Description:
  Takes a full desktop screenshot, creates per-monitor lockscreen images,
  configures the GNOME Lockscreen Extension, and optionally locks the
  current session.

Options:

  -o, --output-dir DIR
      Directory where screenshots and logs are stored.

      Default:
        \$HOME/Pictures/Screenshots/wallpapers

      Example:
        --output-dir /tmp/lockscreen


  --monitor-order ORDER
      Controls how xrandr monitors are mapped to Lockscreen Extension
      settings.

      Supported values:
        normal
        reverse

      Default:
        Uses the default configured by screenshot-lock-screen.sh.

      Example:
        --monitor-order reverse


  --extension-id ID
      GNOME Lockscreen Extension ID.

      Default:
        lockscreen-extension@pratap.fastmail.fm

      Example:
        --extension-id my-extension@example.com


  --extension-schema SCHEMA
      GSettings schema used by the Lockscreen Extension.

      Default:
        org.gnome.shell.extensions.lockscreen-extension

      Example:
        --extension-schema org.example.my-lockscreen


  --extension-schema-dir DIR
      Directory containing the GSettings schemas for the extension.

      Default:
        \$HOME/.local/share/gnome-shell/extensions/<extension-id>/schemas

      Example:
        --extension-schema-dir /path/to/extension/schemas


  --max-monitors NUMBER
      Maximum number of monitors supported by the Lockscreen Extension.

      Default:
        4

      Example:
        --max-monitors 3


  --no-lock
      Generate and configure the lockscreen but do NOT lock the session.

      Example:
        --no-lock


  -h, --help
      Show this help message.


Examples:

  # Normal usage
  ./$(basename "$0")


  # Use a custom output directory
  ./$(basename "$0") --output-dir /tmp/lockscreen


  # Use reverse monitor mapping
  ./$(basename "$0") --monitor-order reverse


  # Use normal monitor mapping
  ./$(basename "$0") --monitor-order normal


  # Generate lockscreen but don't lock the session
  ./$(basename "$0") --no-lock


  # Combine options
  ./$(basename "$0") \\
      --output-dir /tmp/lockscreen \\
      --monitor-order reverse \\
      --max-monitors 2


  # Custom extension
  ./$(basename "$0") \\
      --extension-id my-extension@example.com \\
      --extension-schema org.example.my-lockscreen \\
      --extension-schema-dir "\$HOME/.local/share/gnome-shell/extensions/my-extension@example.com/schemas"


EOF
}


# ============================================================================
# Argument parsing
# ============================================================================

while [[ $# -gt 0 ]]; do

    case "$1" in

        -o|--output-dir)
            if [[ $# -lt 2 ]]; then
                echo "Error: $1 requires a directory."
                exit 1
            fi

            OUTPUT_DIR="$2"
            shift 2
            ;;


        --monitor-order)
            if [[ $# -lt 2 ]]; then
                echo "Error: --monitor-order requires a value."
                exit 1
            fi

            MONITOR_ORDER="$2"

            if [[ "$MONITOR_ORDER" != "normal" &&
                  "$MONITOR_ORDER" != "reverse" ]]; then

                echo "Error: --monitor-order must be 'normal' or 'reverse'."
                exit 1
            fi

            shift 2
            ;;


        --extension-id)
            if [[ $# -lt 2 ]]; then
                echo "Error: --extension-id requires a value."
                exit 1
            fi

            EXTENSION_ID="$2"
            shift 2
            ;;


        --extension-schema)
            if [[ $# -lt 2 ]]; then
                echo "Error: --extension-schema requires a value."
                exit 1
            fi

            EXTENSION_SCHEMA="$2"
            shift 2
            ;;


        --extension-schema-dir)
            if [[ $# -lt 2 ]]; then
                echo "Error: --extension-schema-dir requires a directory."
                exit 1
            fi

            EXTENSION_SCHEMA_DIR="$2"
            shift 2
            ;;


        --max-monitors)
            if [[ $# -lt 2 ]]; then
                echo "Error: --max-monitors requires a number."
                exit 1
            fi

            MAX_MONITORS="$2"

            if ! [[ "$MAX_MONITORS" =~ ^[1-9][0-9]*$ ]]; then
                echo "Error: --max-monitors must be a positive integer."
                exit 1
            fi

            shift 2
            ;;


        --no-lock)
            LOCK_SESSION=false
            shift
            ;;


        -h|--help)
            usage
            exit 0
            ;;


        *)
            echo "Error: Unknown option: $1"
            echo
            usage
            exit 1
            ;;

    esac

done


# ============================================================================
# Validate screenshot script
# ============================================================================

if [[ ! -f "$SCREENSHOT_SCRIPT" ]]; then
    echo "Error: Screenshot script was not found:"
    echo
    echo "  $SCREENSHOT_SCRIPT"
    exit 1
fi

if [[ ! -x "$SCREENSHOT_SCRIPT" ]]; then
    echo "Error: Screenshot script is not executable:"
    echo
    echo "  $SCREENSHOT_SCRIPT"
    echo
    echo "Run:"
    echo "  chmod +x \"$SCREENSHOT_SCRIPT\""
    exit 1
fi


# ============================================================================
# Configure environment for screenshot script
# ============================================================================

declare -a SCREENSHOT_ENV=()

if [[ -n "$OUTPUT_DIR" ]]; then
    SCREENSHOT_ENV+=("OUTPUT_DIR=$OUTPUT_DIR")
fi

if [[ -n "$MONITOR_ORDER" ]]; then
    SCREENSHOT_ENV+=("MONITOR_ORDER=$MONITOR_ORDER")
fi

if [[ -n "$EXTENSION_ID" ]]; then
    SCREENSHOT_ENV+=("EXTENSION_ID=$EXTENSION_ID")
fi

if [[ -n "$EXTENSION_SCHEMA" ]]; then
    SCREENSHOT_ENV+=("EXTENSION_SCHEMA=$EXTENSION_SCHEMA")
fi

if [[ -n "$EXTENSION_SCHEMA_DIR" ]]; then
    SCREENSHOT_ENV+=("EXTENSION_SCHEMA_DIR=$EXTENSION_SCHEMA_DIR")
fi

if [[ -n "$MAX_MONITORS" ]]; then
    SCREENSHOT_ENV+=("MAX_MONITORS=$MAX_MONITORS")
fi


# ============================================================================
# Run screenshot/configuration script
# ============================================================================

echo
echo "Running lockscreen screenshot configuration..."
echo

if [[ ${#SCREENSHOT_ENV[@]} -gt 0 ]]; then
    env "${SCREENSHOT_ENV[@]}" "$SCREENSHOT_SCRIPT"
else
    "$SCREENSHOT_SCRIPT"
fi


# ============================================================================
# Lock session
# ============================================================================

if [[ "$LOCK_SESSION" == true ]]; then

    echo
    echo "Locking current session..."

    loginctl lock-session

    echo "Session locked."

else

    echo
    echo "Lock skipped (--no-lock)."

fi
```
