[org 0x7C00]          ; Indirizzo di caricamento del BIOS

start:
    cli               ; Disattiva gli interrupt
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00    ; Imposta lo stack sotto il bootloader
    sti               ; Riattiva gli interrupt

    ; Qui tipicamente sileggerebbe il kernel dal disco usando INT 13h
    ; e lo si caricherebbe all'indirizzo desiderato (es. 0x0EE0 o simile)

    jmp 0x0000:0x0EE  ; Salto all'indirizzo specificato

    times 510-($-$$) db 0  ; Riempimento fino a 510 byte
    dw 0xAA55              ; Firma di boot (Boot signature)
    
