# EXME-Coding-Lang
It is a a coding lang called EXME which mean execute me becasue you will most likely want to execute yourself when coding in this lang
# HOW TO USEE
Build it with
``` compiler\exme_build_windows.bat```
Install Vs code extenison with

``` vscode_extension\exme_install_vscode_windows.bat```

you can compile it like this 

```compiler\exme.exe program.exme --target windows-x64 -o program.exe```

# How to code in EXME

EXME has 4 executable operations 

W = write/output

G = get/input

M = math

J = jump/control flow

btw waring umm it is like asm where it is a lazy bum and you have to tell every single detail lol

* means start

@ means at

< starts a opp block like {} in C++

> ends a opp block like {} in C++

$ means end of a opp

\ separates diff fields

``` means comment must end in ``` too like ```hi this coding lang sucks ```

B means byte

O is output offset

X is hex bytes

F is fill byte

start a line of code with data to do command stuff

strings are manually encoded bytes.

W is write is made is this way *@W< O<offset>\ B<count>\ X<bytes> >$

G i get made in this way *@G< O<offset>\ B<count>\ X<bytes> >$

M is math made in this way exp *@M< O120\ B5\ XB83C000000 >$

J is jump made this is way exp *@J< O512\ B5\ XE9F0FFFFFF >$

you must chose raw return instruction example exp *@J< O800\ B1\ XC3 >$

use ` to end funcs exp ~func function_name~ ... ~endfunc~

you must  calc a call by your self

