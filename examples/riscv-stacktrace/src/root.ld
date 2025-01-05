OUTPUT_ARCH( "riscv" )

ENTRY( _start )

RAM_BYTES = 0x2000000;
BASE_ADDRESS = 0x80000000;

PROVIDE(.ram_end = BASE_ADDRESS + RAM_BYTES);

MEMORY {
  ram  (wxa) : ORIGIN = BASE_ADDRESS, LENGTH = RAM_BYTES
}

SECTIONS {
  .text ALIGN(0x1000) : AT(BASE_ADDRESS) {
    *(.text .text.*);
  }

  .data ALIGN(0x1000) : ALIGN(0x1000) {
    *(.data .sdata);
  }

  .rodata ALIGN(0x1000) : ALIGN(0x1000) {
    *(.rodata .rodata.* .srodata.*);

    .debug_info_start = .;
    KEEP(*(.debug_info))
    .debug_info_end = .;
    .debug_abbrev_start = .;
    KEEP(*(.debug_abbrev))
    .debug_abbrev_end = .;
    .debug_str_start = .;
    KEEP(*(.debug_str))
    .debug_str_end = .;
    .debug_line_start = .;
    KEEP(*(.debug_line))
    .debug_line_end = .;
    .debug_ranges_start = .;
    KEEP(*(.debug_ranges))
    .debug_ranges_end = .;
  }

  .stack ALIGN(0x1000) : ALIGN(0x1000) {
    *(.stack)
  }
}
