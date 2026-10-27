# Как устроена прошивка

Коротко о том, что запускается на колонке и как это устроено. Нужно, чтобы понимать, куда
вмешиваться, а куда не стоит.

## Загрузка

Buildroot, обычный BusyBox init. `/etc/inittab` поднимает `/proc`, `/dev/pts`, `/dev/shm`,
задаёт hostname и запускает `/etc/init.d/rcS`, а тот выполняет `S??*` по алфавиту:

```
S00hostname  S01rw-dirs  S01syslogd  S01watchdog  S02klogd  S02sysctl  S10mdev
S20urandom  S30dbus  S40dhcpcd-db  S40net.lo  S40wifi  S41dhcpcd  S45tas58xx
S49chrony  S49teeinit  S50hci0  S51bluetoothd  S52bluealsa  S53bluealsa-aplay
S54default-bluez-agent  S70unbound  S98pstore-clear  S99quasar
```

Отсюда правило: наши сервисы ставим как `S99*`, они поднимаются последними. И помним, что
`rcS` запускает **все** файлы, начинающиеся с `S`, независимо от расширения — переименовать
`S99foo` в `S99foo.off` не значит отключить, значит «запустить и попробовать передать ему
аргумент `.off`».

## Запуск Яндекса

`S99quasar` → `/system/vendor/quasar/onboot.sh start`:

1. `overcommit_memory = 1`;
2. чистит остатки OTA в `/bkupgrade/`;
3. выставляет `LD_LIBRARY_PATH` и `GST_PLUGIN_PATH` на `/system/vendor/quasar[/libs]`;
4. `activate_adb.sh check` — поднимает `adbd`, если в `/data/quasar/` есть маркеры;
5. `run.sh`: `ulimit -n 10240`, `ulimit -s 1024`, затем
   `quasar_launcher2 /system/vendor/quasar/launch.json`.

## Один бинарь — много ролей

Почти весь стек Яндекса — это `/system/vendor/quasar/maind`, запущенный с разными ключами:

| Роль | Что делает |
|---|---|
| `--platformd` | основной процесс: кнопки, кольцо, LED-часы, mDNS |
| `--mediad` | плеер: ответы Алисы и музыка, вывод в ALSA |
| `--telemetry` | телеметрия |
| `--fluent-bitd` | логи |
| `--updatesd` | обновления, отсюда растут ноги у отключения OTA |
| `--updater_gateway` | шлюз обновлятора через unix-сокет `/tmp/updater.sock` |

На тот же бинарь есть симлинки: `led_util`, `tcp_alsa_writer`, `keymaster_proxy_app`,
`quasar_client`. Поведение зависит от имени, под которым его запустили.

Есть и служебные ключи вроде `--getprop`. Осторожно: `--getprop ro.product.cpu.abi` отвечает
`arm64-v8a`, но это **захардкоженная строка**, а не правда — сам `maind` собран под ARM32,
как и весь userspace. Из-за этого легко поставить «правильную» 64-битную сборку и удивляться.

## Директивы: чем сервер управляет колонкой

Облако присылает не просто текст ответа, а набор директив, которые раскладываются по
capabilities. Живут два поколения:

- **легаси** — `google.protobuf.Struct` в `TDirective.Payload`, ключи `snake_case`:
  `sound_set_level {new_level, new_percent_level}`, `sound_louder`, `sound_quiter`,
  `sound_mute`, `player_pause {smooth:false}`, `player_continue`, `player_next_track`,
  `player_previous_track`, `start_bluetooth`, `stop_bluetooth`, таймеры;
- **typed** — сериализованный proto в `TDirective.PayloadRaw` плюс номер в `DirectiveType`.
  `maind` собран с protobuf-lite, без рефлексии, поэтому Struct в typed-директиву не
  превратить — формат нужен ровно тот, что ждут.

Шкала громкости в директивах — **0–10**, а не 0–255 как в ALSA.

## Конфиги и логи

| Что | Где |
|---|---|
| конфиг стека | `/system/vendor/quasar/quasar.cfg` |
| список запускаемых ролей | `/system/vendor/quasar/launch.json` |
| версия | `/system/vendor/quasar/VERSION` (у нас `3.21`) |
| логи демонов | `/data/quasar/daemons_logs/` (`maind.log`, `mediad.log`, `yiod.log`) |
| причина последней перезагрузки | `/sys/class/aml_info/reboot_reason` |
| паттерны кольца | `/system/vendor/quasar/ledpatterns/oknix/*.led` |
| модели распознавания | `/system/vendor/quasar/spotter_models/`, `bio_lingware/` |

`pstore` стирается при обычной загрузке (`S98pstore-clear`), так что лог ядра после падения
ловить нужно вживую: `cat /proc/kmsg`.

## Голосовой тракт

Локально на устройстве работают только wake-word («Алиса»/«Яндекс») и порядка двух десятков
коротких команд. Всё остальное — распознавание и понимание — в облаке через
`wss://uniproxy.alice.yandex.net/uni.ws`. Поэтому «поймать» произвольную фразу локально
нельзя: либо снимать сырой микрофон и распознавать самому, либо подменять облако.
