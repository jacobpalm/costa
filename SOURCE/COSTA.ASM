; COSTA.ASM - Costa launcher
;
; This is the part of Costa that launches DESKTOP.EXE with appropriate
; parameters, and stays in memory at all times. Whenever the desktop wants to
; run a program, it writes information about this to disk and exits. This
; launcher then picks up that information and runs the requested program, and
; when that program exits, it reloads the desktop.
;

; ---------------------------------------------------------------------------
; Constants
; ---------------------------------------------------------------------------

STACK_SIZE EQU 400h           ; 1 kilobyte stack
DOS_REQUIRED_VERSION EQU 4    ; Minimum required DOS major version
DESKTOP_EXIT_CODE    EQU 2    ; Exit code from desktop that signals to exit

; ---------------------------------------------------------------------------
; Structure definitions
; ---------------------------------------------------------------------------

; EXEC parameter block
ExecPB STRUC
	EnvSeg      dw 0    ; Use parent environment segment
	ParamOff    dw 0
	ParamSeg    dw 0
	FCB1PtrOff  dw 0
	FCB1PtrSeg  dw 0
	FCB2PtrOff  dw 0
	FCB2PtrSeg  dw 0
ExecPB ENDS

; ---------------------------------------------------------------------------
; Macros
; ---------------------------------------------------------------------------

; Copy ASCIIZ string from src to dest - no length checking, make sure dest is
; large enough!
CopyStr MACRO srcString, destString
	LOCAL CopyByte
	lea si, srcString   ; Load the address of the source string into SI
	lea di, destString  ; Load the address of the dest variable into DI
CopyByte:
	; PUSH/POP values and convert to PROC?
	LODSB                ; AL = [SI], SI++
	STOSB                ; [DI] = AL, DI++
	cmp AL, 0            ; End of string (null) comparison
	jne CopyByte         ; Jump while not null = not end of string
ENDM CopyStr

; Print msg to screen using DOS API
PrintStr MACRO msgString
	lea dx, msgString   ; Load the address of the message string into DX
	mov ah, 09h         ; DOS function to print string
	int 21h             ; Call DOS interrupt
ENDM PrintStr

; Wait for a key press
WaitKey MACRO
	PrintStr MSG_CONTINUE ; Prompt for key press
	mov ah, 07h           ; Read character without echo
	int 21h               ; Call BIOS keyboard interrupt
ENDM WaitKey

SaveStack MACRO
	; Save stack
	mov SavedSS, ss
	mov SavedSP, sp
ENDM

RestoreStack MACRO
	; Restore stack - disable interrupts meanwhile to avoid errors
	cli
	mov ss, SavedSS
	mov sp, SavedSP
	sti
ENDM RestoreStack

InitDataSegRegisters MACRO
	mov bx, @data     ; Load data segment using BX, since AX may contain data
	mov ds, bx
	mov es, bx
ENDM


;----------------------------------------------------------------------------
; Assembler definitions
; ---------------------------------------------------------------------------
.MODEL SMALL
.STACK     STACK_SIZE          


; ---------------------------------------------------------------------------
; Data segment
; ---------------------------------------------------------------------------
.DATA

COSTAEXE        db 'COSTA.EXE', 0
COSTAEXELEN     EQU 9
DESKTOPEXE      db 'DESKTOP.EXE', 0
DESKTOPPARAMS   db 9, ' /RUN', 0Dh, 0 ; Command line MUST end with 0Dh -
									  ; null terminator is added for ASCIIZ
									  ; compatibility with CopyStr, space
									  ; before recommended by MS docs
RUNFILE         db 'CONFIG\RUN.BIN', 0
RUNFILESIZE     EQU 280               ; Expected size of RUNFILE on disk

CostaPath       db 67 dup(0) ; 67 characters + null terminator
Filename        db 67 dup(0) ; 67 characters + null terminator
Path            db 79 dup(0) ; 79 characters + null terminator
Parameters      db 127 dup(0); 127 characters + null terminator
PauseOnExit     db 0
RunningDesktop  db 0 ; Boolean - are we running the desktop now?

ParamBlock      ExecPB <> ; EXEC parameter block based on ExecPB structure

; Messages for output to user
MSG_CONTINUE    db 'Press any key to continue...$', 0
MSG_LOW_MEM     db 'Out of memory', 13, 10, '$', 0
MSG_MEM_ERR     db 'Memory fail', 13, 10, '$', 0
MSG_DOS_TOO_OLD db 'Need DOS 4 or newer', 13, 10, '$', 0
MSG_NOT_FOUND   db 'Desktop not found', 13, 10, '$', 0
MSG_PATH_FAIL   db 'Costa path invalid', 13, 10, '$', 0

; Variables to save stack segment and pointer during EXEC
SavedSS         dw 0 ; Stack Segment
SavedSP         dw 0 ; Stack Pointer

; EXEC status
ExecErrorCode  dw 0 ; DOS error code if ExecErrorFlag is non-zero
ChildExitCode  db 0 ; Exit code of child process called via EXEC

EndOfData LABEL BYTE ; Marks the end of the data segment, used for mem resize

; ---------------------------------------------------------------------------
; Code segment
; ---------------------------------------------------------------------------
.CODE

start:
	InitDataSegRegisters	; Initialize data segment registers
	
	; Check required DOS version (4.0 or higher)
	mov AH, 30h		; Get DOS version
	int 21h
	cmp AL, DOS_REQUIRED_VERSION
	jnc RunDesktop  ; Jump if version is sufficient
	jmp DosTooOld   ; Jump if less than required version

RunDesktop:
	; Copy desktop variables to working variables
	CopyStr DESKTOPEXE, Filename
	CopyStr DESKTOPPARAMS, Parameters
	CopyStr CostaPath, Path
	mov PauseOnExit, 0    ; PauseOnExit = false
	mov RunningDesktop, 1 ; We are running the desktop now

RunProgram:
	; Shrink memory before running external program
	MOV AH, 62h          ; Get PSP segment
	INT 21h              ; BX = PSP segment
	MOV ES, BX
	; Memory layout:
	;   Code segment
	;   Data segment
	;   Stack
	; Label EndOfData marks the end of the data segment, so we can calculate
	; how much memory we need to keep by adding STACK_SIZE to that address
	; BX = paragraphs needed
	MOV AX, OFFSET EndOfData
	ADD AX, STACK_SIZE   ; Include stack size
	ADD AX, 15           ; Round up to next paragraph
	SHR AX, 4            ; Bytes to paragraphs
	MOV BX, AX           ; Move paragraph needed count to BX
	MOV AH, 4Ah          ; Resize memory block
	INT 21h
	jnc CallExec         ; No errors

	; Error during memory resize
	PrintStr MSG_MEM_ERR
	jmp ProgramEnd

CallExec:
	; Set up the EXEC parameter block
	mov ax, @data
	mov ds, ax
	mov es, ax
	mov ParamBlock.EnvSeg, 0 ; Inherit parent environment
	mov ParamBlock.ParamOff, OFFSET Parameters
	mov ParamBlock.ParamSeg, ds
	mov ParamBlock.FCB1PtrSeg, 0
	mov ParamBlock.FCB1PtrOff, 0
	mov ParamBlock.FCB2PtrSeg, 0
	mov ParamBlock.FCB2PtrOff, 0

	; Call EXEC to run the program
	SaveStack
	lea dx, Filename    ; DS-DX = ASCIIZ filename of program to execute
	lea bx, ParamBlock  ; ES:BX = pointer to EXEC parameter block
	mov ah, 4Bh         ; EXEC function
	mov al, 00h         ; Load and run
	int 21h             ; Call DOS

	; Re-initialize data segment registers and reload stack after EXEC
	InitDataSegRegisters	
	RestoreStack

	; Check for errors from EXEC - CF not affected by DS/ES or stack restore
	jnc ExecOK          ; Jump if no error

	; EXEC failed, save error info
	mov ExecErrorCode, ax
	mov ChildExitCode, 0 ; No exit code in this case
	jmp ExecDone

ExecOK:
	; No error - set manually since AX is not guaranteed to be zero on success
	mov ExecErrorCode, 0
	
	; Get exit code of program
	mov ah, 4Dh
	int 21h
	mov ChildExitCode, al

ExecDone:

	cmp RunningDesktop, 1
	jne ProgramEnd      ; If not running desktop, run next program
	
	; Check for errors from desktop EXEC
	mov ax, ExecErrorCode
	cmp ax, 02h		    ; 2 = file not found
	je DeskNotFound
	cmp ax, 08h		    ; 8 = out of memory
	je DeskOutOfMem
	
	; Check exit code from desktop
	cmp ChildExitCode, DESKTOP_EXIT_CODE
	je ProgramEnd       ; Exit if desktop signaled to exit

	mov RunningDesktop, 0 ; We are still here, which means we are about to
						  ; run another program, not the desktop
	jmp ProgramEnd ;DEBUG - load program from RUN.BIN and jump to RunProgram

DeskNotFound:
	PrintStr MSG_NOT_FOUND
	jmp ProgramEnd

DeskOutOfMem:
	PrintStr MSG_LOW_MEM
	jmp ProgramEnd

DosTooOld:
	PrintStr MSG_DOS_TOO_OLD

ProgramEnd:
	WaitKey ; DEBUG

	mov ah, 4Ch    ; DOS interrupt to terminate program
	mov al, 0      ; Return code 0
	int 21h        ; Call DOS interrupt


EndOfCode LABEL BYTE ; Marks the end of the program, used when shrinking program before running EXEC

END start            ; Mark the program's entry point