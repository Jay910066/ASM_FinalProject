INCLUDE Irvine32.inc
INCLUDELIB kernel32.lib

playerSize = 1
gravity = 1
jumpForce = 4

.data
player BYTE 'P'

platformBuffer BYTE 10 DUP(?)
platformCoord COORD <0,0>
charRead DWORD ?

outputHandle DWORD 0
bytesWritten DWORD 0
count DWORD 0
playerXY COORD <10,5>
velocityY SWORD 0
isRunning BYTE 0

platformLevel WORD 24
onPlatform BYTE 1

escConfirm byte 0

cellsWritten DWORD ?
playerAttributes WORD playerSize DUP(0bh)

updateInterval WORD 50 ; 50ms each update

startTime DWORD ?
elapsedTime DWORD ?
timeLimit DWORD 600 ; 600 seconds
TimerXY COORD <0,0>

currentLevel DWORD 1

;畫面繪製
fileHandle HANDLE ?
bytesRead DWORD ?
screenBytesWritten DWORD ?

;遊戲畫面資料
gamescrfile BYTE 'gamefield1.txt',0

;初始畫面資料
buffer BYTE 7000 DUP(?)
initialscrfile BYTE 'start.txt',0
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

;結算畫面資料
endscrfile BYTE 'finish.txt',0
endKeyPos Byte 0
endconfirm Byte 0
endCoinGot DWORD 0
endTime DWORD 0
needsRefresh BYTE 1
isDead BYTE 0
prevKeyPos BYTE 0

endStartLeftPos COORD <30,20>
endStartLeftSymbol DWORD '>',0
endStartRightPos COORD <55,20>
endStartRightSymbol DWORD '<',0

endExitLeftPos COORD <68,20>
endExitLeftSymbol DWORD '>',0
endExitRightPos COORD <93,20>
endExitRightSymbol DWORD '<',0
endCoinGotCoord COORD <43,7>
endTimeCoord COORD <43,4>

;金幣生成資料
coinSeed DWORD 1
coinCoord COORD <0,0>
coinGenerated byte 0
coinSymbol byte '$'
coinAttribute WORD 0Eh
coinGot DWORD 0
coinGotCoord1 COORD <7,2>
coinGet byte 0
seed DWORD ?
preSeed DWORD 0

.code
	SetConsoleOutputCP PROTO STDCALL :DWORD
	GetAsyncKeyState PROTO STDCALL :DWORD
	ReadConsoleOutputCharacterA PROTO STDCALL :DWORD, :PTR BYTE, :DWORD, :COORD, :PTR DWORD
	drawScreen PROTO screenFileName :PTR BYTE
main PROC
	INVOKE SetConsoleOutputCP, 437

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
	mov playerXY.X, 10
	mov playerXY.Y, 5
	mov velocityY, 0
	mov currentLevel, 1
	mov gamescrfile[9], '1'
	mov isDead, 0
	mov escConfirm, 0
	mov endConfirm, 0
	mov coinGot, 0
	
GameLoop:
	call Clrscr
	call updatePhysics
	INVOKE drawScreen, ADDR gamescrfile
	call drawPlayer
	call checkPlatformLevel
	call displayTime
	call displayCoinGot
	call readPlayerMoveInput
	call getCoin
	call generateCoins
	call cheatInput			; 按C鍵進入下一關
	call updateLevel
	call endGame
	cmp  escConfirm, 1
	je endLoop
	invoke Sleep, updateInterval
	jmp GameLoop

endLoop:
	cmp needsRefresh, 1
	je Refresh
	jmp CheckInput

Refresh:
	call Clrscr
	call displayEndscr
	call displayEndData
	mov needsRefresh, 0
	jmp CheckInput

CheckInput:
	call readInputEndscr
	cmp endconfirm, 1
	je conti
	mov al, endKeyPos
	mov ah, prevKeyPos
	cmp ah, al
	je SkipRefresh
	mov needsRefresh, 1
	mov ah, endKeyPos
	mov prevKeyPos, ah

SkipRefresh:
	invoke Sleep, updateInterval
	jmp endLoop

	exit
main ENDP

updatePhysics PROC uses eax ebx
	; 檢查是否超出螢幕上方
	.IF playerXY.Y >= 60000
		mov playerXY.Y, 0
		mov platformLevel, 0
	.ENDIF

	; 檢查是否掉出螢幕下方
	.IF playerXY.Y >= 26
		mov isDead, 1
	.ENDIF
    ; 更新玩家的 Y 座標
    mov ax, velocityY
    add playerXY.Y, ax        ; 根據垂直速度更新位置

    ; 應用重力（加速垂直速度）
    add velocityY, gravity    ; 重力影響：速度越來越快

    ; 檢查是否低於地面
    mov ax, playerXY.Y
    cmp ax, platformLevel
	jle EndPhysics            ; 如果未超過地面，跳過地面處理

    ; 如果超出地面，重置到地面
    mov ax, platformLevel
    mov playerXY.Y, ax        ; 將玩家重置到地面
    mov velocityY, 0          ; 停止垂直運動
    mov onPlatform, 1           ; 標記玩家在地面上
    jmp EndPhysics

EndPhysics:
    ret
updatePhysics ENDP

; 檢查平台高度
checkPlatformLevel PROC uses eax ebx ecx edx
	mov ax, playerXY.X
	mov bx, playerXY.Y
	inc bx
	mov platformCoord.X, ax
	mov platformCoord.Y, bx

	mov cx, 30
detectPlatform:
	mov dx, cx

	INVOKE ReadConsoleOutputCharacterA,
	outputHandle,
	ADDR platformBuffer,
	1,
	platformCoord,
	ADDR charRead

	mov al, platformBuffer
	.IF al != 32
		mov ax, platformCoord.Y
		dec ax
		mov platformLevel, ax
		jmp EndCheck
	.ENDIF
	inc platformCoord.Y
	mov cx, dx
	loop detectPlatform

	; 輸出Debug訊息
;showINFO:
	;mov dl, 0
	;mov dh, 0
	;call gotoxy
	;call WriteDec

EndCheck:
	ret
checkPlatformLevel ENDP

readPlayerMoveInput PROC
    ; 檢查W鍵（向上移動）
    INVOKE GetAsyncKeyState, 'W'
    test ax, 8000h
    jz CheckShift
	cmp onPlatform, 1
	jne CheckShift
	mov ax, jumpForce
	sub velocityY, ax
	mov onPlatform, 0
CheckShift:
	; 檢查Shift鍵（加速）
	mov isRunning, 0
	INVOKE GetAsyncKeyState, VK_SHIFT
	test ax, 8000h
	jz CheckA
	mov isRunning, 1
CheckA:
    ; 檢查A鍵（向左移動）
    INVOKE GetAsyncKeyState, 'A'
    test ax, 8000h
    jz CheckD
    .IF isRunning == 1
		sub playerXY.X, 2
	.ELSE
		dec playerXY.X
	.ENDIF
							
	.IF playerXY.X <= 0
		mov playerXY.X, 1
	.ENDIF

CheckD:
    ; 檢查D鍵（向右移動）
    INVOKE GetAsyncKeyState, 'D'
    test ax, 8000h
    jz CheckESC
    .IF isRunning == 1
		add playerXY.X, 2
	.ELSE
		inc playerXY.X
	.ENDIF
	.IF playerXY.X >= 119
		mov playerXY.X, 118
	.ENDIF

CheckESC:
    ; 檢查ESC鍵（退出遊戲）
    INVOKE GetAsyncKeyState, VK_ESCAPE
    test ax, 8000h
    jz EndInput
    mov escConfirm,1

EndInput:
	ret
readPlayerMoveInput ENDP

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

drawScreen PROC uses eax ebx ecx edx, screenFileName:PTR BYTE
    ;打開文字檔案
	INVOKE CreateFile, screenFileName, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL 
	mov fileHandle, eax

ReadLoop:
	;使用UTF-8編碼，顯示符號
	INVOKE SetConsoleOutputCP, 65001

	;讀取檔案
	INVOKE ReadFile, fileHandle, ADDR buffer, SIZEOF buffer, ADDR bytesRead, NULL

	;畫面更新及輸出檔案
	call Clrscr
	INVOKE SetFilePointer, fileHandle, 0, NULL, FILE_BEGIN
	INVOKE WriteConsole, outputHandle, ADDR buffer, bytesRead, ADDR screenBytesWritten, NULL

EndDraw:
	;關閉檔案
    INVOKE CloseHandle, fileHandle
    ret
drawScreen ENDP

updateLevel PROC
	.IF coinGot == 5 && currentLevel == 1
		mov currentLevel, 2
		mov gamescrfile[9], '2'
		mov playerXY.X, 10
		mov playerXY.Y, 5
		mov velocityY, 0
	.ELSEIF coinGot == 8 && currentLevel == 2
		mov currentLevel, 3
		mov gamescrfile[9], '3'
		mov playerXY.X, 10
		mov playerXY.Y, 5
		mov velocityY, 0
	.ENDIF

updateLevel ENDP

displayTime PROC uses eax ebx ecx edx
	INVOKE GetTickCount
	sub eax, startTime
	cdq
	mov ebx, 1000
	div ebx
	mov elapsedTime, eax
	mov eax, timeLimit
	sub eax, elapsedTime
	mov endTime, eax
	mov dl, 6
	mov dh, 1
	call gotoxy
	call WriteDec
	ret
displayTime ENDP

displayInitialscr PROC uses eax ebx ecx edx
    INVOKE drawScreen, ADDR initialscrfile
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
    ret
displayInitialscr ENDP

readInputInitialscr PROC uses eax ebx ecx edx
	INVOKE GetAsyncKeyState, VK_RETURN
	test eax, 8000h                     
    jz checkW
	cmp initialKeyPos, 0 ;判斷按鍵位置
	je confirm
	call Clrscr
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
    INVOKE drawScreen, ADDR endscrfile
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
    ret
displayEndscr ENDP

readInputEndscr PROC uses eax ebx ecx edx
	INVOKE GetAsyncKeyState, VK_RETURN
	test eax, 8000h                     
    jz checkA
	cmp endKeyPos, 0 ;判斷按鍵位置
	je confirm
	call Clrscr
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

generateCoins PROC uses eax ebx ecx edx
	cmp coinGenerated, 1
	je output
	call generateRandomSeed
	cmp coinSeed, 0
	je Pos1
	cmp coinSeed, 1
	je Pos2
	cmp coinSeed, 2
	je Pos3
	jmp Pos4

Pos1:
	mov coinCoord.x, 15
	mov coinCoord.y, 3
	jmp output

Pos2:
	mov coinCoord.x, 90
	mov coinCoord.y, 4
	jmp output

Pos3:
	mov coinCoord.x, 40
	mov coinCoord.y, 14
	jmp output

Pos4:
	mov coinCoord.x, 98
	mov coinCoord.y, 15
	mov coinSeed, 0
	jmp output

output:
	INVOKE WriteConsoleOutputCharacter,
	outputHandle,
	OFFSET coinSymbol,
	1,
	coinCoord,
	OFFSET count

	INVOKE WriteConsoleOutputAttribute,
	outputHandle, 
	OFFSET coinAttribute,
	1, 
	coinCoord,
	OFFSET count

	mov coinGenerated, 1
	ret
generateCoins ENDP

displayCoinGot PROC uses eax ebx ecx edx
    invoke SetConsoleCursorPosition,outputHandle, coinGotCoord1
	mov eax, coinGot
	call WriteDec
	ret
displayCoinGot ENDP

cheatInput PROC
	INVOKE GetAsyncKeyState, 'C'
	test eax, 8000h
	jz endInput
	.IF currentLevel == 1
		mov coinGot, 5
	.ELSEIF currentLevel == 2
		mov coinGot, 8
	.ELSEIF currentLevel == 3
		mov coinGot, 12
	.ENDIF
endInput:
	ret
cheatInput ENDP

displayEndData PROC uses eax ebx ecx edx
coin:
	mov dl, 43
	mov dh, 7
	call gotoxy
	mov eax, CoinGot
	call WriteDec

time:
	mov dl, 43
	mov dh, 4
	call gotoxy
	mov eax, endTime
	call WriteDec

point:
	mov dl, 43
	mov dh, 10
	call gotoxy
	.IF isDead == 1
		.IF currentLevel == 1
			mov eax, 0
		.ELSEIF currentLevel == 2
			mov eax, 5
		.ELSEIF currentLevel == 3
			mov eax, 8
		.ENDIF
	.ELSE
		mov eax, coinGot
	.ENDIF
	mul endTime
	call WriteDec

level:
	mov dl, 43
	mov dh, 13
	call gotoxy
	mov eax, currentLevel
	.IF isDead == 1
		dec eax
	.ENDIF
	call WriteDec
	
	mov dl, 0
	mov dh, 0
	call gotoxy
	ret
displayEndData ENDP

getCoin PROC uses eax ebx ecx edx
compareX:
	mov ax, playerXY.x
	cmp ax, coinCoord.x
	jne not_equal

compareY:
	mov ax, playerXY.y
	cmp ax, coinCoord.y
	jne not_equal

equal:
	mov coinGet, 1
	inc coinGot
	mov coinGenerated, 0
	jmp end_program

not_equal:
	mov coinGet, 0

end_program:
	ret

getCoin ENDP

endGame PROC uses eax ebx ecx edx
	mov eax, coinGot
	cmp eax, 12
	je equal

	mov eax, endTime
	cmp eax, 0
	je equal

	mov al, isDead
	cmp al, 1
	je equal
	jmp end_program

equal:
	mov escConfirm, 1

end_program:
	ret
endGame ENDP

generateRandomSeed PROC uses eax ebx ecx edx
generate:
	invoke GetTickCount
    mov seed, eax

	mov eax, seed
    imul eax, 214013    
    add eax, 2531011
    shr eax, 16    
    and eax, 7FFFh
    xor edx, edx
	mov ebx, 5
    div ebx    
    mov coinSeed, edx

	cmp edx, preSeed
	je generate
	mov preSeed,edx
	
	ret
generateRandomSeed ENDP

END main