# Simple Rofi Custom Mode Scripts
A collection of my simple scripts for Rofi with custom keybind controls. These are simple bash scripts with minimal required dependencies. They use String matching mostly, so if you are a fan of weird enearthly naming style, you may face issues. If you are not happy with any part, then modify as you like.

The advantage of these scripts are that, they are all used as custom mode in rofi. They don't call dmenu when executed, the scripts are executed simultaneously while using rofi. So you can use multiple modes and you only run rofi once. You can simply change between next/prev modes by pressing the key combo `Shift + Right/Left Arrow` or circle through modes using `Ctrl + Tab`.

For more information read the Rofi manpages.

# Requirements

***Common Dependency*** - grep sed awk wc nl and other common text formatting tools

***Rofi*** - Rofi v1.6.0 or later, with a well configured theme. An example config is provided too.

***Others*** - mpd mpc dunst[For notification] nmcli wmctrl amixer bspc etc [ Check the scripts to know what are the dependecies ]

# Usage

***Run this in your terminal***
```
rofi -theme 'path to theme' -columns 3 -modi 'mode_name':'path to mode script' -show 'mode_name' -kb-custom-1 "KB-1" -kb-custom-2 "KB-2" kb-custom-3 "KB-3"
```

### Mpd-Manager
1. Mpd manager uses 3 custom keybinds to manage playlist and toggle music play/pause.
   - Custom Keybinding 1 - Add the song of the currently selected row to the current playlist.
   - Custom Keybinding 2 - Delete the song of the currently selected row from the current playlist.
   - Custom Keybinding 3 - Toggle Play/Pause.
```
rofi -theme $HOME/rofi/example.rasi -columns 3 -modi Music:$HOME/scripts/rofi-mpd-manager.sh -show Music -kb-custom-1 "Alt+a" -kb-custom-2 "Alt+d" kb-custom-3 "Alt+t"
```

![mpd-manager](/Screenshots/mpd-manager-1.png)

### Wifi-Manager

```
rofi -theme $HOME/rofi/example.rasi -modi "Wifi:$HOME/scripts/rofi-wifi-manager.sh" -show Wifi
```

![wifi-manager](/Screenshots/wifi-manager-1.png)

### Process-Manager

```
rofi -theme $HOME/rofi/example.rasi -modi "ps:$HOME/scripts/rofi-process-manager.sh" -show ps
```

# How to run multiple modes at once ?
```
rofi -theme $HOME/rofi/example.rasi -columns 3 \
-modi "Music:$HOME/scripts/rofi-mpd-manager.sh",\
"Wifi:$HOME/scripts/rofi-wifi-manager.sh" \
-show Music \
-kb-custom-1 "Alt+a" \
-kb-custom-2 "Alt+d" \
-kb-custom-3 "Alt+t"
```
