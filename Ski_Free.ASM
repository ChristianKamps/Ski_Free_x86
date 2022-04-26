; ********* NOTES ********* 
; - ARRAY: rand_Num DOES NOT CONTAIN THE INITIAL PLAYER X-POSITION (39) TO TEST FOR INFINITE SCROLLING AND ROCK GENERATION
; - ROCK GENERATION IS "PSUEDO-RANDOM" SUCH THAT IT IS A LOOP THROUGH THE ARRAY: rand_Num
; - SOFTWARE INTERRUPTS PREFORM ACTIONS DEPENDING ON THE CURRENT VALUES IN SPECEFIC REGISTERS
; - PROGRAM INPUTS 'a','s','q', ONLY WORK FOR LOWERCASE INPUTS
; - INCREASED DIFFICULTY COMES FROM DECREASED DELAY OR INCREASED ROCK COUNT
; *************************

; ********* PESUDO-CODE ********* 
; 1. SETUP DATA AND PROCEDURES
; 2. SETUP DATA SEGMENT (DS) REGISTER AND SOURCE INDEX (SI) REGISTER
; 3. DRAW ROCKS
; 4. SCROLL THE SCREEN ONE ROW UPWARDS
; 5. CHECK FOR PLAYER-ROCK COLLISION (ROCKS MAY NOW OCCUPY SAME LOCATION AS PLAYER)
; 6. DRAW PLAYER
; 7. DELAY
; 8. DRAW PLAYER TRAIL
; 9. CHECK FOR ANY KEY PRESSES
; 10. CHECK FOR SPECEFIC KEY PRESSES
; 11. PROCESS KEY PRESSES
; 12. TERMINATION STRING
; 13. EXIT PROGRAM
; *******************************
.MODEL small
.STACK 100h
.386

.data
    ; rand_Num CONTAINS THE X-POSITION OF THE GENERATED ROCKS FROM 0 TO 79 (EXCLUDING 39: INITIAL PLAYER POSITION)
    rand_Num DB  17, 24, 51, 47, 49, 41, 42, 55, 52, 8, 7, 54, 67, 12, 72, 57, 1, 40, 45, 23
             DB  41, 70, 30, 55, 25, 19, 27, 44, 10, 4, 24, 72, 56, 16, 50, 22, 74, 35, 73, 12
             DB  10, 19, 63, 25, 15, 57, 44, 11, 6, 46, 62, 37, 1, 17, 36, 61, 14, 23, 77, 40
             DB  6, 21, 0, 1, 15, 35, 40, 34, 26, 57, 8, 9, 53, 23, 58, 72, 55, 70, 51, 59
    rand_Location DW $-2 ; END OF ARRAY: rand_Num
    msg DB "PROGRAM TERMINATED", 0 ; TERMINATION STRING: msg
	nSize DW ($ - msg)-1 ; STRING LENGTH OF VARIABLE: msg
    XPOS DB 27h ; VARIABLE FOR PLAYER X-POSITION - INITIAL X-POSITION IS MIDDLE OF THE SCREEN = 0x27 = 39

.code
; ********* SET CURSOR PROCEDURE *********
; THIS PROCEDURE SETS THE REGISTERS FOR SETTING A CURSOR POSITION
; CALLER MUST SET DL AND DH REGISTERS BEFORE CALL
; DL = COLUMN NUMBER
; DH = ROW NUMBER
; ****************************************
set_Cursor PROC
    MOV BH, 0H      ; PAGE NUMBER 0 OF VIDEO MEMORY
    MOV AH, 2H      ; FUNCTION CODE TO SET CURSOR POSITION
    INT 10H         ; INTERRUPT 
    RET             ; POP RETURN ADDRESS OFF THE STACK INTO THE INSTRUCTION POINTER REGISTER
set_Cursor ENDP

; ********* WRITE CHARACTER AT CURSOR LOCATION PROCEDURE *********
; THIS PROCEDURE SETS THE REGISTERS FOR DRAWING A SINGLE CHARACTER AT THE CURRENT CURSOR POSITION
; CALLER MUST SET AL AND BL REGISTERS BEFORE CALL
; AL = CHARACTER
; BL = CHARACTER COLOR
; ****************************************************************
draw PROC
    MOV BH, 0H      ; PAGE NUMBER 0 OF VIDEO MEMORY
    MOV CX, 1H      ; DRAW THE CHARACTER ONCE
    MOV AH, 09H     ; FUNCTION CODE FOR WRITE CHARACTER AT CURSOR POSITION
    INT 10H         ; INTERRUPT
    RET             ; POP RETURN ADDRESS OFF THE STACK INTO THE INSTRUCTION POINTER REGISTER
draw ENDP

; ********* MAIN PROCEDURE *********
_main PROC
    ; ********* SETUP *********
    ; SETUP DATA SEGMENT AND ADDRESS LOCATION OF ARRAY: rand_Num
    ; *************************
    MOV DX, @data               ; MOVE DATA ADDRESS INTO DX
    MOV DS, DX                  ; MOVE DATA ADDRESS TO DATA SEGMENT (DS)
    XOR SI, SI                  ; CLEAR SI
    MOV SI, OFFSET rand_Num     ; SI CONTAINS ADDRESS OF ARRAY: rand_Num

    main_Loop:
    ; ********* DRAW ROCKS *********
    ; DRAWS A SPECEFIC AMOUNT OF ROCKS AT THE BOTTOM ROW OF THE VIDEO SCREEN
    ; ROCK CHARACTER IS: 'R'
    ; ROCK COLOR IS: BROWN
    ; THE LOCATION OF EACH ROCK IS TAKEN FROM ARRAY: rand_Num
    ; SI POINTS TO THE ADDRESS OF EACH NUMBER IN ARRAY: rand_Num
    ; WHEN SI REACHES THE END OF THE ARRAY, IT LOOPS BACK TO THE BEGGINING FOR INFINITE ROCK GENERATION
    ; ******************************
    ; 1. SETUP
    MOV CX, 2                   ; CX HOLDS NUMBER OF ROCKS TO DRAW EACH LOOP        
    draw_Rocks:                 ; LABEL: draw_Rocks
    ; 2. SET CURSOR AT ROCK LOCATION
    MOV DL, byte ptr [SI]       ; COLUMN LOCATION IS GIVEN BY A POINTER TO ARRAY: rand_Num 
    MOV DH, 18H                 ; ROW = 0x18 = 24 = BOTTOM OF VIDEO SCREEN
    CALL set_Cursor             ; PROCEDURE: set_Cursor TO SET CURSOR TO ROCK LOCATION
    ; 3. DRAW ROCK AT CURSOR LOCATION
    MOV AL, 'R'                 ; CHARACTER = 0x52  = R   
    MOV BL, 6H                  ; COLOR     = 0x6   = BROWN    
    PUSH CX                     ; CX IS USED IN PROCEDURE: draw, SO WE SAVE THE REGISTER VALUE IN THE STACK
    CALL draw                   ; PROCEDURE: draw TO DRAW A SINGLE ROCK
    POP CX                      ; RETURN THE ORIGINAL CX VALUE FROM THE STACK
    ; 4. CONTROL SI
    CMP SI, rand_Location       ; COMPARE SI AND END OF ARRAY: rand_Num 
    JNE dont_Reset_SI           ; JUMP TO LABEL: dont_reset_SI IF SI IS NOT AT THE END OF ARRAY: rand_Num
    MOV SI, OFFSET rand_Num     ; IF SI IS AT THE END OF THE ARRAY: rand_Num, MOVE IT BACK TO THE START
    dont_Reset_SI:              ; LABEL: dont_Reset_SI
    INC SI                      ; INCREASE SI TO THE NEXT NUMBER IN ARRAY: rand_Num 
    ; 5. CONDITIONAL LOOP
    LOOP draw_Rocks             ; IF CX>0, LOOP TO LABEL: draw_Rocks AND DRECREASE CX, ELSE BREAK

    ; ********* SCROLL THE SCREEN *********
    ; SCROLLS THE ENTIRE SCREEN UP 1 ROW
    ; VGA TEXT MODE DIMENSIONS: 80 COLUMNS (0:79), 25 ROWS (0:24)
    ; *************************************
    MOV CH, 0H      ; TOP ROW       = 0
    MOV CL, 0H      ; LEFT COLUMN   = 0
    MOV DH, 18H     ; BOTTOM ROW    = 0x18 = 24
    MOV DL, 4FH     ; RIGHT COLUMN  = 0x4F = 79
    MOV AL, 1H      ; SCROLL ONCE
    MOV AH, 06H     ; FUNCTION CODE TO SCROLL
    INT 10H         ; INTERRUPT 

    ; ********* CHECK PLAYER-ROCK COLLISION ********* 
    ; PLAYER IS ALWAYS ON ROW 13 (0xD)
    ; CHECKS IF PLAYER AND ROCK OCCUPY THE SAME LOCATION
    ; IF PLAYER LOCATION CONTAINS A ROCK CHARACTER, TERMINATE PROGRAM
    ; ************************************************
    ; 1. PUT CURSOR ON PLAYER LOCATION
    MOV DL, XPOS        ; COLUMN    = X-POSITION OF PLAYER    
    MOV DH, 0DH         ; ROW       = 0xD = 13 
    CALL set_cursor     ; PROCEDURE: set_Cursor TO SET CURSOR TO PLAYER LOCATION
    ; 2. READ CHARACTER AT PLAYER
    MOV BH, 0H          ; PAGE NUMBER 0 OF VIDEO MEMORY
    MOV AH, 08H         ; FUNCTION CODE TO READ CHARACTER AT CURSOR POSITION
    INT 10H             ; INTERRUPT 
                        ; AL NOW CONTAINS CURSOR CHARACTER 
                        ; AH NOW CONTAINS CURSOR COLOR
    ; 3. CHECK CHARACTER AT PLAYER LOCATION
    CMP AL, 'R'         ; COMPARE CHARACTER AT CURSOR TO ROCK CHARACTER 'R'
                        ; CMP SETS REGISTER FLAG ZF = 1 IF REGISTER VALUES MATCH
    JE end_Program      ; JUMP TO LABEL: end_Program IF ZF = 1

    ; ********* DRAW PLAYER ********* 
    ; PLAYER CHARACTER IS '#'
    ; PLAYER COLOR IS: YELLOW
    ; PLAYER IS ALWAYS ON ROW 13 (0xD)
    ; DRAWS PLAYER ONLY IF PLAYER LOCATION DOES NOT CONTAIN A ROCK
    ; ********************************
    ; 1. MOVE CURSOR TO PLAYER LOCATION
    MOV DL, XPOS        ; COLUMN    = X-POSITION OF PLAYER    
    MOV DH, 0DH         ; ROW       = 0xD = 13 
    CALL set_cursor     ; PROCEDURE: set_Cursor TO SET CURSOR TO PLAYER LOCATION
    ; 2. DRAW PLAYER AT CURSOR LOCATION
    MOV AL, '#'         ; CHARACTER = #
    MOV BL, 0EH         ; COLOR     = 0xE = YELLOW
    CALL draw           ; PROCEDURE: draw TO DRAW PLAYER CHARACTER
    INT 10H             ; INTERRUPT

    ; ********* DELAY ********* 
    ;  WAITS 0.1 SECONDS
    ; *************************
    MOV CX, 01h         ; CX = 0x1
    MOV DX, 86A0h       ; DX = 0x86A0                
    MOV AH, 86h         ; FUNCTION CODE TO WAIT CX:DX MICROSECONDS
    INT 15h             ; INTERRUPT -> CX:DX = 0x186A0 = 100000 MICROSECONDS = 0.1 SECONDS

    ; ********* DRAW PLAYER TRAIL ********* 
    ; DRAWS A TRAIL AT THE PLAYER LOCATION 
    ; TRAIL AND PLAYER ARE DRAWN AT SAME POSITION, HOWEVER TRAIL IS DRAW AFTER SO IT RETAINS WHEN THE SCREEN SCROLLS
    ; PLAYER CHARACTER TAKES VISUAL PRECEDENCE OVER THE TRAIL CHARACTER DUE TO THE DELAY ( PLAYER CHARACTER IS ONLY VISIBILE FOR DELAY PERIOD, WHILE TRAIL CHARACTER IS VISIBLE FOR ALL OTHER TIME IN THE CODE: DELAY TIME>CODE EXECUTION TIME)
    ; **************************************
    ; 1. SET CURSOR TO PLAYER LOCATION
    MOV DL, XPOS        ; COLUMN    = X-POSITION OF PLAYER    
    MOV DH, 0DH         ; ROW       = 0xD = 13 
    CALL set_Cursor     ; PROCEDURE: set_Cursor TO SET CURSOR TO PLAYER LOCATION
    ; 2. DRAW PLAYER TRAIL
    MOV AL, 'X'         ; CHARACTER = X
    MOV BL, 0BH         ; COLOR     = 0xB = LIGHT CYAN
    CALL draw           ; PROCEDURE: DRAW TO DRAW PLAYER

    ; ********* CHECK FOR KEY PRESSES ********* 
    ; CHECKS THE INPUT STATUS FROM THE KEYBOARD FOR A KEY PRESS
    ; *****************************************
    ; 1. GET INPUT STATUS
    MOV AH, 0BH         ; FUNCTION CODE FOR GET INPUT STATUS
    INT 21H             ; INTERRUPT
                        ; AL NOW CONTAINS A VALUE:
                        ; AL = 0    IF NO CHARACTER AVAILABLE
                        ; AL = FFH  IF CHARACTER AVAILABLE
    ; 2. CHECK INPUT STATUS
    CMP AL, 0           ; CHECK FOR NO CHARACTER FROM INPUT STATUS 
    JE no_Key           ; IF NO INPUT, DO NOT MOVE PLAYER AND JUMP TO LABEL: no_Key

    ; ********* KEY PRESS ********* 
    ; MOVES THE PROGRAM TO THE APPROPRIATE MOVEMENT OPERATION BASED ON KEY PRESS
    ; ********************************
    ; 1. GET KEY CHARACTER
    MOV AH, 0H          ; FUNCTION CODE FOR READ KEYSTROKE
    INT 16H             ; INTERRUPT
                        ; AL NOW CONTAINS ASCII CHARACTER OF THE KEY PRESSED (LOWERCASE)
    ; CASE 1) 'q' PRESSED
    CMP AL, 'q'         ; COMPARE KEYSTROKE AND 'q'
    JE end_Program      ; JUMP TO LABEL: end_Program IF 'q' IS PRESSED
    ; CASE 2) 'a' PRESSED
    CMP AL, 'a'         ; COMPARE KEYSTROKE AND 'a'
    JE move_Left        ; JUMP TO LABEL: move_Left IF 'a' IS PRESSED
    ; CASE 3) 's' PRESSED
    CMP AL, 's'         ; COMPARE KEYSTROKE AND 's'
    JE move_Right       ;  JUMP TO LABEL: move_Right IF 'a' IS PRESSED

    ; ********* NO KEY PRESS ********* 
    ; DO NOT MOVE THE PLAYER IF NO KEY PRESS
    ; ********************************
    no_Key:
    ; 1. RESTART MAIN LOOP
    JMP main_Loop       ; RETURN TO LABEL: main_Loop TO PRODUCE NEXT LINE OF ROCKS

    ; ********* 'a' KEY PRESS ********* 
    ; MOVE THE PLAYER LEFT 
    ; *********************************
    move_Left:
    ; 1. MODIFY PLAYER POSITION
    CMP XPOS, 0         ; CHECK IF PLAYER POSITION IS AT THE LEFT MOST COLUMN (0)
    JE dont_DEC_XPOS    ; JUMP TO LABEL: dont_DEC_XPOS IF PLAYER X-POSITION = 0
    DEC XPOS            ; IF NOT AT X-POSITION = 0, DECREASE PLAYER X-POSITION
    dont_DEC_XPOS:
    ; 2. RESTART MAIN LOOP
    JMP main_Loop       ; RETURN TO LABEL: main_Loop TO PRODUCE NEXT LINE OF ROCKS

    ; ********* 's' KEY PRESS ********* 
    ; MOVE THE PLAYER RIGHT
    ; *********************************
    move_Right:
    ; 1. MODIFY PLAYER POSITION
    CMP XPOS, 79        ; CHECK IF PLAYER POSITION IS AT THE RIGHT MOST COLUMN (79)
    JE dont_INC_XPOS    ; JUMP TO LABEL: dont_INC_XPOS IF PLAYER X-POSITION = 79
    INC XPOS            ; IF NOT AT X-POSITION = 79, INCREASE PLAYER X-POSITION
    dont_INC_XPOS:
    ; 2. RESTART MAIN LOOP
    JMP main_Loop       ; RETURN TO LABEL: main_Loop TO PRODUCE NEXT LINE OF ROCKS

    end_Program:
    ; ********* WRITE TERMINATION STRING ********* 
    ; WRITES A TERMINATION STRING WHEN THE PLAYER COLLIDES WITH A ROCK OR WHEN 'q' IS PRESSED
    ; ES:BP = Offset of string
    ; ********************************************   
    MOV DX, @data           ; GET DATA ADDRESS
    MOV ES, DX              ; STORE DATA SEGMENT ADDRESS
    MOV BP, OFFSET msg      ; STORE msg OFFSET
    MOV AH, 13H             ; FUNCTION CODE FOR WRITE STRING
    MOV AL, 1H              ; WRITE MODE
    MOV BH, 0H              ; PAGE NUMBER 0 OF VIDEO MEMORY
    MOV BL, 0CH             ; COLOR     = 0xC   = LIGHT RED
    MOV CX, nSize           ; NUMBER OF CHARACTERS IN STRING
    MOV DH, 14H             ; ROW       = 0x14  = 20
    MOV DL, 20H             ; COLUMN    = 0x14  = 32
    INT 10H                 ; INTERRUPT

    ; ********* PROGRAM TERMINATION ********* 
    ; TERMINATES THE PROGRAM 
    ; *************************************** 
    MOV AX, 4C00H           ; FUNCTION CODE FOR PROGRAM TERMINATION
    INT 21H                 ; INTERRUPT
_MAIN ENDP
END _MAIN