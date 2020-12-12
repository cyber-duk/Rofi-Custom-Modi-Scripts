#!/bin/sh

[ -z "${ROFI_OUTSIDE}" ] && echo "run this script in rofi" && exit # If not running inside rofi, exit.

# Create a cache directory to store temporary files
CACHE_DIR="$HOME/.cache/rofi/System"
[ ! -d $CACHE_DIR ] && mkdir -p "$CACHE_DIR"

date="$(date +"%I:%M %A, %d %B" )"
battery_state="$(cat /sys/class/power_supply/BAT0/status)"
REM=$(cat /sys/class/power_supply/BAT0/energy_now)
FULL=$(cat /sys/class/power_supply/BAT0/energy_full)
PERCENTAGE=$(($REM * 100 / $FULL))
battery_status=$(echo "$PERCENTAGE%, $battery_state")
volume=$(amixer -D pulse sget Master | grep 'Left:' | awk -F'[][]' '{ print $2 " ["$4"]"}')
volume_status="$(echo ${volume^^})"
mem=$(free -h | grep "Mem" | awk '{print$3"/"$2}')
network_state="$(nmcli connection show --active | sed '1d' |  awk '{ print $NF }')"
active_windows="$(wmctrl -l | wc -l)"
occupied_desks="$(bspc query -D -d .occupied --names)"
focused_desk="$(bspc query -D -d .focused --names)"

function mpc_stat(){
	current_playing="$(mpc current)"
	next_song="$(mpc queued)"
	if [[ ! -z $(mpc status | grep -n '\[playing\]') ]]; then
		music_status="[PLAYING]\t\tCURRENT : $(echo ${current_playing:0:30})\t\tNEXT : $(echo ${next_song:0:35})"
	else
		music_status="[PAUSED]\t\tCURRENT : $(echo ${current_playing:0:30})\t\tNEXT : $(echo ${next_song:0:35})"
	fi
}

# Outputs System information
function main_scrn() {
	rm $CACHE_DIR/* >/dev/null 2>&1
	echo -en "\x00prompt\x1fSystem\n" # This changes the Rofi Inputbar header text
	mpc_stat
	echo -en "[WINDOW]\t\t$active_windows Active Windows\n"
	echo -en "[DESKTOP]\t\tFOCUSED : [$focused_desk]\t\t\t\t\tOCCUPIED : [ $(echo $occupied_desks | xargs) ]\n"
	echo -en "\0message\x1f  $date      <b>BAT</b> : $battery_status      <b>VOL</b> : $volume_status      <b>MEM</b> : $mem      <b>NET</b> : $network_state\n"
	echo -en "$music_status\n"
	echo ">> [WIFI MANAGER]"
	echo ">> [LOGOUT]"
}

function help() {
	echo -en "\x00prompt\x1fHelp\n" # This changes the Rofi Inputbar header text
	echo "/run [cmd] - Run a command."
	echo "/open [file/dir/link] - Open a file/directory/website (Requires xdg-open)."
    echo "/search [string] - Search string online. Result shown in browser (Requires firefox)."
    echo "/nvrun [cmd] - Run program with dgpu. For Prime-Run(Prime Offloading) users (Requires prime-run)."
}


if [[ "${ROFI_RETV}" == "0" ]]; then
	main_scrn

elif [[ "${ROFI_RETV}" == "1" ]]; then
	if [[ "$1" == "<- [To Main Menu]" ]]; then
		main_scrn
	elif [[ "$1" =~ "[DESKTOP]" ]] && [[ "$1" =~ "FOCUSED :" ]] && [[ "$1" =~ "OCCUPIED :" ]]; then # Open the Rofi Desktop Switcher interface
		echo -en "\x00prompt\x1fDesktops\n"
		for i in $(bspc query -D --names); do
			if [[ "$i" == "$focused_desk" ]]; then
				echo "[F] Switch to Desktop - $i"
			elif [[ "${occupied_desks[*]}" =~ "$i" ]]; then
				echo "[O] Switch to Desktop - $i"
			else
				echo "[ ] Switch to Desktop - $i"
			fi
		done
		echo -en "\0active\x1f$((focused_desk-1))\n"
	elif [[ "$1" =~ "Switch to Desktop - " ]]; then # Switch to the corresponding desktop
		desk=$(echo "$1" | awk '{ print $NF }')
		bspc desktop -f "$desk"
		exit 0
	elif [[ "$1" =~ "CURRENT :" ]] && [[ "$1" =~ "NEXT :" ]] && [[ "$1" =~ ("[PLAYING]"|"[PAUSED]") ]]; then  
		killall rofi && rofi -theme $HOME/.cache/wal/colors-rofi-user.rasi -columns 3 \
		-modi "Music:$XDG_CONFIG_HOME/rofi/scripts/rofi-mpd-manager.sh" -show "Music" \
		-kb-custom-1 "Alt+a" \
		-kb-custom-2 "Alt+d" \
		-kb-custom-3 "Alt+t"
	elif [[ "$1" == ">> [WIFI MANAGER]" ]]; then  
		killall rofi && rofi -theme $HOME/.cache/wal/colors-rofi-user.rasi \
		-modi "Wifi:$XDG_CONFIG_HOME/rofi/scripts/rofi-wifi-manager.sh" -show "Wifi"
	elif [[ "$1" =~ "[WINDOW]" ]] && [[ "$1" =~ "Active Windows" ]]; then # Open Rofi Window mode.
		if [ $(echo "$1" | awk '{ print $2 }') -gt 0 ]; then
			killall rofi && rofi -show window -theme $HOME/.cache/wal/colors-rofi-user.rasi
		else
			main_scrn
		fi
	elif [[ "$1" =~ "[LOGOUT]" ]]; then # Switch to the corresponding desktop
		echo "none" > "$CACHE_DIR/confirmation"
		echo -en "> Are you sure you ?\0nonselectable\x1ftrue\n"
		echo -en "\0urgent\x1f0\n"
		echo -en "[CONFIRM]\n[RETURN]\n"
	elif [ -f $CACHE_DIR/confirmation ]; then
		if [[ "$1" == "[CONFIRM]" ]]; then
			rm $CACHE_DIR/*
			loginctl terminate-user $USER
		else
			rm $CACHE_DIR/confirmation
			main_scrn
		fi
	fi

elif [[ "${ROFI_RETV}" == "2" ]]; then
	if [[ "$@" == "/help" ]]; then
		help
	elif [[ "$@" =~ "/search" ]]; then # Input is used as search input in browser
        input="$(echo "$1" | cut -b 9- | xargs)"
        if [ -z "$input" ]; then
            main_scrn
        else
            if which firefox >/dev/null 2>&1; then
                firefox --new-tab "https://duckduckgo.com/?q=$input" >/dev/null 2>&1 &
                exit 0
            fi
        fi
	elif [[ "$@" =~ "/run" ]]; then # Run any command
		input="$(echo "$1" | cut -b 6- | xargs)"
        if which "$(echo "$input" | awk '{ print $1 }')" >/dev/null 2>&1; then
            $input >/dev/null 2>&1 &
            exit 0
        else
            main_scrn
        fi
	elif [[ "$@" =~ "/nvrun" ]]; then # Run application with dedicated gpu (Ref. - Prime Render Offloading)
		input="$(echo "$1" | cut -b 8- | xargs)"
        if which prime-run >/dev/null 2>&1; then
            if which "$input" >/dev/null 2>&1; then
                prime-run $input >/dev/null 2>&1 &
                exit 0
            fi
        else
            main_scrn
        fi
	elif [[ "$@" =~ "/open" ]]; then # Xdg open shortcut
		input="$(echo "$1" | cut -b 7- | xargs)" 
        if which xdg-open >/dev/null 2>&1; then
            xdg-open "$input" >/dev/null 2>&1 &
            exit 0
        else
            main_scrn
        fi
	else
		main_scrn
	fi

else
	main_scrn

fi
