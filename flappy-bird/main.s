Stack_Size       EQU     0x400;
	
				 AREA    STACK, NOINIT, READWRITE, ALIGN=3
Stack_Mem        SPACE   Stack_Size
__initial_sp

				 AREA    RESET, DATA, READONLY
                 EXPORT  __Vectors
                 EXPORT  __Vectors_End

__Vectors        DCD     __initial_sp               ; Top of Stack
                 DCD     Reset_Handler              ; Reset Handler
				 DCD	0
				 DCD	0
				 DCD	0
				 DCD	0
				 DCD	0
				 DCD	0
				 DCD	0
				 DCD	0
				 DCD	0
				 DCD	0
				 DCD	0
				 DCD	0
				 DCD	0
				 DCD	0
				 DCD	Button_Handler					 
__Vectors_End    

				 AREA    |.text|, CODE, READONLY
Reset_Handler    PROC
                 EXPORT  Reset_Handler
				 ldr	 r0, =0xE000E100
				 movs	 r4,#1	
				 str	 r4,[r0]						 
			     CPSIE	 i					 
                 LDR     R0, =__main
                 BX      R0
                 ENDP

				 AREA	 button, CODE, READONLY
Button_Handler	 PROC
				 EXPORT	 Button_Handler
				
				 ldr	 r0, =0x40010010
				 ldr	 r1,[r0]
				 movs    r3, r1
				 movs	 r2,#0xFF
				 ands	 r1,r1,r2
				 cmp	 r1,#0			
				 beq	 release
				 cmp 	 r1, #16			; Check if the button is pressed to the up button
				 beq 	 up_button			; Go to label up_button
				 str	 r3,[r0]
				 bx		 lr

up_button	     STR 	 R3, [R0]			; Reset the button addresses to initial
				 SUBS 	 R7, R7, #15		; Increase the TOP BORDER value of the bird by 15
				 SUBS 	 R5, R5, #15		; Increase the BOTTOM BORDER value of the bird by 15
				 bx 	 lr 				; Go back to code were it left
		


release			 str	 r3,[r0]
			     bx      lr
		 
				 
				 
                 AREA    main, CODE, READONLY
                 EXPORT	 __main			 	;make __main visible to linker
                 IMPORT  image			 	; IMPORT game map photo
											; The image.c file is our map
											; And it's size is 160x240
											; We are reapeting our image 2 times
											; First between the 0-160 columns
											; and second between the 160-320 columns
										 
				 IMPORT	 bird			 	; IMPORT bird photo
											; The bird.c file is our bird img
											; It's size is 10x10
											; In draw_char loop we are drawing the image to the lcd

				 ENTRY
__main           PROC
                 
	 				 
				 LDR     R0, =0x40010000	 ;LCD base address
                 MOVS    R7, #120            ;TOP border of bird
				 MOVS	 r5, #130			 ;BOTTOM border of bird
                 MOVS    r4, #10             ;LEFT border of bird
				 MOVS	 r6, #20			 ;RIGHT border of bird
				 
				 
				 push	 {r4}			     ; We store the data of R4 register in stack
											 ; thus we can use the R4 register for data transfer
											 ; The R4 register will hold the max_col that we draw the image
											 ; First the R4 register will hold the COL = 160 value
											 ; and we will draw the image between 0-160 columns
											 ; Then r4 will hold 320 and we draw the image again between 160-320 columnsn
											 
											 ;---- 1-STACK: [R4]
											 
draw_map		 
				 	
				 movs	 r4,  #160			 ; Give the max_col value to R4 register
				 
draw_from_160_col						
				 LDR	 r2, =image			 ; R2 register holds the first address of the map
				 			 
				 MOVS    r3, #0				 ; R3 regsiter holds the ROW COUNTER 	 
draw_rows		 CMP	 r3, #240		 	 ; Compare the row counter with 240 
				 BHS 	 row_end			 ; if it is equal or higher go to row_end label		 	 
				 push	 {r4}				 ; Push the R4 register's value to stack thus,
											 ; we can use R4 for data transfer
											 ;---- 2-STACK: [R4-R4]
				 subs	 r4, r4, #160        ; Substitute 160 from R4 register. With that
											 ; we can get our column counter value
				 
				 MOVS 	 r1, r4			 	 ; The R1 register will hold the COLUMN COUNTER
				 pop	 {r4}				 ; Get the max column value from stack and save it in R4 register
											 ; By doing that we are saving our max column value for draw the image
											 ;---- 3-STACK: [R4]
draw_cols		 CMP	 r1, r4	 	 	 	 ; Compare the COLUMN COUNTER (R1) with max column (R4 -> 160 or 320)
				 BHS     col_end		 	 ; If it is equal or higher it means we reached to the last column 
											 ; Go to the col_end label
				 STR 	 r3, [R0]			 ; Store the ROW COUNTER (R3) value to ROW addres of LCD
				 STR  	 r1, [R0, #0x4]	     ; Store the COLUMN COUNTER (R1) value to COLUMN address of LCD
				 push	 {r1,r3}			 ; For draw the image we should change the RGBA order -> ARGB
											 ; And for the change process we will use the R1 & R3 register.
											 ; That's why we are pushing the values of R1 (ROW COUNTER) & R3 (COLUMN COUNTER) values
											 ; for saving the counters value
											 ;---- 4-STACK: [R1-R3-R4]
				 
				 ldr	 r1, [r2]			 ; Load the image addres to the R1 register
				 rev	 r1, r1				 ; Reverse the R1 register thus we get RGBA->ABGR
				 movs	 r3, #8				 ; For getting the ARGB order we should rotate our image 8bit
				 rors	 r1, r1, r3			 ; Rorate the ABGR-> ARGB thus we get the correct order of the color
				 STR 	 r1, [R0, #0x8]      ; Store the color to the color address
				 adds	 r2, r2, #4	    	 ; Move next pixel of the map
				 pop	 {r1}				 ; Get back the COLUMN COUNTER value
											 ;---- 5-STACK: [R3-R4]
				 pop	 {r3}				 ; Get back the ROW COUNTER value
											 ;---- 6-STACK: [R4]
				 ADDS    r1, r1, #1		     ; Increment the COLUMN COUNTER by 1
				 B 		 draw_cols			 ; Go to the draw_cols label.
											 ; This is for drawing one row of the image 
col_end			 ADDS 	 r3, r3, #1			 ; Now a row is finished so we need to start from the next
											 ; Increment the ROW COUNTER by 1
				 B 	     draw_rows			 ; Go to the draw_rows label
row_end			 							 ; At this point we drawed all pixels of our image
											 
				movs	 r0, r4				 ; R4 was holding the max column value
											 ; We need to keep the max column value for draw the second part of the image
											 ; But in draw_char label we will draw our bird
											 ; And at the top of the code R4 register was holding the
											 ; LEFT BORDER value of the bird
											 ; So for keeping the max column value we move the R4 value to R0 register
				 
				 pop 	 {r4}				 ; Get back the LEFT BORDER value to R4 register
											 ;---- 7-STACK: []
				 push    {r1-r3}	     	 ; We use the R1-R2-R3 registers in draw_char for drawing the bird
											 ; To not lose the values of the R1,R2,R3 registers value we push them to stack
											 ;---- 8-STACK: [R1-R2-R3] 
				 bl		 draw_char			 ; Go to label draw_char and start draw the bird	
				 push	 {r4}				 ; We push the R4 register to the stack and we did not touch the LEFT BORDER value
											 ; Thus we can use is for data transfer
											 ;---- 21-STACK: [R4] 
				 
				 movs	 r4, r0				 ; At the line 240 in the draw_char loop we saved the max column value to the R0
											 ; Now we are storing it back to the R4 register
				 MOVS	 r1, #1				 ; Move 1 to the R1 register for screen refreshing
				 ldr	 r0,=0x40010000		 ; Load the R= register with the base address of lcd
				 STR     r1, [R0, #0xC]	 	 ; Refresh the screen
				 cmp	 r4, #160	   		 ; Compare the max column value (R4) with 160
				 beq	 change_col_start	 ; If it is equal that means we drew the first part of the image
											 ; And go to the change_col_start label
				 b 	 	 draw_map			 ; If not that means we are drawing the first part image and 
											 ; go to the draw_map label

change_col_start 
				 adds	 r4, r4, #160		 ; Change the max_column value to 320
											 ; Thus we can draw the second part of the image
				 b 		 draw_from_160_col	 ; Go to the draw_from_160_col label and start to draw the second part of the image
											 ; from 160-320 columns

draw_char		 
				 movs	 r2, r0			     ; The R0 register is holding our max column value
											 ; And we are moving the max column value to the R2 register 
											 ; Thus we can use our R0 register
				 ldr	 r0, =bird			 ; The R0 register will hold the first address of the bird image
				 movs	 r1, r4				 ; Move the LEFT BORDER value (R4) to the R1 (COLUMN COUNTER) register
				 movs	 r3, r7				 ; Move the TOP BORDER value (R7) to  the R3 (ROW COUNTER 
char_row		 cmp	 r3, r5				 ; Compare the row counter value with BOTTOM BORDER value of the bird
				 bhs	 char_row_end	     ; If it is equal or high that means we finished the drawing of the bird 
											 ; and go to the char_row_end label
				 movs	 r1, r4			     ; Move again the LEFT Border value (R4) to the R1 (COLUMN COUNTER) register
char_col		 cmp	 r1, r6				 ; Compare the column counter value with RIGHT BORDER value of the bird
				 bhs	 char_col_end		 ; IF it is equal or hight that means we finished the draing of the one row of the bird
				 push	 {r0}			     ; The R0 register was holding the first address of bird image
											 ; To use the R0 register for data transfer
											 ; We push the R0 (bird image address) to the stack thus we can get it back
											 ;---- 9-STACK: [R0-R1-R2-R3]
				 LDR     R0, =0x40010000	 ; Load the base address of LCD to the R0 register
				 str	 r3, [r0]		     ; Store the ROW COUNTER value to the row address of LCD
				 str	 r1, [r0, #0x4]	     ; Store the COLUMN COUNTER value to the column address of LCD
				 pop	 {r0}				 ; Get back the bird image addres to the R0 register
											 ;---- 10-STACK: [R1-R2-R3]
				 push	 {r1}				 ; To use R1 (COLUMN COUNTER) register for data transfer
											 ; We push it to the stack
											 ;---- 11-STACK: [R1-R1-R2-R3]
				 movs	 r1, r2				 ; R2 register was holding our max column value and we move it to the R1 register
				 push	 {r1,r3}			 ; Push again the R1 & R3 register to the stack 
											 ; Thus we can use both of them to get the correct form of the bird image color
											 ;---- 12-STACK: [R1-R3-R1-R1-R2-R3]
				 ldr	 r1, [r0]			 ; Load the bird image pixel values to R1
				 rev	 r1, r1			     ; Reverse R1
				 movs	 r3, #8				 ; For rotate the R1 8 bit we store the 8 value in R3 register
				 rors	 r1, r1, r3			 ; Rotate the R1 register 8 bit
				 push	 {r0}				 ; Push the image address (R0) to the stack and we will get it back
											 ; after we stored our color to the color address of LCD
											 ;---- 13-STACK: [R0-R1-R3-R1-R1-R2-R3]
				 LDR     R0, =0x40010000	 ; Get base address of LCD
				 STR 	 r1, [R0, #0x8]      ; Store the color to the color address
				 pop	 {r0}				 ; Get back the image address to the R0 register
											 ;---- 14-STACK: [R1-R3-R1-R1-R2-R3]
				 adds	 r0, r0, #4			 ; Get the next pixel color of the bird image
											 ; In line 212 we pushed the R1 & R3 for usind them in data transfer
				 pop	 {r1}				 ;Now we are taking back the R1 (max column value of the map) and
											 ;---- 15-STACK: [R3-R1-R1-R2-R3]
				 pop	 {r3}				 ; The R3 (ROW COUNTER) value of the map image
											 ;---- 16-STACK: [R1-R1-R2-R3]
				 movs	 r2, r1				 ; We move the R1 register (max column value of map) value to the R2 register	 
				 pop	 {r1}				 ; In line 208 we pushed the R1 register value and now we taking back it (COLUM COUNTER of bird)
											 ;---- 17-STACK: [R1-R2-R3]
				 adds	 r1, r1, #1			 ; Increment the COLUMN COUNTER of the bird 
				 b		 char_col			 ; Go to the label char_col and start drawing from the next column
char_col_end	 adds	 r3, r3, #1			 ; Increment the ROW COUNTER of the bird
				 b		 char_row			 ; Go to the label char_row and start drawing from the next row
char_row_end	 
				 movs	 r0, r2				 ; R2 register was holding the max column value  of the map and we move it to the R0 register
				 
				 pop     {r1}				 ; R1 register was holding the COLUMN COUNTER of the map and we move it to the R0 register
											 ;---- 18-STACK: [R2-R3]
				 	 
				 pop	 {r2}				 ; R2 register was holding the BASE ADDRES of the MAP image and we are taking it back to R2
											 ;---- 19-STACK: [R3]
				 pop	 {r3}				 ; R3 register was holding the ROW COUNTER of the MAP and we are taking it back to R3
											 ;;---- 20-STACK: []
				 
				 
				 
											 ; After drawed our bird we should move the bird down & right
											 ; We are moving our bird 2 pixel down & 1 pixel right in every loop
											 ; For moving the bird DOWN we should increase the TOP & BOTTOM border value
				 							 ; For moving the bird RIGHT we should increase the LEFT & RIGHT border value

				 B		 check_wall			 ; We are checking the LEFT SIDE BORDER with the map columns
											 ; We could not determine how we can do it dynamically
											 ; Thus we made the compare with static values
											 ; At least we wanted to implement an end game screen
											 
walls_ok		 ADDS	 r7, r7, #2			 ; Increase the TOP BORDER value of the bird by 2
				 ADDS	 r5, r5, #2			 ; Increase the BOTTOM BORDER value of the bird by 2
				 ADDS	 r4, r4, #1			 ; Increase the LEFT BORDER value of the bird by 1
				 ADDS	 r6, r6, #1			 ; Increase the RIGHT BORDER value of the bird by 1
				 bx		 lr				     ; Return to code of the main were it was left
                 
											 ;We use the position of the pillars to check the game loss-win status. 
											 ;We check_col_n function when the bird lands on the left edge of the pillars.
											 ;If the bird is higher than the upper pillar or lower than the lower pillar when it comes to the left side of the column,
											 ;it means that it has collide.											 
check_wall		 CMP 	R6, #43				 ;For example, pixel 43 corresponds to column 2 of mine. Proceed to the check_col_1 function.
				 BEQ 	check_col_1			 
col_1_ok		 CMP 	R6,	#78				 
				 BEQ 	check_col_2			
col_2_ok		 CMP 	R6, #112
				 BEQ 	check_col_3
col_3_ok		 CMP 	R6, #147
				 BEQ	check_col_4
col_4_ok		 CMP  	R6, #203
				 BEQ 	check_col_5
col_5_ok		 CMP 	R6, #238
				 BEQ 	check_col_6
col_6_ok	 	 PUSH	{R2}			 	 ;We temporarily PUSH {R2} to store the value 320.
				 LDR 	R2, =272
				 CMP 	R6, R2
				 BEQ	check_col_7
col_7_ok		 LDR 	R2, =307
				 CMP    R6, R2
				 BEQ  	check_col_8
col_8_ok		 LDR 	R2, =320		 	 ;If we can read the value 320, it means that bird have reached the right edge of this screen. 
				 CMP 	R6, R2			 	 ;It has not hit any column so far and it means we've won the game.
				 BEQ 	win			
				 POP	{R2}
				 CMP 	R6, #169
				 BEQ 	check_col_middle				 
col_middle_ok	 b 	  	walls_ok	
	
	
check_col_1		 CMP 	R5, #125			 ;If the bird is smaller than 125 and larger than 77, it means I am passing through these columns. Everything is OK.
				 BHS 	gameover			
				 CMP 	R5, #77
				 BLS 	gameover
				 b	    col_1_ok			 ;If it passes, it goes back to the game condition function to check the next column.
check_col_2		 CMP 	R5, #129
				 BHS 	gameover	
				 CMP 	R5, #81
				 BLS 	gameover
				 b	    col_2_ok
check_col_3		 CMP 	R5, #146
				 BHS 	gameover	
				 CMP 	R5, #98
				 BLS 	gameover
				 b	    col_3_ok
check_col_4		 CMP 	R5, #185
				 BHS 	gameover	
				 CMP 	R5, #137
				 BLS 	gameover
				 b	    col_4_ok
check_col_5		 CMP 	R5, #125
				 BHS 	gameover	
				 CMP 	R5, #77
				 BLS 	gameover
				 b	    col_5_ok
check_col_6		 CMP 	R5, #129
				 BHS 	gameover	
				 CMP 	R5, #81
				 BLS 	gameover
				 b	    col_6_ok
check_col_7		 CMP 	R5, #146
				 BHS 	gameover	
				 CMP 	R5, #98
				 BLS 	gameover
				 b	    col_7_ok
check_col_8		 CMP 	R5, #185
				 BHS 	gameover	
				 CMP 	R5, #137
				 BLS 	gameover
				 b	    col_8_ok
check_col_middle CMP 	R5, #142
				 BHS 	gameover	
				 CMP 	R5, #94
				 BLS 	gameover
				 b	    col_middle_ok





; This win label changes the color to GREEN which we will use at the end_game drawing
win			 	LDR R4,=0xFF00FF00		;Store the green color in R4 register
				BL end_game				;Call end_game function
				B finish_code			; Got to finish_code label
				
; This gameover label changes the color to RED which we will use at the end_game drawing
gameover		LDR R4,=0xFFFF0000		;Store the red color in R4 register
				BL end_game				;Call end_game function
				B finish_code			; Got to finish_code label


; The end_game function only paints the whole screen to a color which is determined above

end_game 		
				LDR R0, =0x40010000		; Base address of LCD
				
				MOVS R6, #0				; Column counter
				LDR R7, =320			; Max column number
				MOVS R5, #0				; Row counter
end_draw_rows 	CMP R5, #240			; Compare the row counter with 240 which is maximum row number
				BHS end_row_end			; When we reached at the last row go to end_row_end
				MOVS R6, #0				; Reset the column counter to 0
end_draw_cols 	CMP R6, R7				; Compare the column counter with max column number
				BHS end_col_end			; If it is equal or high go to end_col_end label
				STR R5, [R0]		    ; Store the row counter value to LCD row address
				STR R6, [R0, #0x4]		; Store the column counter value to LCD column address
				STR R4, [R0, #0x8]		; Store the color value to LCD color address
				ADDS R6, R6, #1			; Increment the column counter by 1
				B end_draw_cols			; Go to end_draw_cols label
end_col_end 	ADDS R5, R5, #1			; Increment the row counter by 1
				B end_draw_rows			; Go to end_draw_rows label
end_row_end 	MOVS R6, #1				; The R6 register will hold the value 1 which we will use in refreshing the LCD
				STR R6, [R0, #0xC]		; Refresh the lcd
				BX LR					; Go back to code were it left

finish_code								; END CODE

                 ENDP
                 END