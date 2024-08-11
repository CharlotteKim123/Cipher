    // version 1.1 10/29/2022 //
#ifndef MYMAIN_S
#else
    .arch   armv6
    .arm
    .fpu    vfp
    .syntax unified

    // imports
    #include "main.h"
    #include "rdbuf.h"
    #include "setup.h"
    #include "cipher.h"
    .extern fwrite
    .extern stdin
    .extern stdout
    .extern stderr

    .section .rodata
    // do not change these error messages
.Lbdrd:  .string "%s: read failed\n"
.Lbdwr:  .string "%s: write failed\n"

    .text

    //
    // encrypter -b bookfile
    //
    // int main(int argc, char **argv)
    // int main(r0=argc, r1=argv)

    .global main
    .type   main, %function

    //
    // stack frame layout
    //
    // TODO Part 2: complete the following stack frame design
    // You can change or delete any comments in this file
    //
    .equ    FP_OFF,     32           // fp offset in main stack frame
    .equ    FPBOOK,     4 + FP_OFF   // FILE * to book file
    .equ    IOBUF,      BUFSZ + FPBOOK   // buffer for input file
    .equ    BOOKBUF,    BUFSZ + IOBUF  // buffer for book file
    .equ    ARGV0,      4 + BOOKBUF // save argv[0] for error printing
    //
    // add your local variables here if you need them:
    // NOTICE: Adjust PAD so FRMADD + FP_OFF + 4 divides by 8 EVENLY!
    //
    .equ    PAD,      4 + ARGV0           // Stack frame PAD
    .equ    OARG5,    4 + PAD             // output arg5 must be at bottom
    .equ    FRMADD,   OARG5-FP_OFF        // space in frame for locals+passed args

    // TODO Part 2: list how you are using the preserved registers
    // preserved register use
    // r4 
    // r5
    // r6
    // r7
    // r8
    // r9
    // r10

main:
    push    {r4-r10, fp, lr}        // push all the usable preserved registers
    add     fp, sp, FP_OFF          // set frame pointer to frame base
    ldr     r3, =FRMADD             // get space needed for locals+passed args
    sub     sp, sp, r3              // allocate space for locals and passed args 
    
    // save argv[0] in argv0
    ldr r2, [r1]
    str r2, [fp, -ARGV0]
    // at the entry to main() argc is in r0 and argv is in r1.
    // call int setup(r0=argc, r1=argv, r2=*FPBOOK)
    // r2 is output parameter. Get the addresses of where
    // FPBOOK is located on main()'s stack and put this in r2
    // so setup can fill it in (passing a pointer to a local variable in r2)
    // if setup fails, put EXIT_FAILURE in r0 and then branch to .Lexit
    sub r2, fp, FPBOOK
    bl setup
    cmp r0, #0
    bne .Lexit_failure
    // set up for main loop
    // save the variables you need in the preserved registers as you will be making
    // function calls in the loop body below and r0-r3 will be used for that
    mov r4, r2
    sub r5, fp, BOOKBUF
    str r5, [fp, -OARG5]

.Lloop:
    // this is a loop that runs until rdbuf indicates the EOF on stdin
    // was reached or there was an error.
    // int rdbuf(r0=stdin, r1=fpbook, r2=BUFSZ, r3=iobuf,OARG5=bookbuf)
    // NOTICE that the 5th arg is on the stack so you need to str the 
    // address of bookbuf at offset OARG5 on the stack
    // if r0 on return from rdbuf has a 0 in r0 we are done, 
    // branch to .Ldone (EXIT_SUCCESS is a 0)
    // if return less than 0, error print to stderr .Lbdrd, 
    // Put EXIT_FAILURE in r0 and go to .Ldone
    ldr r0, =stdin
    ldr r0, [r0]
    ldr r1, [fp, -FPBOOK]
    mov r2, BUFSZ
    sub r3, fp, IOBUF
    bl rdbuf //seg fault after this
    cmp r0, #0
    beq .Ldone
    blt .Lread_failure
    // call either encrypt
    // int encrypt(r0=char *iobuf, r1=char *bookbuf, r2=int cnt)
    // returns cnt
    mov r2, r0
    sub r0, fp, IOBUF
    sub r1, fp, BOOKBUF
    mov r6, r2
    bl encrypt
    sub r0, fp, IOBUF
    mov r1, #1
    mov r2, r6
    ldr r3, =stdout
    ldr r3, [r3]
    bl fwrite
    cmp r0, r6
    bne .Lwrite_failure
    bl .Lloop
    // make sure to save cnt so we can check that fwrite wrote cnt characters
    // fwrite returns number of characters it wrote.
    // fwrite(r0=iobuf, r1=1, r2=cnt, r3=*stdout)
    // if cnt characters written go to .Lloop (write is ok)
    // othewise error, print to stderr .Lbdwr, put EXIT_FAILURE in r0
    // and fall through to .Ldone
   
.Ldone:
    // normal exit, call fclose of fpbook and fall through
    // to .Lexit
    sub r0, fp, FPBOOK
    //bl fclose
    mov r0, #0
    b .Lexit

.Lwrite_failure:
    ldr r0, =stderr
    ldr r0, [r0]
    ldr r1, =.Lbdwr
    sub r2, fp, ARGV0
    ldr r2, [r2]
    bl fprintf
    b .Lexit_failure

.Lread_failure:
    ldr r0, =stderr
    ldr r0, [r0]
    ldr r1, =.Lbdrd
    sub r2, fp, ARGV0
    ldr r2, [r2]
    bl fprintf
    b .Lexit_failure

.Lexit_failure:
    mov r0, EXIT_FAILURE

.Lexit:
    sub     sp, fp, FP_OFF
    pop     {r4-r10, fp, lr}
    bx      lr

    .size   main, (. - main)
    .section .note.GNU-stack,"",%progbits
.end
#endif
