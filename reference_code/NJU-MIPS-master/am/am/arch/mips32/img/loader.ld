SECTIONS {
  . = 0x0;
  .text : {
    *(entry)
    *(.text*)
  }
  . = 0x6000;
  .rodata : {
    *(.rodata*)
  }
  .data : {
    *(.data*)
  }
  .bss : {
    *(.bss*)
  }
  end = .;
}
