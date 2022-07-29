#include <am.h>
extern int main();

int video = 0x4001;
void _putc(char ch) {
    asm volatile(
        "move $24, %0\n\t"
        "sb %1, 0x0($24)\n\t"
        :
        :"r"(video), "r"(ch)
    );
    video++;
}

void _trm_init() {
  asm volatile("ori $sp,$0,0x9000");
  _halt(main());
}

void _halt(int code) {
  if (code) {
    _putc('W'); _putc('A');
  } else {
    _putc('A'); _putc('C');
  }
  while (1);
}

_Area _heap;
