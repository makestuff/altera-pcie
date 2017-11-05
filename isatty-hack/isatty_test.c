#include <stdio.h>
#include <unistd.h>

int main(int argc, const char *argv[]) {
  if ( argc == 2 ) {
    printf("isatty(%s) returns %d\n", argv[1], isatty(STDOUT_FILENO));
  } else {
    printf("isatty() returns %d\n", isatty(STDOUT_FILENO));
  }
  return 0;
}
