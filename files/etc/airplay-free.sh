#!/bin/sh
# освобождает ALSA: mediad перезапустится сам и карту не заберёт без нужды
for p in $(ps -o pid,args 2>/dev/null | grep -F "maind --mediad" | grep -v grep | cut -d" " -f1); do
  kill -9 "$p" 2>/dev/null
done
sleep 1
exit 0
