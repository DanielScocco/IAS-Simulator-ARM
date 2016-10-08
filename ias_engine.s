.global step_instruction

.text
step_instruction:
  push {r4-r6, lr}

  @--check for PC overflow
  ldr r0, =PC
  ldr r0, [r0]
  cmp r0, #1024
  blt noOverflow
  mov r0, #2
  pop {r4-r6, pc}

  noOverflow:
  and r3, r0, #1
  lsr r0, r0, #1
  mov r1, #5
  mul r2, r0, r1
  ldr r1, =IAS_MEM
  add r1, r1, r2
  cmp r3, #1
  beq rightInstruction

  @--fetch instruction on the left
  ldrb r5, [r1]
  add r1, r1, #2
  ldrb r0, [r1], #-1
  lsr r0, r0, #4
  ldrb r1, [r1]
  lsl r1, r1, #4
  orr r6, r0, r1
  b opcodeAddressReady

  @--fetch instruction on the right
  rightInstruction:
  add r1, r1, #2
  ldrb r0, [r1], #1
  and r2, r0, #15
  lsl r2, r2, #4
  ldrb r0, [r1]
  lsr r0, r0, #4
  orr r5, r0, r2
  ldrb r0, [r1], #1
  and r2, r0, #15
  lsl r2, r2, #8
  ldrb r0, [r1]
  orr r6, r0, r2
  
  @--r5=opcode r6=address, ready to go
  opcodeAddressReady:
  @--validate memory address
  cmp r6, #1024
  blt memoryOK
  mov r0, #2
  pop {r4-r6, pc}
  memoryOK:
  ldr r0, =IAS_MEM
  mov r1, #5
  mul r2, r1, r6
  add r0, r0, r2 @--r0=physical address

  @--Switch - calculate offset and branch
  cmp r5, #0
  blt invalidOpcode
  cmp r5, #34
  bge invalidOpcode
  ldr r1, =instructionVector
  ldr r1, [r1, r5, lsl #2]
  bx r1

  @--LOAD M(X) opcode==1
  loadM:  
    bl loadMemory
    ldr r1, =AC
    str r0, [r1]
    b instructionProcessed
  @--LOAD -M(X) opcode==2
  loadNegative:
    bl loadMemory
    mov r2, #-1
    mul r3, r2, r0  
    ldr r1, =AC
    str r3, [r1]
    b instructionProcessed
  @--LOAD |M(X)| opcode==3
  loadModulus:
    bl loadMemory
    cmp r0, #0
    movlt r2, #-1
    mullt r3, r2, r0
    movge r3, r0
    ldr r1, =AC
    str r3, [r1]
    b instructionProcessed
  @--ADD M(X) opcode==5
  add:
    bl loadMemory
    ldr r1, =AC
    ldr r2, [r1]
    add r0, r0, r2
    str r0, [r1]
    b instructionProcessed
  @--SUB M(X) opcode==6
  sub:
    bl loadMemory
                ldr r1, =AC
                ldr r2, [r1]
                sub r2, r2, r0
                str r2, [r1]
                b instructionProcessed
  @--ADD |M(X)| opcode==7
        addModulus:
                bl loadMemory
    cmp r0, #0
    movlt r2, #-1
    mullt r3, r2, r0
    movge r3, r0
                ldr r1, =AC
                ldr r2, [r1]
                add r3, r3, r2
                str r3, [r1]
                b instructionProcessed
   @--SUB |M(X)| opcode==7
        subModulus:
                bl loadMemory
                cmp r0, #0
                movlt r2, #-1
                mullt r3, r2, r0
                movge r3, r0
                ldr r1, =AC
                ldr r2, [r1]
                sub r2, r2, r3
                str r2, [r1]
                b instructionProcessed
  @--LOAD MQ, M(X) opcode==9
  loadMQM:
    bl loadMemory
                ldr r1, =MQ
                str r0, [r1]
                b instructionProcessed
  @--LOAD MQ opcode==10
  loadMQ:
    ldr r0, =MQ
    ldr r0, [r0]
    ldr r1, =AC
    str r0, [r1]
    b instructionProcessed
  @--MUL M(X) opcode==11
  mul:
    bl loadMemory
    ldr r1, =MQ
    ldr r2, [r1]
    mul r3, r2, r0
    str r3, [r1]
    mov r0, #0
    ldr r1, =AC
    str r0, [r1]
    b instructionProcessed
  @--DIV M(X) opcode==12
  div:
    bl loadMemory
    ldr r1, =AC
    ldr r1, [r1]
    mov r2, #0
    divisionLoop:
      cmp r1, r0
      blt endDivision
      add r2, r2, #1
      sub r1, r1, r0
      b divisionLoop
    endDivision:
    ldr r0, =AC
    str r1, [r0]
    ldr r0, =MQ
    str r2, [r0]
    b instructionProcessed
  @--JUMP M(0:19) opcode==13
  jumpLeft:
    lsl r6, r6, #1
    ldr r1, =PC
    str r6, [r1]
    b noPCincrement
  @--JUMP M(20:39( opcode==14
  jumpRight:
    lsl r6, r6, #1
    add r6, r6, #1
    ldr r1, =PC
    str r6, [r1]
    b noPCincrement
  @--JUMP+ M(0:19) opcode==15
  jumpPlusLeft:
    ldr r1, =AC
    ldr r1, [r1]
    cmp r1, #0
    bge jumpLeft
    b instructionProcessed
  @--JUMP+ (20:39) opcode==16
  jumpPlusRight:
    ldr r1, =AC
    ldr r1, [r1]
    cmp r1, #0
    bge jumpRight
    b instructionProcessed
  @--LSH opcode==20
  lsh:
    ldr r0, =AC
    ldr r1, [r0]
    lsl r1, r1, #1
    str r1, [r0]
    b instructionProcessed
  @--RSH opcode==21
  rsh:
    ldr r0, =AC
    ldr r1, [r0]
    lsr r1, r1, #1
    str r1, [r0]
    b instructionProcessed  
  @--STOR M(8:19) opcode==18
  storLeft:
    ldr r1, =AC
    ldr r1, [r1]
    and r3, r1, #15
    and r2, r1, #4080
    lsr r2, r2, #4
    strb r2, [r0, #1]!
    add r0, r0, #1
    ldrb r1, [r0]
    and r1, r1, #15
    lsl r3, r3, #4
    orr r1, r1, r3
    strb r1, [r0]
    b instructionProcessed
  @--STOR M(28:39) opcode==19
  storRight:
    ldr r1, =AC
    ldr r1, [r1]
    and r2, r1, #255
    lsr r1, r1, #8
    and r1, r1, #15
    ldrb r3, [r0, #3]!
    orr r3, r3, r1
    strb r3, [r0]
    strb r2, [r0, #1]
    b instructionProcessed
  @STOR M(X) opcode==33
  stor:
    ldr r1, =AC
    ldrb r2, [r1, #3]!
    strb r2, [r0, #1]!
    ldrb r2, [r1, #-1]!
    strb r2, [r0, #1]!
    ldrb r2, [r1, #-1]!
    strb r2, [r0, #1]!
    ldrb r2, [r1, #-1]!
    strb r2, [r0, #1]!
    b instructionProcessed
  @-- invalid opcode, return 1
  invalidOpcode:
  mov r0, #1
  pop {r4-r6, pc}
  instructionProcessed:
  @--increment PC
  ldr r0, =PC
  ldr r1, [r0]
  add r1, r1, #1
  str r1, [r0]
  @--return without incrementing PC
  noPCincrement:
  mov r0, #0
  pop {r4-r6, pc}

loadMemory:
  add r0, r0, #1
  mov r1, #0
  ldrb r2, [r0], #1
  lsl r2, r2, #24
  orr r1, r1, r2
  ldrb r2, [r0], #1
  lsl r2, r2, #16
  orr r1, r1, r2
  ldrb r2, [r0], #1
  lsl r2, r2, #8
  orr r1, r1, r2
  ldrb r2, [r0]
  orr r1, r1, r2
  mov r0, r1
  bx lr

.data
instructionVector:
    .word invalidOpcode
    .word loadM
    .word loadNegative
    .word loadModulus
    .word invalidOpcode
    .word add
    .word sub
    .word addModulus
    .word subModulus
    .word loadMQM
    .word loadMQ
    .word mul
    .word div
    .word jumpLeft
    .word jumpRight
    .word jumpPlusLeft
    .word jumpPlusRight
    .word invalidOpcode
    .word storLeft
    .word storRight
    .word lsh
    .word rsh
    .word invalidOpcode
    .word invalidOpcode
    .word invalidOpcode
    .word invalidOpcode
    .word invalidOpcode
    .word invalidOpcode
    .word invalidOpcode
    .word invalidOpcode
    .word invalidOpcode
    .word invalidOpcode
    .word invalidOpcode
    .word stor
