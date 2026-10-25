#!/bin/sh
# Крошечная утилита для ALSA-микшера: перечислить контролы и выставить значение.
#   mixvol                     — список контролов
#   mixvol set "SPK Master" 128
set -e
OUT="$(cd "$(dirname "$0")/.." && pwd)/bin"; mkdir -p "$OUT"
WORK="$(cd "$(dirname "$0")/.." && pwd)/build"
cat > "$WORK/mixvol.c" <<'C'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <alsa/asoundlib.h>
int main(int argc, char **argv) {
    snd_mixer_t *m;
    if (snd_mixer_open(&m, 0) < 0) return 1;
    if (snd_mixer_attach(m, "hw:0") < 0) return 1;
    if (snd_mixer_selem_register(m, NULL, NULL) < 0) return 1;
    if (snd_mixer_load(m) < 0) return 1;
    if (argc >= 4 && strcmp(argv[1], "set") == 0) {
        long v = atol(argv[3]);
        for (snd_mixer_elem_t *e = snd_mixer_first_elem(m); e; e = snd_mixer_elem_next(e)) {
            if (strcmp(snd_mixer_selem_get_name(e), argv[2]) != 0) continue;
            snd_mixer_selem_set_playback_volume_all(e, v);
            printf("%s=%ld\n", argv[2], v);
            snd_mixer_close(m);
            return 0;
        }
        fprintf(stderr, "нет контрола %s\n", argv[2]);
        return 3;
    }
    for (snd_mixer_elem_t *e = snd_mixer_first_elem(m); e; e = snd_mixer_elem_next(e)) {
        if (!snd_mixer_selem_is_active(e)) continue;
        printf("%-28s", snd_mixer_selem_get_name(e));
        if (snd_mixer_selem_has_playback_volume(e)) {
            long mn, mx, cur;
            snd_mixer_selem_get_volume_range(e, NULL, NULL);
            snd_mixer_selem_get_playback_volume_range(e, &mn, &mx);
            snd_mixer_selem_get_playback_volume(e, SND_MIXER_SCHN_FRONT_LEFT, &cur);
            printf("  %ld..%ld cur=%ld", mn, mx, cur);
        }
        printf("\n");
    }
    snd_mixer_close(m);
    return 0;
}
C
docker run --rm --platform linux/arm/v7 -v "$(dirname "$0")/..:/w" rust185-full:1 sh -c '
apt-get install -y -qq libasound2-dev >/dev/null 2>&1
cd /w && gcc -O2 -o bin/mixvol build/mixvol.c -lasound && strip bin/mixvol
'
ls -l "$OUT/mixvol"
