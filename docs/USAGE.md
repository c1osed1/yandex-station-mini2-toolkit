# Как пользоваться

Практическая шпаргалка: что уже стоит на колонке и как этим пользоваться каждый день.

## Вход

```sh
ssh alisa-2          # ключ ~/.ssh/id_alisa2, баннер с логотипом
adb connect 192.168.1.94:5555
adb shell            # root
```

Пароля нет ни там, ни там: SSH — только по ключу, ADB — вообще без авторизации, поэтому
наружу порты не пробрасывать.

Полезное на входе:

```sh
cat /system/vendor/quasar/VERSION          # версия quasar
tail -5 /data/quasar/daemons_logs/maind.log
cat /sys/class/aml_info/reboot_reason      # почему перезагружалась
awk '{printf "%.0f C\n", $1/1000}' /sys/class/thermal/thermal_zone0/temp
```

## AirPlay

На Mac или iPhone: «Пункт управления» → AirPlay → **Яндекс Станция Мини 2**. Звук идёт
в динамик колонки, Алиса на время сессии молчит и возвращается после остановки.

Громкость общая: ползунок AirPlay пишет в `SPK Master`, а голос Алисы и кнопки — в `Master`,
который демон `volmirror` переносит туда же. То есть «Алиса, громкость пять» меняет и AirPlay.

```sh
ssh alisa-2 /etc/init.d/S99shairport restart   # если приёмник пропал
ssh alisa-2 'tail -5 /tmp/shairport.log'       # если не играет
```

Задержка около 0.5 с, правится в `/etc/shairport-sync.conf`
(`audio_backend_latency_offset_in_seconds`, сейчас `-1.5`).

## Свои звуки

Штатный GStreamer внутри `maind`, звук идёт в тот же ALSA, что у Алисы, и регулируется её
громкостью. Ничего не надо освобождать и убивать.

```sh
scripts/play-sound.sh chime.wav
scripts/play-sound.sh --url http://example.com/stream.mp3
```

Или прямо на колонке:

```sh
cd /system/vendor/quasar
LD_LIBRARY_PATH=/system/vendor/quasar:/system/vendor/quasar/libs ./maind --gst-launch \
  "filesrc location=/data/sounds/chime.wav ! decodebin ! audioconvert ! audioresample ! alsasink"
```

## Кольцо

Анимации — обычные текстовые файлы, их проигрывает штатный стек. Формат: `loop`, дальше кадры
по шесть цветов (по числу зон) и длительность в миллисекундах.

```sh
scripts/led-pattern.sh list
scripts/led-pattern.sh pull alice_listening > original.led
scripts/led-pattern.sh install alice_listening my.led
scripts/led-pattern.sh restore alice_listening
```

Перед заменой файл копируется в `/data/led-backup/`. Если анимация не обновилась сразу —
прошивка держит паттерны в памяти, нужен перезапуск стека или перезагрузка.

## Громкость из командной строки

```sh
mixvol                                  # список контролов
mixvol set "SPK Master" 120             # реальная громкость
mixvol set Master 200                   # то, что видит Алиса и индикатор
```

Помнить: влияет на звук только `SPK Master`. `Master` — интерфейс для кнопок.

## Обновления

`updatesd` вырезан из `launch.json`, OTA не приезжает. Проверить:

```sh
grep -c updatesd /system/vendor/quasar/launch.json   # 0
```

Вернуть автообновления — вернуть запись в `launch.json` и перезагрузиться. Только учитывайте:
на прошивке новее `.46` активация ADB уже не пройдёт, а гард ADB останется.

## Bluetooth

```sh
scripts/bt-pair.sh --list                 # что видно
scripts/bt-pair.sh AA:BB:CC:DD:EE:FF      # сопрячь, проверить A2DP
```

Работает только как приёмник (телефон стримит на колонку). Отдать музыку на внешнюю
BT-колонку не выходит: транспорт A2DP не захватывается. Сопряжение не сохраняется после
перезагрузки колонки. Подробности — [BLUETOOTH.md](BLUETOOTH.md).

## Откат всего

```sh
scripts/uninstall.sh                       # снять SSH, баннер, AirPlay, volmirror
ssh alisa-2 /etc/init.d/S99statusd stop    # если остался демон индикатора
```

Root ADB, отключённые обновления и гард ADB снимаются отдельно, командой
`make restore-adb` / `make restore-updates` из инструмента, которым активировали ADB.
