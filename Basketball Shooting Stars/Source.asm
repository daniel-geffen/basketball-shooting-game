.486
.model flat, stdcall
option casemap :none

start_manager PROTO
movement_manager PROTO
shooting_power PROTO
power_manager PROTO
shooting_manager PROTO
direction_manager PROTO
change_direction PROTO
miss PROTO
ball_motion_manager PROTO
scoring_manager PROTO
ending_manager PROTO

include \masm32\include\windows.inc
include \masm32\include\kernel32.inc
include \masm32\include\user32.inc
include \masm32\include\msvcrt.inc
includelib msvcrt.lib
include drd.inc
includelib drd.lib

includelib \masm32\lib\winmm.lib 
include \masm32\include\winmm.inc

.data
SystemTime STRUCT
	wYear WORD ?
	wMonth WORD ?
	wDayOfWeek WORD ?
	wDay WORD ?
	wHour WORD ?
	wMinute WORD ?
	wSecond WORD ?
	wMilliseconds WORD ?
SystemTime ENDS

initial_time SystemTime<>
local_time SystemTime<>

start_file BYTE "start.bmp", 0
on_file BYTE "on.bmp", 0
off_file BYTE "off.bmp", 0
line_file BYTE "underline.bmp", 0

switch_pics DWORD 1 dup(offset on_file, offset off_file)

background_file BYTE "Background.bmp", 0
curry_file BYTE "Curry Standing.bmp", 0
lebron_file BYTE "Lebron Standing.bmp", 0
power_bar_file BYTE "powerbar.bmp", 0
color_file BYTE "colors.bmp", 0
ball_file BYTE "Ball.bmp", 0
names_file BYTE "Names.bmp", 0

zero BYTE "zero.bmp", 0
one BYTE "one.bmp", 0
two BYTE "two.bmp", 0
three BYTE "three.bmp", 0
four BYTE "four.bmp", 0
five BYTE "five.bmp", 0

player1_wins BYTE "Player 1 Wins.bmp", 0
player2_wins BYTE "Player 2 Wins.bmp", 0

players DWORD 1 dup(offset curry_file, lebron_file)
numbers DWORD 1 dup(offset zero, offset one, offset two, offset three, offset four, offset five)
winner_photos DWORD 1 dup(offset player1_wins, offset player2_wins)

Coord STRUCT
	x DWORD ?
	y DWORD ?
	path DWORD ?
	pimg Img<0,0,0,0>
Coord ENDS

start_page Coord<0, 0, offset start_file>
sound_switch Coord<365, 380, offset on_file>
underline Coord<310, 150, offset line_file>

background Coord<963, 768, offset background_file>
player Coord<374, 338, offset curry_file>
power_bar Coord<10, 550, offset power_bar_file>
color Coord<12, 690, offset color_file>
ball Coord<0, 0, offset ball_file>
player1_number Coord<330, 50, offset zero>
player2_number Coord<100, 50, offset zero>
names Coord<70, 0, offset names_file>
winner Coord<161, 64, 0>

song BYTE "Hall Of Fame.wav", 0
on_off DWORD 0

initial_ball_x DWORD 0
initial_ball_y DWORD 0

player_x DWORD 85
player_y DWORD 145

color_cut_startx DWORD 0
color_cut_starty DWORD 139
color_cut_widthx DWORD 24
color_cut_heighty DWORD 1

color_dir DWORD 1
ball_dir DWORD -1
p BYTE 0
d BYTE 0
shot_power DWORD 0
shot_dir DWORD 0
time_past DWORD 0
dumb_var DWORD 0
gravity DWORD 4000
x_dir DWORD 1
y_dir DWORD 1

xx DWORD 0
yy DWORD 0

player_num DWORD 0
players_score DWORD 2 dup(0)
must_make DWORD 0

stage DWORD 0

start DWORD 3

.code

X macro args:VARARG
	asm_txt TEXTEQU <>
	FORC char,<&args>
		IFDIF <&char>,<!\>
			asm_txt CATSTR asm_txt,<&char>
		ELSE
			asm_txt
			asm_txt TEXTEQU <>
		ENDIF
	ENDM
	asm_txt
endm

start_manager PROC
	pusha
	invoke drd_imageLoadFile, [start_page.path], offset [start_page.pimg]
	invoke drd_imageLoadFile, [sound_switch.path], offset [sound_switch.pimg]
	invoke drd_imageSetTransparent ,offset [sound_switch.pimg],0ffffffh
	invoke drd_imageLoadFile, [underline.path], offset [underline.pimg]
	invoke drd_imageSetTransparent ,offset [underline.pimg],0ffffffh
	
	l:
	invoke drd_imageDraw, offset [start_page.pimg], 0, 0
	invoke drd_imageDraw, offset [sound_switch.pimg], [sound_switch.x], [sound_switch.y]
	invoke drd_imageDraw, offset [underline.pimg], [underline.x], [underline.y]
	invoke drd_flip
	invoke drd_processMessages

	X	invoke GetAsyncKeyState, VK_RETURN \ cmp eax, 0 \ jne next
	X	invoke GetAsyncKeyState, VK_DOWN \ cmp eax, 0 \ jne lower
	jmp l

	lower:
	X	mov eax, [underline.y] \ add eax, 200 \ mov [underline.y], eax
	jmp change_sound

	change_sound:
	invoke drd_imageDraw, offset [start_page.pimg], 0, 0
	invoke drd_imageDraw, offset [sound_switch.pimg], [sound_switch.x], [sound_switch.y]
	invoke drd_imageDraw, offset [underline.pimg], [underline.x], [underline.y]
	invoke drd_flip
	invoke drd_processMessages

	X	invoke GetAsyncKeyState, VK_RETURN \ cmp eax, 0 \ jne change
	X	invoke GetAsyncKeyState, VK_UP \ cmp eax, 0 \ jne upper
	jmp change_sound

	change:
		X	xor on_off, 1 \ mov ebx, on_off
		X	mov eax, switch_pics[ebx*4] \ mov [sound_switch.path], eax

		invoke drd_imageLoadFile, [sound_switch.path], offset [sound_switch.pimg]
		invoke drd_imageSetTransparent ,offset [sound_switch.pimg],0ffffffh
		
		X	cmp on_off, 1 \ je silent
		invoke PlaySound,ADDR song,NULL,SND_ASYNC
		jmp stall
		silent:
		invoke PlaySound,NULL,NULL,SND_ASYNC
		jmp stall

	stall:
		mov ecx, 80000000
		a:
		loop a
		jmp change_sound

	upper:
		X	mov eax, [underline.y] \ sub eax, 200 \ mov [underline.y], eax
		jmp l

	next:
	X	popa \ ret
start_manager ENDP

movement_manager PROC
	pusha
	X	mov eax, start \ dec eax \ mov start, eax
	X	cmp start, 0 \ je turn \ jmp finish

	turn:
		mov start, 2
		X	invoke GetAsyncKeyState, VK_RIGHT \ cmp eax, 1  \ ja right
		X	invoke GetAsyncKeyState, VK_LEFT \ cmp eax, 0 \ jne left
		X	invoke GetAsyncKeyState, VK_SPACE \ cmp eax, 0 \ jne next
		X	invoke GetAsyncKeyState, VK_ESCAPE \ cmp eax, 0 \ jne start_p
		jmp finish

	right:
		X	mov ebx, [background.x] \ sub ebx, 250
		X	mov eax, [player.x] \ inc eax \ cmp eax, ebx \ jl end_move
		X	mov eax, ebx \ jmp end_move

	left:
		mov ebx, 2
		X	mov eax, [player.x] \ dec eax \ cmp eax, ebx \ jg end_move
		X	mov eax, ebx \ jmp end_move

	end_move:
		X	mov [player.x], eax \ jmp finish

	next:
		X	mov stage, 1 \ jmp finish

	start_p:
		X	invoke start_manager

	finish:	
		X	popa \ ret

movement_manager ENDP

shooting_power PROC
	pusha
	
	X	cmp color_cut_heighty, 1 \ jne next1 \ mov color_dir, 1
	next1:
	X	cmp color_cut_heighty, 139 \ jne next \ mov color_dir, -1

	next:
		X	mov eax, [color.y] \ sub eax, color_dir \ mov [color.y], eax
		X	mov eax, color_cut_heighty \ add eax, color_dir \ mov color_cut_heighty, eax
		X	mov eax, color_cut_starty \ sub eax, color_dir \ mov color_cut_starty, eax
	
	X	popa \ ret
shooting_power ENDP

power_manager PROC
	pusha
	X	mov eax, start \ dec eax \ mov start, eax
	X	cmp start, 0 \ je turn \ jmp finish

	turn:
		mov start, 3
		X	cmp p, 1 \ jne checking_keys
		invoke shooting_power

	checking_keys:
		X	invoke GetAsyncKeyState, VK_SPACE \ cmp eax, 0 \ jne next
		X	invoke GetAsyncKeyState, VK_SHIFT \ cmp eax, 0 \ jne pausea
		X	invoke GetAsyncKeyState, VK_RETURN \ cmp eax, 0 \ jne stop
		jmp finish

	next:
		X	mov p, 1 \ jmp finish

	pausea:
		X	mov p, 2 \ jmp finish

	stop:
		X	mov p, 2 \ mov stage, 2
		X	mov eax, color_cut_heighty \ mov shot_power, eax
		X	mov eax, [player.x] \ add eax, 100 \ mov [ball.x], eax
		X	mov eax, [player.y] \ mov [ball.y], eax

	finish:
		X	popa \ ret

power_manager ENDP

shooting_direction PROC
	pusha
	mov ebx, ball_dir
	X	mov eax, [ball.y] \ add eax, ebx \ mov [ball.y], eax
	X	mov eax, [player.y] \ add eax, 30 \ cmp [ball.y], eax
	X	jne under \ mov ball_dir, -1
	under:
	X	mov eax, [player.y] \ sub eax, 170 \ cmp [ball.y], eax
	X	jne outa \ mov ball_dir, 1

	outa:
		X	popa \ ret
shooting_direction ENDP

direction_manager PROC
	pusha
	X	mov eax, start \ dec eax \ mov start, eax
	X	cmp start, 0 \ je turn \ jmp finish

	turn:
		mov start, 3
		X	cmp d, 1 \ jne cont
		invoke shooting_direction
	cont:
	X	invoke GetAsyncKeyState, VK_RETURN \ cmp eax, 0  \ jne go
	X	invoke GetAsyncKeyState, VK_SHIFT \ cmp eax, 0 \ jne stop
	X	invoke GetAsyncKeyState, VK_SPACE \ cmp eax, 0 \ jne next
	jmp finish

	go:
		X	mov d, 1 \ jmp finish

	stop:
		X	mov d, 2 \ jmp finish
	
	next:
		X	mov edx, [player.x] \ mov eax, player_x
		X	shr eax, 1 \ add edx, eax
		X	mov ebx, [player.y] \ mov eax, player_y
		X	shr eax, 1 \ sub eax, 30 \ add ebx, eax
		X	mov eax, [ball.y] \ mov ecx, [ball.x]
		X	mov initial_ball_x, edx \ mov initial_ball_y, ebx
		;	eax = bally, ebx = playery, ecx = ballx, edx = playerx

		X	sub ebx, eax \ sub ecx, edx
		;	ebx = y difference, ecx = x difference

		X	mov yy, ebx \ mov xx, ecx
		X	fild yy \ fild xx \ fpatan \ fst shot_dir
		;X	mov dumb_var, 180 \ fild dumb_var \ fldpi \ fdivp st(1), st
		;X	fmulp st(1), st \ fist dumb_var \ mov eax, dumb_var

		invoke GetLocalTime, ADDR initial_time
		mov stage, 3

	finish:	
		X	popa \ ret
direction_manager ENDP

change_direction PROC
	pusha
	X	mov x_dir, -1 \ mov y_dir, 0
	X	mov eax, [ball.x] \ mov initial_ball_x, eax
	X	mov eax, [ball.y] \ mov initial_ball_y, eax
	
	X	mov gravity, 500
	X	mov ax, [local_time.wSecond] \ mov [initial_time.wSecond], ax
	X	mov ax, [local_time.wMilliseconds] \ mov [initial_time.wMilliseconds], ax
	
	X	popa \ ret
change_direction ENDP

miss PROC
	pusha

	xor player_num, 1
	X	mov p, 0 \ mov d, 0 \ mov gravity, 4000
	X	mov x_dir, 1 \ mov y_dir, 1 \ mov stage, 0

	X	mov ebx, player_num \ mov eax, players[ebx*4] \ mov [player.path], eax
	invoke drd_imageLoadFile ,[player.path],offset [player.pimg]
	invoke drd_imageSetTransparent ,offset [player.pimg],0ffffffh

	X	cmp must_make, 1 \ jl finish

	X	xor must_make, 1 \ mov ebx, player_num
	X	mov eax, DWORD ptr players_score[ebx*4] \ inc eax \ mov DWORD ptr players_score[ebx*4], eax \ push eax

	X	mov ebx, numbers[eax*4] \ cmp player_num, 0 \ jne player2

	mov [player1_number.path], ebx
	invoke drd_imageLoadFile ,[player1_number.path],offset [player1_number.pimg]
	invoke drd_imageSetTransparent ,offset [player1_number.pimg],000000h
	jmp winning
	
	player2:
	mov [player2_number.path], ebx
	invoke drd_imageLoadFile ,[player2_number.path],offset [player2_number.pimg]
	invoke drd_imageSetTransparent ,offset [player2_number.pimg],000000h

	winning:
	X	pop eax \ cmp ax, 5 \ jne finish

	X	mov ebx, player_num \ mov eax, winner_photos[ebx*4] \ mov [winner.path], eax
	invoke drd_imageLoadFile ,[winner.path],offset [winner.pimg]
	mov stage, 5

	finish:
		X	popa \ ret
miss ENDP

ball_motion_manager PROC
	pusha
	
	invoke GetSystemTime, ADDR local_time
	X	mov ax, [local_time.wSecond] \ sub ax, [initial_time.wSecond] \ mov bx, 1000 \ mul bx
	X	add ax, [local_time.wMilliseconds] \ sub ax, [initial_time.wMilliseconds] \ mov time_past, eax
	
	X	fld shot_dir \ fcos \ fimul shot_power \ fimul time_past \ fimul x_dir
	X	mov dumb_var, 150 \ fidiv dumb_var \ fistp dumb_var
	X	mov eax, initial_ball_x \ mov ebx, dumb_var \ add eax, ebx \ mov [ball.x], eax

	X	fld shot_dir \ fsin \ fimul shot_power \ fimul time_past \ fimul y_dir
	X	mov dumb_var, 185 \ fidiv dumb_var
	X	fild time_past \ fmul st(0), st(0)
	X	fidiv gravity \ fsubp st(1), st(0) \ fistp dumb_var
	X	mov eax, initial_ball_y \ mov ebx, dumb_var \ sub eax, ebx \ mov [ball.y], eax

	roof:	
		X	cmp [ball.y], 5 \ jg floor
		X	mov [ball.y], 1
	
	floor:
		X	mov eax, [background.y] \ sub eax, 25 \ cmp [ball.y], eax \ jl right_wall
		X	mov [ball.y], eax \ invoke miss

	right_wall:
		X	mov eax, [background.x] \ sub eax, 25 \ cmp [ball.x], eax \ jl left_wall
		X	mov [ball.x], eax \ invoke miss
	
	left_wall:
		X	cmp [ball.x], 2 \ jg backboard
		X	mov [ball.x], 2 \ invoke miss

	backboard:
		X	cmp [ball.x], 745 \ jl front_rim
		X	cmp [ball.x], 760 \ jg front_rim
		X	cmp [ball.y], 30 \ jl front_rim
		X	cmp [ball.y], 145 \ jg front_rim
		invoke change_direction

	front_rim:
		X	cmp [ball.x], 695 \ jl under_rim
		X	cmp [ball.x], 705 \ jg under_rim
		X	cmp [ball.y], 135 \ jl under_rim
		X	cmp [ball.y], 140 \ jg under_rim
		invoke change_direction

	under_rim:
		X	cmp [ball.x], 705 \ jl score
		X	cmp [ball.x], 745 \ jg score
		X	cmp [ball.y], 145 \ jl score
		X	cmp [ball.y], 165 \ jg score
		invoke change_direction

	score:
		X	cmp [ball.x], 705 \ jl finish
		X	cmp [ball.x], 745 \ jg finish
		X	cmp [ball.y], 135 \ jl finish
		X	cmp [ball.y], 145 \ jg finish
		mov stage, 4

	finish:
		X	popa \ ret
ball_motion_manager ENDP

scoring_manager PROC
	pusha

	mov [ball.x], 735
	X	mov eax, [ball.y] \ inc eax \ mov [ball.y], eax
	X	mov eax, [background.y] \ sub eax, 25 \ cmp [ball.y], eax \ jl finish

	X	mov [ball.y], eax \ xor player_num, 1 \ xor must_make, 1
	X	mov p, 0 \ mov d, 0 \ mov gravity, 4000
	X	mov x_dir, 1 \ mov y_dir, 1

	X	mov ebx, player_num \ mov eax, players[ebx*4] \ mov [player.path], eax
	invoke drd_imageLoadFile ,[player.path],offset [player.pimg]
	invoke drd_imageSetTransparent ,offset [player.pimg],0ffffffh

	X	cmp must_make, 1 \ jl tie
	
	X	mov stage, 1 \ jmp finish
	tie:
	mov stage, 0
	
	finish:
		X	popa \ ret
scoring_manager ENDP

ending_manager PROC
	pusha

	X	invoke GetAsyncKeyState, VK_RETURN \ cmp eax, 0  \ je finish
	
	X	mov [winner.path], 0 \ mov DWORD ptr players_score[0], 0 \ mov DWORD ptr players_score[4], 0
	invoke drd_imageLoadFile ,DWORD ptr numbers[0],offset [player1_number.pimg]
	invoke drd_imageSetTransparent ,offset [player1_number.pimg],000000h
	invoke drd_imageLoadFile ,DWORD ptr numbers[0],offset [player2_number.pimg]
	invoke drd_imageSetTransparent ,offset [player2_number.pimg],000000h
	mov stage, 0

	finish:
		X	popa \ ret
ending_manager ENDP

main PROC
	invoke drd_init ,[background.x],[background.y],0
	invoke drd_imageLoadFile ,[background.path], offset [background.pimg]
	invoke drd_imageLoadFile ,[player.path],offset [player.pimg]
	invoke drd_imageSetTransparent ,offset [player.pimg],0ffffffh
	invoke drd_imageLoadFile ,[power_bar.path],offset [power_bar.pimg]
	invoke drd_imageSetTransparent ,offset [power_bar.pimg],0ffffffh
	invoke drd_imageLoadFile ,[color.path], offset [color.pimg]
	invoke drd_imageSetTransparent ,offset [color.pimg],0ffffffh
	invoke drd_imageLoadFile ,[ball.path], offset [ball.pimg]
	invoke drd_imageSetTransparent ,offset [ball.pimg],0ffffffh
	invoke drd_imageLoadFile ,[player1_number.path],offset [player1_number.pimg]
	invoke drd_imageSetTransparent ,offset [player1_number.pimg],000000h
	invoke drd_imageLoadFile ,[player2_number.path],offset [player2_number.pimg]
	invoke drd_imageSetTransparent ,offset [player2_number.pimg],000000h
	invoke drd_imageLoadFile ,[names.path],offset [names.pimg]
	invoke drd_imageSetTransparent ,offset [names.pimg],000000h

	invoke PlaySound,addr song,NULL,SND_ASYNC
	invoke start_manager
	
	a:
		invoke drd_processMessages
		invoke drd_imageDraw ,offset [background.pimg],0,0
		invoke drd_imageDraw ,offset [player.pimg],[player.x],[player.y]
		invoke drd_imageDraw ,offset [player1_number.pimg],[player1_number.x],[player1_number.y]
		invoke drd_imageDraw ,offset [player2_number.pimg],[player2_number.x],[player2_number.y]
		invoke drd_imageDraw ,offset [names.pimg],[names.x],[names.y]

		X	cmp p, 0 \ je enda
		invoke drd_imageDraw ,offset [power_bar.pimg],[power_bar.x],[power_bar.y]
		invoke drd_imageDrawCrop ,offset [color.pimg], [color.x], [color.y], color_cut_startx, color_cut_starty, color_cut_widthx, color_cut_heighty
	enda:
		X	cmp d, 0 \ je endb
		invoke drd_imageDraw ,offset [ball.pimg],[ball.x],[ball.y]

	endb:
		X	cmp [winner.path], 0 \ je endc
		invoke drd_pixelsClear, 0ffffffh
		invoke drd_imageDraw ,offset [winner.pimg],[winner.x],[winner.y]

	endc:
		invoke drd_flip
		X	cmp stage, 0 \ je invoke0
		X	cmp stage, 1 \ je invoke1
		X	cmp stage, 2 \ je invoke2
		X	cmp stage, 3 \ je invoke3
		X	cmp stage, 4 \ je invoke4
		X	cmp stage, 5 \ je invoke5
		jmp a
		
		invoke0:
			X	invoke movement_manager \ jmp a

		invoke1:
			X	invoke power_manager \ jmp a

		invoke2:
			X	invoke direction_manager \ jmp a
		
		invoke3:
			X	invoke ball_motion_manager \ jmp a
		
		invoke4:
			X	invoke scoring_manager \ jmp a
		
		invoke5:
			X	invoke ending_manager \ jmp a

	ret
main ENDP

end main