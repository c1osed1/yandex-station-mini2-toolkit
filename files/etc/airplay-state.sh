#!/bin/sh
# Пишет состояние AirPlay в /tmp/airplay.state. Вызывается хуками shairport-sync.
case "$1" in
	playing) printf playing > /tmp/airplay.state ;;
	idle)    printf idle    > /tmp/airplay.state ;;
	*) echo "usage: $0 playing|idle" >&2; exit 1 ;;
esac
exit 0
