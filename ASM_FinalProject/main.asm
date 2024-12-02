include Irvine32.inc
.data 

.code 
main PROC 
	mov ebx, 5
	mov eax, 5
	imul ebx
	mul ebx
	call WriteDec
	invoke ExitProcess, 0
main ENDP 

END main
