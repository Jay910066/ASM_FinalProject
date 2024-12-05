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
onGround DWORD 1


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
	call updatePhysics
	call drawPlayer
	call displayTime
	call readInput
	invoke Sleep, updateInterval
	jmp GameLoop

	exit
main ENDP

updatePhysics PROC uses eax ebx
    ; 1. 更新玩家的 Y 座標
    mov ax, velocityY
    add playerXY.Y, ax        ; 根據垂直速度更新位置

    ; 2. 應用重力（加速垂直速度）
    add velocityY, gravity    ; 重力影響：速度越來越快

    ; 3. 檢查是否低於地面
    mov ax, playerXY.Y
    cmp ax, groundLevel
    jle EndPhysics            ; 如果未超過地面，跳過地面處理

    ; 如果超出地面，重置到地面
    mov ax, groundLevel
    mov playerXY.Y, ax        ; 將玩家重置到地面
    mov velocityY, 0          ; 停止垂直運動
    mov onGround, 1           ; 標記玩家在地面上
    jmp EndPhysics

EndPhysics:
    ret
updatePhysics ENDP

readInput PROC
    ; 檢查W鍵（向上移動）
    INVOKE GetAsyncKeyState, 'W'
    test ax, 8000h
    jz CheckA
	cmp onGround, 1
	jne CheckA
	mov ax, 5
	sub velocityY, ax
	mov onGround, 0

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
    INVOKE ExitProcess, 0    ; 如果按下ESC，退出遊戲

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