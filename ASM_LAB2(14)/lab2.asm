.model small
.stack 100h
.data
msg1 db "Input string:", 0dh, 0ah, '$' 
msg2 db 0dh, 0ah, "Enter the substring you want to delete: $"
msg3 db 0dh, 0ah, "Result:$" 
msg4 db 0dh, 0ah, "Enter new substring: $"
string db 102 dup("$")     
strLen db 0
sbstrToRemove db 102 dup("$")       
sbstrR db 0
sbstrToInsert db 102 dup("$")
capacity EQU 100
sbstrI db 0
flag dw 0

.code   
        
normalizeString macro string, stringLen
    local next, nextSymbol, stringLoop, return, first
    push ax
    push si
    push cx

    cmp stringLen, 0
    je return
    
    first:
    mov ah, string[0]  
    cmp ah, ' '
    jne next

    xor ax, ax 
    mov al, stringLen
    mov cx, ax
    mov si, offset string
    deleteSymbol
    dec stringLen
    jmp first

    next:
    xor ax, ax
    mov al, stringLen
    mov cx, ax
    mov si, offset string
    stringLoop:
        mov ah, [si]
        cmp ah, ' '
        jne nextSymbol
        mov al, [si + 1] 
        cmp ah, al
        jne nextSymbol

        push cx
        xor ax, ax
        mov al, stringLen
        mov cx, ax
        sub cx, si
        add cx, offset string

        deleteSymbol
        pop cx
        dec stringLen
        dec si

        nextSymbol:
        inc si
    loop stringLoop
    dec si
    cmp [si], ' '
    jne return
    mov cx, 1
    deleteSymbol
    dec stringLen
    return:
    pop cx
    pop si
    pop ax
endm   

deleteSymbol macro
    local deleteLoop
    push si   
    push ax
    inc cx     
    deleteLoop:
        mov ah, [si + 1]
        mov [si], ah
        inc si
    loop deleteLoop

    pop ax
    pop si
 endm
                
main proc
mov ax, @data
mov ds, ax
mov es, ax  
  
mov ah, capacity     
mov string[0], ah    ;first byte - max srting size
mov sbstrToRemove[0], ah 
mov sbstrToInsert[0], ah     

lea dx, msg1
call puts
lea dx, string
call gets
call stringLen
mov strLen,cl        
normalizeString string, strLen
lea dx, string
call puts

lea dx, msg2
call puts
lea dx, sbstrToRemove
call gets

lea dx, msg4
call puts
lea dx, sbstrToInsert
call gets

xor cx, cx
mov cl, string[1]
sub cl, sbstrToRemove[1]
jb End
inc cl
cld

lea si, string[2]
lea di, sbstrToRemove[2]

call ReplaceSubstring

End:   
lea dx, msg3
call puts
lea dx, string[2]
call puts
   
NotEqual:    
   
mov ah, 4ch
int 21h

ret
endp main  
          
stringLen proc
push si  
xor si,si
xor cx,cx
strLoop:
cmp string[si], '$'
je endOfstr
inc si
inc cx
jmp strLoop
endOfstr:
pop si
ret
endp stringLen           
          
          
ToStartOfWord proc
push si
push ax
xor ax,ax
wordLoop:
mov al,[bx]
cmp [bx], ' '
je end1
mov al,[bx]
cmp al,string[2]
je end1start
dec bx
;dec si
loop wordLoop   

end1start:
pop ax
pop si
ret
endp

end1: 
pop ax
pop si
inc bx     
ret
endp          

ToEndOfWord proc
push ax
xor ax,ax
wordLoop2:
mov al,[si]
cmp [si],' '
je end2
cmp [si],'$'
je end2
inc si
loop wordLoop2
end2:
pop ax    
ret
endp          

ReplaceSubstring proc
Cycle:
mov flag, 1
push si
push di
push cx

mov bx, si

xor cx, cx
mov cl, sbstrToRemove[1]

repe cmpsb
je FOUND
jne NOT_FOUND

FOUND:  
call ToStartOfWord
call ToEndOfWord 
call DeleteSubstring
mov ax, bx
call InsertSubstring
mov dl, sbstrToInsert[1] 
add string[1], dl        
mov flag, dx  

NOT_FOUND:
pop cx
pop di
pop si
add si, flag

Loop Cycle

ret
endp ReplaceSubstring  

DeleteSubstring proc
push si
push di
xor cx,cx
mov cl, string[1]
mov di, bx

repe movsb

pop di
pop si

ret                
endp DeleteSubstring

InsertSubstring proc
lea cx, string[2]    ; string 1st symbol address
add cl, string[1]    ; add string length to get to next symbol after the last
mov si, cx           ; last symbol as a source 
dec si               ; at the last symbol
mov bx, si           ; save last symbol in bx
add bl, sbstrToInsert[1] ; now there is the last symbol of new string in bx
mov di, bx           ; new last symbol is reciever            

mov dx, ax           ; ax is a place to insert
sub cx, dx           ; after last symbol -= place to insert
std                  ; moving backward
repe movsb

lea si, sbstrToInsert[2] ; source is sbstr 1st symbol
mov di, ax          ; reciever is a place to insert
xor cx, cx          ; set cx to zero
mov cl, sbstrToInsert[1] ; sbstr length to cx
cld                 ; moving forward
repe movsb             
  
ret
endp InsertSubstring                

; I/O procedures

gets proc   
mov ah, 0Ah
int 21h
ret
endp gets

puts proc
mov ah, 9 
int 21h
ret
endp puts