[org 0x7E00]

start:
    call print_prompt
    call read_string
    
    ; Confronta l'input con i comandi disponibili
    mov si, buffer
    mov di, cmd_clear
    call strcmp
    jc do_clear          ; Se il flag Carry è attivo, le stringhe sono uguali

    mov si, buffer
    mov di, cmd_shutdown
    call strcmp
    jc do_shutdown

    ; (Qui puoi aggiungere i controlli per create, delete, readfile)
    
    jmp start

; --- Comando CLEAR ---
do_clear:
    ; Pulisci lo schermo usando il BIOS (Interrupt 10h, Funzione 07h o 00h)
    mov ax, 0x0003       ; Modalità testo 80x25 (pulisce lo schermo)
    int 0x10
    jmp start

; --- Comando SHUTDOWN ---
do_shutdown:
    ; Tenta lo spegnimento via APM (Advanced Power Management) del BIOS
    mov ax, 0x5307
    mov bx, 0x0001
    mov cx, 0x0003
    int 0x15
    
    ; Se APM fallisce, entra in un ciclo infinito di attesa
.halt:
    cli
    hlt
    jmp .halt

; --- Funzione di confronto stringhe ---
; Input: SI = stringa inserita, DI = stringa comando da confrontare
; Output: Flag Carry (CF) impostato se uguali
strcmp:
.loop:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne .notequal
    test al, al
    jz .equal
    inc si
    inc di
    jmp .loop
.notequal:
    clc                  ; Azzera il Carry (diverse)
    ret
.equal:
    stc                  ; Imposta il Carry (uguali)
    ret

; --- Funzioni di supporto (Prompt e Input) ---
print_prompt:
    mov ah, 0x0E
    mov al, '@'
    int 0x10
    mov al, ' '
    int 0x10
    ret

read_string:
    mov di, buffer
.read_loop:
    mov ah, 0x00
    int 0x16
    cmp al, 0x0D
    je .read_done
    cmp al, 0x08
    je .backspace
    stosb
    mov ah, 0x0E
    int 0x10
    jmp .read_loop
.backspace:
    cmp di, buffer
    je .read_loop
    dec di
    mov ah, 0x0E
    mov al, ' '
    int 0x10
    mov al, 0x08
    int 0x10
    jmp .read_loop
.read_done:
    mov byte [di], 0
    mov ah, 0x0E
    mov al, 0x0A
    int 0x10
    mov al, 0x0D
    int 0x10
    ret

read_string:
    mov di, buffer
.read_loop:
    mov ah, 0x00
    int 0x16          ; Legge un tasto da tastiera (il codice ASCII viene salvato in AL)
    
    cmp al, 0x0D      ; Controlla se è INVIO (Enter)
    je .read_done
    
    cmp al, 0x08      ; Controlla se è BACKSPACE (0x08)
    je .handle_backspace
    
    cmp al, 0x7F      ; Controlla se è DELETE (spesso usato come backspace in alcuni emulatori)
    je .handle_backspace
    
    ; Controllo limite buffer (massimo 63 caratteri per evitare overflow)
    push di
    mov ax, di
    sub ax, buffer
    cmp ax, 63
    pop di
    jge .read_loop    ; Se il buffer è pieno, ignora il carattere

    stosb             ; Salva il carattere nel buffer e incrementa DI
    mov ah, 0x0E      ; Funzione BIOS teletype per stampare a schermo
    int 0x10
    jmp .read_loop

.handle_backspace:
    cmp di, buffer    ; Controlla se siamo già all'inizio del buffer
    je .read_loop     ; Se sì, non fa nulla per evitare di cancellare il prompt '@'
    
    dec di            ; Torna indietro di un byte nel buffer
    mov byte [di], 0  ; Pulisce la posizione nel buffer
    
    ; Sequenza visiva per cancellare il carattere a schermo:
    mov ah, 0x0E
    mov al, 0x08      ; 1. Muove il cursore indietro di uno spazio
    int 0x10
    mov al, ' '       ; 2. Stampa uno spazio vuoto (cancella il carattere precedente)
    int 0x10
    mov al, 0x08      ; 3. Muove nuovamente il cursore indietro nella posizione corretta
    int 0x10
    
    jmp .read_loop

.read_done:
    mov byte [di], 0  ; Termina la stringa con il terminatore nullo (0)
    
    ; Stampa una nuova linea a schermo dopo aver premuto Invio
    mov ah, 0x0E
    mov al, 0x0A      ; Line Feed (LF)
    int 0x10
    mov al, 0x0D      ; Carriage Return (CR)
    int 0x10
    ret


; Stringhe di definizione
cmd_clear    db "clear", 0
cmd_shutdown db "shutdown", 0
buffer       times 64 db 0
