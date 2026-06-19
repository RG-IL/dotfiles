#include <dirent.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/select.h>
#include <sys/time.h>
#include <termios.h>
#include <unistd.h>

#define CACHE_DIR "/Users/raphael/Library/Application Support/anifetch/853f89ec14599865a5f6a9a8a79ad9b7bf592da4ecd4af82cd635c5dc468184c/output"
#define WIDTH 90
#define PAD_LEFT 4
#define GAP 2
#define LINE_W (PAD_LEFT + WIDTH + GAP)
#define TOP 2
#define PLAYBACK_RATE 30

static struct termios orig_term;

static int key_pressed(void) {
    fd_set rfds;
    FD_ZERO(&rfds);
    FD_SET(STDIN_FILENO, &rfds);
    struct timeval tv = {0, 0};
    return select(STDIN_FILENO + 1, &rfds, NULL, NULL, &tv) > 0;
}

int main(void) {
    int pressed = 0;
    tcgetattr(STDIN_FILENO, &orig_term);
    struct termios raw = orig_term;
    raw.c_lflag &= ~(ECHO | ICANON | ISIG);
    raw.c_cc[VMIN] = 0;
    raw.c_cc[VTIME] = 0;
    tcsetattr(STDIN_FILENO, TCSANOW, &raw);
    write(STDOUT_FILENO, "\033[?25l\033[2J\033[H", 10);

    // Fastfetch
    size_t ff_cap = 64, ff_len = 0;
    char **ff = calloc(ff_cap, sizeof(char *));
    FILE *fp = popen("fastfetch --logo none --pipe false 2>/dev/null", "r");
    char buf[4096];
    while (fp && fgets(buf, sizeof(buf), fp)) {
        size_t sl = strlen(buf);
        if (sl > 0 && buf[sl - 1] == '\n') buf[sl - 1] = '\0';
        if (ff_len >= ff_cap) { ff_cap *= 2; ff = realloc(ff, ff_cap * sizeof(char *)); }
        ff[ff_len] = strdup(buf);
        ff_len++;
    }
    if (fp) pclose(fp);
    if (ff_len == 0) { ff[0] = strdup(""); ff_len = 1; }

    // Read cached frames, sorted by numeric index
    DIR *d = opendir(CACHE_DIR);
    if (!d) goto done;
    struct dirent *ent;
    size_t fcap = 512, fcnt = 0;
    char **frames = malloc(fcap * sizeof(char *));
    int *indices = malloc(fcap * sizeof(int));
    while ((ent = readdir(d))) {
        if (ent->d_name[0] < '0' || ent->d_name[0] > '9') continue;
        if (fcnt >= fcap) { fcap *= 2; frames = realloc(frames, fcap * sizeof(char *)); indices = realloc(indices, fcap * sizeof(int)); }
        int idx = atoi(ent->d_name);
        char path[1024];
        snprintf(path, sizeof(path), CACHE_DIR "/%s", ent->d_name);
        FILE *f = fopen(path, "r");
        if (!f) continue;
        fseek(f, 0, SEEK_END); long sz = ftell(f); fseek(f, 0, SEEK_SET);
        frames[fcnt] = malloc((size_t)sz + 1);
        fread(frames[fcnt], 1, (size_t)sz, f);
        frames[fcnt][sz] = '\0';
        fclose(f);
        indices[fcnt] = idx;
        fcnt++;
    }
    closedir(d);
    if (fcnt == 0) goto done;

    // Sort frames by numeric index
    for (size_t i = 0; i < fcnt; i++) {
        for (size_t j = i + 1; j < fcnt; j++) {
            if (indices[j] < indices[i]) {
                int ti = indices[i]; indices[i] = indices[j]; indices[j] = ti;
                char *tf = frames[i]; frames[i] = frames[j]; frames[j] = tf;
            }
        }
    }
    free(indices);

    // Parse frames into line arrays
    int *nlines = calloc(fcnt, sizeof(int));
    char ***fl = malloc(fcnt * sizeof(char **));
    for (size_t f = 0; f < fcnt; f++) {
        int n = 1;
        for (char *s = frames[f]; *s; s++) if (*s == '\n') n++;
        nlines[f] = n;
        fl[f] = calloc((size_t)n, sizeof(char *));
        char *copy = strdup(frames[f]);
        char *line = copy;
        for (int i = 0; i < n; i++) {
            char *nl = strchr(line, '\n');
            if (nl) *nl = '\0';
            fl[f][i] = strdup(line);
            line = nl ? nl + 1 : NULL;
        }
        free(copy);
    }

    int max_h = 1;
    for (size_t f = 0; f < fcnt; f++) if (nlines[f] > max_h) max_h = nlines[f];
    while ((int)ff_len < max_h) {
        if (ff_len >= ff_cap) { ff_cap *= 2; ff = realloc(ff, ff_cap * sizeof(char *)); }
        ff[ff_len] = calloc(1, (size_t)WIDTH + 1);
        memset(ff[ff_len], ' ', WIDTH);
        ff_len++;
    }

    size_t out_cap = 1024 * 128;
    char *out = malloc(out_cap);

    // Play loop — anifetch-style timing: frame i appears at i/FPS seconds from start
    struct timeval start;
    gettimeofday(&start, NULL);
    for (size_t f = 0; f < fcnt; f++) {
        double wanted = (double)f / PLAYBACK_RATE;
        struct timeval now;
        gettimeofday(&now, NULL);
        double elapsed = (double)(now.tv_sec - start.tv_sec)
                       + (double)(now.tv_usec - start.tv_usec) / 1000000.0;

        if (f > 0) {
            if (elapsed >= 8.0) { pressed = 1; break; }
            if (key_pressed()) { pressed = 1; break; }
        }

        // Sleep in 2ms chunks checking for keys between each — cuts max latency from 33ms to ~2ms
        double sleep_for = wanted - elapsed;
        while (sleep_for > 0.0 && !pressed) {
            double chunk = sleep_for > 0.002 ? 0.002 : sleep_for;
            usleep((useconds_t)(chunk * 1000000.0));
            if (f > 0 && key_pressed()) { pressed = 1; break; }
            gettimeofday(&now, NULL);
            elapsed = (double)(now.tv_sec - start.tv_sec)
                    + (double)(now.tv_usec - start.tv_usec) / 1000000.0;
            if (elapsed >= 8.0) { pressed = 1; break; }
            sleep_for = wanted - elapsed;
        }
        if (pressed) break;

        int o = 0;

        for (int i = 0; i < max_h; i++) {
            o += sprintf(out + o, "\033[%d;1H", TOP + i + 1);

            if (f == 0) o += sprintf(out + o, "\033[2K");

            // Left padding
            memset(out + o, ' ', PAD_LEFT); o += PAD_LEFT;

            // Chafa content (full line, no byte truncation)
            if (i < nlines[f]) {
                size_t cl = strlen(fl[f][i]);
                if ((size_t)o + cl + 64 > out_cap) break;
                memcpy(out + o, fl[f][i], cl);
                o += (int)cl;
            }

            // Position cursor right after animation area + gap
            o += sprintf(out + o, "\033[%dG", LINE_W + 1);

            // Fastfetch text
            size_t flen = strlen(ff[i]);
            if ((size_t)o + flen + 8 > out_cap) break;
            memcpy(out + o, ff[i], flen);
            o += (int)flen;
            o += sprintf(out + o, "\033[K");
        }

        write(STDOUT_FILENO, out, (size_t)o);
    }

    // Leave ECHO off when restoring terminal — zsh's ZLE sets its own mode.
    // Prevents line-discipline echo of pending input inside the animation area.
    struct termios noecho = orig_term;
    noecho.c_lflag &= ~ECHO;
    char seq[64];
    int n = snprintf(seq, sizeof(seq), "\033[%d;1H\033[2K\033[m\033[?25h", TOP + max_h + 1);
    write(STDOUT_FILENO, seq, (size_t)n);
    tcsetattr(STDIN_FILENO, TCSANOW, &noecho);
    tcdrain(STDOUT_FILENO);
    return pressed;

done:
    write(STDOUT_FILENO, "\033[m\033[?25h", 10);
    tcsetattr(STDIN_FILENO, TCSANOW, &orig_term);
    return 0;
}
