# Using `Win + L` to Lock the Screen

You can configure `Win + L` (also commonly shown as `Super + L`) to run `my-lock-script.sh`.

This allows the custom lockscreen to be generated and configured before the session is locked.

The resulting flow is:

```text
Win + L
   │
   ▼
my-lock-script.sh
   │
   ├── Generate per-monitor screenshots
   ├── Configure Lockscreen Extension
   └── Lock the current session
```

## 1. Verify the Script

Before assigning the keyboard shortcut, verify that the script works.

Test without locking:

```bash
./my-lock-script.sh --no-lock
```

If everything looks correct, test the complete command:

```bash
./my-lock-script.sh
```

---

## 2. Get the Absolute Path

Keyboard shortcuts should use the absolute path to the script.

Run this from the directory containing the script:

```bash
realpath ./my-lock-script.sh
```

Example:

```text
/home/<username>/bin/my-lock-script.sh
```

Make sure the script is executable:

```bash
chmod +x /home/<username>/bin/my-lock-script.sh
```

---

## 3. Configure the Keyboard Shortcut

Open your desktop environment's **Keyboard Shortcuts** settings.

Look for an option such as:

```text
Keyboard → Shortcuts
```

or:

```text
Keyboard Shortcuts → Custom Shortcuts
```

The exact location depends on the desktop environment and distribution.

Create a new custom shortcut with:

**Name:**

```text
Custom Lock Screen
```

**Command:**

```bash
/home/<username>/bin/my-lock-script.sh
```

Then assign:

```text
Super + L
```

or:

```text
Win + L
```

as the keyboard shortcut.

---

## 4. Check for an Existing `Super + L` Shortcut

`Super + L` is commonly already assigned to the desktop environment's default lock action.

If the custom shortcut does not trigger, check whether `Super + L` is already assigned to another action.

For GNOME-based desktops, you can check the default lock shortcut with:

```bash
gsettings get org.gnome.settings-daemon.plugins.media-keys screensaver
```

If it returns:

```text
['<Super>l']
```

then the default lock shortcut is using `Super + L`.

You may need to remove or change the existing shortcut through your desktop environment's keyboard shortcut settings before assigning `Super + L` to the custom script.

For GNOME, the default lock shortcut can be disabled with:

```bash
gsettings set org.gnome.settings-daemon.plugins.media-keys screensaver "[]"
```

Verify:

```bash
gsettings get org.gnome.settings-daemon.plugins.media-keys screensaver
```

---

## 5. Test the Shortcut

After assigning the shortcut, press:

```text
Win + L
```

The script should execute and perform the normal lock workflow:

```text
Win + L
    ↓
my-lock-script.sh
    ↓
screenshot-lock-screen.sh
    ↓
Generate/configure lockscreen
    ↓
Lock session
```

If the shortcut does not work, run the script manually first:

```bash
/home/<username>/bin/my-lock-script.sh
```

This helps determine whether the problem is with the script or the keyboard shortcut configuration.

---

## Using Custom Parameters

The keyboard shortcut command can include any supported command-line options.

For example:

```bash
/home/<username>/bin/my-lock-script.sh --monitor-order reverse
```

Or:

```bash
/home/<username>/bin/my-lock-script.sh \
    --output-dir "$HOME/Pictures/lockscreen" \
    --monitor-order reverse
```

For normal daily usage, the simplest command is:

```bash
/home/<username>/bin/my-lock-script.sh
```

---

## Testing Without Locking

If you want to test the command assigned to the shortcut without actually locking the session, temporarily use:

```bash
/home/<username>/bin/my-lock-script.sh --no-lock
```

After verifying the generated screenshots and configuration, remove `--no-lock`:

```bash
/home/<username>/bin/my-lock-script.sh
```

---

## Restoring the Default Lock Shortcut

If you previously changed the desktop environment's default lock shortcut and want to restore it, use your desktop environment's keyboard shortcut settings.

For GNOME, the default `Super + L` lock shortcut can be restored with:

```bash
gsettings set org.gnome.settings-daemon.plugins.media-keys screensaver "['<Super>l']"
```

Also remove or disable the custom `Super + L` shortcut to avoid a conflict.

---

## Notes

* The exact keyboard shortcut settings depend on your Linux distribution and desktop environment.
* `Win` is commonly called `Super` on Linux.
* The script should be configured using its **absolute path**.
* Do not use `sudo` for the lock script.
* Test the script manually before assigning it to a keyboard shortcut.
* If `Super + L` is already assigned to the system's lock action, that existing shortcut may need to be changed before the custom shortcut can use the same key combination.
