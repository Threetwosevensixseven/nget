; msg.asm

Msg                     proc
  Startup:              db "NGET v1."
                        BuildNo()
                        db CR, Copyright, " 2020 Robin Verhagen-Guest", CR, CR, 0
  SelfHost:             db "This minimal version of NGET is only capable of updating itself "
                        db "to the latest version hosted in the package repository.", CR, CR, "Watch out "
                        db "for a more functional version that can download third-party packages.", CR, CR, 0
  Checking:             db "Repository: nget.nxtel.org", CR, "Package: NGET", CR, CR, "Requesting package...", CR, 0
  Found:                db "Package found, downloading...", CR, 0
  Downloaded:           db "Package downloaded", CR, 0
  Overwriting:          db "Package already exists on Next! Overwriting...", CR, 0
pend

Err                     proc
                        ;  "<-Longest valid erro>", 'r'|128
  Break:                db "D BREAK - CONT repeat", 's'|128
  NoMem:                db "4 Out of memor",        'y'|128
  NotNext:              db "Spectrum Next require", 'd'|128
  ESPComms:             db "WiFi comms erro",       'r'|128
  ESPTimeout:           db "WiFi/server timeou",    't'|128
  ESPConn:              db "Server connect erro",   'r'|128
  CoreMin:              db "Core 3.00.07 require",  'd'|128
pend

PrintRst16              proc
                        SafePrintStart()
                        if DisableScroll
                          ld a, 24                      ; Set upper screen to not scroll
                          ld (SCR_CT), a                ; for another 24 rows of printing
                        endif
                        ei
Loop:                   ld a, (hl)
                        inc hl
                        or a
                        jr z, Return
                        rst 16
                        jr Loop
Return:                 SafePrintEnd()
                        ret
pend

PrintRst16Error         proc
                        SafePrintStart()
                        ei
Loop:                   ld a, (hl)
                        ld b, a
                        and %1 0000000
                        ld a, b
                        jp nz, LastChar
                        inc hl
                        rst 16
                        jr Loop
Return:                 jp PrintRst16.Return
LastChar                and %0 1111111
                        rst 16
                        ld a, CR                        ; The error message doesn't include a trailing CR in the
                        rst 16                          ; definition, so we want to add one when we print it
                        jr Return                       ; in the upper screen.
pend

PrintAHex               proc
                        SafePrintStart()
                        ld b, a
                        if DisableScroll
                          ld a, 24                      ; Set upper screen to not scroll
                          ld (SCR_CT), a                ; for another 24 rows of printing
                          ld a, b
                        endif
                        and $F0
                        swapnib
                        call Print
                        ld a, b
                        and $0F
                        call Print
                        ld a, 32
                        rst 16
                        ld a, 32
                        rst 16
                        jp PrintRst16.Return
Print:                  cp 10
                        ld c, '0'
                        jr c, Add
                        ld c, 'A'-10
Add:                    add a, c
                        rst 16
                        ret
pend

PrintAHexNoSpace        proc
                        SafePrintStart()
                        ld b, a
                        if DisableScroll
                          ld a, 24                      ; Set upper screen to not scroll
                          ld (SCR_CT), a                ; for another 24 rows of printing
                          ld a, b
                        endif
                        and $F0
                        swapnib
                        call Print
                        ld a, b
                        and $0F
                        call Print
                        jp PrintRst16.Return
Print:                  cp 10
                        ld c, '0'
                        jr c, Add
                        ld c, 'A'-10
Add:                    add a, c
                        rst 16
                        ret
pend

PrintChar               proc
                        SafePrintStart()
                        ld b, a
                        if DisableScroll
                          ld a, 24                      ; Set upper screen to not scroll
                          ld (SCR_CT), a                ; for another 24 rows of printing
                          ld a, b
                        endif
                        cp 32
                        jr c, NotPrintable
                        cp 127
                        jr nc, NotPrintable
Print:                  rst 16
                        jp PrintRst16.Return
NotPrintable:           ld a, '.'
                        jr Print
pend

PrintBufferHexProc      proc                            ; hl = Addr, de = Length
                        SafePrintStart()
                        ld a, (hl)
                        call PrintAHex
                        inc hl
                        dec de
                        ld a, d
                        or e
                        jr nz, PrintBufferHexProc
                        jp PrintRst16.Return
pend

