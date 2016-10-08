.global get_cmd
.global my_strlen
.global my_itoah
.global my_itoa
.global my_strcmp
.global my_atoi
.global my_ahtoi

.text
@-- int get_cmd(int* po1, int* op2)
get_cmd:
  push {r4-r8, lr}

  @-- r0 = &param1 r1=&param2
  mov r5, r0 
  mov r6, r1

  @--reset buffers
  ldr r0, =buffer1
  mov r1, #0
  strb r1, [r0]

  bl get_line
  mov r4, r0

  @--check for "exit" command
  ldr r1, =string_exit
  bl my_strcmp
  cmp r0, #0
  moveq r0, #0
  beq return_cmd

  @--check for "si" command
  mov r0, r4
        ldr r1, =string_si
        bl my_strcmp
        cmp r0, #0
        moveq r0, #1
        beq return_cmd

  @--check for "c" command
  mov r0, r4
        ldr r1, =string_c
        bl my_strcmp
        cmp r0, #0
        moveq r0, #3
        beq return_cmd
  
  @--check for "regs" command
  mov r0, r4
        ldr r1, =string_regs
        bl my_strcmp
        cmp r0, #0
        moveq r0, #6
        beq return_cmd

  @--check for sn
  ldr r3, =buffer1
  mov r0, r4
  ldrb r1, [r0], #1
  strb r1, [r3], #1
  ldrb r1, [r0], #1
  strb r1, [r3], #1
  mov r1, #0
  strb r1, [r3]
  mov r7, r0
  ldr r0, =string_sn
  ldr r1, =buffer1
  bl my_strcmp
  cmp r0, #0
  bne not_sn
  @--read parameter
  add r7, r7, #1
  ldr r0, =buffer1
  readNumber:
    ldrb r1, [r7], #1
    cmp r1, #0
    beq endNumber
    strb r1, [r0], #1
    b readNumber
  endNumber:
  mov r1, #0
  strb r1, [r0]
  ldr r0, =buffer1
  bl my_atoi
  str r0, [r5]
  mov r0, #2
  b return_cmd    
  not_sn:

  @--check for p
  ldr r3, =buffer1
  mov r0, r4
  ldrb r1, [r0], #1
  strb r1, [r3], #1
  mov r1, #0
  strb r1, [r3]
  mov r7, r0
  ldr r0, =string_p
  ldr r1, =buffer1
  bl my_strcmp
  cmp r0, #0
  bne not_p
  @--read parameter
  add r7, r7, #2
  ldrb r0, [r7]
  cmp r0, #120
  moveq r8, #1
  movne r8, #0
  addeq r7, r7, #1
  subne r7, r7, #1
  ldr r0, =buffer1
  readNumber2:
    ldrb r1, [r7], #1
    cmp r1, #0
    beq endNumber2
    strb r1, [r0], #1
    b readNumber2
  endNumber2:
  mov r1, #0
  strb r1, [r0]
  ldr r0, =buffer1

  cmp r8, #1
  bleq my_ahtoi
  blne my_atoi

  str r0, [r5]
  mov r0, #5
  b return_cmd
  not_p:

  @--check for stw
  ldr r3, =buffer1
  mov r0, r4
  ldrb r1, [r0], #1
  strb r1, [r3], #1  
  ldrb r1, [r0], #1
        strb r1, [r3], #1
  ldrb r1, [r0], #1
        strb r1, [r3], #1
  mov r1, #0
  strb r1, [r3]
  mov r7, r0
  ldr r0, =string_stw
  ldr r1, =buffer1
  bl my_strcmp
  cmp r0, #0
  bne not_stw
  @--get first parameter
  add r7, r7, #2
  ldrb r0, [r7]
  cmp r0, #120
  moveq r8, #1
  movne r8, #0
  addeq r7, r7, #1
  subne r7, r7, #1
  ldr r0, =buffer1
  readNumber3:
    ldrb r1, [r7], #1
    cmp r1, #32
    beq endNumber3
    strb r1, [r0], #1
    b readNumber3
  endNumber3:
  mov r1, #0
  strb r1, [r0]
  ldr r0, =buffer1
  cmp r8, #1
  bleq my_ahtoi
  blne my_atoi
  str r0, [r5]
  @get second parameter
  add r7, r7, #1
  ldrb r0, [r7]
  cmp r0, #120
  moveq r8, #1
  movne r8, #0
  addeq r7, r7, #1
  subne r7, r7, #1
  ldr r0, =buffer1
  readNumber4:
    ldrb r1, [r7], #1
    cmp r1, #0
    beq endNumber4
    strb r1, [r0], #1
    b readNumber4
  endNumber4:
  mov r1, #0
  strb r1, [r0]
  ldr r0, =buffer1
  cmp r8, #1
  bleq my_ahtoi
  blne my_atoi
  str r0, [r6]
  mov r0, #4
  b return_cmd
  not_stw:

  @--default return=0
  mov r0, #0

  return_cmd:
  pop {r4-r8, pc}  

@-- char* get_line()
get_line:
  push {r4, r7, lr}
  ldr r4, =readBuffer
  mov r0, #0
  strb r0, [r4]
  @--read one line from stdin
  loop:
    mov r0, #0
    mov r1, r4
    mov r2, #1
    mov r7, #3
    svc #0

    ldrb r0, [r4]
    cmp r0, #10
    beq exitEndLine
    cmp r0, #0
    beq exitEndFile
    cmp r0, #255
    beq exitEndFile
    add r4, r4, #1
    b loop
  exitEndLine:
  exitEndFile:
    mov r0, #0
    strb r0, [r4]
    ldr r0, =readBuffer
  pop {r4, r7, pc}

@-- int divideBy10(int x) r0=result, r1=remainder
divideBy10:
  mov r1, r0
        movw r2, #:lower16:429496730
        movt r2, #:upper16:429496730
        smull r3, r0, r1, r2
  mov r3, #10
  mul r2, r0, r3
  sub r1, r1, r2
        bx lr

@--int divideBy16(int x) r0=result, r1=remainder
divideBy16:
  mov r3, r0
  lsr r0, r0, #4
  mov r1, #16
  mul r2, r0, r1
  sub r1, r3, r2
  bx lr

@--int my_strcmp(char* str1, char* str2)
my_strcmp:
  ldrb r2, [r0], #1
  ldrb r3, [r1], #1
  cmp r2, r3
  beq equalChars
  movlt r0, #-1
  movgt r0, #1
  b endComp  
  equalChars:
  cmp r2, #0
  bne my_strcmp
  mov r0, #0
  endComp:
  bx lr

@-- int my_strlen(char* str)
my_strlen:
  push {lr}
  mov r2, r0
head:
  ldrb r1, [r0], #1
  cmp r1, #0
  bne head

  sub r0, r0, r2
  sub r0, r0, #1

  pop {pc}

@-- int my_atoi(const char* str)
my_atoi:
  push {r4,r5}
  mov r5, #1
  mov r3, #0
  mov r2, #10
  ldrb r1, [r0]
  cmp r1, #45
  bne start
  add r0, r0, #1
  mov r5, #-1
  start:
    ldrb r1, [r0], #1
    cmp r1, #0
    beq end
    mov r4, r3
    mul r3, r4, r2  
    sub r1, r1, #48
    add r3, r3, r1
    b start
  end:
    mul r0, r3, r5
    pop {r4,r5}
    bx lr

@--int my_ahtoi(const char* str)
my_ahtoi:
  push {r4,r5}
  mov r5, #1
  mov r3, #0
  mov r2, #16
  ldrb r1, [r0]
  cmp r1, #45
  bne start2
  add r0, r0, #1
  mov r5, #-1
  start2:
    ldrb r1, [r0], #1
    cmp r1, #0
    beq end2
    mov r4, r3
    mul r3, r4, r2
    cmp r1, #80
    blt notLowerCase
    sub r1, r1, #97
    add r1, r1, #10
    b continue    
    notLowerCase:
    cmp r1, #60
    blt notLetter
    sub r1, r1, #65
    add r1, r1, #10
    b continue
    notLetter:
    sub r1, r1, #48
    continue:
    add r3, r3, r1
    b start2
  end2:
    mul r0, r3, r5
    pop {r4,r5}
    bx lr
  
@--void my_itoa(int v, char* buf)
my_itoa:
  push {r4,r5,lr}
  cmp r0, #0
  bge notNegative
  mov r2, r0
  mov r3, #-1
  mul r0, r2, r3
  mov r2, #45
  strb r2, [r1], #1
  notNegative:
  mov r4, #0
        mov r5, r1
  cmp r0, #0
  bne start3
  add r0, r0, #48
  strb r0, [r5], #1
  mov r0, #0
  start3:
    cmp r0, #0
    beq end3
    bl divideBy10
    add r4, r4, #1
    push {r1}
    b start3
  end3:
  output:
    cmp r4, #0
    beq endOutput
    pop {r0}
    add r0, r0, #48
    strb r0, [r5], #1
    sub r4, r4, #1
    b output
  endOutput:
  mov r0, #0
  strb r0, [r5]
  pop {r4,r5,pc}  

@--void my_itoah(int v, char* buf)
my_itoah:
  push {r4,r5,lr}
  cmp r0, #0
  bge notNegative2
  mov r2, r0
  mov r3, #-1
  mul r0, r2, r3
  mov r2, #45
  strb r2, [r1], #1
  notNegative2:
  mov r4, #0
  mov r5, r1
  cmp r0, #0
  bne start4
  add r0, r0, #48
  strb r0, [r5], #1
  mov r0, #0
  start4:
    cmp r0, #0
    beq end4
    bl divideBy16
    add r4, r4, #1
    push {r1}
    b start4
  end4:
  output2:
    cmp r4, #0
    beq endOutput2
    pop {r0}
    cmp r0, #10
    addlt r0, r0, #48
    addge r0, r0, #55
    strb r0, [r5], #1
    sub r4, r4, #1
    b output2
  endOutput2:
  mov r0, #0
  strb r0, [r5]
  pop {r4, r5, pc}

.data
readBuffer: .space 1200
buffer1: .space 400
string_exit: .asciz "exit"
string_si: .asciz "si"
string_sn: .asciz "sn"
string_c: .asciz "c"
string_stw: .asciz "stw"
string_p: .asciz "p"
string_regs: .asciz "regs"
