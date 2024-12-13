INCLUDE Irvine32.inc

playerSize = 1
gravity = 1
jumpForce = -5

.data
player BYTE 'P'

outputHandle DWORD 0
bytesWritten DWORD 0
count DWORD 0
playerXY COORD <10,5>
velocityY SWORD 0

groundLevel WORD 25
onGround BYTE 1


cellsWritten DWORD ?
playerAttributes WORD playerSize DUP(0bh)

updateInterval WORD 50 ; 100ms each update

startTime DWORD ?
elapsedTime DWORD ?
timeLimit DWORD 600 ; 600 seconds
TimerXY COORD <1,1>

buffer BYTE 2048 DUP(?)
startscrfile BYTE 'start.txt',0
startfilehandle HANDLE ?
startbytesRead DWORD ?
startscrBytesWritten DWORD ?
startKeyPos Byte 0
startconfirm Byte 0


.code
	SetConsoleOutputCP PROTO STDCALL :DWORD
	GetAsyncKeyState PROTO STDCALL :DWORD
main PROC
	;INVOKE SetConsoleOutputCP, 437

	; Get the console ouput handle
	INVOKE GetStdHandle, STD_OUTPUT_HANDLE
	mov outputHandle, eax	; save console handle

startLoop:
	call Clrscr
	call displayStartscr
	call readInput_startscr
	cmp startconfirm, 1
	je conti
	jmp startLoop

conti:
	INVOKE GetTickCount
	mov startTime, eax
	
GameLoop:
	call Clrscr
	call updatePhysics
	call drawPlayer
	call displayTime
	call readInput
	invoke Sleep, updateInterval
	jmp GameLoop

	exit
main ENDP

updatePhysics PROC uses eax ebx
    ; 1. ��s���a�� Y �y��
    mov ax, velocityY
    add playerXY.Y, ax        ; �ھګ����t�ק�s��m

    ; 2. ���έ��O�]�[�t�����t�ס^
    add velocityY, gravity    ; ���O�v�T�G�t�׶V�ӶV��

    ; 3. �ˬd�O�_�C��a��
    mov ax, playerXY.Y
    cmp ax, groundLevel
    jle EndPhysics            ; �p�G���W�L�a���A���L�a���B�z

    ; �p�G�W�X�a���A���m��a��
    mov ax, groundLevel
    mov playerXY.Y, ax        ; �N���a���m��a��
    mov velocityY, 0          ; ������B��
    mov onGround, 1           ; �аO���a�b�a���W
    jmp EndPhysics

EndPhysics:
    ret
updatePhysics ENDP

readInput PROC
    ; �ˬdW��]�V�W���ʡ^
    INVOKE GetAsyncKeyState, 'W'
    test ax, 8000h
    jz CheckA
	cmp onGround, 1
	jne CheckA
	mov ax, 5
	sub velocityY, ax
	mov onGround, 0

CheckA:
    ; �ˬdA��]�V�����ʡ^
    INVOKE GetAsyncKeyState, 'A'
    test ax, 8000h
    jz CheckD
    dec playerXY.X           ; ���aX�y�д�֡A�V������

CheckD:
    ; �ˬdD��]�V�k���ʡ^
    INVOKE GetAsyncKeyState, 'D'
    test ax, 8000h
    jz CheckESC
    inc playerXY.X           ; ���aX�y�мW�[�A�V�k����

CheckESC:
    ; �ˬdESC��]�h�X�C���^
    INVOKE GetAsyncKeyState, VK_ESCAPE
    test ax, 8000h
    jz EndInput
    INVOKE ExitProcess, 0    ; �p�G���UESC�A�h�X�C��

EndInput:
	ret
readInput ENDP

drawPlayer PROC
	INVOKE WriteConsoleOutputAttribute,
	outputHandle, 
	OFFSET playerAttributes,
	playerSize, 
	playerXY,
	OFFSET count

	INVOKE WriteConsoleOutputCharacter,
	outputHandle,
	OFFSET player,
	playerSize,
	playerXY,
	OFFSET count
	ret
drawPlayer ENDP

displayTime PROC uses eax ebx ecx edx
	INVOKE GetTickCount
	sub eax, startTime
	cdq
	mov ebx, 1000
	div ebx
	mov elapsedTime, eax
	mov eax, timeLimit
	sub eax, elapsedTime

	mov dl, 1
	mov dh, 1
	call gotoxy
	call WriteDec
	ret
displayTime ENDP

displayStartscr PROC uses eax ebx ecx edx
    ;���}��r�ɮ�
	INVOKE CreateFile, ADDR startscrfile, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL 
	mov startfilehandle, eax

ReadLoop:
	;�ϥ�UTF-8�s�X�A��ܲŸ�
	INVOKE SetConsoleOutputCP, 65001

	;Ū���ɮ�
	INVOKE ReadFile, startfilehandle, ADDR buffer, SIZEOF buffer, ADDR startbytesRead, NULL

	;�e����s�ο�X�ɮ�
	call Clrscr
	INVOKE SetFilePointer, startfilehandle, 0, NULL, FILE_BEGIN
	INVOKE WriteConsole, outputhandle, ADDR buffer, startbytesRead, ADDR startscrBytesWritten, NULL
	INVOKE Sleep, updateInterval

EndDisplay:
	;�����ɮ�
    INVOKE CloseHandle, startfilehandle
    ret
displayStartscr ENDP

readInput_startscr PROC uses eax ebx ecx edx
	INVOKE GetAsyncKeyState, VK_RETURN
	test eax, 8000h                     
    jz checkW
	cmp startKeyPos, 0 ;�P�_�����m
	je confirm
	INVOKE ExitProcess, 0

confirm:
	mov startconfirm, 1
	ret

checkW:
	INVOKE GetAsyncKeyState, 'W'
	test eax, 8000h                     
    jz checkS
	mov startKeyPos, 0
	ret

checkS:
	INVOKE GetAsyncKeyState, 'S'
	test eax, 8000h                     
    jz no_key_pressed
	mov startKeyPos, 1
	ret

no_key_pressed:
	ret
readInput_startscr ENDP


END main