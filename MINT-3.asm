

; =========================================================================
; CONFIGURATION - edit these values as needed
; =========================================================================

ROMSTART    EQU $0000       ; TEC-1 2k ROM at 0000
RAMSTART    EQU $0800       ; TEC-1 2k RAM at 0800
ROMSIZE     EQU $0800
RAMSIZE     EQU $0800

;TEC-1D SC 8k rom/ram alternative:
; ROMSTART  EQU $0000
; RAMSTART  EQU $2000
; ROMSIZE   EQU 8192
; RAMSIZE   EQU 8192

; bit bang baud rate constants @ 4MHz
B300        EQU 0220H
B1200       EQU 0080H
B2400       EQU 003FH
B4800       EQU 001BH
B9600       EQU 000BH

BAUDDEF     EQU B4800       ; default baud rate loaded at RESET

; I/O port addresses (TEC-1)
KEYBUF      EQU 00H         ; MM74C923N KEYBOARD ENCODER (serial RX on bit 7)
SCAN        EQU 01H         ; DISPLAY SCAN LATCH (serial TX on bit 6)
DISPLY      EQU 02H         ; DISPLAY LATCH
PORT3       EQU 03H         ; ST3 (8X8), STROBE (RELAY BOARD) DATLATCH (DAT BOARD)
PORT4       EQU 04H         ; ST4 (8X8), LCD 'E' (DAT BOARD)
PORT5       EQU 05H
PORT6       EQU 06H
PORT7       EQU 07H         ; ENABLE/DISABLE SINGLE STEPPER (IF INSTALLED)

; ASCII codes
ESC         EQU 1BH
CR          EQU 0DH
LF          EQU 0AH

TRUE        EQU -1
FALSE       EQU 0
UNLIMITED   EQU -1

CTRL_C      EQU 3
CTRL_E      EQU 5
CTRL_H      EQU 8
CTRL_L      EQU 12
CTRL_R      EQU 18
CTRL_S      EQU 19

BSLASH      EQU $5C

; RAM sizing
DSIZE       EQU $80
RSIZE       EQU $80
TIBSIZE     EQU $100        ; 256 bytes, a long line!
VARS_SIZE   EQU 26*2

; =========================================================================
; ROM CODE
; =========================================================================

        .ORG ROMSTART

;reset
RSTVEC:
        JP RESET

;FIX 1: every RST stub now saves HL first (the stub itself must
;       clobber L to pass the interrupt id, so it preserves HL here
;       and ISR restores it on exit).
rst1:
        .ORG ROMSTART+$08
        push hl
        ld l,1
        jp ISR

rst2:
        .ORG ROMSTART+$10
        push hl
        ld l,2
        jp ISR

rst3:
        .ORG ROMSTART+$18
        push hl
        ld l,3
        jp ISR

rst4:
        .ORG ROMSTART+$20
        push hl
        ld l,4
        jp ISR

rst5:
        .ORG ROMSTART+$28
        push hl
        ld l,5
        jp ISR

rst6:
        .ORG ROMSTART+$30
        push hl
        ld l,6
        jp ISR

;RST 7 / IM 1 hardware interrupt vector
        .ORG ROMSTART+$38
        push hl                     ;FIX 1
        ld l,7
        jp ISR

        .ORG ROMSTART+$40

;hexadecimal to 7 segment display code table (TEC-1)
sevensegment:
        .DB 0EBH,28H,0CDH,0ADH      ;0,1,2,3
        .DB 2EH,0A7H,0E7H,29H       ;4,5,6,7
        .DB 0EFH,2FH,6FH,0E6H       ;8,9,A,B
        .DB 0C3H,0ECH,0C7H,47H      ;C,D,E,F

;---------------
; BIT TIME DELAY
;---------------
;DELAY FOR ONE SERIAL BIT TIME
;ENTRY : HL = DELAY TIME
; NO REGISTERS MODIFIED
;
PWRUP:
        LD    hl,$2000
BITIME:
        PUSH  HL
        PUSH  DE
        LD    DE,0001H
BITIM1:
        SBC   HL,DE
        JP    NC,BITIM1
        POP   DE
        POP   HL
IntRet:
        RET

;RST 8  Non Maskable Interrupt
        .ORG ROMSTART+$66
        push hl                     ;FIX 2: preserve HL, use dedicated
        ld l,8                      ;       NMI service routine ending
        jp NMISR                    ;       in RETN (see below)

;------------------------
; SERIAL TRANSMIT ROUTINE
;------------------------
;TRANSMIT BYTE SERIALLY ON DOUT (SCAN port bit 6)
;
; ENTRY : A = BYTE TO TRANSMIT
;  EXIT : NO REGISTERS MODIFIED
;
TxChar:
TXDATA:
        PUSH  AF
        PUSH  BC
        PUSH  HL
        LD    HL,(BAUD)
        LD    C,A
;
; TRANSMIT START BIT
;
        XOR   A
        OUT   (SCAN),A
        CALL  BITIME
;
; TRANSMIT DATA
;
        LD    B,08H
        RRC   C
NXTBIT:
        RRC   C                     ;SHIFT BITS TO D6,
        LD    A,C                   ;LSB FIRST AND OUTPUT
        AND   40H                   ;THEM FOR ONE BIT TIME.
        OUT   (SCAN),A
        CALL  BITIME
        DJNZ  NXTBIT
;
; SEND STOP BITS
;
        LD    A,40H
        OUT   (SCAN),A
        CALL  BITIME
        CALL  BITIME
        POP   HL
        POP   BC
        POP   AF
        RET

;-----------------------
; SERIAL RECEIVE ROUTINE
;-----------------------
;RECEIVE SERIAL BYTE FROM DIN (KEYBUF port bit 7)
;
; ENTRY : NONE
;  EXIT : A= RECEIVED BYTE IF CARRY CLEAR
;
; REGISTERS MODIFIED A AND F
;
RxChar:
RXDATA:
        PUSH  BC
        PUSH  HL
;
; WAIT FOR START BIT
;
RXDAT1: IN    A,(KEYBUF)
        BIT   7,A
        JR    NZ,RXDAT1             ;NO START BIT
;
; DETECTED START BIT
;
        LD    HL,(BAUD)
        SRL   H
        RR    L                     ;DELAY FOR HALF BIT TIME
        CALL  BITIME
        IN    A,(KEYBUF)
        BIT   7,A
        JR    NZ,RXDAT1             ;START BIT NOT VALID
;
; DETECTED VALID START BIT,READ IN DATA
;
        LD    B,08H
RXDAT2:
        LD    HL,(BAUD)
        CALL  BITIME                ;DELAY ONE BIT TIME
        IN    A,(KEYBUF)
        RL    A
        RR    C                     ;SHIFT BIT INTO DATA REG
        DJNZ  RXDAT2
        LD    A,C
        OR    A                     ;CLEAR CARRY FLAG
        POP   HL
        POP   BC
        RET

getchar:
        LD HL,(GETCVEC)
        JP (HL)

putchar:
        PUSH HL
        LD HL,(PUTCVEC)
        EX (SP),HL
        RET

;FIX 1: ISR now preserves AF/BC/DE (HL was pushed by the RST stub),
;       and re-enables interrupts before returning so the first
;       hardware interrupt no longer disables interrupts forever.
;       Note: the MINT code run for interrupt handling (definition Z)
;       must be stack-balanced, as always.
ISR:
        ld h,0                      ; hl = interrupt id from stub
        push af
        push bc
        push de
        ld (vIntID),hl
        call enter
        .cstr "Z"
        pop de
        pop bc
        pop af
        pop hl                      ; pushed by RST stub
        ei                          ;FIX 1: re-enable interrupts
        ret

;FIX 2: dedicated NMI service routine - preserves registers and
;       returns with RETN so IFF1 is restored from IFF2. No EI here;
;       RETN handles interrupt state for NMI.
NMISR:
        ld h,0                      ; hl = 8 (NMI id) from stub
        push af
        push bc
        push de
        ld (vIntID),hl
        call enter
        .cstr "Z"
        pop de
        pop bc
        pop af
        pop hl                      ; pushed by NMI stub
        retn

;FIX 7: '//' comment support. The comment-skipping routine existed in
;       the original source but was never dispatched - '//' fell
;       through to division and corrupted the stack. The manual
;       documents '//' comments (on their own line), so alt now routes
;       here. Relocated to page 0 because page 5 is nearly full.
comment:
        inc bc                      ; point to next char
        ld a,(bc)
        cp "\r"                     ; terminate at cr
        jr NZ,comment
        dec bc
        jp (IY)

RESET:
        ld SP,stack
        ;FIX 4: removed dead stores of IntRet into RST08..RST30,
        ;       INTVEC and NMIVEC - nothing ever read them. The RAM
        ;       slots still exist so the memory layout is unchanged.

        LD HL,RXDATA
        LD (GETCVEC),HL
        LD HL,TXDATA
        LD (PUTCVEC),HL

        call PWRUP
        IM  1
        ;FIX 3: EI removed from here - interrupts are now enabled in
        ;       start, AFTER init has built the dispatch tables.

;inline serial initialisation (bit-bang)
        LD    A,$40                 ; TX line idle high (SCAN bit 6)
        LD    C,SCAN
        OUT   (C),A
        LD    HL,BAUDDEF
        LD    (BAUD),HL

        jp   start                  ; into ROMSTART+$180 of the prog

; **************************************************************************
; Page 0  Initialisation
; **************************************************************************

        .ORG ROMSTART + $180        ; put mint code from here

; **************************************************************************
; Macros must be written in Mint and end with ;
; this code must not span pages
; **************************************************************************
macros:

reedit_:
    db "/z/Z;"                      ; remembers last line edited

edit_:
    .cstr "`?`/K/P/Z;"

list_:
    .cstr "/N26(/i65+/Z/k0>(/N))/P;"

printStack_:
    .cstr "`=> `/s2- /D1-(",$22,",2-)'/N/P;"

iOpcodes:
; (macros LITDAT/REPDAT/ENDDAT unrolled into plain db)
    db 15                           ; LITDAT 15
    db    lsb(bang_)        ;   !
    db    lsb(dquote_)      ;   "
    db    lsb(hash_)        ;   #
    db    lsb(dollar_)      ;   $
    db    lsb(percent_)     ;   %
    db    lsb(amper_)       ;   &
    db    lsb(quote_)       ;   '
    db    lsb(lparen_)      ;   (
    db    lsb(rparen_)      ;   )
    db    lsb(star_)        ;   *
    db    lsb(plus_)        ;   +
    db    lsb(comma_)       ;   ,
    db    lsb(minus_)       ;   -
    db    lsb(dot_)         ;   .
    db    lsb(slash_)       ;   /

    db (10 | $80)                   ; REPDAT 10, lsb(num_)
    db lsb(num_)                    ; 10 x repeat lsb of num routine

    db 7                            ; LITDAT 7
    db    lsb(colon_)       ;    :
    db    lsb(semi_)        ;    ;
    db    lsb(lt_)          ;    <
    db    lsb(eq_)          ;    =
    db    lsb(gt_)          ;    >
    db    lsb(question_)    ;    ?
    db    lsb(at_)          ;    @

    db (26 | $80)                   ; REPDAT 26, lsb(call_)
    db lsb(call_)                   ; call a command A, B ....Z

    db 6                            ; LITDAT 6
    db    lsb(lbrack_)      ;    [
    db    lsb(bslash_)      ;    \
    db    lsb(rbrack_)      ;    ]
    db    lsb(caret_)       ;    ^
    db    lsb(underscore_)  ;    _
    db    lsb(grave_)       ;    `   ; for printing `hello`

    db (26 | $80)                   ; REPDAT 26, lsb(var_)
    db lsb(var_)                    ; a b c .....z

    db 4                            ; LITDAT 4
    db    lsb(lbrace_)      ;    {
    db    lsb(pipe_)        ;    |
    db    lsb(rbrace_)      ;    }
    db    lsb(tilde_)       ;    ~ ( a b c -- b c a ) rotate

iAltCodes:
    db 26                           ; LITDAT 26
    db     lsb(alloc_)      ;A      allocate some heap memory
    db     lsb(aNop_)       ;B
    db     lsb(printChar_)  ;C      print a char
    db     lsb(depth_)      ;D      depth of stack
    db     lsb(else_)       ;E      else
    db     lsb(falsex_)     ;F      false condition
    db     lsb(go_)         ;G      go execute mint code
    db     lsb(aNop_)       ;H
    db     lsb(inPort_)     ;I      input from port
    db     lsb(aNop_)       ;J
    db     lsb(key_)        ;K      read a char from input
    db     lsb(aNop_)       ;L
    db     lsb(aNop_)       ;M
    db     lsb(newln_)      ;N      prints a newline to output
    db     lsb(outPort_)    ;O      output to port
    db     lsb(prompt_)     ;P      print MINT prompt
    db     lsb(aNop_)       ;Q
    db     lsb(aNop_)       ;R
    db     lsb(arrSize_)    ;S      array size
    db     lsb(truex_)      ;T      true condition
    db     lsb(unlimit_)    ;U      unlimited loop
    db     lsb(varAccess_)  ;V      address of last access
    db     lsb(while_)      ;W      conditional break from loop
    db     lsb(exec_)       ;X      execute machine code
    db     lsb(aNop_)       ;Y
    db     lsb(editDef_)    ;Z      edit line
    db 0                            ; ENDDAT

backSpace:
    ld a,c
    or b
    jr z, interpret2
    dec bc
    call printStr
    .cstr "\b \b"
    jr interpret2

start:
    ld SP,DSTACK                    ; start of MINT
    call init                       ; setups
    EI                              ;FIX 3: enable interrupts only now,
                                    ;       after tables/vars are built
    call printStr
    .cstr "MINT2.0\r\n"

interpret:
    call prompt

    ld bc,0                         ; load bc with offset into TIB
    ld (vTIBPtr),bc

interpret2:                         ; calc nesting (a macro might have changed it)
    ld E,0                          ; initilize nesting value
    push bc                         ; save offset into TIB,
                                    ; bc is also the count of chars in TIB
    ld hl,TIB                       ; hl is start of TIB
    jr interpret4

interpret3:
    ld a,(hl)                       ; A = char in TIB
    inc hl                          ; inc pointer into TIB
    dec bc                          ; dec count of chars in TIB
    call nesting                    ; update nesting value

interpret4:
    ld a,C                          ; is count zero?
    or B
    jr NZ, interpret3               ; if not loop
    pop bc                          ; restore offset into TIB

waitchar:
    call getchar                    ; loop around waiting for character
    cp $20                          ; compare to space
    jr NC,waitchar1                 ; if >= space
    cp $0                           ; is it end of string? null end of string
    jr Z,waitchar4
    cp '\r'                         ; carriage return? ascii 13
    jr Z,waitchar3                  ; if anything else its macro/control
    cp CTRL_H
    jr z,backSpace
    ld d,msb(macros)
    cp CTRL_E
    ld e,lsb(edit_)
    jr z,macro
    cp CTRL_R
    ld e,lsb(reedit_)
    jr z,macro
    cp CTRL_L
    ld e,lsb(list_)
    jr z,macro
    cp CTRL_S
    ld e,lsb(printStack_)
    jr z,macro
    jr interpret2

macro:
    ld (vTIBPtr),bc
    push de
    call ENTER                      ;mint go operation and jump to it
    .cstr "/G"
    ld bc,(vTIBPtr)
    jr interpret2

waitchar1:
    ld hl,TIBSIZE-3                 ;FIX 5: TIB overflow guard -
    or a                            ;       clear carry (A is preserved)
    sbc hl,bc                       ;       if count >= TIBSIZE-3 ignore
    jr c,waitchar                   ;       the character, leaving room
    jr z,waitchar                   ;       for \r \n ETX
    ld hl,TIB
    add hl,bc
    ld (hl),A                       ; store the character in textbuf
    inc bc
    call putchar                    ; echo character to screen
    call nesting
    jr  waitchar                    ; wait for next character

waitchar3:
    ld hl,TIB
    add hl,bc
    ld (hl),"\r"                    ; store the crlf in textbuf
    inc hl
    ld (hl),"\n"
    inc hl
    inc bc
    inc bc
    call crlf                       ; echo character to screen
    ld a,E                          ; if zero nesting append an ETX after \r
    or A
    jr NZ,waitchar
    ld (hl),$03                     ; store end of text ETX in text buffer
    inc bc

waitchar4:
    ld (vTIBPtr),bc
    ld bc,TIB                       ; we pressed enter
    dec bc

NEXT:
    inc bc                          ; Increment the IP
    ld a,(bc)                       ; Get the next character and dispatch
    or a                            ; is it NUL?
    jr z,exit
    cp CTRL_C
    jr z,etx
    sub "!"
    jr c,NEXT
    ld L,A                          ; Index into table
    ld H,msb(opcodes)               ; Start address of jump table
    ld L,(hl)                       ; get low jump address
    ld H,msb(page4)                 ; Load H with the 1st page address
    jp (hl)                         ; Jump to routine

exit:
    inc bc                          ; store offsets into a table of bytes
    ld de,bc
    call rpop                       ; Restore Instruction pointer
    ld bc,hl
    EX de,hl
    jp (hl)

etx:
    ld hl,-DSTACK                   ; check if stack pointer is underwater
    add hl,SP
    jr NC,etx1
    ld SP,DSTACK
etx1:
    jp interpret

init:
    ld IX,RSTACK
    ld IY,NEXT                      ; IY provides a faster jump to NEXT

    ld hl,vars
    ld de,hl
    inc de
    ld (hl),0
    ld bc,VARS_SIZE * 3             ; init vars, defs and altVars
    LDIR

    ld hl,dStack
    ld (vStkStart),hl
    ld hl,65
    ld (vLastDef),hl
    ld hl,HEAP
    ld (vHeapPtr),hl

initOps:
    ld hl, iOpcodes
    ld de, opcodes
    ;FIX 6: removed dead 'ld bc,$80-32-1-1+26' - BC is always
    ;       reloaded below before each LDIR.

initOps1:
    ld a,(hl)
    inc hl
    SLA A
    ret Z
    jr C, initOps2
    SRL A
    ld C,A
    ld B,0
    LDIR
    jr initOps1

initOps2:
    SRL A
    ld B,A
    ld a,(hl)
    inc hl
initOps2a:
    ld (de),A
    inc de
    DJNZ initOps2a
    jr initOps1

lookupRef0:
    ld hl,defs
    sub "A"
    jr lookupRef1
lookupRef:
    sub "a"
lookupRef1:
    add a,a
    add a,l
    ld l,a
    ld a,0
    ADC a,h
    ld h,a
    XOR a
    or e                            ; sets Z flag if A-Z
    ret

printhex:
                                    ; Display hl as a 16-bit number in hex.
    push bc                         ; preserve the IP
    ld a,H
    call printhex2
    ld a,L
    call printhex2
    pop bc
    ret
printhex2:
    ld  C,A
    RRA
    RRA
    RRA
    RRA
    call printhex3
    ld a,C
printhex3:
    and 0x0F
    add a,0x90
    DAA
    ADC a,0x40
    DAA
    jp putchar

; **************************************************************************
; calculate nesting value
; A is char to be tested,
; E is the nesting value (initially 0)
; E is increased by ( and [
; E is decreased by ) and ]
; E has its bit 7 toggled by `
; limited to 127 levels
; **************************************************************************

nesting:
    cp '`'
    jr NZ,nesting1
    ld a,$80
    xor e
    ld e,a
    ret
nesting1:
    BIT 7,E
    ret NZ
    cp ':'
    jr Z,nesting2
    cp '['
    jr Z,nesting2
    cp '('
    jr NZ,nesting3
nesting2:
    inc E
    ret
nesting3:
    cp ';'
    jr Z,nesting4
    cp ']'
    jr Z,nesting4
    cp ')'
    ret NZ
nesting4:
    dec E
    ret

prompt:
    call printStr
    .cstr "\r\n> "
    ret

crlf:
    call printStr
    .cstr "\r\n"
    ret

printStr:
    EX (SP),hl                      ; swap
    call putStr
    inc hl                          ; inc past null
    EX (SP),hl                      ; put it back
    ret

putStr0:
    call putchar
    inc hl
putStr:
    ld a,(hl)
    or A
    jr NZ,putStr0
    ret

rpush:
    dec IX
    ld (IX+0),H
    dec IX
    ld (IX+0),L
    ret

rpop:
    ld L,(IX+0)
    inc IX
    ld H,(IX+0)
    inc IX
rpop2:
    ret

writeChar:
    ld (hl),A
    inc hl
    jp putchar

enter:
    ld hl,bc
    call rpush                      ; save Instruction Pointer
    pop bc
    dec bc
    jp (iy)

carry:
    ld hl,0
    rl l
    ld (vCarry),hl
    jp (iy)

setByteMode:
    ld a,$FF
    jr assignByteMode
resetByteMode:
    xor a
assignByteMode:
    ld (vByteMode),a
    ld (vByteMode+1),a
    jp (iy)

false_:
    ld hl,FALSE
    jr true1

true_:
    ld hl,TRUE
true1:
    push hl
    jp (iy)

; **********************************************************************
; Page 4 primitive routines
; **********************************************************************
    .align $100
page4:

quote_:                             ; Discard the top member of the stack
    pop     hl
at_:
underscore_:
    jp (iy)

bslash_:
    jr setByteMode

var_:
    ld a,(bc)
    ld hl,vars
    call lookupRef
var1:
    ld (vPointer),hl
    ld d,0
    ld e,(hl)
    ld a,(vByteMode)
    inc a                           ; is it byte?
    jr z,var2
    inc hl
    ld d,(hl)
var2:
    push de
    jr resetByteMode

bang_:                              ; Store the value at the address on TOS
assign:
    pop hl                          ; discard value of last accessed variable
    pop de                          ; new value
    ld hl,(vPointer)
    ld (hl),e
    ld a,(vByteMode)
    inc a                           ; is it byte?
    jr z,assign1
    inc hl
    ld (hl),d
assign1:
    jr resetByteMode

amper_:
    pop de                          ; Bitwise AND top 2 elements of stack
    pop hl
    ld a,E
    and L
    ld L,A
    ld a,D
    and H
and1:
    ld h,a
and2:
    push hl
    jp (iy)

pipe_:
    pop de                          ; Bitwise OR top 2 elements of stack
    pop hl
    ld a,E
    or L
    ld L,A
    ld a,D
    or h
    jr and1

caret_:
    pop     de                      ; Bitwise XOR top 2 elements of stack
xor1:
    pop     hl
    ld      a,E
    XOR     L
    ld      L,A
    ld      a,D
    XOR     H
    jr and1

tilde_:
invert:                             ; Bitwise INVert top member of stack
    ld de, $FFFF                    ; by xoring with $FFFF
    jr xor1

plus_:                              ; add the top 2 members of the stack
    pop     de
    pop     hl
    add     hl,de
    push    hl
    jp carry

call_:
    ld a,(bc)
    call lookupRef0
    ld E,(hl)
    inc hl
    ld D,(hl)
    jp go1

dot_:
    pop hl
    call printDec
dot2:
    ld a,' '
    call putChar
    jp (iy)

comma_:                             ; print hexadecimal
    pop     hl
    call printhex
    jr   dot2

dquote_:
    pop     hl                      ; Duplicate the top member of the stack
    push    hl
    push    hl
    jp (iy)
    ;FIX 6: removed unreachable 'jp NEXT' that followed here -
    ;       whitespace never reaches the dispatch table (filtered
    ;       by the 'sub "!" / jr c,NEXT' in NEXT).

percent_:
    pop hl                          ; Duplicate 2nd element of the stack
    pop de
    push de
    push hl
    push de                         ; and push it to top of stack
    jp (iy)

semi_:
    call rpop                       ; Restore Instruction pointer
    ld bc,hl
    jp (iy)

;  Left shift { is multiply by 2
lbrace_:
    pop hl
    add hl,hl
    jr and2                         ; shift left

;  Right shift } is a divide by 2
rbrace_:
    pop hl                          ; Get the top member of the stack
shr1:
    SRL H
    RR L
    jr and2

; $ swap                            ; a b -- b a Swap top 2 elements
dollar_:
    pop hl
    EX (SP),hl
    jr and2

minus_:                             ; Subtract 2nd on stack from TOS
    inc bc                          ; check if sign of a number
    ld a,(bc)
    dec bc
    cp "0"
    jr c,sub1
    cp "9"+1
    jp c,num
sub1:
    pop de
    pop hl
sub2:
    and A
    sbc hl,de
    push hl
    jp carry

eq_:
    pop hl
    pop de
    or a                            ; reset the carry flag
    sbc hl,de                       ; only equality sets hl=0 here
    jp z,true_
    jp false_

gt_:
    pop hl
    pop de
    jr lt1_

lt_:
    pop de
    pop hl

lt1_:
    or a                            ; reset the carry flag
    sbc hl,de
    jp c,true_
    jp false_

grave_:
str:
    inc bc

str1:
    ld a, (bc)
    inc bc
    cp "`"                          ; ` is the string terminator
    jr Z,str2
    call putchar
    jr str1
str2:
    dec bc
    jp   (IY)

lbrack_:
arrDef:
    ld hl,0
    add hl,sp                       ; save
    call rpush
    jp (iy)

num_:
    jp num
rparen_:
    jp again                        ; close loop
rbrack_:
    jp arrEnd
colon_:
    jp def
lparen_:
    jp begin

question_:
    jr arrAccess
hash_:
    jr hex
star_:
    jr mul
slash_:

alt_:                               ; falls through (must be on page 4)
;*******************************************************************
; Page 5 primitive routines
;*******************************************************************
alt:
    inc bc
    ld a,(bc)
    cp "/"                          ;FIX 7: '//' comments the rest of the line
    jp z,comment
    cp "z"+1
    jr nc,alt1
    cp "a"
    jr nc,altVar
    cp "Z"+1
    jr nc,alt1
    cp "A"
    jr nc,altCode
alt1:
    dec bc
    jp div

altVar:
    cp "i"
    ld l,0
    jp z,loopVar
    cp "j"
    ld l,8
    jr z,loopVar
    ld hl,altVars
    call lookupRef
    jp var1

loopVar:
    ld h,0
    ld d,ixh
    ld e,ixl
    add hl,de
    jp var1

altCode:
    ld hl,altCodes
    sub "A"
    add a,L
    ld L,A
    ld a,(hl)                       ;       get low jump address
    ld hl,page6
    ld L,A
    jp (hl)                         ;       Jump to routine

arrAccess:
    pop hl                          ; hl = index
    pop de                          ; de = array
    ld a,(vByteMode)                ; a = data width
    inc a
    jr z,arrAccess1
    add hl,hl                       ; if data width = 2 then double
arrAccess1:
    add hl,de                       ; hl = addr
    jp var1

hex:
    ld hl,0                         ; Clear hl to accept the number
hex1:
    inc bc
    ld a,(bc)                       ; Get the character which is a numeral
    BIT 6,A                         ; is it uppercase alpha?
    jp Z, hex2                      ; no a decimal
    sub 7                           ; sub 7 to make $A - $F
hex2:
    sub $30                         ; Form decimal digit
    jp C,num2
    cp $0F+1
    jp NC,num2
    add hl,hl                       ; 2X ; Multiply digit(s) in hl by 16
    add hl,hl                       ; 4X
    add hl,hl                       ; 8X
    add hl,hl                       ; 16X
    add a,L                         ; add into bottom of hl
    ld  L,A
    jp  hex1

mul:
    pop de                          ; de = 2nd arg
    pop hl                          ; hl = 1st arg
    push bc                         ; save IP
    ld a,l
    ld c,h
    ld b,16
    ld hl,0
mul1:
    add hl,hl
    rla
    rl c
    jr nc,mul2
    add hl,de
    adc a,0
    jp nc,mul2
    inc c
mul2:
    djnz mul1
    ex de,hl                        ; de = lsw result
    ld h,c
    ld l,a                          ; hl = msw result
    pop bc                          ; restore IP
    jp divExit                      ; pushes lsw, puts msw in vRemain

begin:
loopStart:
    ld (vTemp1),bc                  ; save start
    ld e,1                          ; skip to loop end, nesting = 1
loopStart1:
    inc bc
    ld a,(bc)
    call nesting                    ; affects zero flag
    jr nz,loopStart1
    pop de                          ; de = limit
    ld a,e                          ; is it zero?
    or d
    jr nz,loopStart2
    dec de                          ; de = TRUE
    ld (vElse),de
    jr loopStart4                   ; yes continue after skip
loopStart2:
    ld a,2                          ; is it TRUE
    add a,e
    add a,d
    jr nz,loopStart3
    ld de,1                         ; yes make it 1
loopStart3:
    ld hl,bc
    call rpush                      ; rpush loop end
    dec bc                          ; IP points to ")"
    ld hl,(vTemp1)                  ; restore start
    call rpush                      ; rpush start
    ex de,hl                        ; hl = limit
    call rpush                      ; rpush limit
    ld hl,-1                        ; hl = count = -1
    call rpush                      ; rpush count
loopstart4:
    jp (iy)

again:
loopEnd:
    ld e,(ix+2)                     ; de = limit
    ld d,(ix+3)
    ld a,e                          ; a = lsb(limit)
    or d                            ; if limit 0 exit loop
    jr z,loopEnd4
    inc de                          ; is limit -2
    inc de
    ld a,e                          ; a = lsb(limit)
    or d                            ; if limit 0 exit loop
    jr z,loopEnd2                   ; yes, loop again
    dec de
    dec de
    dec de
    ld (ix+2),e
    ld (ix+3),d
loopEnd2:
    ld e,(ix+0)                     ; inc counter
    ld d,(ix+1)
    inc de
    ld (ix+0),e
    ld (ix+1),d
loopEnd3:
    ld de,FALSE                     ; if clause ran then vElse = FALSE
    ld (vElse),de
    ld c,(ix+4)                     ; IP = start
    ld b,(ix+5)
    jp (iy)
loopEnd4:
    ld de,2*4                       ; rpop frame
    add ix,de
    jp (iy)

; **************************************************************************
; Page 6 Alt primitives
; **************************************************************************
    .align $100
page6:

; allocates raw heap memory in bytes (ignores byte mode)
; n -- a
alloc_:
    pop de
    ld hl,(vHeapPtr)
    push hl
    add hl,de
    ld (vHeapPtr),hl
aNop_:
    jp (iy)

; returns the size of an array
; a -- n
arrSize_:
arrSize:
    pop hl
    dec hl                          ; msb size
    ld d,(hl)
    dec hl                          ; lsb size
    ld e,(hl)
    push de
    jp (iy)

break_:
while_:
while:
    pop hl
    ld a,l
    or h
    jr nz,while2
    ld c,(ix+6)                     ; IP = )
    ld b,(ix+7)
    jp loopEnd4
while2:
    jp (iy)

depth_:
depth:
    ld hl,0
    add hl,SP
    EX de,hl
    ld hl,DSTACK
    or A
    sbc hl,de
    jp shr1

falsex_:
    jp false_

printChar_:
    pop hl
    ld a,L
    call putchar
    jp (iy)

else_:
    ld hl,(vElse)
else1:
    push hl
    jp (iy)

exec_:
    call exec1
    jp (iy)
exec1:
    pop hl
    EX (SP),hl
    jp (hl)

editDef_:
    call editDef
    jp (iy)

prompt_:
    call prompt
    jp (iy)

go_:
    pop de
go1:
    ld a,D                          ; skip if destination address is null
    or E
    jr Z,go3
    ld hl,bc
    inc bc                          ; read next char from source
    ld a,(bc)                       ; if ; tail call optimise
    cp ";"                          ; by jumping to rather than calling
    jr Z,go2
    call rpush                      ; save Instruction Pointer
go2:
    ld bc,de
    dec bc
go3:
    jp (iy)

key_:
    call getchar
    ld H,0
    ld L,A
    jr else1

inPort_:
    pop hl
    ld a,C
    ld C,L
    IN L,(C)
    ld H,0
    ld C,A
    jr else1

newln_:
    call crlf
    jp (iy)

outPort_:
    pop hl
    ld E,C
    ld C,L
    pop hl
    OUT (C),L
    ld C,E
    jp (iy)

truex_:
    jp true_

unlimit_:
    ld hl,-2
    jr else1

varAccess_:
    ld hl,vPointer
    ld e,(hl)
    inc hl
    ld d,(hl)
    push de
    jp (iy)

;*******************************************************************
; Subroutines
;*******************************************************************

editDef:                            ; lookup up def based on number
    pop hl                          ; pop ret address
    EX (SP),hl                      ; swap with TOS
    ld a,L
    EX AF,AF'
    ld a,l
    call lookupRef0
    ld E,(hl)
    inc hl
    ld D,(hl)
    ld a,D
    or E
    ld hl,TIB
    jr Z,editDef3
    ld a,":"
    call writeChar
    EX AF,AF'
    call writeChar
    jr editDef2
editDef1:
    inc de
editDef2:
    ld a,(de)
    call writeChar
    cp ";"
    jr NZ,editDef1
editDef3:
    ld de,TIB
    or A
    sbc hl,de
    ld (vTIBPtr),hl
    ret

; hl = value
printDec:
    bit 7,h
    jr z,printDec2
    ld a,'-'
    call putchar
    xor a
    sub l
    ld l,a
    sbc a,a
    sub h
    ld h,a
printDec2:
    push bc
    ld c,0                          ; leading zeros flag = false
    ld de,-10000
    call printDec4
    ld de,-1000
    call printDec4
    ld de,-100
    call printDec4
    ld e,-10
    call printDec4
    inc c                           ; flag = true for at least 1 digit
    ld e,-1
    call printDec4
    pop bc
    ret
printDec4:
    ld b,'0'-1
printDec5:
    inc b
    add hl,de
    jr c,printDec5
    sbc hl,de
    ld a,'0'
    cp b
    jr nz,printDec6
    xor a
    or c
    ret z
    jr printDec7
printDec6:
    inc c
printDec7:
    ld a,b
    jp putchar

;*******************************************************************
; Page 5 primitive routines continued
;*******************************************************************

def:                                ; Create a colon definition
    inc bc
    ld  a,(bc)                      ; Get the next character
    cp "@"                          ; is it anonymous
    jr nz,def0
    inc bc
    ld de,(vHeapPtr)                ; return start of definition
    push de
    jr def1
def0:
    ld (vLastDef),a
    call lookupRef0
    ld de,(vHeapPtr)                ; start of definition
    ld (hl),E                       ; Save low byte of address in CFA
    inc hl
    ld (hl),D                       ; Save high byte of address in CFA+1
    inc bc
def1:                               ; Skip to end of definition
    ld a,(bc)                       ; Get the next character
    inc bc                          ; Point to next character
    ld (de),A
    inc de
    cp ";"                          ; Is it a semicolon
    jr Z, def2                      ; end the definition
    jr  def1                        ; get the next element
def2:
    dec bc
def3:
    ld (vHeapPtr),de                ; bump heap ptr to after definition
    jp (iy)

num:
    ld hl,$0000                     ; Clear hl to accept the number
    ld a,(bc)                       ; Get numeral or -
    cp '-'
    jr nz,num0
    inc bc                          ; move to next char, no flags affected
num0:
    ex af,af'                       ; save zero flag = 0 for later
num1:
    ld a,(bc)                       ; read digit
    sub "0"                         ; less than 0?
    jr c, num2                      ; not a digit, exit loop
    cp 10                           ; greater than 9?
    jr nc, num2                     ; not a digit, exit loop
    inc bc                          ; inc IP
    ld de,hl                        ; multiply hl * 10
    add hl,hl
    add hl,hl
    add hl,de
    add hl,hl
    add a,l                         ; add digit in a to hl
    ld l,a
    ld a,0
    adc a,h
    ld h,a
    jr num1
num2:
    dec bc
    ex af,af'                       ; restore zero flag
    jr nz, num3
    ex de,hl                        ; negate the value of hl
    ld hl,0
    or a
    sbc hl,de
num3:
    push hl                         ; Put the number on the stack
    jp (iy)                         ; and process the next character

arrEnd:
    ld (vTemp1),bc                  ; save IP
    call rpop
    ld (vTemp2),hl                  ; save old SP
    ld de,hl                        ; de = hl = old SP
    or a
    sbc hl,sp                       ; hl = array count (items on stack)
    srl h                           ; num items = num bytes / 2
    rr l
    ld bc,hl                        ; bc = count
    ld hl,(vHeapPtr)                ; hl = array[-4]
    ld (hl),c                       ; write num items in length word
    inc hl
    ld (hl),b
    inc hl                          ; hl = array[0], bc = count
                                    ; de = old SP, hl = array[0], bc = count
    jr arrayEnd2
arrayEnd1:
    dec bc                          ; dec items count
    dec de
    dec de
    ld a,(de)                       ; a = lsb of stack item
    ld (hl),a                       ; write lsb of array item
    inc hl                          ; move to msb of array item
    ld a,(vByteMode)                ; vByteMode=1?
    inc a
    jr z,arrayEnd2
    inc de
    ld a,(de)                       ; a = msb of stack item
    dec de
    ld (hl),a                       ; write msb of array item
    inc hl                          ; move to next word in array
arrayEnd2:
    ld a,c                          ; if not zero loop
    or b
    jr nz,arrayEnd1
    ex de,hl                        ; de = end of array
    ld hl,(vTemp2)
    ld sp,hl                        ; SP = old SP
    ld hl,(vHeapPtr)                ; de = array[-2]
    inc hl
    inc hl
    push hl                         ; return array[0]
    ld (vHeapPtr),de                ; move heap* to end of array
    ld bc,(vTemp1)                  ; restore IP
    jp resetByteMode

div:
    ld hl,bc                        ; hl = IP
    pop bc                          ; bc = denominator
    ex (sp),hl                      ; save IP, hl = numerator
    ld a,h
    xor b
    push af
    xor b
    jp p,absbc
;absHL
    xor a
    sub l
    ld l,a
    sbc a,a
    sub h
    ld h,a
absbc:
    xor b
    jp p,$+9
    xor a
    sub c
    ld c,a
    sbc a,a
    sub b
    ld b,a
    add hl,hl
    ld a,15
    ld de,0
    ex de,hl
    jr jumpin
Loop1:
    add hl,bc   ;--
Loop2:
    dec a       ;4
    jr z,EndSDiv ;12|7
jumpin:
    sla e       ;8
    rl d        ;8
    adc hl,hl   ;15
    sbc hl,bc   ;15
    jr c,Loop1  ;23-2b
    inc e       ;--
    jp Loop2    ;--
EndSDiv:
    pop af
    jp p,div10
    xor a
    sub e
    ld e,a
    sbc a,a
    sub d
    ld d,a
div10:
    pop bc
divExit:
    push de                         ; quotient
    ld (vRemain),hl                 ; remainder
    jp (iy)

; *******************************************************************************
; *********  END OF ROM CODE  ***************************************************
; *******************************************************************************

; =========================================================================
; RAM LAYOUT (no bytes emitted - DS only)
; =========================================================================

        .ORG RAMSTART

TIB:        DS TIBSIZE

            DS RSIZE
rStack:

            DS DSIZE
dStack:
stack:
tbPtr:      DS 2                    ; reserved for tests
vTemp1:     DS 2                    ;
vTemp2:     DS 2                    ;

RST08:      DS 2                    ; (kept for layout compatibility -
RST10:      DS 2                    ;  no longer initialised, see FIX 4)
RST18:      DS 2
RST20:      DS 2
RST28:      DS 2
RST30:      DS 2
BAUD:       DS 2                    ; current bit-bang baud constant
INTVEC:     DS 2                    ;
NMIVEC:     DS 2                    ;
GETCVEC:    DS 2                    ;
PUTCVEC:    DS 2                    ;

        .align $100
opcodes:
            DS $80-32-1-1
altCodes:
            DS 26

        .align $100

vars:       DS VARS_SIZE
defs:       DS VARS_SIZE

altVars:
            DS 2                    ; a
vByteMode:  DS 2                    ; b
vCarry:     DS 2                    ; c carry variable
            DS 2                    ; d
            DS 2                    ; e
vIntFunc:   DS 2                    ; f interrupt func
            DS 2                    ; g
vHeapPtr:   DS 2                    ; h heap pointer variable
            DS 2                    ; i loop variable
            DS 2                    ; j outer loop variable
vTIBPtr:    DS 2                    ; k address of text input buffer
            DS 2                    ; l
            DS 2                    ; m
            DS 2                    ; n
            DS 2                    ; o
            DS 2                    ; p
            DS 2                    ; q
vRemain:    DS 2                    ; r remainder of last division
vStkStart:  DS 2                    ; s address of start of stack
            DS 2                    ; t
            DS 2                    ; u
vIntID:     DS 2                    ; v interrupt id
            DS 2                    ; w
            DS 2                    ; x
            DS 2                    ; y
vLastDef:   DS 2                    ; z name of last defined function

vPointer:   DS 2                    ;
vElse:      DS 2                    ;

HEAP:
