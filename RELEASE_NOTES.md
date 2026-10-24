## armv7 binaries

Готовые бинарники под Яндекс Станцию Мини 2 (32-битный ARM, glibc 2.30).

Распаковать в `bin/` рядом с репозиторием, затем:

```sh
make install-ssh install-fastfetch
```

| Файл | Что | Сборка |
|---|---|---|
| `dropbear`, `dbclient`, `dropbearkey` | SSH-сервер | musl, статический |
| `fastfetch` | баннер при входе | musl, статический |
| `shairport-sync` | AirPlay | glibc 2.28, libconfig/popt статически |
| `spotifyd` | Spotify Connect | glibc 2.28 (если собрался) |

Проверено на прошивке `0.369.1.50.4794659041.20261021.299`.
