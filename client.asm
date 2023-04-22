section .bss
    read_buffer             resb 1024       ; Buffer to read into

section .data
    server_addr:
        sin_family          dw 2            ; AF_INET
        sin_port            dw 47635        ; Port number (in this case, 8080)
        sin_addr            dd 0x0100007f   ; IPv4 address (127.0.0.1 in little-endian byte order)
    
    socket_error            db "Error: Creating socket",            10, 0
    connect_error           db "Error: Connecting to Client",       10, 0
    input_error             db "Error: Read from STDIN",            10, 0
    send_error              db "Error: Could not send",             10, 0
    close_error             db "Error: Could not close connection", 10, 0
    read_from_server_error  db "Error: Could not read from server", 10, 0
    write_to_console_error  db "Error: Could not write to console", 10, 0
    recv_string             db "Received: ",                        0 
    
    read_buffer_size        dd 1024         ; Size of the read buffer
    server_response_size    dd 1024         ; Size of the server response buffer
    socket_fd               dd 0            ; Socket file descriptor
    number_read             dd 0            ; Number of bytes read from STDIN
    recv_string_length      dd 10           ; Length of the "Received: " string

section .text
    global _start

_start:
    ; Create socket 
    call _create_socket
    ; connect to server
    call _connect_to_server
    ; read from keyboard
    call _read_input    
    ; sendto server
    call _send_buffer_to_server
    ; write back echo
    call _read_from_server
    ; close connection
    call _close_connection
    ; exit program
    call _exit

_create_socket:
    ; Call sys_socket()
    mov rax, 41                 ; System call number for "socket"
    mov rdi, 2                  ; AF_INET
    mov rsi, 1                  ; SOCK_STREAM
    mov rdx, 0                  ; Protocol (0 = IP) 
    syscall

    ; Check for error 
    cmp rax, 0                  ; Check if the return value is 0
    lea rdi, socket_error       ; If it is, load the error message into rdi
    jl _display_error_message   
    ; Save socket fd
    mov [socket_fd], rax
    ret

_connect_to_server:
    ; Call sys_connect()
    mov rax, 42                 ; System call number for "connect"
    mov rdi, [socket_fd]        ; Socket file descriptor
    mov rsi, server_addr        ; Server address
    mov rdx, 16                 ; Size of the server address
    syscall

    ; Check for error
    cmp rax, 0                  ; Check if the return value is 0
    lea rdi, connect_error      ; If it is, load the error message into rdi
    jl _display_error_message

    ret

_read_input:
    ; Call read()
    mov eax, 0                      ; System call number for "read"
    mov edi, 0                      ; File descriptor (stdin)   
    mov esi, read_buffer            ; Buffer to read into
    mov edx, read_buffer_size       ; Buffer size
    syscall                         ; Call the kernel to read from stdin
    mov byte [esi + eax], 0         ; Null-terminate the string

    mov [number_read], eax          ; Save the number of bytes read into the variable
    ret

_send_buffer_to_server:
    ; Call write
    mov eax, 1                      ; System call number for "write"
    mov edi, [socket_fd]            ; File descriptor (socket)
    mov esi, read_buffer            ; Message to send
    mov edx, [number_read]          ; Message length
    syscall

    ; Check for error
    cmp eax, 0                      ; Check if the return value is 0
    lea rdi, send_error             ; If it is, load the error message into rdi
    jl _display_error_message

    ret

_read_from_server:
    ; Call read on socket fd
    mov eax, 0                      ; System call number for "read"           
    mov edi, [socket_fd]            ; File descriptor (socket)
    mov esi, read_buffer            ; Buffer to read into
    mov edx, read_buffer_size       ; Buffer size
    syscall
    mov byte [esi + eax], 0         ; Null-terminate the string
    
    call _write_to_console
    ret

_write_to_console:
    ; Write to stdout
    mov eax, 1                      ; System call number for "write"
    mov edi, 1                      ; File descriptor (stdout)
    mov esi, recv_string            ; Message to print
    mov edx, [recv_string_length]   ; Message length
    syscall                         ; Call the kernel to print the message


    mov eax, 1                      ; System call number for "write"
    mov edi, 1                      ; File descriptor (stdout)
    mov esi, read_buffer            ; Message to print
    mov edx, [number_read]          ; Message length
    syscall                         ; Call the kernel to print the message

    ; Check for error
    cmp eax, 0                      ; Check if the return value is 0
    lea rdi, write_to_console_error ; If it is, load the error message into rdi
    jl _display_error_message

    ret

_close_connection:
    mov rax, 3                      ; System call number for "close"  
    mov rdi, [socket_fd]            ; File descriptor (socket)
    syscall                         ; Call the kernel to close the socket
    
    cmp rax, 0                      ; Check if the return value is 0  
    lea rdi, close_error            ; If it is, load the error message into rdi
    jl _display_error_message

    ret

_display_error_message:
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
    mov rax, 60
    mov rdi, 0
    syscall