global _start

section .text
    _start:

    find_random_index:
        ; Fill buffer with random bytes
        mov rax, 318            ; getrandom syscall
        mov rdi, random_index   ; buffer to be filled with random bytes
        mov rsi, 1              ; get only one random byte
        syscall

        ; Make the random number 0 - 100
        and [random_index], byte 127
        cmp [random_index], byte 100
        jg find_random_index
        

        ; Open the word list file
        mov rax, 2              ; open syscall
        mov rdi, wordfile       ; buffer holding the file name
        mov rsi, 0              ; O_RDONLY
        mov rdx, 0
        syscall                 ; rax stores the fd

        mov rbx, rax            ; store the files fd into rbx

        ; Get the random word by counting down the new lines
    get_word: 
        mov r9, word_buff       ; store a copy of our word buffer into r9
        cmp [random_index], byte 0; check if the index has reach zero yet
        je read_word            ; if so read the next word

    next_char:                  
        mov rax, 0              ; read system call
        mov rdi, rbx            ; read from our word lists fd
        mov rsi, word_buff      ; read into our word buffer
        mov rdx, 1              ; read only 1 byte into our word buffer
        syscall

        cmp [word_buff], byte 10; check if what we read was a new line
        je decrease_word_count  ; reduce the word count and keep finding 

        jmp next_char           ; if it not a new line char then keep on looking
                                ; at the next character

    decrease_word_count:
        sub [random_index], byte 1   ; reduce the word count
        jmp get_word

    read_word:
        mov rax, 0              ; read system call
        mov rdi, rbx            ; read from the current position of our text file
        mov rsi, r9             ; read into r9 (the current position in our buffer)
        mov rdx, 1              ; read a single byte at a time
        syscall

        cmp [r9], byte 10            ; check if what we read was a new line (end of word)
        je print                ; do something else after reading the whole word

        inc r9                  ; if not increment our pointer so it pointers to the
                                ; position of the next character
        jmp read_word

    print:
        ; Print what was read   
        mov rax, 1              ; Write syscall
        mov rdi, 1              ; stdout fd
        mov rsi, word_buff     ; write what is in the read buffer
        mov rdx, rcx            ; write only number of bytes that was read
        syscall

        ; Close the word list file
        mov rax, 3              ; close syscall
        mov rdi, rbx            ; files fd
        syscall
            
        ; Exit the program
        mov rax, 60             ; exit syscall
        mov rdi, 0              ; exit code
        syscall

section .data
    wordfile:
        db "wordlist.txt", 0

section .bss
    random_index:
        resb 1
    word_buff:
        resb 64

section .rodata
