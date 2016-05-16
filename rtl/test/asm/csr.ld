SECTIONS {
    . = 0;
    .initial : { *(.initial) }
    . = 0x2000;
    .exception : { *(.exception) }
}