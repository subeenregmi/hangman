global _start

section .text
    _start:
        ; Get a random number
        mov rax, 318        ; getrandom syscall
        mov rdi, random_buff    ; buffer to be filled with random bytes
        mov rsi, 1          ; get only one random byte
        syscall

        ; Exit the program
        mov rax, 60         ; exit syscall
        mov rdi, [random_buff]         ; exit code
        syscall

section .data

section .bss
    random_buff:
        resb 1

section .rodata
