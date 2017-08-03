#include<stdio.h>


int main(int argc, char *argv[])
{

printf("Host Command\n");
system("ping -c 5 www.google.com");
printf("\nSuccess\n");
   return 0;
}
