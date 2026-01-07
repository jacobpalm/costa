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

STACK_SIZE             EQU 400h    ; 1 kilobyte stack size
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
SET_DRIVE_FUNCTION     EQU 0Eh     ; DOS set current drive function number
GET_DRIVE_FUNCTION     EQU 19h     ; DOS get current drive function number

ERR_UNKNOWN            EQU 0       ; Index in MsgTable for unknown error
ERR_PATH_NOT_FOUND     EQU 3       ; Index for path not found error
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

; Print "Press any key to continue..." and wait for key press
MACRO WAITFORKEY
	lea dx, [MSG_CONTINUE]         ; Load address of message into DX
	mov ah, PRINT_STR_FUNCTION     ; Print string using DOS function
	int 21h

	mov ah, READ_CHAR_FUNCTION     ; Wait for keypress without printing it
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
	Parameters      db 128 dup(0)  ; 127 char + cr - command tail
	PauseOnExit     db 0           ; Boolean - pause after EXEC
ENDS RunProgStruc


; ---------------------------------------------------------------------------
; Data segment
; ---------------------------------------------------------------------------
DATASEG

DESKTOPEXE     db 'DESKTOP.EXE', 0     ; File name of desktop program
DESKTOPPARAMS  db 5, ' /RUN', CR_CHAR  ; Format: Length, space, string, CR
RUNFILE        db 'CONFIG\RUN.BIN', 0  ; File where desktop writes info about program to run to

CostaPath      db 68 dup(0)        ; 63 char + null - path to self
RunFileHandle  dw 0                ; File handle for RUN.BIN

RunningDesktop db 0                ; Bool - are we running desktop?
ExecErrorCode  db 0                ; DOS error code saved here if EXEC fails

SavedSS        dw 0                ; Stack Segment + pointer saved before EXEC
SavedSP        dw 0

ParamBlock     ExecPB <>           ; EXEC parameter block
RunProg        RunProgStruc <>     ; Data about program to run

FilenamePtr    dw 0                ; Pointer to filename for EXEC, either DESKTOPEXE or RunProg.Filename
ParametersPtr  dw 0                ; Pointer to parameters for EXEC, either DESKTOPPARAMS or RunProg.Parameters
PathPtr        dw 0                ; Pointer to path for CHDIR, either CostaPath or RunProg.Path

; Messages, both regular and error
MSG_CONTINUE        db 'Press any key to continue...$'
MSG_UNKNOWN_ERR     db 'Unknown error', CR_CHAR, LF_CHAR, '$'
MSG_DOS_VER_ERR     db 'DOS 4 or newer required', CR_CHAR, LF_CHAR, '$'

; Standard DOS error messages
MSG_INVALID_FUNC    db 'Invalid function', CR_CHAR, LF_CHAR, '$'
MSG_FILE_NOT_FOUND  db 'File not found', CR_CHAR, LF_CHAR, '$'
MSG_PATH_NOT_FOUND  db 'Path not found', CR_CHAR, LF_CHAR, '$'
MSG_TOO_MANY_OPEN   db 'Too many open files', CR_CHAR, LF_CHAR, '$'
MSG_ACCESS_DENIED   db 'Access denied', CR_CHAR, LF_CHAR, '$'
MSG_INVALID_HANDLE  db 'Invalid handle', CR_CHAR, LF_CHAR, '$'
MSG_MEM_CB_DESTR    db 'Memory control block destroyed', CR_CHAR, LF_CHAR, '$'
MSG_INSUFF_MEM      db 'Insufficient memory', CR_CHAR, LF_CHAR, '$'
MSG_INVALID_MEM_ADD db 'Invalid memory address', CR_CHAR, LF_CHAR, '$'
MSG_INVALID_ENV     db 'Invalid environment', CR_CHAR, LF_CHAR, '$'
MSG_INVALID_FORMAT  db 'Invalid format', CR_CHAR, LF_CHAR, '$'
MSG_INVALID_ACCESS  db 'Invalid access mode', CR_CHAR, LF_CHAR, '$'

; Offset table for error messages - 1-12 are standard DOS error codes, 0 and
; 13+ are custom errors
MsgTable dw MSG_UNKNOWN_ERR        ; 0
         dw MSG_INVALID_FUNC       ; 1
		 dw MSG_FILE_NOT_FOUND     ; 2
		 dw MSG_PATH_NOT_FOUND     ; 3
		 dw MSG_TOO_MANY_OPEN      ; 4
		 dw MSG_ACCESS_DENIED      ; 5
		 dw MSG_INVALID_HANDLE     ; 6
		 dw MSG_MEM_CB_DESTR       ; 7
		 dw MSG_INSUFF_MEM         ; 8
		 dw MSG_INVALID_MEM_ADD    ; 9
		 dw MSG_INVALID_ENV        ; 10
		 dw MSG_INVALID_FORMAT     ; 11
		 dw MSG_INVALID_ACCESS     ; 12
		 dw MSG_DOS_VER_ERR        ; 13

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
	mov [RunningDesktop], 0		   ; Clear running desktop flag
	
	lea dx, [CostaPath]            ; Change to Costa's drive+path before loading file
	call ChDir
	jnc OpenRunFile                ; Jump if successful

	mov ah, FATAL_ERROR_FLAG       ; If we can't change to Costa's path, fatal error
	call HandleError               ; Handle path change error

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

	; Move pointers to RunProg variables loaded from RUN.BIN
	mov ax, offset RunProg.Filename
	mov [FilenamePtr], ax
	mov ax, offset RunProg.Parameters
	mov [ParametersPtr], ax
	mov ax, offset RunProg.Path
	mov [PathPtr], ax

	jmp ChangePath                 ; All is good, move ahead

RunDesktop:
	; The desktop is to be run, so move all pointers to desktop variables
	mov ax, offset DESKTOPEXE      ; Get offset of desktop filename
	mov [FilenamePtr], ax          ; Set filename pointer to that offset
	mov ax, offset DESKTOPPARAMS   ; Same for parameters
	mov [ParametersPtr], ax
	mov ax, offset CostaPath       ; Desktop is in the same path as this program, so use own path
	mov [PathPtr], ax
	mov [RunProg.PauseOnExit], 0   ; Don't pause after desktop exit
	mov [RunningDesktop], 1        ; We are running the desktop now

ChangePath:
	mov dx, [PathPtr]              ; Load pointer to path into DX
	call ChDir                     ; Change directory to desired path
	jnc ShrinkMemory               ; Jump if successful

	mov ah, [RunningDesktop]       ; AL already contains error code from int 21
	call HandleError               ; Handle path change error
	jmp RunDesktop                 ; Try to run desktop

ShrinkMemory:
	; Shrink memory before running external program
	mov ah, GET_PSP_FUNCTION
	int 21h
	mov es, bx                     ; set ES = PSP segment
	
	; Calculate required memory size for COSTA.EXE to keep
	mov ax, offset EndOfData       ; Label EndOfData marks the end of the data segment
	add ax, STACK_SIZE             ; Include stack size
	add ax, PARAGRAPH_SIZE - 1     ; Make sure divison rounds up to next paragraph
	shr ax, 4                      ; AX = byte count, divide by 16 to get paragraph count
	add ax, 40h				       ; Add 16 paragraphs for PSP and 32 for overhead (768 bytes)
	mov bx, ax                     ; BX = new size in paragraphs
	mov ah, RESIZE_MEM_FUNCTION
	int 21h

	jnc CallExecFunction           ; No errors, continue to EXEC

	; Error during memory resize
	mov ah, FATAL_ERROR_FLAG       ; al already contains error code from int 21
	call HandleError               ; Handle memory release error, will terminate

CallExecFunction:
	; Note that we are NOT saving registers and SS/SP here - DOS 3+ handles this, and we
	; only target newer versions of DOS.

	; DEBUG - verify that file exists before EXEC, some versions of DOS will hang if not

	; Set up the EXEC parameter block
	mov ax, @data
	mov es, ax
	mov [ParamBlock.EnvSeg], 0     ; 0 = inherit parent environment
	mov ax, [ParametersPtr]        ; Load adress stored in ParametersPtr
	mov [ParamBlock.ParamOff], ax  ; Offset of command tail
	mov [ParamBlock.ParamSeg], ds  ; Segment of command tail, always DS in this case
	mov [ParamBlock.FCB1PtrSeg], 0 ; 0 = inherit FCBs
	mov [ParamBlock.FCB1PtrOff], 0
	mov [ParamBlock.FCB2PtrSeg], 0
	mov [ParamBlock.FCB2PtrOff], 0

	; Call EXEC to run the program
	mov dx, [FilenamePtr]          ; Load adress stored in FilenamePtr
	lea bx, [ParamBlock]           ; ES:BX = pointer to EXEC parameter block
	mov ah, EXEC_FUNCTION          ; EXEC function
	mov al, EXEC_LOAD_RUN          ; Load and run
	int 21h
	mov [ExecErrorCode], al        ; Save error code from EXEC, if any

	; Check for errors from EXEC - CF not affected by DS/ES or stack restore
	jnc ExecSucceeded              ; Jump if no error
	jmp ExecFailed

ExecSucceeded:
	; EXEC succeeded, now check if we need to pause on exit
	cmp [RunProg.PauseOnExit], 0
	je NoPause                     ; If no pause on exit requested, skip ahead
	WAITFORKEY

NoPause:
	cmp [RunningDesktop], 1        ; Were we running the desktop?
	je EvaluateExitCode            ; If so, check exit code to see if we should exit
	jmp LoadRunData                ; Otherwise, jump to top and load RUN.BIN again

EvaluateExitCode:
	; Desktop was exited, check exit code to see if we should exit Costa or not
	mov ah, GET_EXIT_CODE_FUNCTION
	int 21h
	cmp al, DESKTOP_EXIT_CODE      ; Did desktop signal to exit Costa?
	je ProgramEnd                  ; If so, exit program
	jmp LoadRunData                ; Otherwise, reload RUN.BIN and continue

ExecFailed:
	; Error occurred during EXEC, evaluate
	mov al, [ExecErrorCode]
	mov ah, [RunningDesktop]       ; If running desktop, any error is fatal
	call HandleError               ; AH will already contain error code from int 21
	jmp RunDesktop                 ; If we returned from HandleError, run desktop

ProgramEnd:
	mov ah, TERMINATE_FUNCTION
	mov al, 0                      ; Exitcode = 0
	int 21h                        ; Bye


; ---------------------------------------------------------------------------
; Procedures
; ---------------------------------------------------------------------------

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
; Destroys: CF
;
PROC HandleError NEAR
	push bx                        ; Preserve registers
	push cx
	push dx

	mov cl, ah                     ; Save fatal flag in CL

	mov bl, al                     ; Copy error code to BL
	xor bh, bh                     ; Clear upper byte
	shl bx, 1                      ; Multiply error code by 2, size of word, for offset lookup in MsgTable
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


; ChDir - Change drive and directory
;
; Inputs:  DX = pointer to null-terminated path string
;
; Outputs: AL = DOS error code if CF flag set, otherwise undefined
;
; Destroys: CF, AX, SI
;
PROC ChDir NEAR

	mov si, dx                     ; Load path pointer
	mov al, [si]                   ; Check if first character is non-null
	or al, al
	jz Done                        ; If null, nothing to do

SetDrive:
	push dx                        ; Preserve DX

	; Check if path specifies a drive
	inc si                         ; Move to second character
	mov ah, [si]                   ; Store for comparison
	cmp ah, ':'                    ; Is it a colon?
	jne SetDir                     ; PathPtr doesn't specify drive, skip drive change
	
	and al, 0DFh                   ; force uppercase drive letter just in case
	sub al, 'A'                    ; Substracting 'A' gives 0 for A, 1 for B, etc.
	
	mov ah, SET_DRIVE_FUNCTION     ; DOS set current drive function
	mov dl, al                     ; DL = drive number
	int 21h                        ; No error checking, chdir will fail if drive invalid

SetDir:
	mov ah, CHDIR_FUNCTION         ; Change directory function
	pop dx                         ; Restore DX
	int 21h

Done:
	ret
ENDP ChDir

END start                          ; Mark the program's entry point