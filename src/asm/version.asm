; version.asm
;
; Auto-generated by ZXVersion.exe
; On 14 Jan 2020 at 15:16

BuildNo                 macro()
                        db "1"
mend

BuildNoValue            equ "1"
BuildNoWidth            equ 0 + FW1



BuildDate               macro()
                        db "14 Jan 2020"
mend

BuildDateValue          equ "14 Jan 2020"
BuildDateWidth          equ 0 + FW1 + FW4 + FWSpace + FWJ + FWa + FWn + FWSpace + FW2 + FW0 + FW2 + FW0



BuildTime               macro()
                        db "15:16"
mend

BuildTimeValue          equ "15:16"
BuildTimeWidth          equ 0 + FW1 + FW5 + FWColon + FW1 + FW6



BuildTimeSecs           macro()
                        db "15:16:24"
mend

BuildTimeSecsValue      equ "15:16:24"
BuildTimeSecsWidth      equ 0 + FW1 + FW5 + FWColon + FW1 + FW6 + FWColon + FW2 + FW4