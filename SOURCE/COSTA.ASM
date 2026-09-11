; COSTA.ASM - Costa launcher
;
; This is the part of Costa that launches DESKTOP.EXE with appropriate
; parameters, and stays in memory at all times. Whenever the desktop wants to
; run a program, it writes information about this to disk and exits. This
; launcher then picks up that information and runs the requested program, and
; when that program exits, the desktop is reloaded.
;
; Written in assembly language for x86 real mode DOS environment. Not in
; Pascal like the rest of Costa, to keep size as smalll as possible since
; this part stays in memory at all times, including when running other
; programs.
;
; Tested using TASM version 4.1 and TLINK 7.1

; ---------------------------------------------------------------------------
; Constants
; ---------------------------------------------------------------------------

STACK_SIZE             EQU 40h     ; 128 byte stack size
PARAGRAPH_SIZE         EQU 16      ; Size of a memory paragraph in bytes
MSDOS_REQUIRED_VERSION EQU 4       ; Minimum required MS-DOS major version
DRDOS_REQUIRED_VERSION EQU 5       ; Minimum DR-DOS major version
DESKTOP_EXIT_CODE      EQU 1       ; Exit code from desktop that signals exit

EXEC_FUNCTION          EQU 4Bh     ; DOS EXEC function number
EXEC_LOAD_RUN          EQU 00h     ; EXEC load and run subfunction
TERMINATE_FUNCTION     EQU 4Ch     ; DOS terminate program function number
READ_CHAR_FUNCTION     EQU 07h     ; DOS read char w/o echo function number
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

ERR_DOS_VERSION        EQU 13      ; Index for unsupported DOS version error
LASTERROR              EQU 13      ; Highest error number that has a message
NONFATAL_ERROR_FLAG    EQU 0       ; Flag non-fatal error for HandleError
FATAL_ERROR_FLAG       EQU 1       ; Flag fatal error for HandleError

BACKSLASH_CHAR         EQU 5Ch     ; ASCII code for backslash
CR_CHAR                EQU 0Dh     ; ASCII code for carriage return
LF_CHAR                EQU 0Ah     ; ASCII code for line feed


; ---------------------------------------------------------------------------
; Assembler instructions
; ---------------------------------------------------------------------------
IDEAL
NAME COSTA
MODEL TINY


; ---------------------------------------------------------------------------
; Structure definitions
; ---------------------------------------------------------------------------

STRUC ExecPB                       ; MS-DOS INT 21H EXEC parameter block
	EnvSeg      dw 0               ; Environment segment - 0 = inherit
	ParamOff    dw 0               ; Pointer to parameters (command tail)
	ParamSeg    dw 0
	FCB1PtrOff  dw 0               ; Pointer to FCB1 - 0 = none
	FCB1PtrSeg  dw 0
	FCB2PtrOff  dw 0               ; Pointer to FCB2 - 0 = none
	FCB2PtrSeg  dw 0
ENDS ExecPB

STRUC RunProgStruc
	Filename    db 80  dup(0)      ; 79 char + null - filename, maybe path
	Path        db 64  dup(0)      ; 63 char + null - working directory
	Parameters  db 128 dup(0)      ; length + sp + 125 ch + cr = command tail
	PauseOnExit db 0               ; Pause after EXEC - 1 for yes, 0 for no
ENDS RunProgStruc


; ---------------------------------------------------------------------------
; Macros
; ---------------------------------------------------------------------------

; Print "Press any key to continue..." and wait for key press
MACRO WAITFORKEY
	mov dx, offset MSG_CONTINUE    ; Load address of message into DX
	mov ah, PRINT_STR_FUNCTION     ; Print string using DOS function
	int 21h

	mov ah, READ_CHAR_FUNCTION     ; Wait for keypress without printing it
	int 21h
ENDM WAITFORKEY


; ---------------------------------------------------------------------------
; Code segment start - the only segment since we're making a COM program
; ---------------------------------------------------------------------------
CODESEG
ORG 100h

start:
    ; Initialization code is at end of program so that it can be overwritten
    ; once it is no longer needed
	jmp Init

ShrinkMemory:
	; Calculate required memory size for COSTA.COM to keep
	lea ax, EndOfResident          ; Label marks the end of the resident code
	add ax, PARAGRAPH_SIZE - 1     ; Make sure divison rounds up to paragraph
	shr ax, 4                      ; Bytes in AX div 16 AX = paragraph count
	mov bx, ax                     ; BX = new size in paragraphs
	mov ah, RESIZE_MEM_FUNCTION
	int 21h

	jnc MainLoop                   ; No errors, continue ahead

	; Error during memory resize
	mov ah, FATAL_ERROR_FLAG       ; al already contains error code from DOS
	call HandleError               ; Throw fatal error

; ---------------------------------------------------------------------------
; Main loop
; ---------------------------------------------------------------------------
MainLoop:
	mov [RunningDesktop], 0		   ; Clear running desktop flag


	mov [PathPtr], offset CostaPath ; Change to Costa path
	call ChDir
	jnc OpenRunFile                ; Jump if successful

	mov ah, FATAL_ERROR_FLAG       ; Error changing to Costa path is fatal
	call HandleError

OpenRunFile:
	mov ah, OPEN_FILE_FUNCTION     ; Load data about program to run from disk
	mov al, OPEN_READ_ONLY
	mov dx, offset RUNFILE         ; DS:DX = filename to open
	int 21h
	jnc ReadRunFile                ; Jump if open successful

	jmp RunDesktop                 ; On error (inc. not found) run desktop

ReadRunFile:
	mov [RunFileHandle], ax        ; Store file handle
	mov ah, READ_FILE_FUNCTION
	mov bx, [RunFileHandle]        ; BX = file handle
	mov cx, SIZE RunProgStruc      ; Number of bytes to read
	mov dx, offset RunProg.Filename ; Buffer to read into = start of struct
	int 21h
	jnc CloseRunFile               ; Jump if read successful

	mov ah, NONFATAL_ERROR_FLAG    ; Failed, error code already in AL
	call HandleError               ; Handle read error

	mov ah, CLOSE_FILE_FUNCTION    ; Make sure file is closed
	mov bx, [RunFileHandle]
	int 21h

	jmp RunDesktop                 ; Since run failed, run desktop instead

CloseRunFile:
	mov ah, CLOSE_FILE_FUNCTION    ; Close the file
	mov bx, [RunFileHandle]
	int 21h

	mov ah, DELETE_FILE_FUNCTION   ; Delete file so we won't read it again
	mov dx, offset RUNFILE
	int 21h

	; Move pointers to RunProg variables loaded from RUN.BIN
	mov [FilenamePtr], offset RunProg.Filename
	mov [ParametersPtr], offset RunProg.Parameters
	mov [PathPtr], offset RunProg.Path

	jmp ChangeRunPath              ; Ready to go, move ahead

RunDesktop:
	; Point pointers to desktop variables
	mov [FilenamePtr], offset DESKTOPEXE
	mov [ParametersPtr], offset DESKTOPPARAMS
	mov [PathPtr], offset CostaPath           ; CostaPath also = desktop path
	mov [RunProg.PauseOnExit], 0              ; Don't pause after desktop
	mov [RunningDesktop], 1                   ; Yes, running desktop

ChangeRunPath:
	call ChDir                     ; Change directory to PathPointer
	jnc CallExecFunction           ; Jump if successful

	mov ah, [RunningDesktop]       ; AL already contains error code from DOS
	call HandleError               ; If RunningDesktop error is fatal
	jmp RunDesktop                 ; Not RunningDesktop, so try that instead

CallExecFunction:
	; Note that we are NOT saving registers and SS/SP here - DOS 3+ handles
	; this, and we only target newer versions of DOS.

	; DESKTOP.EXE is reponsible for making sure the program to execute exists

	; Set up the EXEC parameter block
	mov [ParamBlock.EnvSeg], 0     ; 0 = inherit parent environment
	mov ax, [ParametersPtr]        ; Load adress stored in ParametersPtr
	mov [ParamBlock.ParamOff], ax  ; Offset of command tail
	mov [ParamBlock.ParamSeg], ds  ; Segment of command tail

	; Call EXEC to run the program
	mov dx, [FilenamePtr]          ; Load adress stored in FilenamePtr
	lea bx, [ParamBlock]           ; ES:BX = pointer to EXEC parameter block
	mov ah, EXEC_FUNCTION          ; DOS EXEC function
	mov al, EXEC_LOAD_RUN          ; Subfunction load and run
	int 21h
	jnc ExecSucceeded              ; Jump if no error

	; Error occurred during EXEC, evaluate
	mov ah, [RunningDesktop]       ; If running desktop, any error is fatal
	call HandleError               ; AH already contains error code from DOS
	jmp RunDesktop                 ; If non-fatal, run desktop

ExecSucceeded:
	cmp [RunProg.PauseOnExit], 0
	je NoPause                     ; If no pause on exit then skip ahead
	WAITFORKEY

NoPause:
	cmp [RunningDesktop], 1        ; Were we running the desktop?
	je EvaluateDesktopExit         ; If so, check desktop exit code
	jmp MainLoop                   ; Otherwise, jump to top of main loop

EvaluateDesktopExit:
	mov ah, GET_EXIT_CODE_FUNCTION ; Get desktop exit code from DOS
	int 21h
	cmp al, DESKTOP_EXIT_CODE      ; Did desktop signal to exit Costa?
	je ProgramEnd                  ; If so, exit launcher
	jmp MainLoop                   ; Otherwise, run main loop again

ProgramEnd:
	mov ah, TERMINATE_FUNCTION     ; DOS terminate program function
	xor al, 0                      ; Exitcode = 0
	int 21h                        ; Bye


; ---------------------------------------------------------------------------
; Procedures
; ---------------------------------------------------------------------------

; HandleError - Display error message based on error code, terminate program
;               if error is fatal
;
; Inputs:   AL = error code number
;           AH = fatal error flag (non-zero = fatal)
; Outputs:  None
; Destroys: CF
PROC HandleError NEAR
	mov cl, ah                     ; Save fatal flag in CL

	; Check if error number is out of bounds of message table
	cmp al, LASTERROR
	jle HandleErrorMsg
	xor al, al                     ; Out of bounds, 0 = "unknown error" msg

HandleErrorMsg:
	; Get error message offset in message table
	mov bl, al                     ; Copy error code to BL
	xor bh, bh                     ; Clear upper byte
	shl bx, 1                      ; Multiply error code by 2, size of word

	mov ah, PRINT_STR_FUNCTION
	mov dx, [MsgTable + bx]        ; Get address of error msg based on offset
	int 21h                        ; Print error message

	mov ah, PRINT_STR_FUNCTION
	mov dx, offset MSG_CRLF        ; Print line feed after error message
	int 21h

	cmp cl, FATAL_ERROR_FLAG       ; If fatal error, jump to program end and
	je ProgramEnd                  ; terminate the launcher

	WAITFORKEY
	ret
ENDP HandleError


; ChDir - Change drive and directory
;
; Inputs:   DX = pointer to null-terminated path string
; Outputs:  AL = DOS error code if CF flag set, otherwise undefined
; Destroys: CF, AX, SI
PROC ChDir NEAR
	mov dx, [PathPtr]              ; Load pointer to path into DX
	mov si, dx                     ; Load path pointer
	mov al, [si]                   ; Check if first character is non-null
	or al, al
	jz ChDirDone                   ; If null, nothing to do

SetDrive:
	; Check if path specifies a drive
	inc si                         ; Move to second character
	mov ah, [si]                   ; Store char in ah for comparison
	cmp ah, ':'                    ; Is it a colon?
	jne SetDir                     ; No drive in PathPtr, skip drive change

	and al, 0DFh                   ; Force uppercase drive letter
	sub al, 'A'                    ; AL minus 'A' gives 0 for A, 1 for B etc.

	mov ah, SET_DRIVE_FUNCTION     ; DOS set current drive function
	mov dl, al                     ; DL = drive number
	int 21h                        ; No error checking, chdir will fail if
	                               ; drive invalid and leave CF = 1

	mov dx, [PathPtr]              ; Reload pointer to path into DX

SetDir:
	mov ah, CHDIR_FUNCTION         ; Change directory function
	int 21h

ChDirDone:
	ret
ENDP ChDir

; ---------------------------------------------------------------------------
; Variables
; ---------------------------------------------------------------------------
	DESKTOPEXE          db 'DESKTOP.EXE', 0     ; File name of desktop
	DESKTOPPARAMS       db 5, ' /RUN', CR_CHAR  ; Length, space, string, CR
	RUNFILE             db 'CONFIG\RUN.BIN', 0  ; File where desktop writes
	                                            ;info about program to run to

	CostaPath           db 64 dup(0)        ; Path to self, 63 char + null
	RunFileHandle       dw 0                ; File handle for RUN.BIN

	RunningDesktop      db 0                ; Bool - are we running desktop?

	ParamBlock          ExecPB <>           ; EXEC parameter block
	RunProg             RunProgStruc <>     ; Data about program to run

	FilenamePtr         dw 0                ; Pointer to filename for EXEC
	ParametersPtr       dw 0                ; Pointer to parameters for EXEC
	PathPtr             dw 0                ; Pointer to path for ChDir

	; Messages
	MSG_CONTINUE        db 'Press any key to continue...', '$'
	MSG_CRLF            db CR_CHAR, LF_CHAR, '$'

	; Error messages
	MSG_UNKNOWN_ERR     db 'Unknown error', '$'
	MSG_INVALID_FUNC    db 'Invalid function', '$'
	MSG_FILE_NOT_FOUND  db 'File not found', '$'
	MSG_PATH_NOT_FOUND  db 'Path not found', '$'
	MSG_TOO_MANY_OPEN   db 'Too many open files', '$'
	MSG_ACCESS_DENIED   db 'Access denied', '$'
	MSG_INVALID_HANDLE  db 'Invalid handle', '$'
	MSG_MEM_CB_DESTR    db 'Memory control block destroyed', '$'
	MSG_INSUFF_MEM      db 'Insufficient memory', '$'
	MSG_INVALID_MEM_ADD db 'Invalid memory address', '$'
	MSG_INVALID_ENV     db 'Invalid environment', '$'
	MSG_INVALID_FORMAT  db 'Invalid format', '$'
	MSG_INVALID_ACCESS  db 'Invalid access mode', '$'
	MSG_DOS_VER_ERR     db 'DOS 4 or newer required', '$'

	; Offset table for error messages - 1-12 are standard DOS error codes, 0
	; and 13+ are custom errors
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

	CustomStack         db  STACK_SIZE dup(?)         ; Custom stack and
	CustomStackTop      equ CustomStack + STACK_SIZE  ; pointer to top it

	LABEL EndOfResident BYTE                       ; End-of-program marker
	                                               ; for memory resize


; ---------------------------------------------------------------------------
; Code after this point will be destroyed at runtime when memory is shrinked
; ---------------------------------------------------------------------------

Init:
	; Use custom stack - point SS/SP to the variable inside code segment. DOS
	; normally creates a stack at the end of the segment, but we want to be
	; able to free as much continous memory as possible so we make our own.
	mov ax, cs                     ; Store code segment in ax
	mov ss, ax                     ; Set stack segment pointer to ax
	mov ax, offset CustomStackTop  ; Store location of top of custom stack
	mov sp, ax                     ; Set stack pointer to adress stored in ax

	; Check required DOS version (4.0 or higher)
	mov ah, GET_DOS_VER_FUNCTION
	int 21h
	cmp al, MSDOS_REQUIRED_VERSION ; major version must be >= required
	jnc GetPathToSelf              ; Jump if version is sufficient

	; If DOS version is less than 4, check if we are running on DR-DOS since
	; most versions of DR-DOS lie and report DOS 3.31 for compatibility
	mov ax, 4452h
	int 21h
	jc DosVersionNotOk             ; Not running DR-DOS
	cmp al, DRDOS_REQUIRED_VERSION ; If DR-DOS, al = major version
	jnc GetPathToSelf

DosVersionNotOk:
	mov al, ERR_DOS_VERSION        ; DOS version unsupported, fatal error
	mov ah, FATAL_ERROR_FLAG
	call HandleError

GetPathToSelf:
	push es

	; Path is stored in environment block, which is pointed to by PSP
	mov ah, GET_PSP_FUNCTION       ; DOS: Get PSP segment
	int 21h
	mov es, bx                     ; ES = PSP

	; Get environment segment pointer from PSP:2Ch
	mov bx, [es:2Ch]               ; ES:2C = WORD pointer to env segment
	mov es, bx                     ; ES = environment segment
	xor si, si                     ; SI = offset in env segment, start at 0

GetPathFindEnvEnd:
	; Scan for double null terminator (end of environment block)
	mov al, [es:si]
	inc si
	or al, al
	jne GetPathFindEnvEnd          ; byte not null, keep scanning
	mov al, [es:si]                ; byte null, check next byte
	inc si
	or al, al
	jne GetPathFindEnvEnd          ; second byte not null, keep scanning

	add si, 2                      ; Skip word gap between env and exe path

	; Copy executable path + name into CostaPath, track last backslash
	lea di, [CostaPath]            ; DI = destination in DS
	xor bx, bx                     ; BX = offset off last \ in CostaPath

GetPathCopyLoop:
	mov al, [es:si]                ; read byte from environment
	inc si
	mov [di], al                   ; store byte into CostaPath
	cmp al, BACKSLASH_CHAR         ; is byte a backslash?
	jne GetPathNotSlash            ; if not skip ahead
	mov bx, di                     ; move offset into bx to track last \

GetPathNotSlash:
	inc di
	cmp al, 0                      ; null terminator?
	jne GetPathCopyLoop            ; if not, keep copying

    ; Remove filename: replace last backslash with null
	test bx, bx
	jz GetPathDone                 ; if no backslash found, skip ahead

	; Check if last slash is at position 2 - indicating that we are at then
	; root of a drive
	lea di, [CostaPath]            ; Load address of CostaPath to di
	add di, 2                      ; Add two the get address of third char
	cmp bx, di                     ; If di matches bx, we are at root
	jne GetPathAddNull             ; If not root, add null over last \

	add bx, 1                      ; If root, move one additional char

GetPathAddNull:
	xor al, al                     ; AL = 0
	mov [bx], al                   ; Add null terminator to path string

GetPathDone:
	pop es                         ; Restore data segment
	jmp ShrinkMemory

END start