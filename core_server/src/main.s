; server.asm — simple TCP line‐based responder in NASM (x86_64, Linux)

global _start

section .data

; sockaddr_in for 0.0.0.0:9000
sockaddr:
    dw 2              ; AF_INET
    dw 0x2823         ; port 9000 in network order (htons(9000))
    dd 0              ; INADDR_ANY
    db 8 dup(0)       ; padding (sin_zero)

; literals to compare
one_str    db 'one'
two_str    db 'two'

on_msg     db 'Server is online', 10
on_msg_len equ $-on_msg

; response for "one"
resp_one:
    db "//this should be in italics//",10
    db "**this should be in bold**",10
    db "* bullet point",10
    db "** subbulletpoint",10
    db 10
    db "== heading ==",10
    db "=== heading2 ===",10
    db 10
    db "{{",10
    db "== [[Nowiki]]",10
    db "//**nothing in here should be formatted**//",10
    db "}}",10
resp_one_len equ $-resp_one

; response for "two"
resp_two:
    db "this is just text",10
resp_two_len equ $-resp_two

; default response
resp_def:
    db "unrecognized command",10
resp_def_len equ $-resp_def

section .bss
buffer:    resb 1024

section .text
_start:

    ; - print startup banner
    mov rax, 1                  ; sys_write
    mov rdi, 1                  ; stdout (fd 1)
    lea rsi, [rel on_msg]
    mov rdx, on_msg_len
    syscall

    ; socket(AF_INET, SOCK_STREAM, 0)
    mov rax, 41
    mov rdi, 2
    mov rsi, 1
    xor rdx, rdx
    syscall
    mov r12, rax          ; sockfd

    ; bind(sockfd, &sockaddr, 16)
    mov rdi, r12
    lea rsi, [rel sockaddr]
    mov rdx, 16
    mov rax, 49
    syscall

    ; listen(sockfd, 128)
    mov rdi, r12
    mov rsi, 128
    mov rax, 50
    syscall

.accept_loop:
    ; accept(sockfd, NULL, NULL)
    mov rdi, r12
    xor rsi, rsi
    xor rdx, rdx
    mov rax, 43
    syscall
    mov r13, rax          ; client_fd

    ; read(client_fd, buffer, 1024)
    mov rdi, r13
    lea rsi, [rel buffer]
    mov rdx, 1024
    xor rax, rax
    syscall
    mov r14, rax          ; bytes read

    ; compare buffer[0..2] to "one"
    lea rbx, [rel buffer]
    mov al, [rbx]
    cmp al, 'o'
    jne .check_two
    mov al, [rbx+1]
    cmp al, 'n'
    jne .check_two
    mov al, [rbx+2]
    cmp al, 'e'
    jne .check_two
    jmp .send_one

.check_two:
    mov al, [rbx]
    cmp al, 't'
    jne .send_def
    mov al, [rbx+1]
    cmp al, 'w'
    jne .send_def
    mov al, [rbx+2]
    cmp al, 'o'
    jne .send_def
    jmp .send_two

.send_one:
    mov rdi, r13
    lea rsi, [rel resp_one]
    mov rdx, resp_one_len
    mov rax, 1
    syscall
    jmp .close_conn

.send_two:
    mov rdi, r13
    lea rsi, [rel resp_two]
    mov rdx, resp_two_len
    mov rax, 1
    syscall
    jmp .close_conn

.send_def:
    mov rdi, r13
    lea rsi, [rel resp_def]
    mov rdx, resp_def_len
    mov rax, 1
    syscall

.close_conn:
    mov rdi, r13
    mov rax, 3
    syscall
    jmp .accept_loop
