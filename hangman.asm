global _start

section .text
    _start:

        mov rax, 1
        mov rdi, 1
        mov rsi, welcome_msg 
        mov rdx, welcome_msg.len
        syscall

        mov rax, 0
        mov rdi, 0
        mov rsi, 0
        mov rdx, 0

    find_random_index:
        ; Fill buffer with random bytes and check it is a valid index value.

        mov rax, 318            ; getrandom syscall
        mov rdi, random_index          
        mov rsi, 1              ; 1 byte = 0 - 255 
        syscall

        ; Ensure that number is between 0 - 100
        and [random_index], byte 127
        cmp [random_index], byte 100

        jg find_random_index    ; If not get another random number
        
    open_word_list:
        ; Open the word list file to get the files fd number.

        mov rax, 2          ; open syscall
        mov rdi, wordfile   ; ptr to a string of the file name
        mov rsi, 0          ; O_RDONLY
        mov rdx, 0
        syscall             ; rax = fd

        mov [file_fd], rax        ; rbx = fd


    get_word:
        ; Get the random word by counting down the new line character.
        
        mov r8, 0                   ; r8 = length of word
        mov r9, word_buff           ; r9 = ptr to our word buffer
        cmp [random_index], byte 0
        je read_word                ; Read the word when we reach the start of
                                    ; our word in the file.
    next_char:
        ; Keep looking at the next character looking for new line characters

        mov rax, 0                  ; read syscall 
        mov rdi, [file_fd]          ; read from word listfd
        mov rsi, word_buff          ; read into the word buffer
        mov rdx, 1                  ; read only 1 byte 
        syscall

        cmp [word_buff], byte 10    ; check for a new line character
        je decrease_word_count       

        jmp next_char               ; if it not a new line char then keep on looking
                                    ; at the next character

    decrease_word_count:
        sub [random_index], byte 1  ; reduce the word count
        jmp get_word                ; check if we are at the start of our word

    read_word:
        ; When at the correct word, read until you reach a new line character.

        mov rax, 0      ; read syscall
        mov rdi, [file_fd]; read from our current position in the word list
        mov rsi, r9     ; read into r9 (the current position in our buffer)
        mov rdx, 1      ; read 1 byte at a time
        syscall
        
        cmp [r9], byte 10       ; check if what we read was a new line (end of word)
        je create_input_buff; do something else after reading the whole word

        inc r9                  ; if not increment our pointer so it pointers to the
                                ; position of the next character
        inc r8                  ; len += 1
        jmp read_word
    
    create_input_buff:

        mov rax, word_buff
        mov rbx, input_buff
       
    create_input_buff_loop:
        cmp [rax], byte 0
        je print_input_buff

        mov [rbx], byte 95
        inc rbx
        inc rax
        jmp create_input_buff_loop

    print_input_buff:
        ; Print out the outline of the word. (the underlines of the word)
        
        mov rax, 1
        mov rdi, 1
        mov rsi, input_buff 
        mov rdx, r8
        syscall

        mov rax, 1
        mov rdi, 1
        mov rsi, newline
        mov rdx, 1
        syscall

        mov [changed], byte 0

    user_loop:
        ; Read the users input
        mov rax, 1
        mov rdi, 1
        mov rsi, user_enter
        mov rdx, user_enter.len
        syscall

        mov rax, 0
        mov rdi, 0
        mov rsi, input_letter 
        mov rdx, 64
        syscall

    update_input_buff:
        ; Update our input buffer
        mov rax, word_buff
        mov rbx, input_buff 
        mov r9, 0
        mov r9b, [input_letter]

    update_input_buff_loop:
        cmp [rax], byte 10
        je next_round
        
        cmp [rax], byte 0
        je next_round 

        cmp [rax], r9b
        je update_input_buff_same

        inc rax
        inc rbx
        jmp update_input_buff_loop

    update_input_buff_same:
        cmp [rbx], r9b
        je next_round

        mov [rbx], r9b 
        inc rax
        inc rbx
        mov [changed], byte 1
        jmp update_input_buff_loop

    next_round:
        cmp [changed], byte 0
        jne check_win 

        mov rax, 1
        mov rdi, 1
        mov rsi, wasted_letter
        mov rdx, wasted_letter.len
        syscall

        dec byte [tries] 
        cmp [tries], byte 0
        jle end_game

        jmp print_input_buff

    check_win:
        mov rax, input_buff 
        mov r10, r8

    check_win_loop:
        cmp [rax], byte 95
        je print_input_buff

        inc rax

        dec r10
        cmp r10, 0
        jle won_game

        jmp check_win_loop

    won_game:
        mov rax, 1
        mov rdi, 1
        mov rsi, win_game_msg
        mov rdx, win_game_msg.len
        syscall

        mov rax, 1
        mov rdi, 1
        mov rsi, word_buff
        mov rdx, r8
        syscall

        mov rax, 1
        mov rdi, 1
        mov rsi, newline
        mov rdx, 1
        syscall

        jmp close_game

    end_game:

        mov rax, 1
        mov rdi, 1
        mov rsi, end_game_msg
        mov rdx, end_game_msg.len
        syscall

        mov rax, 1
        mov rdi, 1
        mov rsi, word_buff 
        mov rdx, r8
        syscall

        mov rax, 1
        mov rdi, 1
        mov rsi, newline
        mov rdx, 1
        syscall
    
    close_game:
        mov rax, 0
        mov rdi, 0
        mov rsi, 0
        mov rdx, 0

        ; Close the word list file
        mov rax, 3              ; close syscall
        mov rdi, [file_fd]            ; files fd
        syscall
            
        ; Exit the program
        mov rax, 60             ; exit syscall
        mov rdi, 0              ; exit code
        syscall

section .data
    wordfile:
        db "wordlist.txt", 0
    underline:
        db "_"
    testcheck:
        db "!"
    newline:
        db 10
    user_enter:
        db "> "
        .len: equ $ - user_enter
    changed:
        db 0
    tries:
        db 10
    wasted_letter:
        db "Wrong or previously used letter!", 10
        .len: equ $ - wasted_letter
    end_game_msg:
        db 10, "The game has ended!", 10, "The word was: "
        .len: equ $ - end_game_msg
    welcome_msg:
        db "You are playing hangman, standard rules apply!", 10
        .len: equ $ - welcome_msg

    win_game_msg:
        db 10, "You have won the game! Congrats.", 10, "The word was: "
        .len: equ $ - win_game_msg

    
    

section .bss
    random_index:
        resb 1
    word_buff:
        resb 64
    input_buff:
        resb 64
    input_letter:
        resb 64
    file_fd:
        resb 64

section .rodata
