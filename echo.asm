section .bss                        ; Holds uninitialized data
    buffer resb 1024                ; Define a buffer to read into    

section .data
    buffer_size dd 1024             ; Define the size of the buffer
    echo_fd dd 0                    ; Socket file descriptor
    number_read dd 0                ; Number of bytes read
    server_msg db "Server: ", 0     ; Message to send to the client
    server_msg_len equ $ - server_msg ; Length of the message

section .text
    global _echo_read_from_stdin    ; Make the function available to other files
    global _write_error             ; Make the function available to other files

_echo_read_from_stdin:
    mov [echo_fd], ax               ; Save the socket file descriptor in the variable
    call _read_from_fd              ; Call the function to read from stdin
    call _write_to_fd               ; Call the function to write to stdout
    ret                             ; Return from the function

_read_from_fd:
    mov eax, 0                      ; System call number for "read"
    mov edi, [echo_fd]              ; File descriptor (stdin)
    mov esi, buffer                 ; Buffer to read into
    mov edx, buffer_size            ; Buffer size
    syscall                         ; Call the kernel to read from stdin
    mov byte [esi + eax], 0         ; Null-terminate the string
    mov [number_read], eax          ; Save the number of bytes read into the variable
    call _display_read
    ret                             ; Return from the function

_display_read:
    mov eax, 1                      ; System call number for "write"
    mov edi, 1                      ; File descriptor (stdout)
    mov esi, server_msg             ; Message to print
    mov edx, server_msg_len         ; Message length
    syscall                         ; Call the kernel to print the message

    mov eax, 1                      ; System call number for "write"
    mov edi, 1                      ; File descriptor (stdout)
    mov esi, buffer                 ; Message to print
    mov edx, [number_read]          ; Message length
    syscall                         ; Call the kernel to print the message

_write_to_fd:
    mov eax, 1                      ; System call number for "write"
    mov edi, [echo_fd]              ; File descriptor (stdout)
    mov esi, buffer                 ; Message to print
    mov edx, [number_read]          ; Message length
    syscall                         ; Call the kernel to print the message
    ret                             ; Return from the function

_write_error:
    ; Error message is in rdi
    ; Get the length of the error message
    xor rdx, rdx
    loop_start:
        cmp byte [rdi + rdx], 0     ; Check if the current byte is 0
        je loop_end                 ; If it is, jump to the end of the loop
        inc rdx                     ; Otherwise, increment the counter
        jmp loop_start              ; And jump to the start of the loop
    loop_end:
        mov rsi, rdi                ; Pointer to the error message
        mov rax, 1                  ; System call number for "write"
        mov rdi, 2                  ; File descriptor (2 = stderr)
        syscall                     ; Call the kernel to write the error message
        call _exit                  ; Call the function to exit the program

_exit:
    ; Exit the program
    mov eax, 60                     ; System call number for "exit"
    xor edi, edi                    ; Exit status (0 = success)
    syscall                         ; Call the kernel to exit