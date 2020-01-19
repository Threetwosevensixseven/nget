; main.asm
                                                        ; Assembles with regular version of Zeus (not Next version),
zeusemulate             "48K", "RAW", "NOROM"           ; because that makes it easier to assemble dot commands
zoSupportStringEscapes  = true;                         ; Download Zeus.exe from http://www.desdes.com/products/oldfiles/
optionsize 5
CSpect optionbool 15, -15, "CSpect", false              ; Option in Zeus GUI to launch CSpect
RealESP optionbool 80, -15, "Real ESP", false           ; Launch CSpect with physical ESP in USB adaptor
UploadNext optionbool 160, -15, "Next", false           ; Copy dot command to Next FlashAir card
ErrDebug optionbool 212, -15, "Debug", false            ; Print errors onscreen and halt instead of returning to BASIC

org $2000                                               ; Dot commands always start at $2000
Start:
                        jr Begin
                        db "NGETv1."                    ; Put a signature and version in the file in case we ever
                        BuildNo()                       ; need to detect it programmatically
                        db 0
Begin:                  di                              ; We run with interrupts off apart from printing and halts
                        ld (Return.Stack1), sp          ; Save so we can always return without needing to balance stack
                        ld sp, $4000                    ; Put stack safe inside dot command
                        ld (SavedArgs), hl              ; Save args for later

                        call InstallErrorHandler        ; Handle scroll errors during printing and API calls

                        //CSBreak()
                        PrintMsg(Msg.Startup)
                        //SafePrintStart()
                        //SafePrintEnd()
                        //CSBreak()

                        ld a, %0000 0001                ; Test for Next courtesy of Simon N Goodwin, thanks :)
                        MirrorA()                       ; Z80N-only opcode. If standard Z80 or successors, this will
                        nop                             ; be executed as benign opcodes that don't affect the A register.
                        nop
                        cp %1000 0000                   ; Test that the bits of A were mirrored as expected
                        ld hl, Err.NotNext              ; If not a Spectrum Next,
                        jp nz, Return.WithCustomError   ; exit with an error.

                        NextRegRead(Reg.MachineID)      ; If we passed that test we are safe to read machine ID.
                        cp 10                           ; 10 = ZX Spectrum Next
                        jp z, IsANext                   ;  8 = Emulator
                        cp 8                            ; Exit with error if not a Next. HL still points to err message,
                        jp nz, Return.WithCustomError   ; be careful if adding code between the Next check and here!
IsANext:
                        NextRegRead(Reg.Peripheral2)    ; Read Peripheral 2 register.
                        ld (RestoreF8.Saved), a         ; Save current value so it can be restored on exit.
                        and %0111 1111                  ; Clear the F8 enable bit,
                        nextreg Reg.Peripheral2, a      ; And write the entire value back to the register.

                        NextRegRead(Reg.CPUSpeed)       ; Read CPU speed.
                        and %11                         ; Mask out everything but the current desired speed.
                        ld (RestoreSpeed.Saved), a      ; Save current speed so it can be restored on exit.
                        nextreg Reg.CPUSpeed, %11       ; Set current desired speed to 28MHz.

                        ; Allocate a 16K package download buffer. We will use IDE_BANK to allocate two 8KB
                        ; banks, which must be freed before exiting the dot command.
                        call Allocate8KBank             ; Bank number in A (not E), errors have already been handled
                        ld (DeallocateBanks.Upper1), a  ; Save bank number
                        call Allocate8KBank             ; Bank number in A (not E), errors have already been handled
                        ld (DeallocateBanks.Upper2), a  ; Save bank number

                        ; Now we can page in the the two 8K banks at $C000 and $E000.
                        ; This paging will need to be undone during cmd exit.
                        di
                        nextreg $57, a                  ; Allocated bank for $E000 was already in A, page it in.
                        ld a, (DeallocateBanks.Upper1)
                        nextreg $56, a                  ; Page in allocated bank for $C000)

BeginWork:                                              ; Setup is finished, real work of the dot cmd starts here.
                        PrintMsg(Msg.SelfHost)
                        ESPSend("ATE0")
                        ErrorIfCarry(Err.ESPComms)      ; Raise ESP error if no response
                        call ESPReceiveWaitOK
                        ErrorIfCarry(Err.ESPComms)      ; Raise ESP error if no response

                        ESPSend("AT+CIPCLOSE")          ; Don't raise error on CIPCLOSE
                        call ESPReceiveWaitOK           ; Because it might not be open

                        ESPSend("AT+CIPMUX=0")
                        ErrorIfCarry(Err.ESPComms)      ; Raise ESP error if no response
                        call ESPReceiveWaitOK
                        ErrorIfCarry(Err.ESPComms)      ; Raise ESP error if no response

                        ESPSend("AT+CIPSTART=\"TCP\",\"" + NGetServer + "\",44444")
                        ErrorIfCarry(Err.ESPComms)      ; Raise ESP error if no response
                        call ESPReceiveWaitOK
                        ErrorIfCarry(Err.ESPComms)      ; Raise ESP error if no response

                        ESPSend("AT+CIPSEND=2")
                        ErrorIfCarry(Err.ESPComms)      ; Raise ESP error if no response
                        call ESPReceiveWaitPrompt
                        ErrorIfCarry(Err.ESPComms)      ; Raise ESP error if no prompt
                        ESPSendBufferLen(Cmd.GetV1, Cmd.GetV1Len)
                        ErrorIfCarry(Err.ESPComms)      ; Raise ESP error if no response

                        //PrintMsg(Msg.Checking)
                        //PrintMsg(Msg.Found)
                        //PrintMsg(Msg.Downloaded)
                        //PrintMsg(Msg.Overwriting)

                        if (ErrDebug)
                          ; This is a temporary testing point that indicates we have have reached
                          ; The "success" point, and does a red/blue border effect instead of
                          ; actually exiting cleanly to BASIC.
                          Freeze(1,2)
                        else
                          ; This is the official "success" exit point of the program which restores
                          ; all the settings and exits to BASIC cleanly.
                          //PrintMsg(Msg.Success)
                          jp Return.ToBasic
                        endif

                        include "constants.asm"         ; Global constants
                        include "macros.asm"            ; Zeus macros
                        include "general.asm"           ; General routines
                        include "esp.asm"               ; ESP and SLIP routines
                        include "esxDOS.asm"            ; ESXDOS routines
                        include "print.asm"             ; Messaging and error routines
                        include "vars.asm"              ; Global variables
                                                        ; Everything after this is padded to the next 8K
                                                        ; but assembles at $8000


Length       equ $-Start

zeusprinthex "Cmd size:   ", Length

if zeusver >= 74
  zeuserror "Does not run on Zeus v4.00 (TEST ONLY) or above, Get v3.991 available at http://www.desdes.com/products/oldfiles/zeus.exe"
endif

if (Length > $2000)
  zeuserror "DOT command is too large to assemble!"
endif

output_bin "..\\..\\dot\\NGET", Start, Length

if enabled UploadNext
  output_bin "R:\\dot\\NGET", Start, Length
endif

if enabled CSpect
  if enabled RealESP
    zeusinvoke "..\\..\\build\\cspect.bat"
  else
    zeusinvoke "..\\..\\build\\cspect-emulate-esp.bat"
  endif
else
  zeusinvoke "..\\..\\build\\builddot.bat"
endif

