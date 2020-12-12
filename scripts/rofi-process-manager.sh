#!/bin/sh

if [ -z "${ROFI_OUTSIDE}" ] # Exit if script is running outside rofi
then
    echo "run this script in rofi".
    exit
fi

CACHE_DIR="$HOME/.cache/rofi/process"
[ ! -d $CACHE_DIR ] && mkdir -p "$CACHE_DIR"

function show_process() {
	echo -en "\00prompt\x1fProcess\n"
	echo -en "\0message\x1f    ID : CPU : MEM : Process Name\t\t\t\t\t[KB-1] - To kill a process\n"
	ps k -start_time -U $UID --no-headers -o pid,%cpu,rss,args
}

if [[ "${ROFI_RETV}" == "0" ]]; then
	rm $CACHE_DIR/* >/dev/null 2>&1
	show_process

elif [[ "${ROFI_RETV}" == "1" ]]; then
	if [[ "$@" == "<|=- [GO BACK]" ]]; then
		rm $CACHE_DIR/*
		show_process

	elif [ ! -f $CACHE_DIR/pid ]; then
		pid=$(echo "$@" | awk '{ print $1 }' | xargs)
		echo "$pid" > "$CACHE_DIR/pid"
		echo "<|=- [GO BACK]"
		echo -en "\00prompt\x1fProcess Details\n"
		echo -en "\0message\x1f\t\t\t\t\t[KB-1] - To kill a process\n"
		cat /proc/"$pid"/status
	fi

elif [[ "$ROFI_RETV" == "10" ]]; then
	if [ ! -f $CACHE_DIR/pid ]; then
		pid=$(echo "$@" | awk '{ print $1 }' | xargs)
		kill "$pid"

	elif [ -f $CACHE_DIR/pid ]; then
		pid=$(cat "$CACHE_DIR/pid")
		kill "$pid"
	fi
	show_process
fi
