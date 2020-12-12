#!/bin/sh

# Requirements #
# rofi mpc mpd dunst 

# Launch Command #
# rofi -modi mpd:path_to_this_script -show mpd -theme path_to_theme \
# -columns 3 -kb-custom-1 "Alt+a" -kb-custom-2 "Alt+d" -kb-custom-3 "Alt+t"
# KB-1 - Alt+a
# KB-2 - Alt+d
# KB-3 - Alt+t

[ -z "${ROFI_OUTSIDE}" ] && echo "run this script in rofi" && exit # Exit if running outside rofi

CACHE_DIR="$HOME/.cache/rofi/music"
CONFIG_DIR="$HOME/.cache/rofi/config"

[ ! -d $CACHE_DIR ] && mkdir -p "$CACHE_DIR"
[ ! -d $CONFIG_DIR ] && mkdir -p "$CONFIG_DIR"

if [ -f $CONFIG_DIR/mpd_history ]; then
    HISTORY_MODE=1
else
    HISTORY_MODE=0
fi

function help() { # Prints help menu
    echo "<|=- [ To Previous Menu ]"
    echo ":save <playlist_name> = Save current playlist as new playlist with provided name"
    echo ":volume <{+/-}num> = Increase/Decrease volume [Example: : volume -10 = Decrease volume by 10"
    echo ":history on/off = Turn On/Off History mode [Start where left last time]"
    echo "/play = Play/Resume music"
    echo "/pause = Pause music"
    echo "/stop = Stop playing"
    echo "/toggle = Toggle Play/Pause"
    echo "/shuffle = Shuffle current playlist"
    echo "/repeat on/off = Turn On/Off Repeat mode"
    echo "/random on/off = Turn On/Off Random mode"
    echo "/consume on/off = Turn On/Off Consume mode"
    echo "/single on/off = Turn On/Off Consume mode"
    echo "/help = Print this menu"
}

function music_stat(){ # Information of Currently playing and queued songs. Shown as a Message inside Rofi 
	current_playing="$(mpc current | tr -d "&")"
	next_song="$(mpc queued | tr -d "&")"
    other_stats="$(mpc status | sed '$!d')"
	if [[ $(mpc status | sed '2!d' | awk '{print $1}') == "[playing]" ]]; then
		music_status="[PLAYING]\t[NOW] : $(echo ${current_playing:0:35})\t\t[NEXT] : $(echo ${next_song:0:40})"
	else
		music_status="[PAUSED]\t[NOW] : $(echo ${current_playing:0:35})\t\t[NEXT] : $(echo ${next_song:0:40})"
	fi
}

function main_scrn() { # Main window on start
	rm $CACHE_DIR/* >/dev/null 2>&1 # Clear cache directory
	music_stat
    mpc -q update
	echo -en "\x00prompt\x1fMusic\n" # Change the Prompt entry in rofi
	echo -en "\0message\x1f$music_status\n" # Show a message inside rofi
    echo -en "\t\t\t\t$(echo ${other_stats^^})\0nonselectable\x1ftrue\n" # This prints a non-selectable line
    echo "-=|> Current Playlist"
    echo "-=|> Sort by Titles"
    echo "-=|> Sort by Albums"
	echo "-=|> Sort by Artists"
    echo "-=|> Manage Saved Playlists"
}

function show_current_playlist() { # Show all songs in current playlist
    echo -en "\x00prompt\x1fCurrent Playlist\n"
    echo -en "\0message\x1f\t\t[Enter] - Play slected song\t\t\t[KB-2] - Remove selected song from playlist\n"
    echo "none" > "$CACHE_DIR/current_playlist"
    echo "<|=- [ To Previous Menu ]"
    echo "-=|> [ CLEAR PLAYLIST ]"
    mpc playlist | nl # List songs with position no
    if [[ $(mpc status | sed '2!d' | awk '{print $1}') == "[playing]" ]]; then
        echo -en "\0active\x1f$(($(mpc current -f %position%)+1))\n" # Mark currently playing song as active row in rofi 
    fi
}

function show_artists() { # List artists available
    echo -en "\x00prompt\x1fArtists\n"
    echo -en "\0message\x1f\t\t[Enter] : See Albums of selected Artist\t\t[KB-1] : Add Artist to current Playlist\n"
    echo "none" > "$CACHE_DIR/select_artist"
    echo "<|=- [ To Previous Menu ]"
    mpc list Artist | sort
}

function show_albums() { # List albums available
    echo -en "\0message\x1f\t\t[Enter] : See Titles of selected Album\t\t[KB-1] : Add Album to current Playlist\n"
    echo "<|=- [ To Previous Menu ]"
    if [ -f $CACHE_DIR/select_artist ]; then
        echo "none" > "$CACHE_DIR/select_album"
        rm $CACHE_DIR/select_artist
        echo -en "\x00prompt\x1f$artist\n"
        mpc list Album Artist "$artist" | sort
    elif [ -f $CACHE_DIR/artist_selected ]; then
        artist=$(cat "$CACHE_DIR/artist_selected")
        echo "none" > "$CACHE_DIR/select_album"
        echo -en "\x00prompt\x1f$artist\n"
        mpc list Album Artist "$artist" | sort
    else
        echo "none" > "$CACHE_DIR/select_album"
        echo -en "\x00prompt\x1fAlbums\n"
        mpc list Album | sort
    fi
}

function show_titles() { # List titles available
    echo -en "\0message\x1f\t\t[Enter] : Play selected Title\t\t[KB-1] : Add Title to current Playlist\n"
    echo "<|=- [ To Previous Menu ]"
    if [ -f $CACHE_DIR/select_album ]; then
        echo "none" > "$CACHE_DIR/select_title"
        rm $CACHE_DIR/select_album
        echo -en "\x00prompt\x1f$album\n"
        mpc list Title Album "$album" | sort
    elif [ -f $CACHE_DIR/album_selected ]; then
        album=$(cat "$CACHE_DIR/album_selected")
        echo -en "\x00prompt\x1f$album\n"
        mpc list Title Album "$album" | sort
    else
        echo "none" > "$CACHE_DIR/select_title"
        echo -en "\x00prompt\x1fTitles\n"
        mpc list Title | sort
    fi
}

function show_saved_playlists() { # Show all saved playlists
    echo -en "\0message\x1f[Enter] : Play selected playlist\t[KB-1] : Add selected playlist to current playlist\t[KB-2] : Delete selected playlist\n"
    echo -en "\x00prompt\x1fAll Playlists\n"
    echo "<|=- [ To Previous Menu ]"
    echo "none" > "$CACHE_DIR/select_playlist"
    mpc -q update
    mpc lsplaylists | sed '/.m3u/d' # Remove duplicate entries
}

function add_artist() {
    mpc -q findadd Artist "$artist"
    notify-send "MPD added Artist " "$artist"
}

function add_album() {
    mpc -q findadd Album "$album"
    notify-send "MPD added Album " "$album"
}

function restore_view() {
    if [ -f $CACHE_DIR/select_artist ]; then
        show_artists
    elif [ -f $CACHE_DIR/select_album ]; then
        show_albums
    elif [ -f $CACHE_DIR/select_title ]; then
        show_titles
    elif [ -f $CACHE_DIR/current_playlist ]; then
        show_current_playlist
    elif [ -f $CACHE_DIR/select_playlist ]; then
        show_saved_playlists
    else
        main_scrn
    fi
}

function show_previous_menu() {
    if [ -f $CACHE_DIR/select_title ]; then
        if [ -f $CACHE_DIR/album_selected ]; then
            rm $CACHE_DIR/select_title
            rm $CACHE_DIR/album_selected
            show_albums
        else
            main_scrn
        fi
    elif [ -f $CACHE_DIR/select_album ]; then
        if [ -f $CACHE_DIR/artist_selected ]; then
            rm $CACHE_DIR/*
            show_artists
        else
            main_scrn
        fi
    else
        main_scrn
    fi

}

if [[ "${ROFI_RETV}" == "0" ]]; then
    if [ "$HISTORY_MODE" = 1 ]; then
        restore_view
    else
        main_scrn
    fi

elif [[ "${ROFI_RETV}" == "1" ]]; then
    if [[ "$@" == "<|=- [ To Previous Menu ]" ]]; then
        show_previous_menu
    
    elif [[ "$@" == "-=|> [ CLEAR PLAYLIST ]" ]]; then
        mpc -q clear
        restore_view

    elif [[ "$@" == "-=|> Current Playlist" ]]; then
        show_current_playlist
    
    elif [[ "$@" == "-=|> Sort by Titles" ]]; then
        show_titles

    elif [[ "$@" == "-=|> Sort by Albums" ]]; then
        show_albums

    elif [[ "$@" == "-=|> Sort by Artists" ]]; then
        show_artists

    elif [[ "$@" == "-=|> Manage Saved Playlists" ]]; then
        show_saved_playlists

    elif [ -f $CACHE_DIR/current_playlist ]; then
        mpc -q play $(echo "$@" | awk '{print $1}' | xargs) && notify-send "MPD Playing " "$(mpc current)"
        exit 0

    elif [ -f $CACHE_DIR/select_artist ]; then
        artist="$@"
        echo "$artist" > "$CACHE_DIR/artist_selected"
        show_albums

    elif [ -f $CACHE_DIR/select_album ]; then
        album="$@"
        echo "$album" > "$CACHE_DIR/album_selected"
        show_titles
    
    elif [ -f $CACHE_DIR/select_title ]; then
        mpc -q clear
        mpc -q findadd Title "$@"
        mpc -q play
        notify-send "MPD Playing " "$(mpc current)"
        exit 0

    elif [ -f $CACHE_DIR/select_playlist ]; then
        mpc -q clear
        mpc -q load "$@" >/dev/null 2>&1
        mpc -q play
        notify-send "MPD Playing " "$@"
        exit 0

    fi

elif [[ "${ROFI_RETV}" == "2" ]]; then
    if [[ "$@" =~ "/" ]]; then
        case "$@" in
            "/help") help ;;
            "/play") mpc -q play && restore_view ;; 
            "/pause") mpc -q pause && restore_view ;;
            "/stop") mpc -q stop && restore_view ;;
            "/toggle") mpc -q toggle && restore_view ;;
            "/shuffle") mpc -q shuffle && restore_view ;;
            "/repeat on") mpc -q repeat on && restore_view ;;
            "/repeat off") mpc -q repeat off && restore_view ;;
            "/random on") mpc -q random on && restore_view ;;
            "/random off") mpc -q random off && restore_view ;;
            "/single on") mpc -q single on && restore_view ;;
            "/single off") mpc -q single off && restore_view ;;
            "/consume on") mpc -q consume on && restore_view ;;
            "/consume off") mpc -q consume off && restore_view ;;
            *) restore_view ;;
        esac
    elif [[ "$@" =~ ":" ]]; then
        if [[ "$@" =~ ":save" ]]; then
            pl_name=$(echo "$@" | cut -c 7-)
            mpc -q save "$pl_name" >/dev/null 2>&1
            restore_view
        elif [[ "$@" =~ ":volume" ]]; then
            vol=$(echo "$@" | cut -c 9-)
            mpc -q volume "$vol" >/dev/null 2>&1
            restore_view
        elif [[ "$@" =~ ":history" ]]; then
            mode="$(echo "$@" | awk '{print $2}' | xargs)"
            if [[ "$mode" == "off" ]]; then
                rm $CONFIG_DIR/mpd_history >/dev/null 2>&1
                notify-send "History mode " "Disabled"
            elif [[ "$mode" == "on" ]]; then
                echo "enabled" > "$CONFIG_DIR/mpd_history"
                notify-send "History mode " "Enabled"
            fi
            restore_view
        else
            restore_view
        fi
    else
        notify-send "For help " "/help"
        restore_view
    fi

elif [[ "${ROFI_RETV}" == "10" ]]; then
    if [ -f $CACHE_DIR/select_artist ]; then
        artist="$@"
        add_artist
        restore_view

    elif [ -f $CACHE_DIR/select_album ]; then
        album="$@"
        add_album
        restore_view

    elif [ -f $CACHE_DIR/select_title ]; then
        mpc -q findadd Title "$@"
        notify-send "MPD added Title " "$@"
        restore_view
    
    elif [ -f $CACHE_DIR/select_playlist ]; then
        mpc -q load "$@" >/dev/null 2>&1
        notify-send "MPD added playlist" "$@"
        restore_view

    else 
        restore_view
    fi

elif [[ "${ROFI_RETV}" == "11" ]]; then
    if [ -f $CACHE_DIR/current_playlist ]; then
        pos=$(echo "$@" | awk '{print $1}' | xargs)
        if [ "$pos" -gt 0 ] 2>/dev/null; then
            mpc -q del "$pos"
            notify-send "Removed from Playlist " "$(echo "$@" | awk '{ $1=""; print substr($0,2) }' )"
        fi
        restore_view

    elif [ -f $CACHE_DIR/select_playlist ]; then
        if [[ "$(mpc lsplaylists | grep -o -m 1 "$@")" == "$@" ]]; then
            mpc -q rm "$@" && notify-send "MPD removed " "$@"
        fi
        restore_view

    else
        restore_view

    fi

elif [[ "${ROFI_RETV}" == "12" ]]; then
    mpc -q toggle
    if [[ $(mpc status | sed '2!d' | awk '{print $1}') == "[playing]" ]]; then
        notify-send "MPD " "Music is now playing!"
    elif [[ -z $(mpc playlist) ]]; then
        notify-send "MPD " "Playlist is empty!"
    else
        notify-send "MPD " "Music is paused!"
    fi
    restore_view

fi
