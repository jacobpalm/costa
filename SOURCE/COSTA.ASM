; COSTA.ASM - Costa launcher
;
; This is the part of Costa that launches DESKTOP.EXE with appropriate
; parameters, and stays in memory at all times. Whenever the desktop wants to
; run a program, it writes information about this to disk and exits. This
; launcher then picks up that information and runs the requested program, and
; when that program exits, it reloads the desktop.
;
; Written in assembly language for x86 real mode DOS environment. Not in
; Pascal like the rest of Costa, to keep size as smalll as possible since this
; part stays in memory at all times, including when running other programs.

; ---------------------------------------------------------------------------
; Constants
; ---------------------------------------------------------------------------

STACK_SIZE           EQU 400h ; 1 kilobyte stack
DOS_REQUIRED_VERSION EQU 4    ; Minimum required DOS major version
DESKTOP_EXIT_CODE    EQU 2    ; Exit code from desktop that signals to exit
RUNFILESIZE          EQU 280  ; Expected size of RUNFILE on disk, bytes

; ---------------------------------------------------------------------------
; Structure definitions
; ---------------------------------------------------------------------------

; EXEC parameter block
ExecPB STRUC
	EnvSeg      dw 0          ; Environment segment - 0 = inherit from parent
	ParamOff    dw 0          ; Pointer to parameters (command tail)
	ParamSeg    dw 0          
	FCB1PtrOff  dw 0          ; Pointer to FCB1 - 0 = none
	FCB1PtrSeg  dw 0          
	FCB2PtrOff  dw 0          ; Pointer to FCB2 - 0 = none
	FCB2PtrSeg  dw 0          
ExecPB ENDS

; ---------------------------------------------------------------------------
; Macros
; ---------------------------------------------------------------------------

; Copy ASCIIZ string from src to dest - no length checking, make sure dest is
; large enough! Assumes ES and DS are set to data segment.
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

; Save stack pointer and segment before EXEC
SaveStack MACRO
	mov SavedSS, ss
	mov SavedSP, sp
ENDM

; Restore stack - disable interrupts meanwhile to avoid errors on certain
; CPUs
RestoreStack MACRO
	cli
	mov ss, SavedSS
	mov sp, SavedSP
	sti
ENDM RestoreStack

; Point DS and ES to data segment
InitDataSegRegisters MACRO
	mov bx, @data     ; Load data segment using BX, since AX may contain data
	mov ds, bx        ; in some cases (eg. after EXEC)
	mov es, bx
ENDM


;----------------------------------------------------------------------------
; Assembler instructions
; ---------------------------------------------------------------------------
.MODEL SMALL
.STACK STACK_SIZE


; ---------------------------------------------------------------------------
; Data segment
; ---------------------------------------------------------------------------
.DATA

COSTAEXE        db 'COSTA.EXE', 0       ; File name of this program
COSTAEXELEN     EQU 9
DESKTOPEXE      db 'DESKTOP.EXE', 0     ; File name of desktop program
DESKTOPPARAMS   db 9, ' /RUN', 0Dh, 0   ; Command line MUST end with 0Dh -
									    ; null terminator is added for ASCIIZ
									    ; compatibility with CopyStr, space
									    ; before recommended by MS docs
RUNFILE         db 'CONFIG\RUN.BIN', 0  ; File where desktop writes program to
									    ; run and its parameters

CostaPath       db 68 dup(0)            ; 63 char + null - path to self

Filename        db 80 dup(0)            ; 79 char + null - filename to run,
                                        ; may include path
Path            db 68 dup(0)            ; 67 char + null - working directory
Parameters      db 128 dup(0)           ; 127 char + null - command tail
PauseOnExit     db 0 ; Boolean - pause after EXEC so user can see output
RunningDesktop  db 0 ; Boolean - are we running the desktop now?

ParamBlock      ExecPB <> ; EXEC parameter block based on ExecPB structure

; Messages for output to user
MSG_CONTINUE    db 'Press any key to continue...$', 0
MSG_LOW_MEM     db 'Out of memory', 13, 10, '$', 0
MSG_MEM_ERR     db 'Memory not released', 13, 10, '$', 0
MSG_DOS_TOO_OLD db 'DOS 4 or newer required', 13, 10, '$', 0
MSG_NOT_FOUND   db 'Desktop not found', 13, 10, '$', 0
MSG_PATH_FAIL   db 'Costa path invalid', 13, 10, '$', 0

; Variables to save stack segment and pointer during EXEC
SavedSS         dw 0 ; Stack Segment
SavedSP         dw 0 ; Stack Pointer

; EXEC status
ExecErrorCode   dw 0 ; DOS error code if ExecErrorFlag is non-zero
ChildExitCode   db 0 ; Exit code of child process called via EXEC

EndOfData LABEL BYTE ; Marks end of the data segment, used for memory resize

; ---------------------------------------------------------------------------
; Code segment
; ---------------------------------------------------------------------------
.CODE

start:
	mov ax, @data    ; Initialize data segment registers
	mov ds, ax
	mov es, ax

	; Check required DOS version (4.0 or higher)
	mov ah, 30h		; Get DOS version
	int 21h
	cmp al, DOS_REQUIRED_VERSION
	jnc GetCostaPath  ; Jump if version is sufficient
	jmp DosTooOld     ; Jump if less than required version
	
GetCostaPath:
; --- Setup segments ---
    mov ah, 62h       ; DOS: Get PSP segment
    int 21h
    mov es, bx        ; ES = PSP

; --- Get environment segment pointer from PSP:2Ch ---
    mov bx, es:[2Ch]  ; ES:2C contains WORD pointer to environment segment
    mov es, bx        ; ES = environment segment
    xor si, si        ; SI = offset in environment segment, start at 0

; --- Scan for double null terminator (end of environment block) ---
FindEnvEnd:
    mov al, es:[si]
    inc si
    or al, al
    jne FindEnvEnd
    mov al, es:[si]   ; check next byte
    inc si
    or al, al
    jne FindEnvEnd

; --- Skip word gap between environment and exe path ---
    add si, 2

; --- Copy executable full path into CostaPath, track last backslash ---
    lea di, CostaPath   ; DI = destination in DS
    xor bx, bx          ; BX = pointer to last backslash in CostaPath

CopyPathLoop:
    mov al, es:[si]    ; read byte from environment
    inc si
    mov byte ptr [di], al       ; store into CostaPath
    cmp al, 5Ch
    jne NoSlash
    mov bx, di         ; track last backslash
NoSlash:
    inc di
    cmp al, 0          ; null terminator?
    jne CopyPathLoop

; --- Remove filename: replace last backslash with null ---
    test bx, bx        ; if no backslash found, skip ahead
    jz DoneCopy
	mov byte ptr [bx], 0 ; add null after last backslash to remove exe name 
DoneCopy:
    mov ax, @data
	mov es, ax

RunDesktop:
	; Copy desktop variables to working variables
	CopyStr DESKTOPEXE, Filename
	CopyStr DESKTOPPARAMS, Parameters
	CopyStr CostaPath, Path
	mov PauseOnExit, 0    ; 0 = false
	mov RunningDesktop, 1 ; We are running the desktop now

RunProgram:
	; Change to the directory in Path
	mov ah, 3Bh
	lea dx, Path
	int 21h
	jnc PathOK 	   ; Jump if successful
	jmp PathError  ; Jump if error

PathOK:
	; Shrink memory before running external program
	mov ah, 62h          ; Get PSP segment
	int 21h              ; BX = PSP segment
	mov es, bx           ; ES = PSP
	; Memory layout:
	;   Code segment
	;   Data segment
	;   Stack
	; Label EndOfData marks the end of the data segment, so we can calculate
	; how much memory we need to keep by adding STACK_SIZE to that address
	mov ax, offset EndOfData
	add ax, STACK_SIZE   ; Include stack size
	add ax, 15           ; Round up to next paragraph
	shr ax, 4            ; Convert bytes to paragraphs
	mov bx, ax           ; Move count of paragraphs needed to BX
	mov ah, 4Ah          ; Resize memory block function
	int 21h
	jnc CallExec         ; No errors

	; Error during memory resize
	PrintStr MSG_MEM_ERR
	jmp ProgramEnd

CallExec:
	; Set up the EXEC parameter block
	mov ax, @data
	mov es, ax
	mov ParamBlock.EnvSeg, 0 ; Inherit parent environment
	mov ParamBlock.ParamOff, offset Parameters
	mov ParamBlock.ParamSeg, ds
	mov ParamBlock.FCB1PtrSeg, 0
	mov ParamBlock.FCB1PtrOff, 0
	mov ParamBlock.FCB2PtrSeg, 0
	mov ParamBlock.FCB2PtrOff, 0

	; Call EXEC to run the program
	SaveStack            ; Stack will likely be changed by EXEC
	lea dx, Filename     ; DS-DX = ASCIIZ filename of program to execute
	lea bx, ParamBlock   ; ES:BX = pointer to EXEC parameter block
	mov ah, 4Bh          ; EXEC function
	mov al, 00h          ; Load and run
	int 21h              ; Call DOS

	; Re-initialize data segment registers and reload stack after EXEC
	mov ax, @data
	mov ds, ax
	mov es, ax
	RestoreStack         ; Restore stack saved before EXEC

	; Check for errors from EXEC - CF not affected by DS/ES or stack restore
	jnc ExecOK           ; Jump if no error

	; EXEC failed, save error info from ax
	mov ExecErrorCode, ax
	mov ChildExitCode, 0 ; No exit code in this case
	jmp ExecDone

ExecOK:
	; No error - set manually since AX is not guaranteed to be zero on success
	mov ExecErrorCode, 0

	; Retrieve and store exit code
	mov ah, 4Dh          ; Get exit code of child process
	int 21h
	mov ChildExitCode, al

ExecDone:
	cmp RunningDesktop, 1
	jne ProgramEnd      ; If not running desktop, run next program

	; Check for errors from trying to EXEC desktop
	mov ax, ExecErrorCode
	cmp ax, 02h		    ; 2 = file not found
	je DeskNotFound
	cmp ax, 08h		    ; 8 = out of memory
	je DeskOutOfMem

	; Desktop executed, compare exit code
	cmp ChildExitCode, DESKTOP_EXIT_CODE
	je ProgramEnd       ; Exit if desktop signaled to exit

	mov RunningDesktop, 0 ; We are still here, which means we are about to
						  ; run another program, not the desktop
	jmp ProgramEnd        ;DEBUG - load program from RUN.BIN and jump to RunProgram

DeskNotFound:
    ; Fatal error - desktop program not found
	PrintStr MSG_NOT_FOUND
	jmp ProgramEnd

DeskOutOfMem:
	; Fatal error - not enough memory to run desktop
	PrintStr MSG_LOW_MEM
	jmp ProgramEnd

PathError:
	; Couldn't change path - only fatal if we are trying to run desktop
	cmp RunningDesktop, 1
	jne ProgramEnd ; If not running desktop, we will ignore error and run desktop - DEBUG
	PrintStr MSG_PATH_FAIL
	jmp ProgramEnd    ; Couldn't change to desktop path, exit

DosTooOld:
	; Fatal error - DOS version too old
	PrintStr MSG_DOS_TOO_OLD

ProgramEnd:
	WaitKey ; DEBUG
	PrintStr CostaPath
	mov ah, 4Ch    ; Terminate program
	mov al, 0      ; Exitcode = 0
	int 21h        ; Bye

END start            ; Mark the program's entry point