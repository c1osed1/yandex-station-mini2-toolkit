#!/bin/sh
# Проиграть звук на станции через штатный GStreamer (maind --gst-launch).
# Звук идёт в тот же ALSA, что у Алисы, поэтому играет поверх и регулируется её громкостью.
#
#   scripts/play-sound.sh chime.wav
#   scripts/play-sound.sh --url http://example.com/radio.mp3
#   scripts/play-sound.sh --text "Проверка"        # если файла нет — просто подсказка
# shellcheck source=scripts/lib.sh
. "$(dirname "$0")/lib.sh"

connect
dev "mkdir -p /data/sounds"

case "${1:-}" in
	--url)
		[ -n "${2:-}" ] || die "укажите URL"
		say "играю поток $2"
		dev "cd /system/vendor/quasar && LD_LIBRARY_PATH=/system/vendor/quasar:/system/vendor/quasar/libs GST_PLUGIN_PATH=/system/vendor/quasar/libs ./maind --gst-launch 'souphttpsrc location=$2 ! decodebin ! audioconvert ! audioresample ! alsasink' >/tmp/gst.log 2>&1 &"
		;;
	"")
		die "укажите файл или --url"
		;;
	*)
		[ -f "$1" ] || die "нет файла $1"
		name=$(basename "$1")
		say "заливаю $name"
		push "$1" "/data/sounds/$name" 644
		say "играю через gst-launch"
		dev "cd /system/vendor/quasar && LD_LIBRARY_PATH=/system/vendor/quasar:/system/vendor/quasar/libs GST_PLUGIN_PATH=/system/vendor/quasar/libs ./maind --gst-launch 'filesrc location=/data/sounds/$name ! decodebin ! audioconvert ! audioresample ! alsasink' >/tmp/gst.log 2>&1 &"
		;;
esac

sleep 1
dev "tail -2 /tmp/gst.log 2>/dev/null | cut -c1-100"
cat <<TIP

Звук идёт в общий ALSA, громкость — та, что у Алисы. Файлы лежат в /data/sounds.
TIP
