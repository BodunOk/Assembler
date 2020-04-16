sseg segment 
    stack db 512 DUP (?)
sseg ends    

data segment
    msg db "Enter number (and press `Enter`): ", 10, 13,"$"
    new_line db 10, 13, '$'
    space db "  $", 
    input_buffer db buff_size 
    input_size db 0
    input db buff_size dup('$')
    
    output db 10 dup('$')
    
    test_num dw 0
    
    ;array_size dw 8
    ;array dw 9, 8, 7, 6, 5, 4, 3, 2
    
    matrix dw row_size dup(0)
           dw row_size dup(0)
           dw row_size dup(0)
           dw row_size dup(0)
           dw row_size dup(0)
data ends

code segment
jmp start

init:
    buff_size equ 5
    row_size equ 3    ;swipe on 5x6!!!
    row_count equ 3
    mov ax, data
    mov ds, ax
    mov es, ax
ret

error_handler:
    call exit
ret

is_empty macro input_buffer
    push ax
    push si
    
    mov si, input_buffer
    inc si
    mov ah, 00h
    mov al, [si]
    
    cmp al, 00h
    je empty_true
    jne empty_false
    
    empty_true:
        call error_handler  
    
    empty_false:
    pop si
    pop ax
endm

get_line:
    push bp
    mov bp, sp
    push ax
    push dx
           
    mov ax, 0a00h
    mov dx, ss:[bp+4]
    int 21h
    
    is_empty dx
    
    pop dx       
    pop ax
    pop bp    
ret

; place ascii symbol in `bx` to use
; `bp` will be used as result flag
is_negative:
    cmp bx, '-'
    jne negative_false
    
    mov bp, 1
    
    negative_false: 
ret

;result will be stored in `di` reg
atoi:
    push bp
    mov bp,sp
    push ax
    push bx
    push cx
    push dx
    push si
    
    mov si, sp:[bp + 4]
    inc si
    mov ch, 00h
    mov cl, byte ptr ds:[si]
    inc si
    mov di, 0h
    
    mov bh, 00h    
    mov bl, byte ptr ds:[si]
    call is_negative
    cmp bp, 1h
    je skip_minus
    jne atoi_iterate
    
    skip_minus:
        inc si
        dec cx

atoi_iterate:
    mov bh, 00h    
    mov bl, byte ptr ds:[si]
    cmp bx, 48
    jl error_handler
    cmp bx, 57
    jg error_handler
    
    sub bx, 48
    mov dx, 10 
    
    push cx
    dec cx
    mov ax, 1
    cmp cx, 0h
    je skip_pow
    pow:
        push dx
        mul dx
        pop dx
        loop pow
    skip_pow:     
    mul bx
    pop cx
    add di, ax
    inc si 
    loop atoi_iterate
    
    cmp bp, 1h
    jne end_atoi
    neg di
    
    end_atoi:
    pop si
    ;pop di
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
ret


itoa:
    push bp
    mov bp, sp
    push di
    push si
    push bx
    push ax
    push dx
    
    mov di, ss:[bp + 6] ;output
    mov si, ss:[bp + 4] ;number address (number stored as word) 
    mov ax, word ptr [si] ;actual number
    mov bx, 10
    
    ;check if number is negative
    cmp word ptr [si], 0h
    jge positive_true
    
    mov byte ptr [di], '-'
    inc di
    neg ax

    positive_true:
    mov si, di
    
    itoa_iterate:
        mov dx, 00h
        cmp ax, 10
        jl itoa_end
        
        div bx
        add dx, 48
        mov byte ptr [di], dl
        inc di
        
        jmp itoa_iterate
    
    itoa_end:
    add ax, 48
    mov byte ptr [di], al
    
    push si
    push di
    call reverse
    pop di
    pop si
    
    inc di
    mov byte ptr[di], '$'
    
    pop dx
    pop ax
    pop bx
    pop si
    pop di
    pop bp
ret
       
; first param is a start index
; second param is an end end index
      
reverse:
    push bp
    mov bp, sp
    push si
    push di
    push ax
    push bx
    push dx
    
    mov si, ss:[bp + 6] ;start address
    mov bx, ss:[bp + 4] ;end address
    mov di, bx
    
    cmp si, bx
    je reverse_end
    
    mov ah, 00h
    reverse_iterate:
        lodsb ; from memory with [si] address to `al` register
        dec si
        mov dl, byte ptr [di]
        mov byte ptr ds:[si], dl
        stosb ;from `al` register to memory with [di] address 
        inc si
        sub di, 2
        
        cmp si, di
        je reverse_end
        
        dec si
        cmp si, di
        je reverse_end
        inc si
        jne reverse_iterate
    
    
    reverse_end:    
    
    pop dx
    pop bx
    pop ax
    pop di
    pop si    
    pop bp
ret

; set last element as pivot
; arrange array so element from left part have to be less or equal
; and element from right part have to be greater then pivot
; repeat algorigth for left part & right part
q_sort: 
    ; need to place in si start_element address
    ; need to place in bx end_element (new pivot)
    push si
    mov di, si
    mov dx, word ptr ds:[bx]
    iterate:
        mov ax, word ptr ds:[di]
        cmp ax, dx
        jle swap
        jg continue
    
        swap:
            push di
            push si
            call word_swap
            pop si
            pop di
            
            add si, 2h
            
        continue:
            add di, 2h
            cmp di, bx
            je end_traversal
            jmp iterate
        
        end_traversal:
            push bx
            push si
            call word_swap
            ;swap adresses
            pop bx
            pop si ;not a mistake
            pop si ;set si to su-array start
            
            mov dx, si
            add dx, 2h
            cmp dx, bx

            jl left_part
            jg right_part
            jmp sort_complete
            
            left_part:
                push bx
                push di
                push si
                sub bx, 2h
                call q_sort
                pop si
                pop di
                pop bx
            
            right_part:
                add bx, 2h
                mov si, bx
                mov bx, di
                
                cmp si, bx
                
                jge sort_complete
                call q_sort
                
    sort_complete:
ret

word_swap:
    push bp
    mov bp, sp
    push si
    push bx
    push ax
    push dx
    ;bp + 4 1-st adress
    ;bp + 6 2-sr adress
    
    mov bx, ss:[bp + 4]
    mov si, ss:[bp + 6]
    
    cmp bx, si
    je skip_swap
    
    mov ax, word ptr ds:[bx]
    mov dx, word ptr ds:[si]
    mov word ptr ds:[bx], dx
    mov word ptr ds:[si], ax
    
    skip_swap:
    pop dx
    pop ax
    pop bx
    pop si
    pop bp
ret 

clear_str:
    push bp
    mov bp, sp
    push si
    push cx
    
    mov si, ss:[bp + 4]
    inc si
    mov ch, 00h
    mov cl, byte ptr [si]
    inc cl
    clear_iterate:
        inc si
        mov byte ptr [si], '$'
    loop clear_iterate
     
    pop cx
    pop si
    pop bp
ret

matrix_input:
    push bp
    mov bp, sp
    push cx
    push dx
    push bx
    push ax 
    ; matrix 1-st row placed in [bp + 4] 
    mov bx, ss:[bp + 4]
    mov ax, row_count
    mov dx, row_size 
    mul dx
    mov cx, ax
    mov ax, 1h
    row_iterate:
        push offset msg
        call echo
        pop dx
        
        push offset input_buffer
        call get_line
        pop dx        
        
        push offset new_line
        call echo
        pop dx
        
        push offset input_buffer
        call atoi ;result in di
        pop dx
        
        mov word ptr [bx], di
        add bx, 2h
        
        push offset input_buffer
        call clear_str
        pop dx
    loop row_iterate
    
    pop ax
    pop bx
    pop dx
    pop cx
    pop bp
ret

matrix_sort:
    push bp
    mov bp, sp
    mov si, ss:[bp + 4]
    mov cx, row_count
    sort_loop:
        push si
        
        mov bx, si
        add bx, row_size
        add bx, row_size
        sub bx, 2h
        call q_sort
    
        pop si
        
        add si, row_size
        add si, row_size
    loop sort_loop
    
    pop bp
ret

matrix_output:
   push bp
   mov bp, sp
   push cx
   
   mov bx, ss:[bp + 4]
   mov cx, row_count
   
   print_row:
        push cx
        mov cx, row_size
        print_element:
            push offset output
            push bx
            call itoa
            pop dx
            pop dx
            
            push offset output
            call echo
            pop dx
            
            push offset space
            call echo
            pop dx
            
            add bx, 2h
            
        loop print_element 
        
        push offset new_line
        call echo
        pop dx
        
        pop cx
   
   loop print_row
   
   pop cx
   pop bp
ret

exit:
    mov ax, 4c00h
    int 21h
ret

echo proc
    push bp
    mov bp, sp
    mov ax, 0900h
    mov dx, ss:[bp+4]
    int 21h
    
    pop bp
    ret
echo endp

start:
    call init
    push offset matrix
    call matrix_input
    pop dx
    
    push offset matrix
    call matrix_sort
    pop dx
    
    push offset matrix
    call matrix_output
    pop dx

    call exit
end start
    
code ends