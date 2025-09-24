<h1 align=center>🌌 Niri-Caelestia Shell</h1>

<div align=center>

![GitHub last commit](https://img.shields.io/github/last-commit/jutraim/niri-caelestia-shell?style=for-the-badge&labelColor=101418&color=9ccbfb)
![GitHub Repo stars](https://img.shields.io/github/stars/jutraim/niri-caelestia-shell?style=for-the-badge&labelColor=101418&color=b9c8da)
![GitHub repo size](https://img.shields.io/github/repo-size/jutraim/niri-caelestia-shell?style=for-the-badge&labelColor=101418&color=d3bfe6)

</div>


> A **Quickshell-based desktop environment** forked from [Caelestia Shell](https://github.com/caelestia-shell/caelestia-shell), adapted to run with the **Niri window manager**.
> This fork keeps the dashboard-based workflow while experimenting with new sidebar features and Niri.

<div align=center>

https://github.com/user-attachments/assets/0840f496-575c-4ca6-83a8-87bb01a85c5f

</div>

> [!CAUTION]
> This is my personal thingy and it's **STILL WORK IN PROGRESS.**
>
> Due to civil unrest in my country I don't have much time to boot up my PC so I update slowly :/
>
> This repo is **ONLY for the desktop shell** of the caelestia dots. For the default caelestia dots, head to [the main repo](https://github.com/caelestia-dots/caelestia) instead.

>[!WARNING]
> **HELP REQUIRED!**
>
> I **skipped** unneccesary commit from original shell named: "bar/workspaces: add special ws overlay" and "bar/workspaces: better scroll" because there is no special workspace in Niri.
>
> Unfortunately, I **skipped** an important commit from original shell named: "bar: per-monitor workspaces option (#394)"
> - **Reason:** I don't have multi monitor so I'm not sure if this actually works, I might break stuff :/. I need help implementing that feature :)



---

## ✨ What’s Different in This Fork?

Replaces **`Hyprland`** with **`Niri`** as the window manager.

### `Dashboard`

  - Window switch popup
    * [x] Dashboard is now opened after clicking on the popup instead of completely popping up and taking up half the screen.
    * [ ] Window decorations for pinning, hovering window, toggling fullscreen, and closing the window.

  - Experimental Niri management tab in dashboard
    * [x] Niri IPC command buttons for focused workspace
    * [ ] Needs re-design

### `Sidebar`

- Workspace bar refactor (WIP)
  * [x] Program Icon support instead of Material Font
  * [x] Switch to window by clicking
  * [x] Right click context menu
    * [ ] Allow performing Niri IPC operations in context menu
  * [x] Reorder window in workspace by drag&drop
  * [x] Grouping windows of same program
  * [x] Layout sensitive icons
  * [ ] Needs rewrite

### `Misc`
- * [x]  Niri event parser for Quickshell
- * [x]  Task manager (GPU/CPU/Memory monitoring, still improving)
- * [x]  Collapsible container UI element
- * [ ]  Application dock
- * [ ]  Searching programs in Niri overview

> [!NOTE]
> Some Caelestia features are dropped or WIP due to Niri limitations. See [ known issues](#-known-issues)

---

## 📦 Dependencies

You need both runtime dependencies and development headers.

<br>

* All dependencies in plain text:
   * `quickshell-git networkmanager fish glibc qt6-declarative gcc-libs cava libcava aubio libpipewire lm-sensors ddcutil brightnessctl material-symbols caskaydia-cove-nerd grim swappy app2unit libqalculate`

> [!NOTE]
>
> Unlike the default shell,
> [`caelestia-cli`](https://github.com/caelestia-dots/cli) is **not required for Niri**.

<details><summary> <b> Detailed info about all dependencies </b></summary>

<div align=center>


#### Core Dependencies 🖥️

| Package | Usage |
|---|---|
| [`quickshell-git`](https://quickshell.outfoxxed.me) | Must be the git version |
| [`networkmanager`](https://networkmanager.dev) | Network management |
| [`fish`](https://github.com/fish-shell/fish-shell) | Terminal |
| `glibc` | C library (runtime dependency) |
| `qt6-declarative` | Qt components |
| `gcc-libs` | GCC runtime |

#### Audio & Visual 🎵

| Package | Usage |
|---|---|
| [`cava`](https://github.com/karlstav/cava) | Audio visualizer |
| [`libcava`](https://pipewire.org) | Visualizer backend |
| [`aubio`](https://github.com/aubio/aubio) | Beat detector |
| [`libpipewire`](https://pipewire.org) | Media backend |
| [`lm-sensors`](https://github.com/lm-sensors/lm-sensors) | System usage monitoring |
| [`ddcutil`](https://github.com/rockowitz/ddcutil) | Monitor brightness control |
| [`brightnessctl`](https://github.com/Hummer12007/brightnessctl) | Brightness control |

#### Fonts 🔣

| Package | Usage |
|---|---|
| [`material-symbols`](https://fonts.google.com/icons) | Icon font |
| [`caskaydia-cove-nerd`](https://www.nerdfonts.com/font-downloads) | Monospace font |

#### Screenshot & Utilities 🧰

| Package | Usage |
|---|---|
| [`grim`](https://gitlab.freedesktop.org/emersion/grim) | Screenshot tool |
| [`swappy`](https://github.com/jtheoof/swappy) | Screenshot annotation |
| [`app2unit`](https://github.com/Vladimir-csp/app2unit) | Launch apps |
| [`libqalculate`](https://github.com/Qalculate/libqalculate) | Calculator |

#### BUILD dependencies 🏗️

| Package | Usage |
|---|---|
| [`cmake`](https://cmake.org) | Build tool |
| [`ninja`](https://github.com/ninja-build/ninja) | 🥷 |

</div>


### Manual installation

To install the shell manually, install all dependencies and clone this repo to `$XDG_CONFIG_HOME/quickshell/niri-caelestia-shell`.
Then simply build and install using `cmake`.


</details>

---

## ⚡ Installation

> [!NOTE]
> There is **NO** package manager installation support yet because... 🤔

### Manual Build

1. Install dependencies.
2. Clone the repo:

    ```sh
    cd $XDG_CONFIG_HOME/quickshell
    git clone https://github.com/jutraim/niri-caelestia-shell
    ```
3. Build:

    ```sh
    cd $XDG_CONFIG_HOME/quickshell/niri-caelestia-shell
    cmake -B build -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=$HOME \
      -DINSTALL_QSCONFDIR=$HOME/.config/quickshell/niri-caelestia-shell
    cmake --build build
    cmake --install build
    ```
    It's trying to install into system paths (`/usr/lib/caelestia/...`),
    so grab the necessary permissions or use sudo while installing.

    If you get `VERSION is not set and failed to get from git` error, that means I forgot to tag version. You can do `git tag 1.1.1` to work around it :)

### Arch Installation
If you are on Arch the following commands do a proper installation (mind the prefix):
```bash
# Dependencies
pacman -S --needed cava aubio libpipewire lm_sensors ddcutil brightnessctl grim swappy libqalculate ttf-cascadia-code-nerd qt6-declarative
yay -S quickshell-git app2unit libcava ttf-material-symbols-variable-git
# Clone Repo
cd $XDG_CONFIG_HOME/quickshell
git clone https://github.com/jutraim/niri-caelestia-shell
# Build & Install
cd ~/.config/quickshell/niri-caelestia-shell
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/
cmake --build build
sudo cmake --install build
```

### 🔃 Updating
You can update by running `git pull` in `$XDG_CONFIG_HOME/quickshell/niri-caelestia-shell`.

```sh
cd $XDG_CONFIG_HOME/quickshell/niri-caelestia-shell
git pull
```

<br>

---

## 🚀 Usage

The shell can be started via the `quickshell -c niri-caelestia-shell -n` command or `qs -c niri-caelestia-shell -n` on your preferred terminal.
><sub> (`qs` and `quickshell` are interchangable.) </sub>


* Example line for niri `config.kdl` to launch the shell at startup:

   ```
   spawn-at-startup "quickshell" "-c" "niri-caelestia-shell" "-n"
   ```

### Custom Shortcuts/IPC

All keybinds are accessible via [Quickshell IPC msg](https://quickshell.org/docs/v0.1.0/types/Quickshell.Io/IpcHandler/).

All IPC commands can be called via `quickshell -c niri-caelestia-shell ipc call ...`

* For example:

   ```sh
   qs -c niri-caelestia-shell ipc call mpris getActive <trackTitle>
   ```

* Example shortcut in `config.kdl` to toggle the launcher drawer:
    ```sh
    Mod+Space { spawn  "qs" "-c" "niri-caelestia-shell" "ipc" "call" "drawers" "toggle" "launcher"; }
    ```

    ```sh
    Mod+Space hotkey-overlay-title="Caelestia app launcher" { spawn-sh "qs -c niri-caelestia-shell ipc call drawers toggle launcher"; }
    ```

<br>

 The list of IPC commands can be shown via `qs -c shell ipc show`.

<br>

<details><summary> <b> Ipc Commands </b></summary>

  ```sh
  ❯ qs -c shell ipc show
  target picker
    function openFreeze(): void
    function open(): void
  target drawers
    function list(): string
    function toggle(drawer: string): void
  target lock
    function unlock(): void
    function isLocked(): bool
    function lock(): void
  target wallpaper
    function get(): string
    function set(path: string): void
    function list(): string
  target notifs
    function clear(): void
  target mpris
    function next(): void
    function previous(): void
    function getActive(prop: string): string
    function playPause(): void
    function pause(): void
    function stop(): void
    function list(): string
    function play(): void
  ```

</details>

---

## ⚙️ Configuration

Config lives in:

```
~/.config/caelestia/shell.json
```
<details><summary> <b> Example JSON </b></summary>

```json
{
    "appearance": {
        "anim": {
            "durations": {
                "scale": 1
            }
        },
        "font": {
            "family": {
                "material": "Material Symbols Rounded",
                "mono": "CaskaydiaCove NF",
                "sans": "Rubik"
            },
            "size": {
                "scale": 1
            }
        },
        "padding": {
            "scale": 1
        },
        "rounding": {
            "scale": 1
        },
        "spacing": {
            "scale": 1
        },
        "transparency": {
            "enabled": false,
            "base": 0.85,
            "layers": 0.4
        }
    },
    "general": {
        "apps": {
            "terminal": [
                "foot"
            ],
            "audio": [
                "pavucontrol"
            ]
        }
    },
    "background": {
        "desktopClock": {
            "enabled": false
        },
        "enabled": true,
        "visualiser": {
            "enabled": true,
            "autoHide": true,
            "rounding": 1,
            "spacing": 1
        }
    },
    "bar": {
        "clock": {
            "showIcon": false
        },
        "dragThreshold": 20,
        "entries": [
            {
                "id": "logo",
                "enabled": true
            },
            {
                "id": "workspaces",
                "enabled": true
            },
            {
                "id": "spacer",
                "enabled": true
            },
            {
                "id": "activeWindow",
                "enabled": true
            },
            {
                "id": "spacer",
                "enabled": true
            },
            {
                "id": "tray",
                "enabled": true
            },
            {
                "id": "clock",
                "enabled": true
            },
            {
                "id": "statusIcons",
                "enabled": true
            },
            {
                "id": "power",
                "enabled": true
            },
            {
                "id": "idleInhibitor",
                "enabled": false
            }
        ],
        "persistent": false,
        "showOnHover": true,
        "status": {
            "showAudio": false,
            "showBattery": true,
            "showBluetooth": true,
            "showMicrophone": false,
            "showKbLayout": false,
            "showNetwork": true
        },
        "tray": {
            "background": true,
            "recolour": true
        },
        "workspaces": {
            "activeIndicator": true,
            "activeLabel": "󰮯",
            "activeTrail": false,
            "groupIconsByApp": true,
            "groupingRespectsLayout": true,
            "windowRighClickContext": true,
            "label": "◦",
            "occupiedBg": true,
            "occupiedLabel": "⊙",
            "showWindows": true,
            "shown": 4,
            "windowIconImage": true,
            "focusedWindowBlob": true,
            "windowIconGap": 0,
            "windowIconSize": 30
        }
    },
    "border": {
        "rounding": 25,
        "thickness": 10
    },
    "dashboard": {
        "mediaUpdateInterval": 500,
        "showOnHover": true
    },
    "launcher": {
        "actionPrefix": ">",
        "dragThreshold": 50,
        "vimKeybinds": false,
        "enableDangerousActions": false,
        "maxShown": 8,
        "maxWallpapers": 9,
        "specialPrefix": "@",
        "useFuzzy": {
            "apps": false,
            "actions": false,
            "schemes": false,
            "variants": false,
            "wallpapers": false
        },
        "showOnHover": false
    },
    "lock": {
        "recolourLogo": false
    },
    "notifs": {
        "actionOnClick": false,
        "clearThreshold": 0.3,
        "defaultExpireTimeout": 5000,
        "expandThreshold": 20,
        "expire": false
    },
    "osd": {
        "enabled": true,
        "enableBrightness": true,
        "enableMicrophone": true,
        "hideDelay": 2000
    },
    "paths": {
        "mediaGif": "root:/assets/bongocat.gif",
        "sessionGif": "root:/assets/kurukuru.gif",
        "wallpaperDir": "~/Pictures/Wallpapers"
    },
    "services": {
        "audioIncrement": 0.1,
        "defaultPlayer": "Spotify",
        "gpuType": "",
        "playerAliases": [
            {
                "from": "com.github.th_ch.youtube_music",
                "to": "YT Music"
            }
        ],
        "weatherLocation": "",
        "useFahrenheit": false,
        "useTwelveHourClock": false,
        "smartScheme": true,
        "visualiserBars": 45
    },
    "session": {
        "dragThreshold": 30,
        "vimKeybinds": false,
        "commands": {
            "logout": [
                "loginctl",
                "terminate-user",
                ""
            ],
            "shutdown": [
                "systemctl",
                "poweroff"
            ],
            "hibernate": [
                "systemctl",
                "hibernate"
            ],
            "reboot": [
                "systemctl",
                "reboot"
            ]
        }
    }
}

```

</details>

<details><summary> <b> Example Nix Home Manager </b></summary>

I don't have nix, plz help :D

```nix
{
  programs.niri-caelestia-shell = {
    enable = true;
    with-cli = true;
    settings.theme.accent = "#ffb86c";
  };
}
```

</details>

### 🎭 PFP/Wallpapers
The profile picture for the dashboard is read from the file `~/.face`, so to set
it you can copy your image to there or set it via the dashboard. **It's not a directory.**

The wallpapers for the wallpaper switcher are read from `~/Pictures/Wallpapers`
by default. To change it, change the wallpapers path in `~/.config/caelestia/shell.json`.

To set the wallpaper, you can use the app launcher command `> wallpaper`.


---

## 🧪 Known Issues

1. Multi-monitor support is currently hardcoded :(
2. Task manager has no Intel GPU support.
3. Workspace bar needs refactoring at the moment.
4. Picker (screenshot tool) window grabbing is WIP due to Niri limitations.
5. Focus grabbing for Quickshell windows (power menu, task manager, settings) behaves awkwardly because of Niri limitations.
6. Quickshell may occasionally crash because of upstream issues (it re-opens automagically)
7. I'm not happy that you have to build it to be able to use it, so I might revert.
8. Some dependencies aren't actually required but I keep them because the original repo still has them.
9. I haven't touched theming, be cautious.

---

## ❓ FAQ

**Q: Can I theme it?**
A: Yes, via `shell.json` (or Nix options if you use Home Manager).

**Q: Why does my task manager Intel GPU messed-up?**
A: GPU monitoring is limited; Intel isn’t supported yet.

**Q: Why does it take so long for you to update?**
A: Civil unrest in my country 😥

---

## 🙏 Credits

* [Quickshell](https://github.com/quickshell/quickshell) – Core shell framework
* [Caelestia](https://github.com/caelestia-shell/caelestia-shell) – Original project
* [Niri](https://github.com/YaLTeR/niri) – Window manager backend
* All upstream contributors :)

---

## 📈 Useless chart

[![Star History Chart](https://api.star-history.com/svg?repos=jutraim/niri-caelestia-shell\&type=Date)](https://star-history.com/#jutraim/niri-caelestia-shell&Date)
