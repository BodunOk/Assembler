.model tiny
.code
.186

org 100h

start:

jmp install


COMMAND_LINE_LENGTH equ 127

command_line db COMMAND_LINE_LENGTH dup(0) ;buffer dlia comandnoi stroci

SPACE equ 20h
TAB equ 9h
NEW_LINE equ 0Ah
CARRIAGE_RETURN equ 0Dh

error_message1 db "Invalid parameters.",13,10,'$' 

display_x db 0
display_y db 0

MAX_X equ 72
MAX_Y equ 24
max_coordinate_value dw 0 

BUFFER_LENGTH equ 16

buffer db BUFFER_LENGTH dup(0)
    
attribute db 0Fh

old_int1Ch_handler dd 0F0001260h

old_segment_address dw 0

debug_buffer db 100 dup('$')



int1Ch_handler PROC
    
    pushf
    call cs:old_int1Ch_handler
    
    cli
    call display_time
    sti
    
    iret    
int1Ch_handler ENDP

display_time PROC
    
    push es
    push ds
    pusha
    
    mov ax,cs
    mov ds,ax
    mov es,ax
        
    mov ah,02h
    int 1Ah
    jc cannot_read_time
        
    xor ax,ax
    mov al,ch
    push offset buffer
    call convert_int_to_char
    add sp,2
    
    mov buffer[4],':'
    mov al,attribute
    mov buffer[5],al
    
    mov al,cl
    push offset buffer+6
    call convert_int_to_char
    add sp,2
    
    mov buffer[10],':'
    mov al,attribute
    mov buffer[11],al
    
    mov al,dh
    push offset buffer+12
    call convert_int_to_char
    add sp,2
    
    mov ax,0b800h
    mov es,ax
    
    mov ax,0A0h
    mov bl,[display_y]
    mul bl
    mov di,ax
    
    xor ax,ax
    mov al,[display_x]
    shl al,1
    add di,ax
    
    mov si,offset buffer
    mov cx,BUFFER_LENGTH
    
    rep movsb
    
    cannot_read_time:
    popa
    pop ds
    pop es
    ret
display_time ENDP    

convert_int_to_char PROC
    
    push bp
    mov bp,sp
    mov di,[bp+4]
    push ax cx dx di
    
    xor dx,dx
    mov bx,10h
    xor cx,cx
    
    get_another_number:
    div bx
    push dx
    inc cx
    xor dx,dx
    
    cmp ax,0
    jne get_another_number
    
    mov bx,cx
    write_another_char:
        
        pop dx 
        mov al,dl
        add al,'0'
        stosb
        mov al,attribute
        stosb
            
    loop write_another_char
    
    pop di dx cx ax bp
    ret
convert_int_to_char ENDP



end_of_resident_part:

show_str MACRO
    
    push ax
    
    mov ah,9
    int 21h
    
    pop ax
ENDM

is_delimiter PROC
    
    xor ah,ah
    
    cmp al,SPACE
    jne not_space
    mov ah,1
    not_space:
    
    cmp al,TAB
    jne not_tab
    mov ah,1
    not_tab:
    
    ret
is_delimiter ENDP

is_digit PROC
    
    xor ch,ch
    
    cmp cl,30h
    jge greater_than_zero
    jmp not_a_number
    greater_than_zero:
    
    cmp cl,39h
    jle less_than_nine
    jmp not_a_number
    less_than_nine:
    
    mov ch,1
    not_a_number:
    
    ret
is_digit ENDP

find_word PROC
    
    push bp
    mov bp,sp
    push ax cx si 
    
    mov si,[bp+4]
    
    handle_word:
    
    skip_delimiter:
    mov al,[si]
    call is_delimiter
    
    cmp ah,1
    je found_delimiter
    jmp stop_reading_string
    found_delimiter:
    
    cmp cx,0
    jne string_end_not_reached
    jmp stop_reading_string
    string_end_not_reached:
    
    inc si
    dec cx
    
    jmp handle_word
    stop_reading_string:
    
    mov bx,si
    sub bx,[bp+4]
    
    skip_character:
    
    mov al,[si]
    call is_delimiter
    
    cmp ah,1
    jne not_delimiter
    jmp word_read
    not_delimiter:
    
    cmp cx,0
    jne can_read_more
    jmp word_read
    can_read_more:
    
    cmp al,CARRIAGE_RETURN
    jne not_the_end
    jmp word_read
    not_the_end:

    inc si
    dec cx
    jmp skip_character
    
    word_read:
    
    mov di,si
    sub di,[bp+4]
    cmp bx,di
    je word_not_found
    dec dx
    word_not_found:
    
    cmp cx,0
    jne not_end_of_string
    jmp out_of_loop
    not_end_of_string:
    
    cmp dx,0
    jne not_this_word
    jmp out_of_loop
    not_this_word:
    
    cmp byte ptr [si],CARRIAGE_RETURN
    jne not_stop
    jmp out_of_loop
    not_stop:
    
    jmp handle_word
    
    out_of_loop:
    
    pop si cx ax bp
    ret
find_word ENDP

get_number_from_cmd_line PROC
    
    push bx cx dx si
    
    mov cx,bx
    push offset command_line
    call find_word
    add sp,2
    
    cmp dx,0
    jne invalid_input
    
    mov si,10
    xor ax,ax
    get_another_digit:
    
    mov cl,command_line[bx]
    
    cmp bx,di
    jne not_end_of_number
    jmp end_of_number
    not_end_of_number:
    
    call is_digit
    cmp ch,1
    je digit_read
    jmp invalid_input
    digit_read:
    
    mul si
    
    xor ch,ch
    sub cx,30h
    add ax,cx
    cmp ax,[max_coordinate_value]
    jle limit_not_reached
    jmp invalid_input
    limit_not_reached:
    
    inc bx
    jmp get_another_digit
    
    end_of_number:
    jmp proc_end 
    
    invalid_input:
    mov ax,0FFh
    
    proc_end:
    
    pop si dx cx bx
    ret
get_number_from_cmd_line ENDP

read_command_line PROC
    
    push cx si di
    
    xor cx,cx
    mov cl,ds:[0080h] ;kollichestvo symvolov v peredannoi comandnoi stroce
    mov bx,cx
   
    mov si,81h ;nachalo comandnoi stroci
    lea di,command_line 
    
    rep movsb ;perenosim comand line v buffer
    
    pop di si cx
    ret
read_command_line ENDP

install_int1Ch_handler PROC
    
    push ax dx ds
                
    mov dx,offset int1Ch_handler
    mov ax,251Ch
    cli
    int 21h
    sti

    pop ds dx ax    
    ret
install_int1Ch_handler ENDP

uninstall_int1Ch_handler PROC
    
    push ax dx ds
    
    mov ax,0f000h
    mov ds,ax
    mov dx,1260h
    
    mov ax,251Ch
    cli
    int 21h
    sti
    
    pop ds dx ax
    ret
uninstall_int1Ch_handler ENDP
    
check_int60h_handler PROC
    
    push ax bx es
    
    mov ax,3560h ;poluchit adress obrabotchica prerivania (60 - nomer prerivania) 
    int 21h
    
    mov ax,es ;segmentii adress obrabotchica prerivania
    mov [old_segment_address],ax
    
    mov cx,1
    cmp bx,0
    jne not_zero
    cmp ax,0
    jne not_zero
    
    xor cx,cx
    not_zero:
    
    pop es bx ax
    ret
check_int60h_handler ENDP

set_int60h_handler PROC
    
    push ax dx ds
    mov ds,ax
    
    mov ax,2560h
    cli
    int 21h
    sti
    
    pop ds dx ax
    ret
set_int60h_handler ENDP

free_memory PROC
    
    push ax es
    
    mov ax,[old_segment_address]
    mov es,ax
    
    mov ah,49h
    int 21h
    
    pop es ax
    ret
free_memory ENDP    

install:
    mov ax,0003h
    int 10h
    
    mov ax,cs
    mov es,ax
    
    call read_command_line ;chitaem comand line v buffer
    mov ds,ax
    
    call check_int60h_handler
    cmp cx,0
    je not_installed_already
        
        call uninstall_int1Ch_handler
        
        call free_memory
        
        xor ax,ax
        call set_int60h_handler

    not_installed_already:

    mov dx,1
    mov [max_coordinate_value],MAX_X
    call get_number_from_cmd_line
    cmp ax,0FFh
    je invalid_parameter
    mov [display_x],al 
    
    mov dx,2
    mov [max_coordinate_value],MAX_Y
    call get_number_from_cmd_line
    cmp ax,0FFh
    je invalid_parameter
    mov [display_y],al
    

    mov ax,cs
    call set_int60h_handler
    
    call install_int1Ch_handler

    
    mov ax,3100h
    mov dx,(end_of_resident_part-start+110h)/16
    int 21h
    
    invalid_parameter:
    mov dx,offset error_message1
    show_str
    
    mov ax,4c00h
    int 21h
            
end start
