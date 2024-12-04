INCLUDE Irvine32.inc

playerSize = 1

.data
player BYTE 'a'

outputHandle DWORD 0
bytesWritten DWORD 0
count DWORD 0
playerXY COORD <10,5>

cellsWritten DWORD ?
playerAttributes WORD playerSize DUP(0bh)

updateInterval DWORD 100 ; 100ms each update

startTime DWORD ?
elapsedTime DWORD ?
timeLimit DWORD 600 ; 600 seconds
TimerXY COORD <1,1>

.code
	SetConsoleOutputCP PROTO STDCALL :DWORD
	GetAsyncKeyState PROTO STDCALL :DWORD
main PROC
	;INVOKE SetConsoleOutputCP, 437

	; Get the console ouput handle
	INVOKE GetStdHandle, STD_OUTPUT_HANDLE
	mov outputHandle, eax	; save console handle
	call Clrscr

	INVOKE GetTickCount
	mov startTime, eax
	
GameLoop:
	call Clrscr
	call drawPlayer
	call displayTime
	call readInput
	invoke Sleep, updateInterval
	jmp GameLoop

	

	exit
main ENDP

test PROC
	mov eax, 0
	ret
test ENDP

readInput PROC
    ; �ˬdW��]�V�W���ʡ^
    INVOKE GetAsyncKeyState, 'W'
    test ax, 8000h
    jz CheckS
    dec playerXY.Y           ; ���aY�y�д�֡A�V�W����

CheckS:
    ; �ˬdS��]�V�U���ʡ^
    INVOKE GetAsyncKeyState, 'S'
    test ax, 8000h
    jz CheckA
    inc playerXY.Y           ; ���aY�y�мW�[�A�V�U����

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
    exit                     ; �p�G���UESC�A�h�X�C��

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

END main