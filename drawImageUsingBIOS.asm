; Created by Beniamin Gajecki
; Kompilacja nasm -f bin nazwa_pliku.asm
; Testowane za pomoc¹ emulatora qemu
[bits 16]
[org 7C00h]

main:
    push 03h ; Tekstowy tryb pracy
    call setVideoMode
    add sp, 1

    push welcomeText
    call printf
    add sp, 2

    push ax
    call getKey
    mov ax, [getKeyBuffer]
    cmp ax, 0x59 ; Y
    je continue
    cmp ax, 0x79 ; y
    je continue
    cmp ax, 0x4E ; N
    je eof_n
    cmp ax, 0x6E ; n
    je eof_n
    pop ax
    jmp main

continue:
    pop ax
    push 13h ; Graficzny tryb pracy
    call setVideoMode
    add sp, 1

    call drawImage

    jmp $ ; Skok do aktualnej pozycji
eof_n:
    pop ax
    jmp $ ; Skok do aktualnej pozycji
;----------------------------------------------------------------------------------------------------
printf:
    push bp ; Pocz¹tek ramki
    mov bp, sp

    push ax ; Zostawiamy wartoœci rejstrów na stosie
    push si

    mov si, [bp + 4] ; Od pocz¹tku bp do[bp + ip] textu
    mov ah, 0Eh ; Opcja wypisywanie znaków dla przerwania 10h
    jmp printf_loop
printf_loop:
    lodsb
    cmp al, 0x0 ; Sprawdzanie czy koniec tekstu
    je printf_end ; Je¿eli tak to koniec dzia³ania funkcji
    int 10h ; Wywo³anie przerwania 10h
    jmp printf_loop
printf_end:

    pop si ; Przywracamy stare wartoœci rejstrów
    pop ax

    mov sp, bp
    pop bp ; Koniec ramki

    ret
;----------------------------------------------------------------------------------------------------
getKey:
    push ax
    mov ah, 00h
    int 16h
    mov [getKeyBuffer], al ; Pobrany kod ascii przycisku leci areoplanem do bufora
    pop ax
    ret
;----------------------------------------------------------------------------------------------------
writePixel: ; writePixel (x, y, kolor)
    push bp
    mov bp, sp

    push ax
    push bx
    push cx
    push dx

    mov ah, 0Ch
    mov bh, 0 ; Numer strony
    mov cx, [bp + 4] ; Kolumna - x
    mov dx, [bp + 6] ; Wiersz - y
    mov al, [bp + 8] ; Kolor
    int 10h


    pop dx
    pop cx
    pop bx
    pop ax

    mov sp, bp
    pop bp

    ret
;----------------------------------------------------------------------------------------------------
drawImage:
    push bp
    mov bp, sp
    push cx
    mov cx, 0xFE01 ; Supi liczba
drawImage_loop:
    push 10
    push cx
    push cx
    call writePixel
    add sp, 3 ; Niepoprawne, ale daje bardzo fajny efekt wizualny :) Poprawnie powinno byæ add sp, 5 i wtedy nie u¿ywa³bym bp do zapamiêtania sp
    loop drawImage_loop
    pop cx
    mov sp, bp
    pop bp
    ret
;----------------------------------------------------------------------------------------------------
setVideoMode: ; Ustawianie trybu pracy karty graficznej (po u¿yciu czyœci te¿ ekran).
  push bp
  mov bp, sp

  push ax

  mov ah, 00h
  mov al, [bp + 4]
  int 10h

  pop ax

  mov sp, bp
  pop bp

  ret
;----------------------------------------------------------------------------------------------------
welcomeText db "Do you want see my splash art? (y/n): ", 0x0
getKeyBuffer db 0x0
;----------------------------------------------------------------------------------------------------
times 510 - ($ - $$) db 0x0
dw 0xAA55