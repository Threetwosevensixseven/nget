; general.asm

InstallErrorHandler     proc
                        ld hl, ErrorHandler
                        Rst8(esxDOS.M_ERRH)
                        ret
pend

ErrorHandler            proc
                        ld hl, Err.Break
                        jp Return.WithCustomError
pend

ErrorProc               proc
                        if enabled ErrDebug
                          call PrintRst16Error
Stop:                     Border(2)
                          jr Stop
                        else
                          push hl                       ; If we want to print the error at the top of the screen,
                          call PrintRst16Error          ; as well as letting BASIC print it in the lower screen,
                          pop hl                        ; then uncomment this code.
                          jp Return.WithCustomError     ; Straight to the error handing exit routine
                        endif
pend

RestoreF8               proc
Saved equ $+1:          ld a, SMC                       ; This was saved here when we entered the dot command
                        and %1000 0000                  ; Mask out everything but the F8 enable bit
                        ld d, a
                        NextRegRead(Reg.Peripheral2)    ; Read the current value of Peripheral 2 register
                        and %0111 1111                  ; Clear the F8 enable bit
                        or d                            ; Mask back in the saved bit
                        nextreg Reg.Peripheral2, a      ; Save back to Peripheral 2 register
                        ret
pend

DeallocateBanks         proc
Upper1 equ $+1:         ld a, $FF                       ; Default value of $FF means not yet allocated
                        call Deallocate8KBank           ; Ignore any error because we are doing best efforts to exit
Upper2 equ $+1:         ld a, $FF                       ; Default value of $FF means not yet allocated
                        call Deallocate8KBank           ; Ignore any error because we are doing best efforts to exit
                                                        ; In more robust library code we might want to set these
                                                        ; locations back to $FF before exiting, but here we are
                                                        ; definitely exiting the dot command imminently.
                        //ld sp, $4000                    ; Put stack within dot command for the final part
                        nextreg $56, 0                  ; Restore what BASIC is expecting to find at $C000 (16K bank 0)
                        nextreg $57, 1                  ; Restore what BASIC is expecting to find at $E000 (16K bank 0)
                        //ld sp, (Return.Stack1)          ; PRestore stack to original BASIC place for the final messages
                        //dec sp
                        //dec sp
                        ret
pend

RestoreSpeed            proc
Saved equ $+3:          nextreg Reg.CPUSpeed, SMC       ; Restore speed
                        ret
pend

Return                  proc
ToBasic:
                        call RestoreSpeed               ; Restore original CPU speed
                        call RestoreF8                  ; Restore original F8 enable/disable state
                        call DeallocateBanks            ; Return allocated 8K banks and restore upper 48K banking
                        xor a
Stack                   ld sp, SMC                      ; Unwind stack to original point
Stack1                  equ Stack+1
                        ei
                        //CSBreak()
                        ret                             ; Return to BASIC
WithCustomError:
                        //CSBreak()
                        ld sp, $4000
                        ld (ErrAddr), hl
                        call RestoreSpeed               ; Restore original CPU speed
                        call RestoreF8                  ; Restore original F8 enable/disable state
                        call DeallocateBanks            ; Return allocated 8K banks and restore upper 48K banking
ErrAddr equ $+1:        ld hl, SMC
                        //CSBreak()
                        xor a
                        scf                             ; Signal error, hl = custom error message
                        jp Stack                        ; (NextZXOS is not currently displaying standard error messages,
pend                                                    ;  with a>0 and carry cleared, so we use a custom message.)

Allocate8KBank          proc
                        ld hl, $0001                    ; H = $00: rc_banktype_zx, L = $01: rc_bank_alloc
Internal:               exx
                        ld c, 7                         ; 16K Bank 7 required for most NextZXOS API calls
                        ld de, IDE_BANK                 ; M_P3DOS takes care of stack safety stack for us
                        Rst8(esxDOS.M_P3DOS)            ; Make NextZXOS API call through esxDOS API with M_P3DOS
                        ErrorIfNoCarry(Err.NoMem)       ; Fatal error, exits dot command
                        ld a, e                         ; Return in a more conveniently saveable register (A not E)
                        ret
pend

Deallocate8KBank        proc                            ; Takes bank to deallocate in A (not E) for convenience
                        cp $FF                          ; If value is $FF it means we never allocated the bank,
                        ret z                           ; so return with carry clear (error) if that is the case
                        ld e, a                         ; Now move bank to deallocate into E for the API call
                        ld hl, $0003                    ; H = $00: rc_banktype_zx, L = $03: rc_bank_free
                        jr Allocate8KBank.Internal      ; Rest of deallocate is the same as the allocate routine
pend

