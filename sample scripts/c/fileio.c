#include <stdio.h>
#include <stdlib.h>
 
int main(void)
{

char c;
FILE *f1;


f1 = fopen("myfile", "a");
 
    if (f1 == NULL) {
        perror("Failed to open file \"myfile\"");
        return EXIT_FAILURE;
    }
//fprintf(f1, "Testing...\n");

while(c != 'a'){

scanf("%c",&c);
fputc(c, f1);
}

fclose(f1);
return 0;
}

