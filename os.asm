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
