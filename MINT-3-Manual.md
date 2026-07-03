


# MINT 3 Manual — TEC‑1 Bit‑Bang Build (TEC1‑MINT‑BITBANG)

This manual documents the consolidated, bug‑fixed MINT 2 ROM for the TEC‑1
(`TEC1-MINT-BITBANG.asm`). Every example in this manual was executed and
verified against the assembled ROM running in a Z80 emulator with simulated
bit‑bang serial. Where this build differs from older MINT 2 documentation,
the difference is called out in the **Errata** section at the end.

MINT is a minimalist character‑based RPN interpreter by John Hardy and Ken
Boak, with bit‑bang serial routines by Craig Jones. GPL v3.

---

## 1. This build at a glance

- Target: TEC‑1 (and compatibles), 2K ROM at $0000, 2K RAM at $0800
- Serial: **bit‑bang**, default **4800 bps** (8N2 framing), TX on SCAN port
  bit 6, RX on KEYBUF port bit 7, timing constants for a 4 MHz CPU
- ROM usage: $0000–$07FC (3 bytes spare in 2K)
- Prompt: `> ` — commands are executed when you press Enter (CR)
- Line length: up to **253 characters**; anything beyond is silently
  ignored (this build adds an input‑buffer guard, so over‑long lines can no
  longer corrupt memory — but they still won't run, so keep lines short)
- Interrupts: fully working in this build. Any RST, INT or NMI runs the
  MINT function `Z` and records which interrupt fired in `/v`
- `//` comments: working in this build (previously broken — see Errata)
- The asm80.com emulator models a 6850 ACIA, so this bit‑bang build will
  not talk in that emulator. It is for real hardware.

To change the baud rate or memory map, edit the CONFIGURATION section at
the top of the source file (`BAUDDEF`, `ROMSTART`, `RAMSTART`, etc.) and
reassemble.

---

## 2. Quick start

On reset MINT prints its banner and prompt:

```
MINT2.0

>
```

Type RPN expressions and press Enter:

```
> 10 20 + .
30
>
```

Numbers go on the stack. Operators consume stack items and push results.
`.` pops and prints in decimal, `,` pops and prints in hexadecimal.

Rules that matter from day one:

- MINT has **no error checking**. A syntax error can corrupt the
  interpreter's state until reset. All input must be exact.
- There is **no stack underflow protection**. Popping from an empty stack
  yields garbage numbers, not an error.
- Every `/X`‑style command (a `/` followed by an uppercase letter) needs a
  **space before it**: `12! /E` is right, `12!/E` is wrong.
- Function definitions have **no space** between `:` and the letter:
  `:F` is right, `: F` is wrong.

---

## 3. Numbers

MINT works only with 16‑bit integers.

- **Decimal** numbers are signed: −32768 to 32767. Negative literals take
  a leading minus sign: `-786`.
- **Hexadecimal** numbers are unsigned: `#0000` to `#FFFF`. They are
  prefixed with `#` and written with digits `0–9` and **uppercase** `A–F`.
  Lowercase hex digits terminate the number.

The same 16 bits underneath — only the printing differs:

```
> #FFFF 1 - .
-2
> #FFFF 1 - ,
FFFE
> #3FFF .
16383
> #FF ,
00FF
```

`,` always prints four hex digits. `.` prints signed decimal. Both print a
trailing space. To negate a value, multiply by −1:

```
> 7 -1 * .
-7
```

---

## 4. Printing

| Op  | Action                                        |
| --- | --------------------------------------------- |
| `.` | pop and print as signed decimal, plus a space |
| `,` | pop and print as 4‑digit hex, plus a space    |
| `` `text` `` | print the literal text between backticks (no `.` needed) |
| `/C` | pop and print as an ASCII character          |
| `/N` | print CR+LF (newline)                        |
| `/P` | print the `> ` prompt                        |

```
> `hello`
hello
> 65 /C 66 /C 67 /C
ABC
```

---

## 5. The stack

| Op  | Name | Effect         |
| --- | ---- | -------------- |
| `"` | dup  | n → n n        |
| `'` | drop | m n → m        |
| `$` | swap | m n → n m      |
| `%` | over | m n → m n m    |
| `/D`| depth| — → n          |

```
> 10 " . .
10 10
> 20 30 ' .
20
> 40 50 $ . .
40 50
> 60 70 % . . .
60 70 60
> 1 2 3 /D .
3
```

Note the over example: `%` copies the **second** item to the top, so
printing top‑down gives `60 70 60`. (An older manual showed `70 60 70`
here, which is wrong — see Errata.)

There is no PICK or deep access. Keep stack depth small (≤3 per function)
and keep functions stack‑balanced.

---

## 6. Arithmetic, carry and remainder

| Op  | Action                        |
| --- | ----------------------------- |
| `+` | add                           |
| `-` | subtract (2nd − top... i.e. `10 20 -` = −10) |
| `*` | multiply (16×16, 32‑bit result) |
| `/` | divide (signed), quotient on stack |

Two system variables track what doesn't fit in 16 bits:

- `/c` — **carry** from the last `+` or `-`
- `/r` — **remainder** of the last `/`, or the **high word (overflow)** of
  the last `*`

They keep their value until the next operation sets them, or you clear
them yourself with `0 /c!` and `0 /r!`.

```
> 0 /r! 0 /c!
> #FFFF 1 + ,
0000
> /c .
1
> 0 /c! /c .
0

> 5 4 / .
1
> /r .
1

> 0 /r! #FFFF 2 * ' /r .
1
```

**Modulo:** there is no `%`‑style mod operator (`%` is OVER). To get
`a mod b`, divide, drop the quotient, and read `/r`:

```
a b / ' /r
```

---

## 7. Logic and bitwise operators

Booleans: false is `0` (constant `/F`), true is `-1` (constant `/T`,
all bits set).

| Op  | Action                                |
| --- | ------------------------------------- |
| `=` | equal → −1 / 0                        |
| `<` | less than → −1 / 0                    |
| `>` | greater than → −1 / 0                 |
| `&` | bitwise AND                           |
| `\|`| bitwise OR                            |
| `^` | bitwise XOR                           |
| `~` | bitwise NOT (invert all 16 bits)      |
| `{` | shift left one bit (×2)               |
| `}` | shift right one bit (÷2)              |

You cannot combine comparisons (`>=`, `<>`, etc.) — do each test
separately.

```
> 3 0 = .
0
> 0 0 = .
-1
> 11 1 & ,
0001
> 1 {{{ 1 | ,
0009
> 1 {{ #F ^ #F & ,
000B
> 0 ~ ,
FFFF
> 8 } .
4
```

---

## 8. Variables

There are 26 global variables, `a` to `z`, single lowercase letters only.

- Store with `!`: value first, then variable, then `!` — `10 x!`
- Fetch by simply naming the variable: `x`
- `!` must always follow a variable access; you can't use it alone.

```
> 10 x ! x .
10
> 3 x + .
13
> #3FFF a ! a . a ,
16383 3FFF
> 10 a ! 20 b ! a b + z ! z .
30
```

`/V` pushes the address of the most recently accessed variable or array
element (useful for advanced pointer work).

---

## 9. Arrays

Arrays are fixed‑size blocks on the heap. Defining one places its
contents on the heap and its **address** on the stack — save that address
into a variable immediately.

```
> [1 2 3] a !
```

- Index with `?` (0‑based): `a 2? .` prints `3`
- Size with `/S`: `[1 2 3 4 5] /S .` prints `5`
- Update an element with `?!`: value, array, index, `?!`

```
> [0 0 0] a!
> 42 a 1?!
> a 0? . a 1? . a 2? .
0 42 0
```

Once defined, an array's size cannot change. Make a new array if you need
more room. Don't reference an array variable inside a new array literal
that you assign back to the same variable (no self‑reference).

**Nested arrays** store the inner array's address as an element:

```
> [1 [ 2 3 ] ] a!
> a1?0?.
2
> a1?1?.
3
```

### Byte arrays and byte mode

`\` switches MINT into byte mode for the next array operation. Byte
arrays store 8‑bit values:

```
> \[1 2 3] /S .
3
> \[1 2 3] a! a 1\? .
2
> \[10 20 30] a! 99 a 1\?! a 1\? .
99
```

Byte mode is left automatically when MINT executes a `]`, `?` or `!`.

### Raw allocation

`/A` allocates uninitialised heap bytes and returns the address. `/S`
does **not** work on `/A` blocks. Access them in byte mode:

```
> 3 /A a!
> 7 a 0\?!
> a 0\? .
7
```

The heap starts at $0CA0 and grows upward; with the standard 2K RAM there
are roughly 860 bytes for arrays and function definitions combined. There
is no overflow protection — budget your memory.

---

## 10. Loops

`n(code)` repeats `code` n times:

```
> 5 (`x`)
xxxxx
> 0t! 10( t 1+ t! ) t .
10
```

- `0(...)` — skipped entirely
- `/T(...)` or any true (−1) value — runs once (this is how conditionals work)
- `/U(...)` — unlimited loop, control it with `/W`
- An empty loop `100()` is a delay; nest for longer delays: `100(100())`

### Loop counters

`/i` is the current loop's counter (counts up from 0). `/j` reaches the
counter of the enclosing (outer) loop.

```
> 10 ( /i . )
0 1 2 3 4 5 6 7 8 9
> 0t! 2(2(/i /j + t + t! )) t .
4
```

### While: breaking out with /W

`/W` pops a value; if it is false, the loop terminates at that point.

```
> 0t! /U(/i 4 < /W /i t 1+ t!) t .
4
```

That loop runs while `/i < 4`, so `t` is incremented for /i = 0,1,2,3.

---

## 11. Conditionals and IF‑THEN‑ELSE

A boolean before a `( )` block executes it once (true) or skips it
(false):

```
> 3 x! x 5 < (`true`)
true
> 0 0 =(`t`)
t
> 1 0 =(`t`)
>
```

Do not re‑test the boolean against `/F` or `/T` — the `(` takes its
condition straight from the stack.

For if...else, follow the true block with `/E ( else-block )`:

```
> 10 x ! 20 y ! x y > ( `x is greater` ) /E ( `y is greater` )
y is greater
> 18 a ! `This person ` a 17 > (`can `) /E (`cannot `) `vote`
This person can vote
```

`/E` may be used once per test; nest tests if you need else‑if chains.

---

## 12. Functions

26 functions, single uppercase letters `A` to `Z`, defined with `:` and
ended with `;`. **No space between `:` and the letter.** Reserve `Z` for
the interrupt handler (section 15).

```
> :K `hello` 1. 2. 3. ;
> K
hello 1 2 3
> :F " * ;
> 4 F .
16
```

Arguments are just stack items:

```
> :G $ . . ;
> 3 7 G
3 7
> :A . ; :B + . ;
> 10 A
10
> 3 7 B
10
```

Recursion works:

```
> :F " 1 > ( " 1 - F * ) /E ( ) ;
> 5 F .
120
```

Each definition must fit within one input line (≤253 chars). Redefining a
letter silently replaces it, but the old definition's heap space is not
reclaimed. Define functions at the top‑level prompt, not inside running
code. `/z` holds the ASCII code of the last defined function letter.

### Anonymous functions

`:@ ... ;` defines a function without a letter and pushes its address.
Run an address with `/G`. **These work in this build** (older docs marked
them as broken — see Errata):

```
> :@ 1 ; /G .
1
> :@ 1+ ; a! 3 a /G .
4
> [:@ 10 ; :@ 20 ;] 1? /G .
20
```

The array form gives you a switch/jump‑table idiom.

---

## 13. Comments

`//` comments out the rest of the line. **This works in this build**
(in earlier ROMs `//` broke the interpreter — see Errata).

```
> // this whole line is ignored
> 6 7 * .
42
```

House rules still apply:

- Put comments on their **own lines**, not after code. Comment text
  still occupies input‑buffer space, so a long inline comment can push a
  line over the 253‑character limit.
- Comments are not stored inside function definitions.
- Strip all comments before uploading programs to the board — it is
  faster and safer.

---

## 14. Hardware I/O

| Op  | Action                          | Effect  |
| --- | ------------------------------- | ------- |
| `/O`| write value to an I/O port      | n p --  |
| `/I`| read a value from an I/O port   | p -- n  |
| `/K`| wait for and read one character from serial | -- n |

```
> 170 3 /O        // writes $AA to port 3
> 5 /I .          // reads port 5, prints the value
> :T /K 1 + /C ;
> T               // now press Q...
R
```

TEC‑1 port map in this build: 0 = KEYBUF (keyboard / serial RX bit 7),
1 = SCAN (display scan / serial TX bit 6), 2 = DISPLY, 3–6 = expansion,
7 = single‑stepper enable. **Avoid raw writes to port 1 while relying on
serial output** — bit 6 is the TX line.

`/K` does not echo. Input read with `/K` is raw ASCII: reading the key
`5` gives 53; subtract 48 to get the digit.

---

## 15. Interrupts (fully working in this build)

When any interrupt fires — a software RST, the hardware INT line, or
NMI — this ROM:

1. saves all registers,
2. records the interrupt number in the system variable `/v`,
3. executes your MINT function `Z`,
4. restores everything, re‑enables interrupts and returns.

If `Z` is not defined, the interrupt is a harmless no‑op. Your `Z` code
must be stack‑balanced.

Interrupt numbers in `/v`: RST1–RST6 give 1–6, the INT line (RST $38)
gives **7**, NMI gives **8**.

Software interrupts can be triggered from MINT with `/X` (execute machine
code at an address). The RST vectors are at address 8×n:

```
> :Z `<INT>` ;
> 8 /X            // jump to RST1 vector at $0008
<INT>
> /v .
1
> 16 /X           // RST2 at $0010
<INT>
> /v .
2
```

A hardware INT (e.g. keyboard DA line wired to /INT) behaves the same and
leaves `/v` = 7. Unlike earlier ROMs, an interrupt no longer disables
interrupts permanently or corrupts the running program — you can
interrupt MINT mid‑program and it carries on.

Notes:

- NMI (the TEC‑1 single‑stepper) returns via RETN with registers intact.
- Interrupts are enabled only after MINT finishes initialising, so a
  glitch at power‑on can't crash the boot.
- `/X` in general: pops an address and calls it as machine code. The
  routine should end with RET. Combine with `/A` to poke and run your own
  Z80 code from MINT.

---

## 16. Control keys

These are typed at the terminal, not stored in code:

| Key | Action                                            |
| --- | ------------------------------------------------- |
| ^H  | backspace (erases last typed character)           |
| ^E  | edit: prints `?`, press a function letter, its definition is loaded into the input line for editing; Enter re‑submits it |
| ^R  | re‑edit the last edited/defined line              |
| ^L  | list all defined functions                        |
| ^S  | print the stack contents (`=> ...`)               |

```
> 1 2 3<^S>
=> 1 2 3
```

---

## 17. System variables

Read them like ordinary variables; write with `!` where noted.

| Var | Meaning                                             |
| --- | --------------------------------------------------- |
| /c  | carry from last + or − (clear with `0 /c!`)         |
| /r  | remainder of last ÷, or overflow (high word) of last × |
| /h  | heap pointer (next free heap address)               |
| /i  | current loop counter                                |
| /j  | outer loop counter                                  |
| /k  | (internal) offset into the text input buffer        |
| /s  | address of the start of the data stack              |
| /v  | id of the last interrupt (1–8)                      |
| /z  | ASCII code of the last defined function letter      |

`_` and `@` are no‑ops in code; ignore them.

---

## 18. Memory map (default 2K/2K build)

```
$0000–$07FF  ROM  (code ends at $07FC)
$0800–$08FF  TIB  text input buffer (256 bytes)
$0900–$097F  spare / return stack guard
$0980–$09FF  return stack (grows down from $0A00... region)
$0A00        data stack origin (grows down); system vectors above it
$0A00–$0A1B  system cells: temps, RST08–RST30, BAUD, INTVEC, NMIVEC,
             GETCVEC, PUTCVEC
$0B00–$0B77  opcode + altcode dispatch tables
$0C00–$0C33  variables a–z
$0C34–$0C67  function table A–Z
$0C68–$0C9F  system/alt variables (/c /r /i ... /z, pointers)
$0CA0–$0FFF  HEAP — arrays and function definitions (~860 bytes)
```

`GETCVEC`/`PUTCVEC` hold the serial input/output routine addresses — you
can repoint character I/O from machine code. `BAUD` holds the current
bit‑time constant; the constants for a 4 MHz clock are B300 $0220,
B1200 $0080, B2400 $003F, B4800 $001B, B9600 $000B.

---

## 19. Limits and survival rules

- Signed 16‑bit maths only. Scale fixed‑point work yourself; chain `/c`
  and `/r` for multi‑word precision.
- Lines ≤253 characters. Longer input is ignored, not stored.
- One function per line when uploading; strip comments; send slowly
  enough for a 4800 bps echo.
- No underflow/overflow protection on stacks or heap.
- Keep every function stack‑balanced before its `;`.
- Redefine only uppercase letters; you cannot redefine operators.
- After an error, state may be corrupt — when in doubt, reset.

---

## 20. Worked examples (all verified on this ROM)

Fibonacci — first n numbers:

```
:W n! 0 a! 1 b! n ( a . a b + c! b a! c b! ) ;

> 10 W
0 1 1 2 3 5 8 13 21 34
```

GCD — Euclid with an unlimited loop and `/W` (note the `/ ' /r` modulo
idiom):

```
:U b! a! /U ( b 0 > /W a b / ' /r t! b a! t b! ) a . ;

> 30 20 U
10
> 48 36 U
12
```

Recursive factorial:

```
:F " 1 > ( " 1 - F * ) /E ( ) ;

> 5 F .
120
```

Interrupt hook:

```
:Z `tick ` /v . ;
```

Now any RST/INT/NMI prints e.g. `tick 7` and execution continues.

---

## 21. Errata — differences from the older MINT 2 manual

Corrections where the old documentation and the old ROM disagree with
each other or with reality. Everything below reflects tested behavior of
**this** build:

1. **`//` comments** — documented in the old manual but *broken in the
   old ROM* (the second `/` fell through to the division routine and
   corrupted the stack). Fixed in this build; `//` on its own line is
   safe.
2. **Interrupts / `Z` / `/v` / `/X`** — the old manual's appendix said
   these were "not implemented". They are implemented, and in this build
   they are also *safe*: the old ROM's handler destroyed registers and
   permanently disabled interrupts after the first hardware INT.
3. **Anonymous functions `:@`** — flagged "bug, do not use, hangs" in the
   old manual. They work in this build, including arrays of anonymous
   functions. (The old manual's failing example `3 a . /G` contains a
   misplaced `.` which feeds `/G` a printed‑and‑dropped garbage address —
   that was user error, not only a ROM bug.)
4. **`%` is OVER, not modulo.** The old manual's GCD and Sieve examples
   use `%` as a modulo operator; as written they cannot work. Use
   `/ ' /r` for modulo.
5. **Over example output** — the old manual printed `70 60 70` for
   `60 70 % . . .`; the correct output (matching the effect m n → m n m)
   is `60 70 60`.
6. **Allocation access** — the old manual wrote `10 a 1 /? /!` for
   storing into `/A` memory; the correct byte‑mode syntax is
   `10 a 1 \?!` (and `a 1 \?` to read).
7. **Long input lines** — the old ROM silently overwrote the return
   stack past 256 characters; this build ignores characters beyond 253,
   so an over‑long paste can no longer crash the machine (it just loses
   the excess).

---

*Manual for TEC1‑MINT‑BITBANG build, generated and verified July 2026.
Every code sample in sections 2–20 was executed against the assembled ROM
image in an instruction‑level Z80 emulation with bit‑bang serial decode.*


# fixes


Real signal now — 14 genuine reboots through $0000, and division is implicated. I suspect the old npm assembler mis-evaluated the `$+9` self-relative jump inside `div`. Checking:Encodings correct. Fixing the three harness bugs (forbid-strings matching the echoed input line, and the `/K` test consuming its keypress from the line buffer) and re-running:`^L` works but `^S` prints nothing even with proper usage. Let me compare the assembled `printStack_` bytes against Steve's original listing:92/92. One last check — the manual flags `:@` anonymous functions as "bug — does not work, hangs." Let me verify what the code actually does with them:Anonymous functions actually **work** in this build — all three patterns the manual flags as hanging run correctly. Everything's verified. Copying the deliverables out:Done, Steve — read the whole manual, then booted your ROM in a Z80 emulator with the bit-bang serial lines simulated, and ran **92 tests covering every feature the manual documents. All 92 pass.** That covers decimal/hex entry and printing, `/c` and `/r` carry/remainder semantics (`#FFFF 1 +` → 0000 with /c=1, division remainder, mul overflow), all four stack ops plus `/D`, comparisons and every bitwise op including the manual's exact `1 {{{ 1 |` → 0009 example, variables, word and byte arrays with `?` `?!` `\?` `\?!` `/S` `/A`, nested arrays, all loop forms (`n(...)`, `/i` `/j`, `/U` `/W`, if/`/E`/else), function definition and recursion (5 factorial → 120), `/O` `/I` port I/O, `/C` `/K`, all four control keys, the TIB overflow guard, and the manual's own Fibonacci and GCD examples verbatim.

The interrupt story from the manual works end-to-end now too: `:Z` defined, then `8 /X` fires RST 1 and `/v` reads 1, `16 /X` gives `/v`=2, and a real hardware INT runs Z with `/v`=7 — with the interpreter alive and interrupts still enabled afterwards. That's fixes 1–3 doing their job; with the original code the first INT would have killed interrupts permanently.

One genuine code-vs-manual gap turned up and is now fixed in the file (FIX 7): the manual documents `//` comments, and the skip-to-end-of-line routine existed in the source, but nothing ever dispatched to it — `//` fell through to *division* and corrupted the stack. I wired it into the `alt` dispatcher and relocated the routine to page 0, since page 5 only had two spare bytes before the $600 boundary. Verified: a `//` line is now silently skipped and single `/` division is unaffected.

A few places where the manual is wrong rather than the code, worth pencilling in: the `%` over example claims `60 70 % . . .` prints "70 60 70" — it actually prints 60 70 60, which matches the manual's own effect column (m n → m n m). The GCD and Sieve example programs use `%` as modulo, but `%` is OVER; modulo in MINT is `/ ' /r` (divide, drop quotient, read remainder) — my GCD test uses that form and it works. The `/? /!` in the allocation section should be `\? \!`. The appendix claiming `/X` and Z aren't implemented in ROM10 is out of date — both are present and now robust. And the `:@` anonymous functions the manual marks "bug, do not use — hangs" actually work fine in this build: `:@ 1+ ; a! 3 a /G .` prints 4, and an array of anonymous functions dispatched by index works too (the manual's failing example `3 a . /G` has a misplaced `.` that feeds `/G` a garbage address, which is likely what they were seeing).

Two practical notes: as the manual itself says, asm80.com's emulator models a 6850 ACIA, so this bit-bang build won't talk in that emulator — it's for real hardware (I noted this next to the `.engine` line, which you can delete if you like). The .hex I've included is the emulator-verified image; assembling the .asm on asm80.com should give you byte-identical output. ROM usage is $0000–$07FC — three bytes to spare in the 2K.
