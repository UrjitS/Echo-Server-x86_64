section .bss
    client_addr     resb 16
    
section .data
   socket_sockaddr:
        sin_family  dw 2            ; AF_INET
        sin_port    dw 47635        ; Port number (in this case, 8080)
        sin_addr    dd 0x0100007f   ; IPv4 address (127.0.0.1 in little-endian byte order)
    
    ; Constants
    socket_fd       dd 0            ; Socket file descriptor
    accepted_fd     dd 0            ; Accepted file descriptor
    client_addr_len dd 16           ; Size of the client address

    socket_err_msg  db "Error: could not create socket",     10, 0
    bind_err_msg    db "Error: could not bind to socket",    10, 0
    listen_err_msg  db "Error: could not listen on socket",  10, 0
    accept_err_msg  db "Error: could not accept connection", 10, 0
    close_err_msg   db "Error: could not close connection",  10, 0

section .text                       ; Holds executable code
    global _start                   ; Entry point for the program

extern _echo_read_from_stdin        ; Function to echo from a fd
extern _write_error                 ; Function to write an error message

_start:
    call _create_socket             ; Call the function to create a socket
    call _bind_to_socket            ; Call the function to bind to the socket
    call _listen_on_socket          ; Call the function to listen on the socket
    call _accept_loop               ; Call the function to forever accept connections

_create_socket:
    ; Create a socket (int family, int type, int protocol)
    mov eax, 41                     ; System call number for "socket"
    mov edi, 2                      ; AF_INET
    mov esi, 1                      ; SOCK_STREAM
    mov edx, 0                      ; Protocol (0 = default)
    syscall                         ; Call the kernel to create a socket
    mov [socket_fd], eax            ; Save the socket fd

    cmp eax, 0                      ; Check if the socket fd is valid
    lea rdi, socket_err_msg         ; If not, load the error message
    jl _write_error                

    ret

_bind_to_socket:
    ; Bind the socket (int fd, const struct sockaddr *addr, socklen_t addrlen)
    mov rax, 49                     ; sys_bind
    mov rdi, [socket_fd]            ; socket file descriptor
    mov rsi, socket_sockaddr        ; pointer to sockaddr struct
    mov rdx, 16                     ; size of sockaddr struct
    syscall                         ; Call the kernel to bind the socket

    ; Check for errors
    cmp rax, 0                      ; Check if the socket fd is valid
    lea rdi, bind_err_msg           ; If not, load the error message
    jl _write_error

    ret

_listen_on_socket:
    ; listen on the socket (int fd, int backlog)
    mov eax, 50                     ; System call number for "listen"
    mov edi, [socket_fd]            ; Socket fd
    mov esi, 5                      ; Backlog         
    syscall                         ; Call the kernel to listen on the socket

    ; Check for errors
    cmp eax, 0                      ; Check if the socket fd is valid
    lea rdi, listen_err_msg         ; If not, load the error message
    jl _write_error                    

    ret

_accept_loop:
    mov dword [client_addr_len], 16 ; Reset the length of the client address
    mov rdi, client_addr            ; Set the destination address
    mov ecx, 16                     ; Set the number of bytes to set
    mov al, 0                       ; Set the value to 0
    rep stosb                       ; Fill the memory with the value of AL

    call _accept_connection         ; Call the function to accept a connection

    mov ax, [accepted_fd]           ; Parameter 1: accepted socket fd
    call _echo_read_from_stdin      ; Call the function to echo the message

    call _close_connection          ; Call the function to close the connection    
    jmp  _accept_loop               ; Loop back to accept another connection


_accept_connection:
    ; accept a connection (int fd, struct sockaddr *addr, socklen_t *addrlen)
    mov rax, 43                     ; System call number for "accept"
    mov rdi, [socket_fd]            ; Socket file descriptor
    mov rsi, client_addr            ; Pointer to the client address
    mov rdx, client_addr_len        ; Pointer to the length of the client address
    syscall

    ; Check for errors
    cmp rax, 0                      ; Check if the socket fd is valid
    lea rdi, accept_err_msg         ; If not, load the error message
    jl _write_error                 

    mov [accepted_fd], eax          ; Save the accepted socket fd
    ret

_close_connection:
    ; Close the connection (int fd)
    mov eax, 3                      ; System call number for "close"
    mov edi, [accepted_fd]          ; Accepted socket fd
    syscall

    cmp eax, 0                      ; Check if the socket fd is valid
    lea rdi, close_err_msg          ; If not, load the error message
    jl _write_error

    ret
