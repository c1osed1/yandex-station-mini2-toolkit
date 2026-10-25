#!/bin/sh
# Анимации кольца на Мини 2: это текстовые файлы .led, их проигрывает штатный стек.
#
#   scripts/led-pattern.sh list
#   scripts/led-pattern.sh pull alice_listening        > alice_listening.led
#   scripts/led-pattern.sh install alice_listening my.led
#   scripts/led-pattern.sh restore alice_listening
#
# Формат кадра: 6 цветов (по числу зон) и длительность в мс, первая строка обычно "loop".
#   loop
#   6b0fff 6b0fff 6b0fff 6b0fff 6b0fff 6b0fff 20
#
# Перед заменой файл копируется в /data/led-backup/, откат — restore или перезагрузка
# (после перепрошивки вернётся штатная версия).
# shellcheck source=scripts/lib.sh
. "$(dirname "$0")/lib.sh"

DIR=/system/vendor/quasar/ledpatterns/oknix
BACKUP=/data/led-backup

case "${1:-}" in
	list)
		connect
		dev "ls $DIR/*.led 2>/dev/null | sed 's|.*/||; s|\.led$||'"
		;;
	pull)
		[ -n "${2:-}" ] || die "укажите имя паттерна (см. list)"
		connect
		"$ADB" -s "$SERIAL" shell "cat $DIR/$2.led" 2>/dev/null || die "нет такого паттерна: $2"
		;;
	install)
		if [ -z "${2:-}" ] || [ -z "${3:-}" ]; then
			die "использование: $0 install <имя> <файл.led>"
		fi
		[ -f "$3" ] || die "нет файла $3"
		connect
		say "сохраняю оригинал в $BACKUP"
		dev "mkdir -p $BACKUP && cp -p $DIR/$2.led $BACKUP/$2.led 2>/dev/null; true"
		say "устанавливаю $3 -> $2.led"
		push "$3" "$DIR/$2.led" 644
		say "готово. Штатный стек проиграет анимацию при следующем событии «$2»."
		;;
	restore)
		[ -n "${2:-}" ] || die "укажите имя паттерна"
		connect
		dev "test -f $BACKUP/$2.led && cp -p $BACKUP/$2.led $DIR/$2.led && echo 'восстановлено' || echo 'бэкапа нет'"
		;;
	*)
		sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'
		;;
esac
