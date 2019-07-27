#include <stdio.h>
#include <string.h>
#include <libbrand/brand.h>

int main(int argc, char **argv){
  printf("%s", brand3(atoi(argv[1])));

  return 0;
}
