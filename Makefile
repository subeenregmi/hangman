all: hangman.o
	ld hangman.o -o hangman.out

hangman.o: hangman.asm
	nasm -f elf64 hangman.asm -o hangman.o

clean:
	rm *.o *.out
