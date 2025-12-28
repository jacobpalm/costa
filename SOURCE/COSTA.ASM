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
;
; Tested using TASM version 4.1 and TLINK 7.1

; ---------------------------------------------------------------------------
; Constants
; ---------------------------------------------------------------------------

STACK_SIZE           EQU 400h ; 1 kilobyte stack
DOS_REQUIRED_VERSION EQU 4    ; Minimum required DOS major version
DESKTOP_EXIT_CODE    EQU 1    ; Exit code from desktop that signals to exit


;----------------------------------------------------------------------------
; Assembler instructions
; ---------------------------------------------------------------------------
IDEAL
MODEL SMALL
STACK STACK_SIZE


; ---------------------------------------------------------------------------
; Macros
; ---------------------------------------------------------------------------

; Print msg to screen using DOS API
MACRO PrintStr msgString
	lea dx, msgString       ; Load address of msgString into DX
	mov ah, 09h             ; DOS function to print string
	int 21h
ENDM PrintStr

MACRO WaitForKey
	PrintStr [MSG_CONTINUE] ; Prompt for key press
	mov ah, 07h             ; Read character without echo
	int 21h
ENDM WaitForKey


; ---------------------------------------------------------------------------
; Structure definitions
; ---------------------------------------------------------------------------

STRUC ExecPB                  ; MS-DOS INT 21H EXEC parameter block
	EnvSeg      dw 0          ; Environment segment - 0 = inherit from parent
	ParamOff    dw 0          ; Pointer to parameters (command tail)
	ParamSeg    dw 0
	FCB1PtrOff  dw 0          ; Pointer to FCB1 - 0 = none
	FCB1PtrSeg  dw 0
	FCB2PtrOff  dw 0          ; Pointer to FCB2 - 0 = none
	FCB2PtrSeg  dw 0
ENDS ExecPB


; ---------------------------------------------------------------------------
; Data segment
; ---------------------------------------------------------------------------
DATASEG

COSTAEXE        db 'COSTA.EXE', 0      ; File name of this program
DESKTOPEXE      db 'DESKTOP.EXE', 0    ; File name of desktop program
DESKTOPPARAMS   db 9, ' /RUN', 0Dh, 0  ; Command line MUST end with 0Dh -
                                       ; null terminator is added for ASCIIZ
                                       ; compatibility with CopyStr, space
                                       ; before recommended by MS docs
RUNFILE         db 'CONFIG\RUN.BIN', 0 ; File where desktop writes program to
                                       ; run and its parameters

CostaPath       db 68 dup(0)           ; 63 char + null - path to self

Filename        db 80 dup(0)           ; 79 char + null - filename to run,
                                       ; may include path
Path            db 68 dup(0)           ; 67 char + null - working directory
Parameters      db 128 dup(0)          ; 127 char + null - command tail
PauseOnExit     db 0                   ; Boolean - pause after EXEC
RunningDesktop  db 0                   ; Boolean - are we running the desktop

ParamBlock      ExecPB <> ; EXEC parameter block based on ExecPB structure

; Messages for output to user
MSG_CONTINUE    db 'Press any key to continue...$', 0
MSG_LOW_MEM     db 'Out of memory', 13, 10, '$', 0
MSG_MEM_ERR     db 'Memory not released', 13, 10, '$', 0
MSG_DOS_TOO_OLD db 'DOS 4 or newer required', 13, 10, '$', 0
MSG_NOT_FOUND   db 'Desktop not found', 13, 10, '$', 0
MSG_PATH_FAIL   db 'Invalid path', 13, 10, '$', 0

SavedSS         dw 0     ; Stack Segment + pointer saved before EXEC
SavedSP         dw 0

ExecErrorCode   dw 0     ; DOS error code saved here if EXEC fails

LABEL EndOfData BYTE     ; Marks end of the data segment, used for memory resize


; ---------------------------------------------------------------------------
; Code segment
; ---------------------------------------------------------------------------
CODESEG

start:
	mov ax, @data     ; Initialize data segment registers
	mov ds, ax
	mov es, ax

	; Check required DOS version (4.0 or higher)
	mov ah, 30h		  ; Get DOS version
	int 21h
	cmp al, DOS_REQUIRED_VERSION
	jnc GetCostaPath  ; Jump if version is sufficient
	jmp DosTooOld     ; Jump if less than required version

GetCostaPath:
	; Path is stored in environment block, which is pointed to by PSP
	mov ah, 62h       ; DOS: Get PSP segment
	int 21h
	mov es, bx        ; ES = PSP

	; Get environment segment pointer from PSP:2Ch
	mov bx, [es:2Ch]  ; ES:2C contains WORD pointer to environment segment
	mov es, bx        ; ES = environment segment
	xor si, si        ; SI = offset in environment segment, start at 0

	; Scan for double null terminator (end of environment block)
FindEnvEnd:
	mov al, [es:si]
	inc si
	or al, al
	jne FindEnvEnd    ; byte not null, keep scanning
	mov al, [es:si]   ; byte null, check next byte
	inc si
	or al, al
	jne FindEnvEnd    ; second byte not null, keep scanning

	
	add si, 2 ; Skip word gap between environment and exe path

	; Copy executable path + name into CostaPath, track last backslash
	lea di, [CostaPath]    ; DI = destination in DS
	xor bx, bx             ; BX = pointer to last backslash in CostaPath

CopyPathLoop:
	mov al, [es:si]        ; read byte from environment
	inc si
	mov [di], al           ; store byte into CostaPath
	cmp al, 5Ch            ; is byte a backslash?
	jne NotSlash
	mov bx, di             ; move counter into bx to track last backslash
NotSlash:
	inc di
	cmp al, 0              ; null terminator?
	jne CopyPathLoop       ; if not, keep copying

    ; Remove filename: replace last backslash with null
	test bx, bx
	jz DoneCopy            ; if no backslash found, skip ahead
	xor al, al             ; AL = 0
	mov [bx], al           ; Replace last backslash with null
DoneCopy:
	mov ax, @data          ; Reset data segment
	mov es, ax

RunDesktop:
	; Copy desktop variables to working variables
	lea si, [DESKTOPEXE]    ; Copy desktop exe to filename
	lea di, [Filename]
	call CopyStr
	lea si, [DESKTOPPARAMS] ; Copy desktop parameters to parameters
	lea di, [Parameters]
	call CopyStr
	lea si, [CostaPath]    ; Copy Costa path to working path
	lea di, [Path]
	call CopyStr
	mov [PauseOnExit], 0    ; 0 = false
	mov [RunningDesktop], 1 ; We are running the desktop now

RunProgram:
	mov ah, 3Bh           ; Change directory function
	lea dx, [Path]	      ; DS:DX = path to change to
	int 21h
	jnc PathOK 	          ; Jump if successful
	jmp PathError         ; Jump if error

PathOK:
	; Shrink memory before running external program
	mov ah, 62h          ; Get PSP segment function
	int 21h
	mov es, bx           ; bx = PSP segment, store in ES
	; Memory layout of EXE:
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
	PrintStr [MSG_MEM_ERR]
	jmp ProgramEnd

CallExec:
	; Set up the EXEC parameter block
	mov ax, @data
	mov es, ax
	mov [ParamBlock.EnvSeg], 0       ; 0 = inherit parent environment
	mov [ParamBlock.ParamOff], offset Parameters
	mov [ParamBlock.ParamSeg], ds
	mov [ParamBlock.FCB1PtrSeg], 0   ; 0 = inherit FCBs
	mov [ParamBlock.FCB1PtrOff], 0
	mov [ParamBlock.FCB2PtrSeg], 0
	mov [ParamBlock.FCB2PtrOff], 0

	; Call EXEC to run the program
	mov [SavedSS], ss    ; Save stack segment and pointer before EXEC
	mov [SavedSP], sp
	lea dx, [Filename]   ; DS-DX = ASCIIZ filename of program to execute
	lea bx, [ParamBlock] ; ES:BX = pointer to EXEC parameter block
	mov ah, 4Bh          ; EXEC function
	mov al, 00h          ; Load and run
	int 21h

	mov ax, @data        ; Re-initialize data segment registers
	mov ds, ax
	mov es, ax
	cli                  ; Disable interrupts due to bug on some CPUs
	mov ss, [SavedSS]    ; Restore stack
	mov sp, [SavedSP]
	sti                  ; Re-enable interrupts

	; Check for errors from EXEC - CF not affected by DS/ES or stack restore
	jnc ExecOK           ; Jump if no error

	; EXEC failed, save error info from ax
	mov [ExecErrorCode], ax
	jmp ExecDone

ExecOK:
	; No error - set manually since AX is not guaranteed to be zero on success
	mov [ExecErrorCode], 0  ; Exec OK, AX can be anything so set explicitly

	cmp [PauseOnExit], 0
	je ExecDone             ; If no pause on exit requested, continue
	WaitForKey

ExecDone:
	cmp [RunningDesktop], 1
	jne ProgramEnd       ; If not running desktop, run next program

	; Check for errors from trying to EXEC desktop
	mov ax, [ExecErrorCode]
	cmp ax, 02h		     ; 2 = file not found
	je DeskNotFound
	cmp ax, 08h		     ; 8 = out of memory
	je DeskOutOfMem

	; Desktop executed without error, check exit code
	mov ah, 4Dh           ; "Get exit code of child process" function
	int 21h
	cmp al, DESKTOP_EXIT_CODE ; Did desktop signal to exit Costa?
	je ProgramEnd

	mov [RunningDesktop], 0 ; We are still here, which means we are about to
						  ; run another program, not the desktop
	jmp RunDesktop        ; DEBUG - load program from RUN.BIN and jump to RunProgram

DeskNotFound:
	; Fatal error - desktop program not found
	PrintStr [MSG_NOT_FOUND]
	jmp ProgramEnd

DeskOutOfMem:
	; Fatal error - not enough memory to run desktop
	PrintStr [MSG_LOW_MEM]
	jmp ProgramEnd

PathError:
	; Couldn't change path - only fatal if we are trying to run desktop
	PrintStr [MSG_PATH_FAIL] ; Show path error message
	cmp [RunningDesktop], 1
	jne PathErrorIgnore      ; If not running desktop, we will ignore error
	jmp ProgramEnd           ; Couldn't change to desktop path, exit

PathErrorIgnore:
	; We weren't running the desktop, so ignore path error and run desktop
	WaitForKey
	jmp RunDesktop

DosTooOld:
	; Fatal error - DOS version too old
	PrintStr [MSG_DOS_TOO_OLD]

ProgramEnd:
	mov ah, 4Ch          ; Terminate program
	mov al, 0            ; Exitcode = 0
	int 21h              ; Bye


; ---------------------------------------------------------------------------
; Procedures
; ---------------------------------------------------------------------------

; CopyStr - Copy ASCIIZ string. No length limit, copies until null terminator
;           found. Make sure destination buffer is big enough.
;
; Inputs:   DS:SI = source string
;           ES:DI = destination string
;
; Outputs:  DS:SI and ES:DI point to byte after null terminator
;
; Destroys: AL, SI, DI, Flags
;
PROC CopyStr NEAR
CopyByte:
	lodsb                ; Load byte from [SI] into AL, SI++
	stosb                ; Save byte from AL into [DI], DI++
	test al, al          ; Test if al is null (end of string)
	jnz CopyByte         ; Jump while not null = not end of string
	ret
ENDP CopyStr

END start                ; Mark the program's entry point