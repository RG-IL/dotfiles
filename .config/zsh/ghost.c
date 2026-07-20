#include <dirent.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
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

// Convert truecolor \033[38;2;R;G;Bm to 256-color \033[38;5;Nm
static int r24_to_ansi256(int r, int g, int b) {
    if (r == g && g == b) {
        if (r < 8) return 0;
        if (r < 188) return 232 + (int)((r - 8) / 10);
        return 255;
    }
    return 16 + 36 * (int)(r / 51) + 6 * (int)(g / 51) + (int)(b / 51);
}

static void optimize_escapes(char *s) {
    char *out = s;
    char *p = s;
    int last256 = -1;
    while (*p) {
        // Truecolor foreground: \033[38;2;R;G;Bm
        if (p[0] == '\033' && p[1] == '[' && p[2] == '3' && p[3] == '8' &&
            p[4] == ';' && p[5] == '2' && p[6] == ';') {
            int r = 0, g = 0, b = 0;
            char *start = p + 7;
            r = atoi(start);
            while (*start && *start != ';') start++;
            if (*start == ';') start++;
            g = atoi(start);
            while (*start && *start != ';') start++;
            if (*start == ';') start++;
            b = atoi(start);
            while (*start && *start != 'm') start++;
            if (*start == 'm') start++;
            int c = r24_to_ansi256(r, g, b);
            if (c == last256) continue;
            last256 = c;
            int n = sprintf(out, "\033[38;5;%dm", c);
            out += n;
            p = start;
            continue;
        }
        // Reset: \033[0m
        if (p[0] == '\033' && p[1] == '[' && p[2] == '0' && p[3] == 'm') {
            char *after = p + 4;
            if (*after == '\033') { p = after; continue; }
            if (*after == '\n' || *after == '\0') { p = after; continue; }
            last256 = -1;
            memcpy(out, p, 4);
            out += 4;
            p = after;
            continue;
        }
        *out++ = *p++;
    }
    *out = '\0';
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

    for (size_t f = 0; f < fcnt; f++)
        for (int i = 0; i < nlines[f]; i++)
            optimize_escapes(fl[f][i]);

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
        }

        // Wait for the next frame or a keypress — replaces 2ms polling with an exact timeout
        double sleep_for = wanted - elapsed;
        if (sleep_for > 0) {
            fd_set rfds;
            FD_ZERO(&rfds);
            FD_SET(STDIN_FILENO, &rfds);
            struct timeval tv;
            tv.tv_sec = (long)sleep_for;
            tv.tv_usec = (long)((sleep_for - tv.tv_sec) * 1000000.0);
            if (select(STDIN_FILENO + 1, &rfds, NULL, NULL, &tv) > 0) {
                char buf[65536];
                int total = 0;
                for (;;) {
                    int n = (int)read(STDIN_FILENO, buf + total,
                                      sizeof(buf) - (size_t)total);
                    if (n <= 0) break;
                    total += n;
                    if ((size_t)total >= sizeof(buf)) break;
                    fd_set more;
                    FD_ZERO(&more);
                    FD_SET(STDIN_FILENO, &more);
                    struct timeval tw = {0, 2000};
                    if (select(STDIN_FILENO + 1, &more, NULL, NULL, &tw) <= 0) break;
                }
                if (total > 0) {
                    // ESC, Enter, 'q' → close animation
                    if (total == 1 && (buf[0] == 27 || buf[0] == '\n' || buf[0] == '\r' || buf[0] == 'q')) {
                        pressed = 1;
                    } else {
                        for (int i = 0; i < total; i++) {
                            if (buf[i] != 'q')
                                ioctl(STDIN_FILENO, TIOCSTI, &buf[i]);
                        }
                        pressed = 1;
                    }
                }
            }
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
