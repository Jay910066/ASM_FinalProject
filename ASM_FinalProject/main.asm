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
    ; 檢查W鍵（向上移動）
    INVOKE GetAsyncKeyState, 'W'
    test ax, 8000h
    jz CheckS
    dec playerXY.Y           ; 玩家Y座標減少，向上移動

CheckS:
    ; 檢查S鍵（向下移動）
    INVOKE GetAsyncKeyState, 'S'
    test ax, 8000h
    jz CheckA
    inc playerXY.Y           ; 玩家Y座標增加，向下移動

CheckA:
    ; 檢查A鍵（向左移動）
    INVOKE GetAsyncKeyState, 'A'
    test ax, 8000h
    jz CheckD
    dec playerXY.X           ; 玩家X座標減少，向左移動

CheckD:
    ; 檢查D鍵（向右移動）
    INVOKE GetAsyncKeyState, 'D'
    test ax, 8000h
    jz CheckESC
    inc playerXY.X           ; 玩家X座標增加，向右移動

CheckESC:
    ; 檢查ESC鍵（退出遊戲）
    INVOKE GetAsyncKeyState, VK_ESCAPE
    test ax, 8000h
    jz EndInput
    exit                     ; 如果按下ESC，退出遊戲

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