## armv7 binaries

Готовые бинарники под Яндекс Станцию Мини 2 (32-битный ARM, glibc 2.30).

Распаковать в `bin/` рядом с репозиторием, затем:

```sh
make install-ssh install-fastfetch install-spotifyd
```

| Файл | Что | Сборка | Проверено на станции |
|---|---|---|---|
| `dropbear`, `dbclient`, `dropbearkey` | SSH-сервер | musl, статический | да |
| `fastfetch` | баннер при входе | musl, статический | да |
| `spotifyd` | Spotify Connect (OAuth) | glibc 2.28, Rust 1.85 | да |
| `shairport-sync` | AirPlay | glibc 2.28, libconfig/popt статически | да |

Проверено на прошивке `0.369.1.50.4794659041.20261021.299`.

### Особенности сборки

- **musl не подходит для всего**: `shairport-sync` и `spotifyd` собираются под glibc 2.28,
  иначе на ядре 4.9 падают по `clock_gettime64` (см. `docs/FINDINGS.md`).
- **spotifyd** требует Rust 1.85+ (в lock-файле есть crate с `edition2024`), а также
  `cmake`, `clang`/`libclang-dev` (для `aws-lc-sys`) и `nasm`.
- **rustup в buster не работает** — старые корневые сертификаты. Rust ставится из tarball.
