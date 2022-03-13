/*
 * exp-test -- this is a simple C program to test the interactive functions of expect.
 */

#include <stdio.h>
#include <string.h>

#define ARRAYSIZE 128

main (argc, argv)
int argc;
char *argv[];
{
  char line[ARRAYSIZE];

  do {
    memset (line, 0, ARRAYSIZE);
    fgets (line, ARRAYSIZE, stdin);
    *(line + strlen(line)-1) = '\0'; /* get rid of the newline */

    /* look for a few simple commands */
    if (strncmp (line,"prompt ", 6) == 0) {
      printf ("%s (y or n) ?", line + 6);
      if (getchar() == 'y')
	puts ("YES");
      else
	puts ("NO");
    }
    if (strncmp (line, "print ", 6) == 0) {
      puts (line + 6);
    }
  } while (strncmp (line, "quit", 4));
}
