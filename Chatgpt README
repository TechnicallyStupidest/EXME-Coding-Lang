# EXME 1.0

## 1. What EXME is

EXME is an extremely low-level compiled language where the programmer controls the exact bytes placed into the final binary.

EXME does **not** automatically convert instructions such as addition, printing, jumping, or function calls into CPU instructions.

Instead, you provide the exact machine-code bytes yourself.

The EXME compiler mainly does this:

```text
.EXME source
      ↓
read offsets and exact bytes
      ↓
place those bytes into the requested locations
      ↓
write the final binary
```

The programmer controls:

```text
CPU instruction bytes
register usage
memory layout
file layout
endianness
calling convention
jump offsets
function calls
return instructions
operating-system interfaces
executable headers
sections
imports
exports
relocations
entry points
```

EXME does not decide these things for you.

---

# 2. File extension

EXME source files use:

```text
.exme
```

Example:

```text
game.exme
robot.exme
math.exme
kernel.exme
```

---

# 3. Philosophy

EXME follows three main ideas.

## Everything is explicit

The compiler should make as few decisions as possible.

You choose:

```text
where bytes go
how many bytes exist
what those bytes are
what CPU instruction they represent
```

## Only four operation groups

EXME keeps four operation letters:

```text
W
G
M
J
```

They are organizational categories.

They do NOT automatically generate particular CPU instructions.

## Same syntax style everywhere

EXME uses forms such as:

```text
*@M<
    ...
>$
```

and directives such as:

```text
~file\...~
```

Fields are separated with:

```text
\
```

---

# 4. Basic symbols

## `*`

Means:

```text
start
```

Example:

```text
*@M<
```

---

## `@`

Means:

```text
at
```

It is part of the EXME operation syntax.

---

## `<`

Starts an operation block.

```text
*@M<
```

---

## `>`

Closes an operation block.

---

## `$`

Marks the end of an operation.

```text
>$
```

---

## `\`

Separates fields.

Example:

```text
O120\B5\XB83C000000
```

This contains three fields:

```text
O120
B5
XB83C000000
```

---

# 5. Comments

EXME comments begin with three backticks.

Example:

````text
~file\B132\F00~ ``` create 132 byte binary
````

Everything following:

```text
```

````

on that line is ignored.

Example:

```text
*@J<
    O130\
    B2\
    X0F05
>$ ``` syscall instruction
````

---

# 6. Creating the output file

Every binary starts by declaring its exact size.

Syntax:

```text
~file\B<size>\F<byte>~
```

Example:

```text
~file\B4096\F00~
```

Meaning:

```text
B4096
```

Create a file exactly:

```text
4096 bytes
```

long.

And:

```text
F00
```

means initially fill every byte with:

```text
00
```

---

# 7. `B` — byte count

`B` means:

```text
Bytes
```

Example:

```text
B5
```

means:

```text
exactly 5 bytes
```

Example:

```text
B4096
```

means:

```text
4096 bytes
```

EXME does not infer sizes.

If you say:

```text
B5
```

you must provide exactly five bytes.

---

# 8. `O` — output offset

`O` means:

```text
Offset
```

Example:

```text
O120
```

means:

> Start writing at byte 120 of the final binary.

Example:

```text
*@M<
    O120\
    B5\
    XB83C000000
>$
```

means:

```text
offset: 120
length: 5 bytes
bytes:
B8 3C 00 00 00
```

---

# 9. `X` — exact hexadecimal bytes

`X` means:

```text
exact hex bytes
```

Example:

```text
XB83C000000
```

represents:

```text
B8 3C 00 00 00
```

EXME does not interpret these as a particular CPU instruction.

If x86-64 interprets those bytes as:

```asm
mov eax, 60
```

that is because **you chose the correct x86 encoding**.

EXME simply writes the bytes.

---

# 10. `F` — fill byte

`F` is used with the file declaration.

Example:

```text
F00
```

means:

```text
initialize unused bytes to 00
```

Example:

```text
~file\B1024\FFF~
```

would initially fill the file with:

```text
FF
```

---

# 11. Raw data

Use:

```text
~data\O<offset>\B<count>\X<hex>~
```

Example:

```text
~data\O1024\B4\X01020304~
```

means:

```text
at offset 1024
write exactly 4 bytes

01 02 03 04
```

EXME does not assign a data type.

They are simply bytes.

---

# 12. Integer representation

EXME does not automatically encode integers.

Suppose you want:

```text
10
```

as a 32-bit little-endian integer.

You manually write:

```text
~data\O1024\B4\X0A000000~
```

The bytes are:

```text
0A 00 00 00
```

If your target required big-endian data, you would write:

```text
~data\O1024\B4\X0000000A~
```

EXME does not choose endianness.

---

# 13. Strings

Strings are also manually encoded bytes.

For example:

```text
Hello
```

in ASCII is:

```text
48 65 6C 6C 6F
```

So you could write:

```text
~data\O500\B5\X48656C6C6F~
```

EXME doesn't automatically:

```text
encode strings
add null terminators
store lengths
choose UTF-8
choose UTF-16
```

You control those decisions.

---

# 14. Four EXME operation groups

EXME has four operation letters:

```text
W
G
M
J
```

They preserve EXME's original four-operation design.

In EXME 2.0 they do **not** automatically generate CPU instructions.

---

# 15. `W` — Write category

Syntax:

```text
*@W<
    O<offset>\
    B<count>\
    X<bytes>
>$
```

Example:

```text
*@W<
    O300\
    B4\
    X90909090
>$
```

EXME writes:

```text
90 90 90 90
```

at offset:

```text
300
```

`W` is normally used to organize code related to output/writing.

But EXME does not assume that the bytes actually perform output.

---

# 16. `G` — Get category

Syntax:

```text
*@G<
    O<offset>\
    B<count>\
    X<bytes>
>$
```

Example:

```text
*@G<
    O125\
    B5\
    XBF2A000000
>$
```

This writes five exact bytes at offset 125.

The compiler does not know whether those bytes:

```text
read input
load a register
access hardware
do nothing
```

The CPU decides based on the byte sequence.

---

# 17. `M` — Math category

Example:

```text
*@M<
    O120\
    B5\
    XB83C000000
>$
```

Again, `M` does NOT mean:

```text
perform math automatically
```

It only organizes the source as a math-related operation.

You must encode the actual CPU instruction.

For x86-64:

```text
B8 3C 00 00 00
```

happens to represent an instruction involving a register.

EXME doesn't generate it.

---

# 18. `J` — Jump/control category

Example:

```text
*@J<
    O512\
    B5\
    XE9F0FFFFFF
>$
```

Here you manually provide the exact jump instruction.

You must calculate:

```text
jump opcode
instruction width
target address
relative displacement
endianness
encoded displacement
```

EXME will not calculate those for you.

---

# 19. Raw return instruction example

On x86-64:

```text
C3
```

is the common `RET` opcode.

EXME:

```text
*@J<
    O800\
    B1\
    XC3
>$
```

You chose:

```text
C3
```

EXME simply places it at offset:

```text
800
```

---

# 20. Functions

Functions can still be used to organize EXME source.

Syntax:

```text
~func function_name~

    ...

~endfunc~
```

Example:

```text
~func calculate~

    *@M<
        O800\
        B3\
        X909090
    >$

    *@J<
        O803\
        B1\
        XC3
    >$

~endfunc~
```

Important:

`~func~` does NOT automatically generate:

```text
stack frame
CALL
RET
arguments
register saving
register restoring
calling convention
```

You manually encode all of those.

---

# 21. Calling functions

EXME does not automatically calculate a call.

For x86 you may use a `CALL rel32` instruction.

But you must calculate:

```text
function location
CALL instruction location
next instruction address
relative displacement
byte order
```

Then manually provide the correct bytes.

---

# 22. Imports

Syntax:

```text
~import "filename.exme"~
```

Example:

```text
~import "graphics.exme"~
```

Imports behave like source inclusion.

If:

```text
graphics.exme
```

contains:

```text
~data\O2000\B4\XAABBCCDD~
```

then those bytes are written at offset 2000.

EXME does not relocate imported code.

You are responsible for preventing offset collisions.

---

# 23. File offsets

The output file starts at:

```text
O0
```

Then:

```text
O1
O2
O3
...
```

Each number represents a byte position in the final file.

Example:

```text
O100
```

means:

> the 101st byte of the file, because counting begins at zero.

---

# 24. No automatic memory allocation

EXME does not contain traditional variables such as:

```c
int x;
```

You manually create bytes and decide what they mean.

Example:

```text
~data\O2000\B8\X0000000000000000~
```

You might decide that those eight bytes represent:

```text
signed integer
pointer
floating point number
bit field
hardware register
```

EXME itself does not know.

---

# 25. No automatic registers

EXME does not choose:

```text
RAX
RBX
RCX
RDX
R8
R9
```

You choose the machine-code encoding that uses the register you want.

---

# 26. No automatic instruction selection

EXME does not decide between things such as:

```asm
inc eax
add eax, 1
lea eax, [eax+1]
```

You manually choose the exact instruction and encode its bytes.

---

# 27. No automatic jumps

EXME does not resolve labels into branch offsets.

You calculate them.

Example formula for a typical x86 relative branch:

```text
relative offset =
target address - address after jump instruction
```

Then you encode the result manually.

---

# 28. No automatic executable format

If you want a Windows `.exe`, you must create the required PE structure yourself.

That can include:

```text
DOS header
PE signature
COFF header
optional header
section table
code section
data section
entry point
import directory
relocations
permissions
```

EXME does not create them automatically.

---

# 29. Linux ELF

For Linux executables, you manually create things such as:

```text
ELF magic
architecture
entry point
program headers
segment permissions
virtual addresses
file offsets
machine code
```

EXME simply writes the bytes.

---

# 30. Firmware / raw binaries

EXME does not require PE or ELF.

You can create:

```text
firmware.bin
ROM images
boot sectors
microcontroller binaries
custom binary formats
```

Example:

```text
~file\B32768\FFF~
```

Then populate exact offsets.

This means EXME itself isn't locked to one CPU architecture.

---

# 31. CPU architectures

Because EXME doesn't generate CPU instructions, you can theoretically write bytes for:

```text
x86
x86-64
ARM
ARM64
RISC-V
AVR
other architectures
```

You are responsible for knowing the target instruction encoding.

---

# 32. Operating-system APIs

EXME does not automatically call Windows or Linux APIs.

For Windows, you must manually construct whatever executable/import machinery your program requires.

For Linux, you could manually use system-call instructions.

The exact requirements depend on your target operating system and CPU.

---

# 33. Calling conventions

EXME does not automatically implement:

```text
Windows x64 ABI
System V AMD64 ABI
cdecl
stdcall
fastcall
```

If another language calls your EXME code, your machine code must manually follow the required convention.

That includes things such as:

```text
argument registers
stack arguments
stack alignment
callee-saved registers
caller-saved registers
return registers
```

---

# 34. Libraries

You can create libraries with EXME, but the binary format is manually constructed.

For example, a Windows DLL requires the appropriate PE/DLL structures.

A Linux shared object requires the appropriate ELF shared-library structures.

EXME doesn't build export/import tables automatically.

---

# 35. EXME compiler responsibilities

The compiler intentionally does very little.

It handles:

```text
reading .exme files
reading imports
parsing EXME syntax
reading offsets
reading byte counts
converting hex text to bytes
placing bytes into the output file
writing the final file
```

It may also perform basic compile-time checks such as:

```text
invalid hex
wrong byte count
offset outside declared file
invalid syntax
```

These checks happen while compiling.

They do not add runtime instructions.

---

# 36. What EXME does NOT do

EXME does not automatically provide:

```text
variables
garbage collection
memory allocation
arrays
strings
classes
objects
exceptions
runtime type checking
automatic integer types
bounds checking
overflow checking
register allocation
instruction selection
optimization
function ABI generation
stack frames
system calls
PE generation
ELF generation
relocations
linking
debug information
```

Unless those are manually represented in your bytes.

---

# 37. Example: manually built Linux program

A small Linux x86-64 program might eventually execute:

```asm
mov eax, 60
mov edi, 42
syscall
```

Machine bytes:

```text
B8 3C 00 00 00
BF 2A 00 00 00
0F 05
```

EXME:

```text
*@M<
    O120\
    B5\
    XB83C000000
>$

*@G<
    O125\
    B5\
    XBF2A000000
>$

*@J<
    O130\
    B2\
    X0F05
>$
```

The EXME compiler doesn't know this means:

```text
exit(42)
```

It only knows:

```text
write these bytes
at these offsets
```

The ELF header and program header must also have been manually supplied elsewhere in the file.

---

# 38. Example raw binary

```text
~file\B16\F00~

~data\O0\B4\X01020304~

*@M<
    O4\
    B4\
    XAABBCCDD
>$

*@J<
    O8\
    B1\
    XC3
>$
```

Final file:

```text
Offset   Bytes

0        01 02 03 04
4        AA BB CC DD
8        C3
9-15     00
```

---

# 39. Compile EXME

Typical usage:

```text
exme program.exme -o program.bin
```

If the source contains a complete valid Windows executable layout:

```text
exme program.exme -o program.exe
```

If it contains a complete ELF:

```text
exme program.exme -o program
```

EXME doesn't determine the file format from the extension.

The **bytes you wrote** determine what the file actually is.

---

# 40. EXME vs assembly

Assembly:

```asm
mov eax, 60
```

Assembler converts that to:

```text
B8 3C 00 00 00
```

EXME Manual requires you to provide:

```text
XB83C000000
```

yourself.

Therefore:

```text
Assembly
    ↓
assembler decides instruction encoding
    ↓
machine code
```

while EXME is:

```text
EXME
    ↓
YOU decide machine-code encoding
    ↓
compiler places your bytes
```

---

# 41. EXME vs raw hex editing

Raw hex editing would require directly editing every position in a binary file.

EXME gives you a structured source format:

```text
*@M<
    O120\
    B5\
    XB83C000000
>$
```

so machine-code projects can still be:

```text
organized
split into files
commented
grouped into functions
imported
version controlled
```

while retaining exact byte control.

---

# 42. Why keep W/G/M/J?

They organize source code into four conceptual areas:

```text
W = output/write-related machine code
G = input/get-related machine code
M = computation/math-related machine code
J = control/jump-related machine code
```

But they do not restrict what bytes can be placed inside them.

This preserves EXME's original four-operation identity without allowing the compiler to make instruction decisions.

---

# 43. Recommended EXME source organization

A larger program could look like:

````text
~file\B8192\F00~

``` executable headers

~data\O2048\B... \X...~

~import "math.exme"~
~import "graphics.exme"~

~func update~

    *@M<
        ...
    >$

    *@J<
        ...
    >$

~endfunc~

~func render~

    *@W<
        ...
    >$

    *@J<
        ...
    >$

~endfunc~
````

You must coordinate every output offset across all imported files.

---

# 44. Major danger of EXME

EXME gives the programmer almost complete control.

That means mistakes can result in:

```text
invalid executables
CPU exceptions
crashes
incorrect jumps
corrupted stack state
bad pointers
wrong calling conventions
invalid OS structures
incorrect endianness
overlapping code/data
```

This is intentional.

EXME is not designed to protect the programmer from low-level mistakes.

---

# 45. Current EXME keyword summary

## Directives

```text
~file~
~data~
~import~
~func~
~endfunc~
```

## Operations

```text
W
G
M
J
```

## Fields

```text
O = output offset
B = byte count
X = hexadecimal bytes
F = initial file fill byte
```

## Structural symbols

```text
* = start
@ = at
< = begin block
> = close block
$ = end operation
\ = field separator
```

## Comment

```text
```

````

begins an EXME comment for the remainder of the line.

---

# 46. EXME design rule

When adding future EXME syntax, it should continue following the same style.

Prefer:

```text
~thing\FIELD\FIELD~
````

or:

```text
*@X<
    FIELD\
    FIELD\
    FIELD
>$
```

Do not suddenly introduce unrelated C-style syntax such as:

```c
function test() {
}
```

The language should remain visually consistent with EXME.

---

# 47. Short EXME cheat sheet

```text
~file\B4096\F00~
```

Create exact output size.

```text
~data\O100\B4\XAABBCCDD~
```

Place raw data.

```text
*@W< O200\B3\XABCDEF >$
```

Write exact bytes under W category.

```text
*@G< O300\B2\X1234 >$
```

Write exact bytes under G category.

```text
*@M< O400\B5\XB801000000 >$
```

Write exact bytes under M category.

```text
*@J< O500\B1\XC3 >$
```

Write exact bytes under J category.

```text
~func name~
...
~endfunc~
```

Organize code as a function.

```text
~import "other.exme"~
```

Include another EXME source file.

---

# 48. EXME in one sentence

**EXME is a structured raw-machine-code authoring language where the programmer decides essentially every byte and the compiler mainly places those bytes into the final binary exactly where requested.**
