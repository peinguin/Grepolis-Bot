#!/bin/sh
cd /home/scripts/grepolis_bot
./grepolis_bot.pl | /usr/local/bin/ascii2uni -a L >> log 2>/dev/null
