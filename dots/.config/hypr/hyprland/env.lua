local home_dir = os.getenv("HOME")

-- Wayland
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- Applications
local current = os.getenv("XDG_DATA_DIRS") or "/usr/local/share:/usr/share"
hl.env("XDG_DATA_DIRS", home_dir .. "/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:" .. current)

-- Themes
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "kde")
hl.env("XDG_MENU_PREFIX", "plasma-")

-- Virtual environment
hl.env("ILLOGICAL_IMPULSE_VIRTUAL_ENV", home_dir .. "/.local/state/quickshell/.venv")
