@ This is a macro definition to help setting entries in the
@ IAS memory map
.macro mm_entry byte1 byte2 byte3 byte4 byte5
  .byte 0xbyte1
  .byte 0xbyte2
  .byte 0xbyte3
  .byte 0xbyte4
  .byte 0xbyte5
.endm

@ This .data section defines the architectural state
@ of the IAS machine
.data
  .align 4
  .globl IAS_MEM
  .globl PC
  .globl AC
  .globl MQ

PC:
  .word  0

AC:
  .word  0

MQ:
  .word  0

IAS_MEM:
  mm_entry 09 00 50 B0 06
  mm_entry 00 00 00 00 00
  mm_entry 00 00 00 00 00
  mm_entry 00 00 00 00 00
  mm_entry 00 00 00 00 00
  mm_entry 00 00 00 00 04
  mm_entry 00 00 00 00 05
  mm_entry 00 00 00 00 00
  mm_entry 00 00 00 00 03
  mm_entry 00 00 00 00 0A
  mm_entry 00 00 00 00 00
  mm_entry 00 00 00 00 00
  .fill  1012, 5, 0
