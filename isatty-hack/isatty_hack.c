#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>
#include <unistd.h>

int isatty(int fd) {
  typedef int (*FuncPtr)(int);
  static FuncPtr realImpl = NULL;
  if ( !realImpl ) {
    void *const handle = dlopen("libc.so.6", RTLD_LAZY);
    if ( !handle ) {
      fprintf(stderr, "dlopen() failed: %s\n", dlerror());
      exit(1);
    }
    #pragma GCC diagnostic push
    #pragma GCC diagnostic ignored "-Wpedantic"
    realImpl = (FuncPtr)dlsym(handle, "isatty");
    #pragma GCC diagnostic pop
    if ( !realImpl ) {
      fprintf(stderr, "dlsym() failed: %s\n", dlerror());
      exit(1);
    }
  }
  if ( fd == STDOUT_FILENO || fd == STDERR_FILENO ) {
    return 1;
  } else {
    return realImpl(fd);
  }
}
