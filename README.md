 


<img width="555" height="555" alt="image" src="https://github.com/user-attachments/assets/404baeeb-6ae2-4975-b781-face3bb329e7" />

# News
3 july 2026 fixed all bugs in v2, called it v3 but its still v2 features without the bugs ( i hope)


# Down to business...
Down to business, chaps! And now for something completely similar...

* 'Tis a pint-sized, lightning-swift Forth-ish contraption, crafted with loving care for the noble TEC-1 prototype and its rather dim-witted simian kin—revs A, B, C, D (E? F? Who knows!), G, and the mighty SCC; and if the whole blasted lot explodes in a puff of logic, by Jove, prop up the Micocomp-1 under a chair leg and call it a day!

* A staggering [2,000 – 10,000 MINT words per second](https://github.com/SteveJustin1963/tec-MINT/wiki/speed) on a 1 MIPS, 4MHz clock, no less—or, if you prefer, or two order of magnitude slower than whatever clock you've got ticking away in your pocket!

* Dont have a TEC-1 ? Then pop your code into asm80 (16MHz clock, old bean) and behold: approximately 1,600,000 parsecs—or 4000 shekels, give or take six sigma—on a jolly sunny afternoon, round about 3:23pm, with tea and crumpets optional!

* Or if you prefer hyperspace drive use my mint_octave code

* Permits rapid prototyping of code, effortless concatenation, no tiresome compiling, runs forthwith like a knight on a quest—test as you build, and build as you test, what ho!

* Should an undetected error sneak past like a dead parrot, do treat yourself to a hearty punch to the n@@ts—it's the only decent reward!

* [THE SOURCE CODE](https://github.com/orgMINT/MINT) (fanfare, please!)
* https://github.com/tec1group/MINT-cookbook — the ver1 goodies, straight from the ministry!
* The [monsonite site](https://github.com/monsonite/MINT) (somewhere in the colonies, no doubt)
* [FB Search](https://www.facebook.com/groups/623556744820045/search/?q=mint) (for when you're feeling social)
* [spreadsheet help files](https://docs.google.com/spreadsheets/d/1uoJT1DG8Mu-oMqlK1f7USof6CF3R0vvWduXqJm4WmjY/)  (because even knights need a ledger)
* [Code to keep punching](https://github.com/SteveJustin1963/tec-MINT/tree/main/code) ... and scattered across my GitHub like holy grail crumbs
* My ongoing updated [SJ Manual Mint V2.md](https://github.com/SteveJustin1963/tec-MINT/blob/main/MINT2%20Manual.md) (now with 50% more wisdom!)
* Everybody expects the Spanish Inquisition so here is my [autopsy and extraction](https://github.com/SteveJustin1963/tec-MINT/wiki) dissecting the beast!
* https://github.com/crsjones/ETI-Simple/tree/main
 

# Acknowledgments

```
The structuring or acknowledgment of the individuals involved
in the development of the MINT interpreter
follows no discernible hierarchy or prioritization of recognition,
implying that their contributions are regarded in a manner
devoid of any preordained or systematic reverence.
This lack of sequentiality reflects an egalitarian or arbitrary approach,
wherein no specific developer is elevated above another
in terms of the order of respect or recognition for their work.
```
<img width="365" height="610" alt="Tribute to Chucky Moore the II" src="https://github.com/user-attachments/assets/4ed8ede4-673a-4334-9ea4-7ff66e2856a6" />


# Announcements
  - https://www.facebook.com/groups/tec1z80/posts/1250512652124448/ 
  - https://github.com/SteveJustin1963/tec-MINT/blob/main/docs/history.md

![](https://github.com/SteveJustin1963/tec-MINT/blob/main/pics/263565308_1147844542415783_7150078760328965579_n.jpg)

# Videos
- https://github.com/SteveJustin1963/tec-MINT/blob/main/pics/video-1638969598.mp4
- https://github.com/SteveJustin1963/tec-MINT/blob/main/pics/video-1639658972.mp4
- https://www.youtube.com/watch?v=m66y6C54Cds **Alright, buckle up buttercup, because we're about to embark on a 3.5 hour cinematic quest, longer than a toddler's nap after a sugar rush!**




# Time for MINTing 

![image](https://github.com/user-attachments/assets/76699c73-d350-4f52-a544-398e5a6214a2)
 
Ah, right then, gather 'round, ye code-crunching wizards! You must read my excessively scribbled-upon, over-explained, and possibly bewildering edition of the MINT2 Manual, now with 67% more footnotes and unnecessary asides. When done reading, try and code some wild and mysterious code fragments then give em a good ol smoke test and modify on the fly— which, in this case, may or may not be assisted by some questionable items of dubious legality. As the test hacking progresses, you’ll inevitably amass a sizeable collection of code nuts — so be sure they’re good and crispy! Next, tie up those nuts but not too tightly into neat function bundles labeled with :A....: , :B....; and so on, until all your nuts are firmly in place so not one dares to escape from use. And now for the Pièce de Résistance: take a deep breath, fling your functions around like a fish monger upon their glorious unification shouting with confidence, “This piece of halibut is good enough for Jehovah!” and Voilà! You've now written and used MINT code for intergalactic conquest.


And now for something completely... calculable! As MINT can be a right slippery eel to wrangle solo, I’ve concocted **MINT-Octave**—a splendid version that lounges luxuriously inside a Linux terminal, flexing its muscles on heavier maths, floating-point jiggery-pokery, transcendental tomfoolery, and all manner of advanced wizardry. It boasts **multiple modes** (not just FP, mind you—there’s integer mode for the purists), plus a **built-in debugger** so you lot of vibe-coding knights can ping-pong merrily between MINT-Octave and the genuine Z80-powered MINT to squash bugs faster than a Spaniard with a comfy chair. Consult the manual, post-haste! Once you’ve mastered the beast, cast off the training wheels, hoist that colossal boulder aloft, and **hurl it with gusto**! **Pro tip:** If your nuts are sore, torn asunder, or simply knackered—apply the sacred **POLA cream** as nobody expects an Inquisition!



# Specs
You can run small programs in 2k but for real halibut you need to max out your ram physically (see below), the tec-1d can take 2k x 7 chips (14k) or if using the asm80.com emulation of the code, max out the ram in file `constants.asm` aka... for then non-puritans there's the fully sic TEC1-G.

```
; Configuration for TEC-1
LOADER EQU 0
BITBANG EQU 0
        
ROMSTART    EQU $0000
RAMSTART    EQU $0800
ROMSIZE     EQU $0800
RAMSIZE     EQU $4000   ;this is 14k of ram (like a real tec1-D maxed out), asm80 can take it bigger
```
This may also help if your nuts are too big — just change ram.ram to show TIBSIZE EQU $800 on both the TEC-1 and asm80 builds. That lets you enter huge nuts of code per line. The text input buffer (TIB) is where your code lives, and it’s also reused to display code when you press Ctrl-L.

When running MINT under asm80 emulation, I made a nifty upload tool called autotyper.py. It auto-types directly into any window — including the asm80 console — while MINT is running, and it conveniently strips out any comments starting with //.

 


# The Build
# My attempt to run v1.1, first go

- using an EEPROM; AT28C64B.  https://github.com/SteveJustin1963/eeprom-programmer/wiki/eeprom
- compile v1.1, set flags as needed
- mod the socket, install eeprom, hangs over the existing rom socket by 2 pins each side. make the mod
- result; turn a 24 pin socket into 28 pins, lucky the pinout is identical except for A12 and VCC
- see this https://github.com/SteveJustin1963/tec-MINT/blob/main/docs/MemoryDevices01.pdf
 
![](https://github.com/SteveJustin1963/tec-MINT/blob/main/pics/ee%20pins2.png)

- cut off a 2x2 off a wide socket bend the pins out and epoxy to the end of the 24 sock, attach wires
- make a bigger socket to 28 pins
- one pin will touch the wire bridge, so unsolder it and just solder it to pad landing, dont let the wire poke thru and touch the socket pin.
- solder another wire from vcc on lhs so rom select switch 5v.

![](https://github.com/SteveJustin1963/tec-MINT/blob/main/pics/IMG_8433.jpg)

![](https://github.com/SteveJustin1963/tec-MINT/blob/main/pics/sock1.png)

- Terminal on PC; TeraTerm at https://ttssh2.osdn.jp/
  - has variable baud rates, helps to find timing faults
- USB to TTL serial cable, TTl 5v is close enough for rs232
  - has embedded chip for usb to ttl 
  - 4 wires, tx-green rx-white gnd-blk 5v-red
- the pc will load PnP driver and allocate a com port
  - find in device manager
  - Teraterm will list it so select it
  - do a loop back test, short tx-rx, should echo char in terminal screen
- as we opted without a uart we can use serial bitbang
  - compile and get code that supports it, default is 4800
  - need 4mhz clock
- add cct mod for serial line off data bus,  https://github.com/SteveJustin1963/tec-BIT-BANG
![tec1-schematic](https://github.com/user-attachments/assets/d316e4da-a300-4390-832a-6fd06e389e6e)
![](https://github.com/SteveJustin1963/tec-MINT/blob/main/pics/IMG_8455.jpg)
![](https://github.com/SteveJustin1963/tec-MINT/blob/main/pics/IMG_8483%20(1).jpg)
![](https://github.com/SteveJustin1963/tec-MINT/blob/main/pics/IMG_8484%20(1).jpg)
![](https://github.com/SteveJustin1963/tec-MINT/blob/main/pics/IMG_8485%20(1).jpg)
![](https://github.com/SteveJustin1963/tec-MINT/blob/main/pics/IMG_8486%20(1).jpg)
![](https://github.com/SteveJustin1963/tec-MINT/blob/main/pics/IMG_8487%20(1).jpg)
![](https://github.com/SteveJustin1963/tec-MINT/blob/main/pics/IMG_8488%20(1).jpg)
![](https://github.com/SteveJustin1963/tec-MINT/blob/main/pics/IMG_8467.jpg)
![]()

# Build v 1.1
- set correct flags for the build and then compile and then burn the rom. this will combine bitbang with MINT
- “it finally works"!  

# Ver 2 getting respectable
- new release, see my updated ver 2 manual 
- John still fixing bugs  [bugs](https://github.com/orgMINT/MINT/issues)
- my 2k cannot handle big halibut, i should move to 4k or more, or the mighty G ? 
- I wish to add SPI cct .. see [tec-SCOPE ](https://github.com/SteveJustin1963/tec-SCOPE)
- need to test /int calls :Z function
- need a larger variable and function set, increased to 2 characters would be a good start

# Ver 3 2025 maybe 
- adapted from JH's comments
- maintain the classic 1D, hell yes!
- add with modification the last two high address to get 6k more out of eeprom
- ![image](https://github.com/user-attachments/assets/9d753110-e74e-45b1-a050-2187cc91c0a7)
- ![image](https://github.com/user-attachments/assets/36d45b5b-a19b-4acb-93f1-78bcea778814)
- arrays and strings are handled the same way, never directly stored on the stack, uses heap space (grows with ram)
- need examples of calculations when doing floating point and/or matrices...even the most basic floating point number could be considered an array with one element in it.
- consider ideas from APL style languages, next MINT will be https://github.com/SteveJustin1963/Tec-TACIT
- add SPI master
- enhance /INT :F
- enhance ASM calls and return
- the Big halibut **Will do 32-bit floating point signed number!** 
- btw, FP always goes into a VAR, and if its put on the stack, only the pointer is stored there

```
The range depends on the allocation of bits for the sign, exponent, and mantissa. Following the typical IEEE 754 format:
1 bit for the sign
8 bits for the exponent (bias of 127)
23 bits for the mantissa (plus an implicit leading 1 for normalized numbers)
```
- the stack is only for 16-bit integers and pointers, then mint doesn't need to change very much and you could have larger than 32-bit floating point numbers.

# FP range is:

![image](https://github.com/user-attachments/assets/4f85de62-eb23-4f8c-94b9-0629619b52d6)

- https://en.wikipedia.org/wiki/IEEE_754

# work in progress
- playing with 7 seg display
- https://github.com/SteveJustin1963/tec-MINT/blob/main/code/8-LED-light-chaser.md
- https://github.com/tec1group/MINT-cookbook/tree/main/misc/4-digit-counter
- adding new features to mint octave, issues with parsing and list command compressing spaces
- build CUDA connections to speed up more

 

 



![image](https://github.com/user-attachments/assets/e15ac155-4a9c-48a9-a4c3-31413bce2aa3)
