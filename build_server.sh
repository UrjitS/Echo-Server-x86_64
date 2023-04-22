cd build/
nasm -f elf64 -o echo.o ../echo.asm
nasm -f elf64 -o echo_server.o ../server.asm
ld echo.o echo_server.o -o echo_server
./echo_server
