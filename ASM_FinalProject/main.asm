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

escConfirm byte 0

cellsWritten DWORD ?
playerAttributes WORD playerSize DUP(0bh)

updateInterval WORD 50 ; 100ms each update

startTime DWORD ?
elapsedTime DWORD ?
timeLimit DWORD 600 ; 600 seconds
TimerXY COORD <0,0>

gamescrfile BYTE 'gamefield.txt',0
gamefilehandle HANDLE ?
gamebytesRead DWORD ?
gamescrBytesWritten DWORD ?

buffer BYTE 3500 DUP(?)
initialscrfile BYTE 'start.txt',0
initialfilehandle HANDLE ?
initialbytesRead DWORD ?
initialscrBytesWritten DWORD ?
initialKeyPos Byte 0
initialconfirm Byte 0

initialStartLeftPos COORD <49,17>
initialStartLeftSymbol DWORD '>',0
initialStartRightPos COORD <73,17>
initialStartRightSymbol DWORD '<',0

initialExitLeftPos COORD <49,23>
initialExitLeftSymbol DWORD '>',0
initialExitRightPos COORD <73,23>
initialExitRightSymbol DWORD '<',0

endscrfile BYTE 'finish.txt',0
endfilehandle HANDLE ?
endbytesRead DWORD ?
endscrBytesWritten DWORD ?
endKeyPos Byte 0
endconfirm Byte 0

endStartLeftPos COORD <30,20>
endStartLeftSymbol DWORD '>',0
endStartRightPos COORD <55,20>
endStartRightSymbol DWORD '<',0

endExitLeftPos COORD <68,20>
endExitLeftSymbol DWORD '>',0
endExitRightPos COORD <93,20>
endExitRightSymbol DWORD '<',0


.code
	SetConsoleOutputCP PROTO STDCALL :DWORD
	GetAsyncKeyState PROTO STDCALL :DWORD
main PROC
	;INVOKE SetConsoleOutputCP, 437

	; Get the console ouput handle
	INVOKE GetStdHandle, STD_OUTPUT_HANDLE
	mov outputHandle, eax	; save console handle

initialLoop:
	call Clrscr
	call displayInitialscr
	call readInputInitialscr
	cmp Initialconfirm, 1
	je conti
	jmp initialLoop

conti:
	INVOKE GetTickCount
	mov startTime, eax
	mov escConfirm, 0
	
GameLoop:
	call Clrscr
	call updatePhysics
	call displayGamescr
	call drawPlayer
	call displayTime
	call readInput
	cmp  escConfirm, 1
	je endLoop
	invoke Sleep, updateInterval
	jmp GameLoop

endLoop:
	call Clrscr
	call displayEndscr
	call readInputEndscr
	cmp endconfirm, 1
	je conti
	jmp endLoop

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
    mov escConfirm,1

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

displayGamescr PROC uses eax ebx ecx edx
    ;���}��r�ɮ�
	INVOKE CreateFile, ADDR gamescrfile, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL 
	mov gamefilehandle, eax

ReadLoop:
	;�ϥ�UTF-8�s�X�A��ܲŸ�
	INVOKE SetConsoleOutputCP, 65001

	;Ū���ɮ�
	INVOKE ReadFile, gamefilehandle, ADDR buffer, SIZEOF buffer, ADDR gamebytesRead, NULL

	;�e����s�ο�X�ɮ�
	call Clrscr
	INVOKE SetFilePointer, gamefilehandle, 0, NULL, FILE_BEGIN
	INVOKE WriteConsole, outputhandle, ADDR buffer, gamebytesRead, ADDR gamescrBytesWritten, NULL

EndDisplay:
	;�����ɮ�
    INVOKE CloseHandle, gamefilehandle
    ret
displayGamescr ENDP

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

displayInitialscr PROC uses eax ebx ecx edx
    ;���}��r�ɮ�
	INVOKE CreateFile, ADDR initialscrfile, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL 
	mov initialfilehandle, eax

ReadLoop:
	;�ϥ�UTF-8�s�X�A��ܲŸ�
	INVOKE SetConsoleOutputCP, 65001

	;Ū���ɮ�
	INVOKE ReadFile, initialfilehandle, ADDR buffer, SIZEOF buffer, ADDR initialbytesRead, NULL

	;�e����s�ο�X�ɮ�
	call Clrscr
	INVOKE SetFilePointer, initialfilehandle, 0, NULL, FILE_BEGIN
	INVOKE WriteConsole, outputhandle, ADDR buffer, initialbytesRead, ADDR initialscrBytesWritten, NULL
	cmp initialKeyPos, 1
	je Pos2 

Pos1:
	INVOKE WriteConsoleOutputCharacter,
	outputHandle, 
	OFFSET initialStartLeftSymbol,
	1, 
	initialStartLeftPos,
	OFFSET count

	INVOKE WriteConsoleOutputCharacter,
	outputHandle, 
	OFFSET initialStartRightSymbol,
	1, 
	initialStartRightPos,
	OFFSET count
	jmp conti

Pos2:
	INVOKE WriteConsoleOutputCharacter,
	outputHandle, 
	OFFSET initialExitLeftSymbol,
	1, 
	initialExitLeftPos,
	OFFSET count

	INVOKE WriteConsoleOutputCharacter,
	outputHandle, 
	OFFSET initialExitRightSymbol,
	1, 
	initialExitRightPos,
	OFFSET count

conti:
	INVOKE Sleep, updateInterval

EndDisplay:
	;�����ɮ�
    INVOKE CloseHandle, initialfilehandle
    ret
displayInitialscr ENDP

readInputInitialscr PROC uses eax ebx ecx edx
	INVOKE GetAsyncKeyState, VK_RETURN
	test eax, 8000h                     
    jz checkW
	cmp initialKeyPos, 0 ;�P�_�����m
	je confirm
	INVOKE ExitProcess, 0

confirm:
	mov initialconfirm, 1
	ret

checkW:
	INVOKE GetAsyncKeyState, 'W'
	test eax, 8000h                     
    jz checkS
	mov initialKeyPos, 0
	ret

checkS:
	INVOKE GetAsyncKeyState, 'S'
	test eax, 8000h                     
    jz no_key_pressed
	mov initialKeyPos, 1
	ret

no_key_pressed:
	ret
readInputInitialscr ENDP

displayEndscr PROC uses eax ebx ecx edx
    ;���}��r�ɮ�
	INVOKE CreateFile, ADDR endscrfile, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL 
	mov endfilehandle, eax

ReadLoop:
	;�ϥ�UTF-8�s�X�A��ܲŸ�
	INVOKE SetConsoleOutputCP, 65001

	;Ū���ɮ�
	INVOKE ReadFile, endfilehandle, ADDR buffer, SIZEOF buffer, ADDR endbytesRead, NULL

	;�e����s�ο�X�ɮ�
	call Clrscr
	INVOKE SetFilePointer, endfilehandle, 0, NULL, FILE_BEGIN
	INVOKE WriteConsole, outputhandle, ADDR buffer, endbytesRead, ADDR endscrBytesWritten, NULL
	cmp endKeyPos, 1
	je Pos2 

Pos1:
	INVOKE WriteConsoleOutputCharacter,
	outputHandle, 
	OFFSET endStartLeftSymbol,
	1, 
	endStartLeftPos,
	OFFSET count

	INVOKE WriteConsoleOutputCharacter,
	outputHandle, 
	OFFSET endStartRightSymbol,
	1, 
	endStartRightPos,
	OFFSET count
	jmp conti

Pos2:
	INVOKE WriteConsoleOutputCharacter,
	outputHandle, 
	OFFSET endExitLeftSymbol,
	1, 
	endExitLeftPos,
	OFFSET count

	INVOKE WriteConsoleOutputCharacter,
	outputHandle, 
	OFFSET endExitRightSymbol,
	1, 
	endExitRightPos,
	OFFSET count

conti:
	INVOKE Sleep, updateInterval

EndDisplay:
	;�����ɮ�
    INVOKE CloseHandle, endfilehandle
    ret
displayEndscr ENDP

readInputEndscr PROC uses eax ebx ecx edx
	INVOKE GetAsyncKeyState, VK_RETURN
	test eax, 8000h                     
    jz checkA
	cmp endKeyPos, 0 ;�P�_�����m
	je confirm
	INVOKE ExitProcess, 0

confirm:
	mov endconfirm, 1
	ret

checkA:
	INVOKE GetAsyncKeyState, 'A'
	test eax, 8000h                     
    jz checkD
	mov endKeyPos, 0
	ret

checkD:
	INVOKE GetAsyncKeyState, 'D'
	test eax, 8000h                     
    jz no_key_pressed
	mov endKeyPos, 1
	ret

no_key_pressed:
	ret
readInputEndscr ENDP

END main