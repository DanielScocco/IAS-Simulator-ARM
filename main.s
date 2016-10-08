.global main

.text
main:
  push {r4-r8, lr}
  mov r6, #0
  mainLoop:
    ldr r0, =param1
    ldr r1, =param2
    bl get_cmd
    mov r4, r0
    @--return code==0 "exit"
    cmp r4, #0
    beq exitSimulator
    @--return code==1 "si"
    cmp r4, #1
    bne not_si
    bl step_instruction
    cmp r0, #0
    bne exitSimulator
    not_si:    
    @--return code==2 "sn"
    cmp r4, #2
    bne not_sn
    ldr r8, =param1
    ldr r8, [r8]
    executionLoop:
      cmp r8,#0
      ble endExecutionLoop
      bl step_instruction
      cmp r0, #0
      bne exitSimulator
      sub r8, r8, #1
      b executionLoop
    endExecutionLoop: 
    not_sn:
    @--return code==3 "c"
    cmp r4, #3
    bne not_c
    infiniteLoop:
      bl step_instruction
      cmp r0, #0
      beq infiniteLoop
      bne exitSimulator
    not_c:
    @--return code==4 "stw"
    cmp r4, #4
    bne not_stw
    ldr r0, =param2 @valor
    ldr r1, =param1 @endereco
    ldr r1, [r1]
    mov r2, #5
    mul r3, r1, r2
    ldr r1, =IAS_MEM
    add r1, r1, r3
    add r1, r1, #1
    add r0, r0, #3
    ldrb r2, [r0], #-1
    cmp r2, #0
    strneb r2, [r1], #1
    addeq r1, r1, #1
    ldrb r2, [r0], #-1
    cmp r2, #0
                strneb r2, [r1], #1
    addeq r1, r1, #1
    ldrb r2, [r0], #-1
    cmp r2, #0
                strneb r2, [r1], #1
    addeq r1, r1, #1
    ldrb r2, [r0]
                strb r2, [r1]    
    not_stw:
    @--return code==5 "p"
    cmp r4, #5
    bne not_p
    @--print newline if not first run
                cmp r6, #0
                beq firstRun2
                ldr r1, =buffer2
                mov r2, #10
                strb r2, [r1]
                mov r0, #1
                mov r2, #1
                mov r7, #4
                svc #0          
                firstRun2:
                add r6, r6, #1
    @--print value at memory address
    ldr r0, =param1
    ldr r0, [r0]
    mov r2, #5
    mul r3, r0, r2
    ldr r1, =IAS_MEM
    add r0, r1, r3
    bl printMemory
    not_p:
    @-- return code==6 "regs"
    cmp r4, #6
    bne not_regs
    @--print newline if not first run
                cmp r6, #0
                beq firstRun
                ldr r1, =buffer2
                mov r2, #10
                strb r2, [r1]
                mov r0, #1
                mov r2, #1
                mov r7, #4
                svc #0          
                firstRun:
    add r6, r6, #1
    @--print AC
    mov r0, #1
    ldr r1, =string_AC
    mov r2, #4
    mov r7, #4
    svc #0
    ldr r0, =AC
    ldr r0, [r0]
    mov r1, #1
    bl printHex
    @--print MQ
     mov r0, #1
    mov r2, #4
    ldr r1, =string_MQ
    mov r7, #4
    svc #0
    ldr r0, =MQ
    ldr r0, [r0]
    mov r1, #1
    bl printHex
    @--print PC  
    mov r0, #1
    ldr r1, =string_PC
    mov r2, #4
    mov r7, #4
    svc #0
    ldr r0, =PC
    ldr r0, [r0]
    tst r0, #1
    moveq r5, #69
    movne r5, #68
    lsr r0, r0, #1 
    mov r1, #0
    bl printHex
    ldr r0, =buffer2
    mov r1, #47
    strb r1, [r0], #1
    strb r5, [r0]
    mov r0, #1
    ldr r1, =buffer2
    mov r2, #2
    mov r7, #4
    svc #0  
    not_regs:
    b mainLoop
  exitSimulator:
  @--output 
  ldr r1, =buffer2
  mov r0, #0
  strb r0, [r1]
  mov r0, #1
  mov r2, #1
  mov r7, #4
  svc #0

  mov r0, #0
  pop {r4-r8, pc}

printMemory:
  push {r4-r7,lr}
  mov r4, r0

  ldr r6, =buffer3
        mov r2, #48
        strb r2, [r6], #1
        mov r2, #120
        strb r2, [r6], #1

  mov r5, #0
  processBytes:
    cmp r5, #5
    bge endProcess
    ldrb r0, [r4], #1
    cmp r0, #16
    movlt r2, #48
    strltb r2, [r6], #1
    ldr r1, =buffer2
    bl my_itoah
    ldr r1, =buffer2
    transferBytes:
      ldrb r0, [r1], #1
      cmp r0, #0
      beq endTransfer
      strb r0, [r6], #1
      b transferBytes
    endTransfer:
    add r5, r5, #1    
    b processBytes
  endProcess:
  mov r0, #1
  ldr r1, =buffer3
  mov r2, #12
  mov r7, #4
  svc #0  

  pop {r4-r7, pc}

printHex:
  push {r7,r8, lr}
  mov r8, r1
  ldr r1, =buffer2
        bl my_itoah
        ldr r0, =buffer2
        bl my_strlen

  ldr r1, =buffer3
  mov r2, #48
  strb r2, [r1], #1
  mov r2, #120
  strb r2, [r1], #1

  mov r3, #48
  addZeroes:
    cmp r0, #10
    bge endZeroes
    strb r3, [r1], #1
    add r0, r0, #1
    b addZeroes
  endZeroes:
  ldr r0, =buffer2
  copyNumber:
    ldrb r2, [r0], #1
    cmp r2, #0
    beq copyDone
    strb r2, [r1], #1
    b copyNumber
  copyDone:
  cmp r8, #1
  moveq r2, #10
  streqb r2, [r1]
  moveq r2, #13
  movne r2, #12

  mov r0, #1
  ldr r1, =buffer3
  mov r7, #4
  svc #0

  pop {r7,r8, pc}

.data
param1: .space 4
param2: .space 4
buffer2: .space 400
buffer3: .space 400
string_AC: .ascii "AC: "
string_MQ: .ascii "MQ: "
string_PC: .ascii "PC: "
