org 0x7c00                   ; set assumed memory location, comment out to debug
bits 16                      ; 16-bit mode since this is in a boot sector

start:
    xor eax, eax
    mov ds, ax               ; make sure ds is 0
    mov di, 0xb800
    mov es, di               ; set di to text video memory (https://wiki.osdev.org/Printing_to_Screen)

clear:                       ; clear the screen of any bios messages, etc.
    xor di, di
.nextbyte:
    mov byte [es:di], 0x00   ; clear the current byte
    inc di                   ; go to the next one
    cmp di, 4000
    jl .nextbyte             ; keep going unless all 4,000 bytes are cleared
    xor di, di

main:
    xor cx, cx               ; use cx as pixel counter

.nextpixel:
    mov  ax, cx              ; move pixel number to ax
    mov  bl, 80
    div  bl                  ; divide by number of columns (80)
    mov  bx, ax              ; we need to use ax, save it in bx
    and  ax, 0x00ff          ; get the low byte, which is the result of the division
    push ax
    fild word  [esp]         ; load x pixel position
    push dword [Y_STEP]
    fmul dword [esp]
    push dword [Y_MIN]
    fadd dword [esp]         ; (y * step) + min
    fstp dword [ypos]        ; store y position in ypos
    mov esp, ebp             ; reset stack

    mov  ax, bx
    and  ax, 0xff00          ; now get high byte, which is the remainder that is used as the x position
    sar  ax, 8               ; shift right a byte so that it is now in the lower part of ax
    push ax
    fild word  [esp]
    push dword [X_STEP]
    fmul dword [esp]
    push dword [X_MIN]
    fadd dword [esp]         ; (x * step) + min
    fstp dword [xpos]        ; same as with y but for x
    mov esp, ebp             ; reset stack

    mov eax, dword [xpos]    ; eax is x
    mov ebx, dword [ypos]    ; ebx is y

    xor dx, dx               ; use dx as loop counter

.loop:
    push eax
    push ebx

     ; esp: y pos
     ; esp+4: x pos

    fld  dword [esp]
    fmul dword [esp]
    fstp dword [esp]         ; square y position on stack

     ; esp: y pos * y pos
     ; esp+4: x pos

    fld  dword [esp+4]
    fmul dword [esp+4]
    fsub dword [esp]         ; real = x*x - y*y
    fstp dword [real]        ; store result in reserved space

    mov  dword [esp], ebx    ; restore ebx to non-squared value

     ; esp: y pos
     ; esp+4: x pos

    fld  dword [two]
    fmul dword [esp]
    fmul dword [esp+4]
    fstp dword [imag]        ; imag = 2xy

    fld  dword [real]
    fadd dword [xpos]
    fstp dword [esp+4]       ; x = real + original x

    fld  dword [imag]
    fadd dword [ypos]
    fstp dword [esp]         ; y = imag + original y

                             ; esp: new y pos
                             ; esp+4: new x pos

    mov eax, dword [esp+4]
    mov ebx, dword [esp]

    fld  dword [esp]
    fmul dword [esp]
    fstp dword [esp]
    fld  dword [esp+4]
    fmul dword [esp+4]
    fadd dword [esp]         ; store x*x+y*y in floating-point register
    mov esp, ebp             ; done with those stack values

                             ; esp: magnitude of imaginary number
                             ; esp+4: (new) x pos

    fld    dword [four]
    fcompp                   ; compare magnitude to 4
    push   eax               ; save current value of eax
    fnstsw ax                ; save result of comparison to ax
    sahf                     ; move that result to the flags used by jb, ja, etc.
    pop    eax               ; restore value of eax
    jb     .done             ; magnitude is above 4, so the value isn't in the set
    cmp    dx, 35
    jge    .done             ; stop after 35 loops
    inc    dx
    jmp    .loop

.done:
    mov eax, pixels          ; store memory location of pixels in eax

    cmp dx, 30               ; if it took over 30 iterations, completely fill the pixel (pixel 4)
    jg  .4
    cmp dx, 20
    jg  .3
    cmp dx, 15
    jg  .2
    cmp dx, 10               ; if it's less than 30, choose a pixel between 1-3
    jg  .1

    jmp .0                   ; not close enough, choose pixel 0, or space to make the pixel empty

.4: inc eax
.3: inc eax
.2: inc eax
.1: inc eax
.0: mov al, byte [eax]
    push eax                 ; save character to stack

    mov ax, cx               ; get current pixel offset from 0
    mov bx, 2
    mul bx                   ; multiply by 2 because each character is 2 bytes
    mov di, ax               ; this is the location where the pixel goes
    pop eax                  ; put the desired character into al
    mov byte [es:di], al     ; fill in pixel
    mov byte [es:di+1], 0x0f ; set color to 0f (white-on-black)
    mov esp, ebp             ; reset stack

    inc cx                   ; go to next pixel
    cmp cx, 2000
    jle .nextpixel           ; loop again unless 1ll 2000 pixels are already filled

.halt:
    hlt                      ; done!

xpos: dd 0
ypos: dd 0
real: dd 0
imag: dd 0                   ; reserve memory locations for certain values that I don't want to put on the stack

pixels db " +*@#"            ; pixels in order from least to greatest number of iterations
two    dd 2.0
four   dd 4.0                ; don't really need to do this but it seemed easier

; size of window
X_MIN  dd -2.0
X_STEP dd 0.0511             ; Y_STEP / 1.8 (aspect ratio)
Y_MIN  dd -1.15
Y_STEP dd 0.092              ; 4 / 25

times 510 - ($-$$) db 0
dw 0xaa55
