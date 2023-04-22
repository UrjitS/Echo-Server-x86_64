cd build/
nasm -f elf64 -o client.o ../client.asm
ld client.o -o client
./client
