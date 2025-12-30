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

STACK_SIZE             EQU 400h    ; 1 kilobyte stack
PARAGRAPH_SIZE         EQU 16      ; Size of a memory paragraph in bytes
WORD_SIZE              EQU 2       ; Size of a word in bytes
DOS_REQUIRED_VERSION   EQU 4       ; Minimum required DOS major version
DESKTOP_EXIT_CODE      EQU 1       ; Exit code from desktop that signals to exit

EXEC_FUNCTION          EQU 4Bh     ; DOS EXEC function number
EXEC_LOAD_RUN          EQU 00h     ; EXEC load and run subfunction
TERMINATE_FUNCTION     EQU 4Ch     ; DOS terminate program function number
READ_CHAR_FUNCTION     EQU 07h     ; DOS read char without echo function number
PRINT_STR_FUNCTION     EQU 09h     ; DOS print string function number
GET_DOS_VER_FUNCTION   EQU 30h     ; DOS get version function number
GET_PSP_FUNCTION       EQU 62h     ; DOS get PSP segment function number
CHDIR_FUNCTION         EQU 3Bh     ; DOS change directory function number
RESIZE_MEM_FUNCTION    EQU 4Ah     ; DOS resize memory block function number
GET_EXIT_CODE_FUNCTION EQU 4Dh     ; DOS get exit code of child process
OPEN_FILE_FUNCTION     EQU 3Dh     ; DOS open file function number
OPEN_READ_ONLY         EQU 00h     ; Open file read-only mode
CLOSE_FILE_FUNCTION    EQU 3Eh     ; DOS close file function number
READ_FILE_FUNCTION     EQU 3Fh     ; DOS read file function number
DELETE_FILE_FUNCTION   EQU 41h     ; DOS delete file function number

ERR_UNKNOWN			   EQU 0       ; Index in MsgTable for unknown error
ERR_MEMORY             EQU 8       ; Index for memory error
ERR_DOS_VERSION        EQU 13      ; Index for unsupported DOS version error

FATAL_ERROR_FLAG       EQU 1       ; Flag indicating fatal error for HandleError

DOS_ERR_FILE_NOT_FOUND EQU 02h     ; DOS error code for file not found
DOS_ERR_OUT_OF_MEM     EQU 08h     ; DOS error code for out of memory

BACKSLASH_CHAR         EQU 5Ch     ; ASCII code for backslash
SPACE_CHAR             EQU 20h     ; ASCII code for space
CR_CHAR                EQU 0Dh     ; ASCII code for carriage return
LF_CHAR                EQU 0Ah     ; ASCII code for line feed


;----------------------------------------------------------------------------
; Assembler instructions
; ---------------------------------------------------------------------------
IDEAL
NAME COSTA
MODEL SMALL
STACK STACK_SIZE


; ---------------------------------------------------------------------------
; Macros
; ---------------------------------------------------------------------------

; Print msg to screen using DOS API
MACRO PRINTSTR msgString
	lea dx, msgString              ; Load address of msgString into DX
	mov ah, PRINT_STR_FUNCTION
	int 21h
ENDM PRINTSTR

MACRO WAITFORKEY
	PRINTSTR [MSG_CONTINUE]        ; Prompt for key press
	mov ah, READ_CHAR_FUNCTION     ; Read character without echo
	int 21h
ENDM WAITFORKEY


; ---------------------------------------------------------------------------
; Structure definitions
; ---------------------------------------------------------------------------

STRUC ExecPB                       ; MS-DOS INT 21H EXEC parameter block
	EnvSeg      dw 0               ; Environment segment - 0 = inherit from parent
	ParamOff    dw 0               ; Pointer to parameters (command tail)
	ParamSeg    dw 0
	FCB1PtrOff  dw 0               ; Pointer to FCB1 - 0 = none
	FCB1PtrSeg  dw 0
	FCB2PtrOff  dw 0               ; Pointer to FCB2 - 0 = none
	FCB2PtrSeg  dw 0
ENDS ExecPB

STRUC RunProgStruc
	Filename        db 80 dup(0)   ; 79 char + null - filename, maybe path
	Path            db 68 dup(0)   ; 67 char + null - working directory
	Parameters      db 128 dup(0)  ; 127 char + null - command tail
	PauseOnExit     db 0           ; Boolean - pause after EXEC
ENDS RunProgStruc


; ---------------------------------------------------------------------------
; Data segment
; ---------------------------------------------------------------------------
DATASEG

DESKTOPEXE      db 'DESKTOP.EXE', 0        ; File name of desktop program
DESKTOPPARAMS   db 5, ' /RUN', CR_CHAR, 0  ; Format: Length, space,
                                           ; string, CR, null (null is not
                                           ; req. by DOS but is used by
                                           ; CopyStr procedure here)
RUNFILE         db 'CONFIG\RUN.BIN', 0     ; File where desktop writes program
                                           ; to run and its parameters to

CostaPath       db 68 dup(0)       ; 63 char + null - path to self
RunFileHandle   dw 0               ; File handle for RUN.BIN

RunningDesktop  db 0               ; Bool - are we running desktop?
ExecErrorCode   db 0               ; DOS error code saved here if EXEC fails

SavedSS         dw 0               ; Stack Segment + pointer saved before EXEC
SavedSP         dw 0

ParamBlock      ExecPB <>          ; EXEC parameter block
RunProg         RunProgStruc <>    ; Data about program to run

; Messages, both regular and error 
MSG_CONTINUE        db 'Press any key to continue...$', 0
MSG_UNKNOWN_ERR     db 'Unknown error', CR_CHAR, LF_CHAR, '$', 0
MSG_DOS_VER_ERR     db 'DOS 4 or newer required', CR_CHAR, LF_CHAR, '$', 0

; Standard DOS error messages
MSG_INVALID_FUNC    db 'Invalid function', CR_CHAR, LF_CHAR, '$', 0
MSG_FILE_NOT_FOUND  db 'File not found', CR_CHAR, LF_CHAR, '$', 0
MSG_PATH_NOT_FOUND  db 'Path not found', CR_CHAR, LF_CHAR, '$', 0
MSG_TOO_MANY_OPEN   db 'Too many open files', CR_CHAR, LF_CHAR, '$', 0
MSG_ACCESS_DENIED   db 'Access denied', CR_CHAR, LF_CHAR, '$', 0
MSG_INVALID_HANDLE  db 'Invalid handle', CR_CHAR, LF_CHAR, '$', 0
MSG_MEM_CB_DESTR    db 'Memory control block destroyed', CR_CHAR, LF_CHAR, '$', 0
MSG_INSUFF_MEM      db 'Insufficient memory', CR_CHAR, LF_CHAR, '$', 0
MSG_INVALID_MEM_ADD db 'Invalid memory address', CR_CHAR, LF_CHAR, '$', 0
MSG_INVALID_ENV     db 'Invalid environment', CR_CHAR, LF_CHAR, '$', 0
MSG_INVALID_FORMAT  db 'Invalid format', CR_CHAR, LF_CHAR, '$', 0
MSG_INVALID_ACCESS  db 'Invalid access mode', CR_CHAR, LF_CHAR, '$', 0

; Offset table for error messages - 1-12 are standard DOS error codes, 0 and
; 13+ are custom errors
MsgTable   dw MSG_UNKNOWN_ERR      ; 0
           dw MSG_INVALID_FUNC     ; 1
		   dw MSG_FILE_NOT_FOUND   ; 2
		   dw MSG_PATH_NOT_FOUND   ; 3
		   dw MSG_TOO_MANY_OPEN    ; 4
		   dw MSG_ACCESS_DENIED    ; 5
		   dw MSG_INVALID_HANDLE   ; 6
		   dw MSG_MEM_CB_DESTR     ; 7
		   dw MSG_INSUFF_MEM       ; 8
		   dw MSG_INVALID_MEM_ADD  ; 9
		   dw MSG_INVALID_ENV      ; 10
		   dw MSG_INVALID_FORMAT   ; 11
		   dw MSG_INVALID_ACCESS   ; 12
		   dw MSG_DOS_VER_ERR      ; 13

LABEL EndOfData BYTE               ; Marks end of the data segment, used for memory resize


; ---------------------------------------------------------------------------
; Code segment
; ---------------------------------------------------------------------------
CODESEG

start:
	mov ax, @data                  ; Initialize data segment registers
	mov ds, ax
	mov es, ax

	; Check required DOS version (4.0 or higher)
	mov ah, GET_DOS_VER_FUNCTION
	int 21h
	cmp al, DOS_REQUIRED_VERSION   ; al = major version, must be >= required
	jnc DosVersionOk               ; Jump if version is sufficient
	
	mov al, ERR_DOS_VERSION        ; DOS version error, will terminate
	mov ah, FATAL_ERROR_FLAG
	call HandleError

DosVersionOk:
	; Get path to this executable (Costa launcher)
	call GetPathToSelf

LoadRunData:
	mov ax, @data
	mov ds, ax
	mov ah, CHDIR_FUNCTION		   ; Change directory to Costa's path
	lea dx, [CostaPath]
	int 21h
	jnc OpenRunFile                ; Jump if successful
	
	mov al, [RunningDesktop]       ; AL already contains error code from int 21
	call HandleError               ; Handle path change error
	jmp RunDesktop                 ; Still here? Then try to run desktop

OpenRunFile:
    ; Load program to run data from RUN.BIN
	mov ax, @data
	mov ds, ax
	mov ah, OPEN_FILE_FUNCTION
	mov al, OPEN_READ_ONLY
	lea dx, [RUNFILE]              ; DS:DX = filename to open
	int 21h
	jnc ReadRunFile                ; Jump if open successful

	jmp RunDesktop                 ; If error, assume no RUN.BIN, and run desktop

ReadRunFile:
	mov [RunFileHandle], ax        ; Save file handle
	mov ax, @data
	mov ds, ax
	mov ah, READ_FILE_FUNCTION
	mov bx, [RunFileHandle]        ; BX = file handle
	mov cx, SIZE RunProgStruc      ; Number of bytes to read
	lea dx, [RunProg.Filename]     ; DS:DX = buffer to read into, first field of struct
	int 21h
	jnc CloseRunFile               ; Jump if read successful

	mov ah, 0                      ; Non-fatal error, error code already in AL
	call HandleError               ; Handle read error

	mov ah, CLOSE_FILE_FUNCTION    ; Make sure file is closed
	mov bx, [RunFileHandle]
	int 21h                        ; Close file
	jmp RunDesktop                 ; After showing error, run the desktop
	
CloseRunFile:
	mov ah, CLOSE_FILE_FUNCTION
	mov bx, [RunFileHandle]
	int 21h                        ; Close file
	
	; Delete RUN.BIN after reading it
	mov ah, DELETE_FILE_FUNCTION
	lea dx, [RUNFILE]
	int 21h                        ; Delete file
	
	jmp RunProgram                 ; All is good, run the program

RunDesktop:
	; Copy desktop variables to working variables
	; CopyStr procedure expects DS:SI = source, ES:DI = dest
	lea si, [DESKTOPEXE]
	lea di, [RunProg.Filename]
	call CopyStr
	lea si, [DESKTOPPARAMS]
	lea di, [RunProg.Parameters]
	call CopyStr
	lea si, [CostaPath]
	lea di, [RunProg.Path]
	call CopyStr
	mov [RunProg.PauseOnExit], 0   ; 0 = false
	mov [RunningDesktop], 1        ; We are running the desktop now

RunProgram:
	mov al, [RunProg.Path]		   ; Check if path is non-empty
	cmp al, 0
	je ShrinkMemory                ; If empty, skip changing directory

	mov ah, CHDIR_FUNCTION         ; Change directory function
	lea dx, [RunProg.Path]         ; DS:DX = path to change to
	int 21h
	jnc ShrinkMemory               ; Jump if successful

	mov ah, [RunningDesktop]       ; AL already contains error code from int 21
	call HandleError               ; Handle path change error
	jmp RunDesktop                 ; Try to run desktop again

ShrinkMemory:
	; Shrink memory before running external program
	mov ah, GET_PSP_FUNCTION
	int 21h
	mov es, bx                     ; bx = PSP segment, store in ES
	; Memory layout of EXE:
	;   Code segment
	;   Data segment
	;   Stack
	; Label EndOfData marks the end of the data segment, so we can calculate
	; how much memory we need to keep by adding STACK_SIZE to that address
	mov ax, offset EndOfData
	add ax, STACK_SIZE             ; Include stack size
	add ax, PARAGRAPH_SIZE - 1     ; Make sure divison rounds up to next paragraph
	shr ax, 4                      ; AX = byte cound, divide by 16 to get paragraph count
	mov bx, ax                     ;  (4 bits shift right = divide by 16)
	mov ah, RESIZE_MEM_FUNCTION
	int 21h

	jnc CallExecFunction           ; No errors, continue to EXEC

	; Error during memory resize
	mov ah, FATAL_ERROR_FLAG       ; al already contains error code from int 21
	call HandleError               ; Handle memory release error, will terminate

CallExecFunction:
	; Set up the EXEC parameter block
	mov ax, @data
	mov es, ax
	mov [ParamBlock.EnvSeg], 0     ; 0 = inherit parent environment
	mov [ParamBlock.ParamOff], offset RunProg.Parameters
	mov [ParamBlock.ParamSeg], ds
	mov [ParamBlock.FCB1PtrSeg], 0 ; 0 = inherit FCBs
	mov [ParamBlock.FCB1PtrOff], 0
	mov [ParamBlock.FCB2PtrSeg], 0
	mov [ParamBlock.FCB2PtrOff], 0

	; Call EXEC to run the program
	mov [SavedSS], ss              ; Save stack segment and pointer before EXEC, they will
	mov [SavedSP], sp              ; likely be changed by EXEC
	lea dx, [RunProg.Filename]     ; DS-DX = ASCIIZ filename of program to execute
	lea bx, [ParamBlock]           ; ES:BX = pointer to EXEC parameter block
	mov ah, EXEC_FUNCTION          ; EXEC function
	mov al, EXEC_LOAD_RUN          ; Load and run
	int 21h
	mov [ExecErrorCode], al        ; Save error code from EXEC, if any

	mov ax, @data                  ; Re-initialize data segment registers, will likely
	mov ds, ax                     ; have been changed by EXEC
	mov es, ax
	cli                            ; Disable interrupts due to bug on some CPUs
	mov ss, [SavedSS]              ; Restore stack
	mov sp, [SavedSP]
	sti                            ; Re-enable interrupts

	; Check for errors from EXEC - CF not affected by DS/ES or stack restore
	jnc ExecSucceeded              ; Jump if no error
	jmp EvaluateExecOutcome

ExecSucceeded:
	; EXEC ran the program successfully
	mov [ExecErrorCode], 0         ; If no error AL will have returned garbage, not zero

	cmp [RunProg.PauseOnExit], 0
	je EvaluateExecOutcome         ; If no pause on exit requested, skip ahead
	WAITFORKEY

EvaluateExecOutcome:
	mov al, [ExecErrorCode]        ; Check for errors from EXEC
	cmp al, 0
	je EvaluateExitCode            ; No error, continue to check exit code

	; Error occurred during EXEC, evaluate
	mov ah, [RunningDesktop]       ; If running desktop, any error is fatal
	call HandleError               ; AH will already contain error code from int 21
	jmp RunDesktop                 ; If we returned from HandleError, run desktop

EvaluateExitCode:
	; Desktop executed without error, check exit code
	mov ah, GET_EXIT_CODE_FUNCTION
	int 21h
	cmp al, DESKTOP_EXIT_CODE      ; Did desktop signal to exit Costa?
	je ProgramEnd

	mov [RunningDesktop], 0        ; We are still here, which means we are about to
	                               ; run another program, not the desktop
	jmp LoadRunData                ; Load RUN.BIN data again and run program

ProgramEnd:
	mov ah, TERMINATE_FUNCTION
	mov al, 0                      ; Exitcode = 0
	int 21h                        ; Bye


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
	lodsb                          ; Load byte from [SI] into AL, SI++
	stosb                          ; Save byte from AL into [DI], DI++
	test al, al                    ; Test if al is null (end of string)
	jnz CopyByte                   ; Jump while not null = not end of string
	ret
ENDP CopyStr


; GetPathToSelf - Get path to this executable
;
; Inputs:   None
;
; Outputs:  CostaPath filled with path to this executable
;
PROC GetPathToSelf NEAR
	push es

	; Path is stored in environment block, which is pointed to by PSP
	mov ah, GET_PSP_FUNCTION       ; DOS: Get PSP segment
	int 21h
	mov es, bx                     ; ES = PSP

	; Get environment segment pointer from PSP:2Ch
	mov bx, [es:2Ch]               ; ES:2C contains WORD pointer to environment segment
	mov es, bx                     ; ES = environment segment
	xor si, si                     ; SI = offset in environment segment, start at 0

	; Scan for double null terminator (end of environment block)
FindEnvEnd:
	mov al, [es:si]
	inc si
	or al, al
	jne FindEnvEnd                 ; byte not null, keep scanning
	mov al, [es:si]                ; byte null, check next byte
	inc si
	or al, al
	jne FindEnvEnd                 ; second byte not null, keep scanning

	add si, 2 ; Skip word gap between environment and exe path

	; Copy executable path + name into CostaPath, track last backslash
	lea di, [CostaPath]            ; DI = destination in DS
	xor bx, bx                     ; BX = pointer to last backslash in CostaPath

CopyPathLoop:
	mov al, [es:si]                ; read byte from environment
	inc si
	mov [di], al                   ; store byte into CostaPath
	cmp al, BACKSLASH_CHAR         ; is byte a backslash?
	jne NotSlash
	mov bx, di                     ; move counter into bx to track last backslash
NotSlash:
	inc di
	cmp al, 0                      ; null terminator?
	jne CopyPathLoop               ; if not, keep copying

    ; Remove filename: replace last backslash with null
	test bx, bx
	jz DoneCopy                    ; if no backslash found, skip ahead
	xor al, al                     ; AL = 0
	mov [bx], al                   ; Replace last backslash with null
DoneCopy:
	pop es                         ; Restore data segment
	ret
ENDP GetPathToSelf

; HandleError - Display error message based on error code, terminate
;               program if error is fatal
;
; Inputs: AL = error code number
;         AH = fatal error flag (non-zero = fatal)
;
; Outputs: None
;
PROC HandleError NEAR
	push bx                        ; Preserve registers
	push cx
	push dx
	
	mov cl, ah                     ; Save fatal flag in CL

	mov bl, al                     ; Copy error code to BL
	xor bh, bh		               ; Clear upper byte
	shl bx, 1                      ; Multiply error code by 2, size of word, for lookup in MsgTable
	mov dx, [MsgTable + bx]        ; Get address of error msg based on offset
	
	mov ah, PRINT_STR_FUNCTION
	int 21h                        ; Print error message
	
	cmp cl, FATAL_ERROR_FLAG
	je FatalError                  ; If fatal, terminate program

	pop dx                         ; Restore registers
	pop cx
	pop bx
	WAITFORKEY
	ret

FatalError:
	mov ah, TERMINATE_FUNCTION
	mov al, 1                      ; Exitcode = 1 for error
	int 21h                        ; Terminate program
ENDP HandleError

END start                          ; Mark the program's entry point