.section .init

.globl drawBeeBody 	//has 9 vertical stripes of equal size upon the body
			// base stripe size is currently 10 pixels
			// base bee height is currently 90 pixels
			// r0, top left x
			// r1, top left y
			// r2, size multiplier (will be included in a shift operation, ex: 2^r2)
			// [sp], non-black colour
.globl drawBeeK
.globl drawBeeP
.globl drawBeeQ
.globl drawBeeSting
.globl drawBeeWings
.globl drawBG		//fills in the entire screen with a colour
			//r0 is that colour
.globl drawBush
.globl drawCursor 	//draws triangle cursor for use on pause menu always faces right
			// r0 is x location
			// r1 is y location
			// (x,y) is the rightmost point
.globl drawDiamond
.globl drawGameOverScreen
.globl drawLazer
.globl drawLine
.globl drawPixel	// draws a pixel at location (x,y)
			// r0 is x
			// r1 is y
			// r2 is colour
.globl drawPlayer
.globl drawPauseScreen	//the pause screen (colours currently unselected)
			//r0 indicates 0 (Resume), 1 (Restart Game), or 2 (Quit)
.globl drawRect		//draws a rectangle when given the top left point (x,y) 
			// where the right/left sides have length lenY and the top/bottom sides have length lenX
			// in order on stack: {x,y,colour,lenX,lenY}
.globl drawRectB 	//rectangle with border
			// r0 is x location
			// r1 is y location
			// r2 is borderwidth
			// [sp] is bordercolour
			// [sp+4] is main rectangle colour
			// [sp+8] is length (x-dist)
			// [sp+12] is width (y-dist)
.globl drawTriangleUp
.globl drawTriangleDown
.globl drawTriangleLeft
.globl drawTriangleRight
.globl drawVictoryScreen
.globl refreshGameScreen
.globl setBeeStingerSize
.globl setLazerDirection
.globl setPlayerSize

.section .text

drawPixel: //r0 is assumed to be the x location, r1 is assumed to be the y location, r2 is assumed to be the colour data
	
	cmp    r0,    #1024                  //check max x
	bge    endDrawPixel                  //
	cmp    r0,    0                      //check min x
	blt    endDrawPixel                  //
	cmp    r1,    #768                   //check max y
	bge    endDrawPixel                  //
	cmp    r1,    0                      //check min y
	blt    endDrawPixel                  //
	
	mul    r1,    #1024                  //row-major
	add    r0,    r1                     //
	lsl    r0,    #4                     //16-bit colour assumed
	ldr    r1,    =frameBufferPointer    // should get frameBuffer location from file that contains frameBuffer information
	ldr    r1,    [r1]                   //
	add    r1,    r0                     // add offset
	strh   r2,    [r1]                   // stores the colour into the FrameBuffer location
endDrawPixel:
	bx     lr                            // branch to calling code

drawBG: //r0 is the colour to set the background to
	push {r3-r5}
	mov	r5, r0 	      //colour
	mov	r3, #0        //row number
	rowBGloops:
	cmp	r3, #1024     //compare row number with 1024
	bge	rowBGloope    // end if row number >= 1024
	mov	r4, #0        //column number
	colBGloops:
	cmp	r4, #768      //compare column number with 768
	bge	colBGloope    //end if column number >= 768
	mov	r0, r3	      //set x to draw
	mov	r1, r4        //set y to draw
	mov	r2, r5        //set colour to draw
	bl	drawPixel     //draw current pixel
	add	r4, #1	      //increment column
	b	colBGloops    //back to start of column loop
	colBGloope:
	add	r3, #1        // increment row
	b	rowBGloops    //back to start of row loop
	rowBGloope:
	pop {r3-r5}           //restore registers
	bx	lr	      //branch to calling code
	
drawRect: // in order on stack: {x,y,colour,lenX,lenY}
	push {r3,r4,r5,r6,r7,r8} //save registers
	ldr   r7, [sp,#24] // x
	ldr   r8, [sp,#28] // y
	ldr   r2, [sp,#32] // colour
	ldr   r3, [sp,#36] // lenX
	ldr   r4, [sp,#40] // lenY
	mov   r5, #0       // i=0
	dRFL1s:
	cmp	  r5, r3   // compare i and lenX
	bge	  dRFL1e   // if i>= lenX, the for loop ends
	mov   r6, #0       // j=0
	dRFL2s:
	cmp   r6, r4       // compares j with lenY
	bge   dRFL2e	   // if j >= lenY, the loop ends
	add   r0, r7, r5   // stores x+i in r0
	add   r1, r8, r6   // stores y+j in r1
	bl     drawPixel   // calls drawPixel
	add   r6, #1       // increments j
	b     dRFL2s       // back to the start of column iterating loop
	dRFL2e:
	add   r5, #1       // increments i
	b     dRFL1s       // back to the start of row iterating loop
	dRFL1e:
	pop {r3,r4,r5,r6,r7,r8} // restore registers
	bx	lr         //branch to calling code
	
	
drawLine: //takes thickness as a parameter, vertical/horizontal/diagonalU/diagonalD as parameters
	push  {r3-r10}     // save registers
	ldr   r0, [sp,#32] // x
	ldr   r1, [sp,#36] // y
	ldr   r2, [sp,#56] // colour
	ldr   r3, [sp,#48] // length
	ldr   r4, [sp,#52] // thickness
	ldr   r5, [sp,#44] // direction
	sub   r6, r4, #1   // stores thickness - 1 into r6
	lsr   r6, #1 	   // stores (thickness-1)/2 into r6 (a)
	mov   r7, #0       // i
	mov   r8, r0       // x (constant)
	mov   r9, r1       // y (constant)
	dLFL1s:
	cmp   r7, r3       // compares i with length
	bge   dLFL1e       // end loop if i >= length
	mov   r0, r8       // store x in r0
	mov   r1, r9       // store y in r1
	bl    drawPixel    // draws pixel in (x,y) with colour r2
	cmp   r4, #1       // compares thickness with 1
	ble   afterif1     // if thickness <= 1, end loop
	and   r0, r5, #2   // store direction & 0x0010 into r0
	lsr   r0, #1       // store r0/2 into r0
	and   r1, r5, #4   // store direction & 0x0100 into r1
	lsr   r1, #2       // store r1/4 into r1
	orr   r0, r1       // set the first bit to be one in r0 if it is so in either r0 , r1
	ldr   r1, =0xFFFFFFFE
	bic   r0, r1       // clears every bit in r0 excluding the first bit
	cmp   r0, #1       // checks if either bit 1 or bit 2 of direction is 1
	bne   afterif1     // if neither are 1, go to the else portion
	sub   r0, r8, r6   // stores x - a in r0
	mov   r1, r9       // stores y in r1
	mov   r10, #1      // stores 1 in r10
	push {r0,r1,r2,r6,r10} // push required parameters onto the stack
	bl     drawRect    // call drawRect
	pop {r0,r1,r2,r6,r10} // remove parameters from stack
	mov    r0, r8      // store x in r0
	push {r0,r1,r2,r6,r10} // push required parameters onto the stack
	bl     drawRect     // call drawRect
	pop {r0,r1,r2,r6,r10}  // remove parameters from stack
	afterif1:          // after thickness for horizontal
	and   r0, r5, #1    // 
	cmp   r0, #1
	bne   afterif2      // if (direction & 1) != 1, go to else 
	cmp	  r4, #1
	ble   afterif3      // if thickness <= 1, go to else
	push  {r4}
	mov   r0, #1
	push  {r0}
	push  {r2}
	mov   r0,r8
	sub   r1,r9,r4
	push  {r0,r1}
	bl     drawRect	    //vertical above-line thickness
	pop  {r0,r1}
	pop  {r0,r1}
	pop   {r0}
	push  {r4}
	mov   r0, #1
	push {r0}
	mov   r0, r8
	mov   r1, r9
	push {r0,r1,r2}
	bl     drawRect	      //vertical below-line thickness
	pop {r0,r1}
	pop {r0,r1}
	pop {r0}
	afterif3:             //after thickness for vertical line
	add   r8, #1
	afterif2:
	tst  r5, #2
	bne  ifpart2          // direction & 2 != 1
	add  r9, #1	      // increment y
	ifpart2:
	tst r5, #4
	bne  afterif4        // direction & 4 != 1
	sub  r9, #1          // decrement y
	afterif4:
	add  r7, #1
	b    dLFL1s
	dLFL1e:	
	pop {r3-r9}           // restore registers
	bx	lr           // branch to calling code


drawTriangleUp: //r0 is x, r1 is y, r2 is height, colour is sent over stack
push {r3-r8}
mov	r3, r0       //x
mov	r4, r1       //y
mov	r5, r2       // height
ldr	r6, [sp,#24] //colour
mov	r7, #0       // i
dtufl1start:         //draw triangle up for loop 1 start
cmp	r7, r5       
bge	dtufl1end   
push	 {r6} 	     //push 6th paramter, colour onto stack
mov	r0, #1
push	 {r0} 	     //push 5th parameter, thickness (1) onto stack
add	r0, r7, r7
add	r0, #1
pus	 {r0}	     //push 4th parameter, length (2i+1) onto stack
mov	r0, #1
push 	{r0}	     //push 3rd parameter, direction (1)(horizontal) onto stack
add	r0, r4, r7
push 	{r0}	     //push 2nd paramteter, (y+i) onto stack
sub	r0, r3, r7
push    {r0}	     //push 1st paramter, (x-i) onto stack
bl	drawLine
add	sp, #24
add	r7, #1
b	dtufl1start
dtufl1end:
pop    {r3-r8}
bx	lr


drawTriangleDown: //r0 is x, r1 is y, r2 is height, colour is sent over stack
push {r3-r7}
mov	r3, r0 //x
mov	r4, r1 //y
mov	r5, r2 // height
ldr	r6, [sp,#20] //colour
mov	r7, #0 // i
dtdfl1start: //draw triangle down for loop 1 start
cmp	r7, r5
bge	dtdfl1end
push {r6} 	//push 6th paramter, colour onto stack
mov	r0, #1
push {r0} 	//push 5th parameter, thickness (1) onto stack
add	r0, r7, r7
add	r0, #1
push {r0}	//push 4th parameter, length (2i+1) onto stack
mov	r0, #1
push {r0}	//push 3rd parameter, direction (1)(horizontal) onto stack
sub	r0, r4, r7
push {r0}	//push 2nd paramteter, (y-i) onto stack
sub	r0, r3, r7
push {r0}	//push 1st paramter, (x-i) onto stack
bl	drawLine
add	sp, #24
add	r7, #1
b	dtdfl1start
dtdfl1end:
pop {r3-r7}
bx	lr


drawTriangleLeft: //r0 is x, r1 is y, r2 is height, colour is sent over stack
push {r3-r7}
mov	r3, r0 //x
mov	r4, r1 //y
mov	r5, r2 // height
ldr	r6, [sp,#20] //colour
mov	r7, #0 // i
dtlfl1start: //draw triangle left for loop 1 start
cmp	r7, r5
bge	dtlfl1end
push {r6} 	//push 6th paramter, colour onto stack
mov	r0, #1
push {r0} 	//push 5th parameter, thickness (1) onto stack
add	r0, r7, r7
add	r0, #1
push {r0}	//push 4th parameter, length (2i+1) onto stack
mov	r0, #2
push {r0}	//push 3rd parameter, direction (2)(vertical) onto stack
add	r0, r4, r7
push {r0}	//push 2nd paramteter, (y+i) onto stack
add	r0, r3, r7
push {r0}	//push 1st paramter, (x+i) onto stack
bl	drawLine
add	sp, #24
add	r7, #1
b	dtlfl1start
dtlfl1end:
pop {r3-r7}
bx	lr

drawTriangleRight: //r0 is x, r1 is y, r2 is height, colour is sent over stack
push {r3-r7}
mov	r3, r0 //x
mov	r4, r1 //y
mov	r5, r2 // height
ldr	r6, [sp,#20] //colour
mov	r7, #0 // i
dtrfl1start: //draw triangle right for loop 1 start
cmp	r7, r5
bge	dtrfl1end
push {r6} 	//push 6th paramter, colour onto stack
mov	r0, #1
push {r0} 	//push 5th parameter, thickness (1) onto stack
add	r0, r7, r7
add	r0, #1
push {r0}	//push 4th parameter, length (2i+1) onto stack
mov	r0, #2
push {r0}	//push 3rd parameter, direction (2)(vertical) onto stack
add	r0, r4, r7
push {r0}	//push 2nd paramteter, (y+i) onto stack
sub	r0, r3, r7
push {r0}	//push 1st paramter, (x-i) onto stack
bl	drawLine
add	sp, #24
add	r7, #1
b	dtrfl1start
dtrfl1end:
pop {r3-r7}
bx	lr

drawDiamond:
//r0 is x, r1 is y, r2 is height
//[sp] is colour
// (x,y) is the topmost point of the diamond
push {r3-r6}    //save registers to restore after use
mov	r3, r0  // x
mov	r4, r1  // y
lsr	r2, #1  // divide height in half
mov	r5, r2  // height/2
ldr	r6, [sp,#16] // colour
push {r6}	//push colour onto the stack
bl	drawTriangleUp //draw the top half of the diamond
add	sp, #4  //remove colour off the stack
add	r4, r5  
add	r4, r5  //add the full height to the y coordinate
mov	r0, r3  //set x for drawing
mov	r1, r4  // set y for drawing
mov	r2, r5  // set height for drawing
push {r6}	//push colour onto the stack
bl	drawTriangleDown //draw the bottom half of the diamond
add	sp, #4  //remove colour off the stack
pop {r3-r10}	//restore registers
bx	lr	//branch to calling code

drawBeeBody:
	// r0, top left x
	// r1, top left y
	// r2, size multiplier (will be included in a shift operation, ex: 2^r2)
	// [sp], non-black colour
	// nine-striped bees
	push {r3-r8}	     // save registers
	mov	r8, r2       // number of times to multiply size by 2
	mov	r3, r0       // x
	mov	r4, r1       // y
	mov	r5, #0       // stripe counter initialization
	ldr	r6, =beeBlackColour
	ldr	r6, [r6]     //black colour
	ldr	r7, [sp,#24] //other colour
	startStripBeeLoop:
	cmp	r5, #10
	bge	endStripBeeLoop
	mov	r0, #10        // init stripe xlength
	lsl	r0, r8        // adjust stripe xlength
	mov	r1, #90       // init bee height
	lsl	r1, r8        // adjusted bee height
	push {r1}              //push p4
	push {r0}              //push p3
	tst	r5, #1
	bne	stripecolourelse
	push {r6}              //push p2
	b 	stripecolourafterif
	stipecolourelse:
	push {r7}              //push p2
	stripecolourafterif:
	push {r4}              //push p1
	push {r3}              //push p0
	bl	drawRect
	add	sp, #20       //remove parameters from stack
	add	r5, #1        //increment stripe counter
	endStripBeeLoop:
	pop {r3-r8}	      // restore registers
	bx	lr	      // branch to calling code

drawRectB: //rectangle with border
	// r0 is x location
	// r1 is y location
	// r2 is borderwidth
	// [sp] is bordercolour
	// [sp+4] is main rectangle colour
	// [sp+8] is length
	// [sp+12] is width
	push {r3-r10}
	mov	r3, r0 // x
	mov	r4, r1 // y
	mov	r5, r2  //border width
	ldr	r6, [sp,#44] // overall width
	mov	r0, r6
	sub	r0, r5
	sub	r0, r5
	push {r0}
	ldr	r7, [sp,#40] //overall length
	sub	r0, r7, r5
	sub	r0, r5
	push {r0}
	ldr	r0, [sp,#36] //main rectangle colour
	push {r0}
	add	r0, r4, r5
	push {r0}
	add	r0, r3, r5
	push {r0}
	bl	drawRect	//draws center rectangle
	add	sp, #20
	push {r5, r6}
	ldr	r8, [sp,#32]     //border colour
	push {r8}
	push {r3,r4}
	bl	drawRect	//draws left portion of border
	add	sp, #20
	push {r5}
	push {r7,r8}
	push {r3,r4}
	bl	drawRect	//draws top portion of border
	add	sp, #20
	push {r6}
	push {r5}
	push {r8}
	push {r4}
	add	r0, r3, r7
	sub	r0, r5
	push {r0}
	bl	drawRect	// draws right portion of border
	add	sp, #20
	push {r5}
	push {r7}
	push {r8}
	add	r0, r4, r6
	sub	r0, r5
	push {r0}
	push {r3}
	bl	drawRect	// draws bottom portion of border
	add	sp, #20
	pop {r3-r10}
	bx	lr
	

drawBeeWings: //very boxy wings
	//r0 is x location
	//r1 is y location
	//r2 is size (square-ish)
	push 	{r3-r6}
	mov	r3, r0 //x
	mov	r4, r1 //y
	mov	r5, r2 //size
	ldr	r6, =beeWingColour
	ldr	r6, [r6] //colour
	push    {r5}
	push    {r5}
	push    {r6}
	push 	{r4}
	push 	{r3}
	bl	drawRect //main wing
	add	sp, #20
	sub	r4,#1
	push 	{r6}
	mov	r0, #1
	push 	{r0}
	sub	r1,r2,#2
	push 	{r1}
	push 	{r0}
	add	r1,r3,#1
	sub	r0,r4,#1
	push 	{r0,r1}
	bl	drawLine  //hint of wing-curve
	add	sp, #24
	pop 	{r3-r6}
	bx	lr
	
drawBeeEye:
	//r0 is x
	//r1 is y
	push	{r4-r10}	//make room for local registers
	sub	sp, #8 		//make room for two local variables on the stack
	mov	r4, #13		//default inner eye length
	mov	r5, #26		//default outer-eye length
	mov	r6, #20	 	//default inner-eye width
	mov	r7, #40 	//default outer-eye width
	mov	r8, #0		//default inner-eye colour
	ldr	r9, =0xFFFFFFF	//default outer-eye colour
	str	r0, [sp,#4]	//saves x as a local variable (sp+4)
	str	r1, [sp]	//saves y as a local variable (sp)
	push	{r5,r7}		//push lenX, lenY onto stack
	push	{r0,r1,r9}	//push x,y,colour onto stack
	bl	drawRect	//draws outer-eye
	add	sp, #20		//removes paramters of outer-eye off of the stack
	ldr	r0, [sp,#4]	//load x from local storage
	lsl	r7, #2		//divide outer length by 4
	add	r0, r7		//add (oLen/4) to x
	str	r0, [sp, #4]	//save the changes to x
	ldr	r1, [sp]	//load y from local storage
	lsl	r5, #2		//divide outer width by 4
	add	r1, r5		//add (oWid/4) to y
	str	r1, [sp]	//save changes to y
	ldr	r0, [sp, #4]	//load x from the stack
	ldr	r1, [sp]	//load y from the stack
	push	{r4,r6}		//push lenX, lenY onto the stack
	push	{r0,r1,r8}	//push x,y,colour onto the stack
	bl	drawRect	//draw the inner-eye (pupil)
	add	sp, #20		//remove parameters left on stack
	add	sp, #8		//remove local variables from the stack
	pop	{r4-r10}	//restore original registers
	bx	lr		//branch to calling code
	

drawBeeP: //draws pawn bee (top left)
	// r0 is the x location
	// r1 is the y location
	push 	{r3-r10}
	mov	r2, #0
	ldr	r3, =beeYellowColour
	ldr	r3, [r3]
	push 	{r3}
	mov	r4, r0 //top-left x
	mov	r5, r1 // top-left y
	bl	drawBeeBody //draw bee body
	add	sp, #4
	mov	r6, r4
	add	r6, #90 //add in bee body width (will probably need to be changed later)
	sub	r6, #5 //breathing room
	ldr	r7, =wingLength
	ldr	r7, [r7]
	sub	r6, r7
	mov	r0, r6
	mov	r1, r5
	add	r1, #15 //more natural looking wings
	mov	r2, r7	//store wingLength so it may be used by drawBeeWings
	bl	drawBeeWings	//call drawBeeWings
	add	r0, r4, #12	// make the drawing position for the bee's eye (x)
	add	r1, r5, #7	// make the drawing position for the bee's eye (y)
	bl	drawBeeEye	// draw the bee's eye
	//now both body and wings are drawn along with the eye
	pop 	{r3-r10}	//restore registers
	bx	lr		//branch to calling code

drawBeeK: //draws knight bee
	//draws knight bee (top left)
	// r0 is the x location
	// r1 is the y location
	push 	{r3-r10}
	mov	r2, #1
	ldr	r3, =beeRedColour
	ldr	r3, [r3]
	push 	{r3}
	mov	r4, r0 //top-left x
	mov	r5, r1 // top-left y
	bl	drawBeeBody //draw bee body
	add	sp, #4
	mov	r6, r4
	add	r6, #180 //add in bee body width (will probably need to be changed later)
	sub	r6, #10 //breathing room
	ldr	r7, =wingLength
	ldr	r7, [r7]
	sub	r6, r7
	mov	r0, r6
	mov	r1, r5
	add	r1, #15 //more natural looking wings
	mov	r2, r7	//store wingLength so it may be used by drawBeeWings
	bl	drawBeeWings	//call drawBeeWings
	add	r0, r4, #12	// make the drawing position for the bee's eye (x)
	add	r1, r5, #7	// make the drawing position for the bee's eye (y)
	bl	drawBeeEye	// draw the bee's eye
	//now both body and wings are drawn along with the eye
	pop 	{r3-r10}	//restore registers
	bx	lr		//branch to calling code

drawBeeQ: //draws queen bee
	
	bx	lr

drawCrown:	//draws the crown that the queen bee shall wear
	//r0 is the x at the top left of the crown's rectangular base
	//r1 is the y at the top left of the crown's rectangular base
	//crownColour is stored in the data section of this file
	//height of base is 25 pixels
	//length of base is 50 pixels
	//height of triangles is 15 pixels
	//total crown height is 25+15=40 pixels
	push	{r4-r10}
	mov	r4, r0		//x
	mov	r5, r1		//y
	ldr	r6, =crownColour //colour address 
	ldr	r6, [r6]	//colour
	
	
	pop	{r4-r10}
	bx	lr

drawPlayer: //draws player at location (x,y) that is the leftmost portion of their helmet
	//r0 is x location
	//r1 is y location
	push {r3-r7}
	mov	r3, r0
	mov	r4, r1
	ldr	r5, =playerSize
	ldr	r5, [r5]
	ldr	r6, =playerHelmColour
	ldr	r6, [r6]
	push {r5}
	push {r5}
	push {r6}
	push {r4}
	push {r3}
	bl	drawRect //draws head
	add	sp, #20
	ldr	r6, =playerBodyColour
	ldr	r6, [r6]
	mov	r7, r5
	add	r7, r5
	add	r7, r5 //r7 = 3*r5
	sub	r0, r3, r5
	add	r1, r4, r5
	push {r5}
	push {r7}
	push {r6}
	push {r1}
	push {r0}
	bl	drawRect	//draw body
	add	sp, #20
	add	r0, r4, r5
	add	r0, r5
	push {r5}
	push {r5}
	push {r6}
	push {r0}
	push {r3}
	bl	drawRect	//draw feet things
	add	sp, #20
	add	r0, r4, r5
	add	r0, r5
	lsr	r1, r5, #1     // logical shift right
	add	r1, r3
	ldr	r6, =beeBlackColour
	ldr	r6, [r6]
	mov	r2, #2
	push 	{r6}
	push 	{r2}
	push	{r5}
	pus	{r2}
	push	{r0}
	push 	{r1}
	bl	drawLine    //calls drawLine
	add	sp, #24
	pop 	{r3-r7}
	bx	lr

drawBush: //draws "bush" cover
	//r0 is the x location
	//r1 is the y location
	//r2 is the size of the bush (bush is square)
	push {r3}
	ldr	r3, =bushColour
	ldr	r3, [r3]
	push 	{r2}
	push 	{r2}
	push 	{r3}
	push 	{r1}
	pus	{r0}
	bl	drawRect
	add	sp, #20
	pop {r3}
	bx	lr

drawLazer: //draws player lazer projectile
	// r0 is x location
	// r1 is y location
	// (x,y) is the top left-most location
	// returns memory location of lazerSize
	push 	{r3-r8}
	mov	r3, r0 //x location (xMin)
	mov	r4, r1 // y location (yMin)
	ldr	r5, =lazerSize
	mov	r8, r5
	ldr	r6, [r5] //length
	ldr	r5, [r5,#4] //width
	ldr	r7, =lazerColour
	ldr	r7, [r7]
	push 	{r5}
	push 	{r6}
	push 	{r7}
	push 	{r4}
	push 	{r3}
	bl	drawRect
	mov	r0, r8
	pop 	{r3-r7}
	bx	lr


drawBeeSting: //draws bee bullet projectile
	//r2 is bee sting direction
	//r0 is x location
	//r1 is y location
	// 0 is up
	// 1 is down
	// 2 is left
	// 3 is right
	push   {r3-r4}
	mov 	r4, r2
	ldr	r2, =beeStingSize
	ldr	r2, [r2]
	ldr	r3, =beeStingColour
	ldr	r3, [r3]
	push    {r3}
	cmp	r4, #0
	bne	bdsif2
	bl	drawTriangleUp
	bdsif2:
	cmp	r4, #1
	bne	bdsif3
	bl	drawTriangleDown
	bdsif3:
	cmp	r4, #2
	bne	bdselse
	bl	drawTriangleLeft
	bdselse:
	bl	drawTriangleRight
	add	sp, #4
	pop   	{r3-r4}
	bx	lr

drawCursor: //draws triangle cursor for use on pause menu always faces right
	// r0 is x location
	// r1 is y location
	// (x,y) is the rightmost point
	push 	{r3-r6}
	mov	r3, r0
	mov	r4, r1
	ldr	r5, =cursorSize
	ldr	r5, [r5]
	ldr	r6, =cursorColour
	ldr	r6, [r6]
	mov	r0, r3
	mov	r1, r4
	mov	r2, r5
	push 	{r6}
	bl	drawTriangleRight
	add	sp, #4 //removes colour from stack
	pop 	{r3-r6}
	bx	lr

drawPauseScreen:
	//r0 will indicate which option is selected
	// 0 indicates Resume
	// 1 indicates Restart Game
	// 2 indicates Quit
	push	{r4-r10}
	
	//pause menu will be drawn with top-left-most coordinates (100, 0)
	//768 pixels wide, 600 pixels long, border width of 30 pixels
	//a newline will be 20 pixels tall
	mov	r4, r0	//r4 is now the option selected
	
	mov	r0, #100	//x
	mov	r1, #0		//y
	mov	r2, #30
	mov	r5, #768
	push	{r5}
	mov	r5, #600
	push	{r5}
	ldr	r5, =pauseMenuMC
	ldr	r5, [r5]
	push	{r5}
	ldr	r5, =pauseMenuBC
	ldr	r5, [r5]
	push	{r5}
	bl	drawRectB
	add	sp, #16
	
	mov	r5, #20		//r5 is now the newline distance
	//start writing words at (150,50)
	mov	r6, #150	//x
	mov	r7, #50		//y
	ldr	r8, =0xFFFFFF	//white text for pause menu
	
	//starts with the word "Resume"
	add 	r1, r6, #0	//draw x
	mov 	r2, r7	        //draw y
	mov 	r3, r8		//draw colour
	mov 	r0, #'R'	//draw character
	bl 	drawChar	//call to subroutine
	add 	r1, r6, #10	//draw x
	mov 	r2, r7	        //draw y
	mov 	r3, r8		//draw colour
	mov 	r0, #'e'	//draw character
	bl 	drawChar	//call to subroutine
	add 	r1, r6, #20	//draw x
	mov 	r2, r7	        //draw y
	mov 	r3, r8		//draw colour
	mov 	r0, #'s'	//draw character
	bl 	drawChar	//call to subroutine
	add 	r1, r6, #30	//draw x
	mov 	r2, r7	        //draw y
	mov 	r3, r8		//draw colour
	mov 	r0, #'u'	//draw character
	bl 	drawChar	//call to subroutine
	add 	r1, r6, #40	//draw x
	mov 	r2, r7	        //draw y
	mov 	r3, r8		//draw colour
	mov 	r0, #'m'	//draw character
	bl 	drawChar	//call to subroutine
	add 	r1, r6, #50	//draw x
	mov 	r2, r7	        //draw y
	mov 	r3, r8		//draw colour
	mov 	r0, #'e'	//draw character
	bl 	drawChar	//call to subroutine
	add	r7, r5		//adds the newline distance
	
	//Next is "Restart Game"
	add 	r1, r6, #0	//draw x
	mov 	r2, r7	        //draw y
	mov 	r3, r8		//draw colour
	mov 	r0, #'R'	//draw character
	bl 	drawChar	//call to subroutine
	add 	r1, r6, #20	//draw x
	mov 	r2, r7	        //draw y
	mov 	r3, r8		//draw colour
	mov 	r0, #'e'	//draw character
	bl 	drawChar	//call to subroutine
	add 	r1, r6, #30	//draw x
	mov 	r2, r7	        //draw y
	mov 	r3, r8		//draw colour
	mov 	r0, #'s'	//draw character
	bl 	drawChar	//call to subroutine
	add 	r1, r6, #40	//draw x
	mov 	r2, r7	        //draw y
	mov 	r3, r8		//draw colour
	mov 	r0, #'t'	//draw character
	bl 	drawChar	//call to subroutine
	add 	r1, r6, #50	//draw x
	mov 	r2, r7	        //draw y
	mov 	r3, r8		//draw colour
	mov 	r0, #'a'	//draw character
	bl 	drawChar	//call to subroutine
	add 	r1, r6, #60	//draw x
	mov 	r2, r7	        //draw y
	mov 	r3, r8		//draw colour
	mov 	r0, #'r'	//draw character
	bl 	drawChar	//call to subroutine
	add 	r1, r6, #70	//draw x
	mov 	r2, r7	        //draw y
	mov 	r3, r8		//draw colour
	mov 	r0, #'t'	//draw character
	bl 	drawChar	//call to subroutine
	add 	r1, r6, #90	//draw x skips one character slot for space
	mov 	r2, r7	        //draw y
	mov 	r3, r8		//draw colour
	mov 	r0, #'G'	//draw character
	bl 	drawChar	//call to subroutine
	add 	r1, r6, #100	//draw x
	mov 	r2, r7	        //draw y
	mov 	r3, r8		//draw colour
	mov 	r0, #'a'	//draw character
	bl 	drawChar	//call to subroutine
	add 	r1, r6, #0	//draw x
	mov 	r2, r7	        //draw y
	mov 	r3, r8		//draw colour
	mov 	r0, #'m'	//draw character
	bl 	drawChar	//call to subroutine
	add 	r1, r6, #0	//draw x
	mov 	r2, r7	        //draw y
	mov 	r3, r8		//draw colour
	mov 	r0, #'e'	//draw character
	bl 	drawChar	//call to subroutine
	add	r7, r5		//adds the newline distance
	
	//third word is "Quit"
	add 	r1, r6, #0	//draw x
	mov 	r2, r7	        //draw y
	mov 	r3, r8		//draw colour
	mov 	r0, #'Q'	//draw character
	bl 	drawChar	//call to subroutine
	add 	r1, r6, #10	//draw x
	mov 	r2, r7	        //draw y
	mov 	r3, r8		//draw colour
	mov 	r0, #'u'	//draw character
	bl 	drawChar	//call to subroutine
	add 	r1, r6, #20	//draw x
	mov 	r2, r7	        //draw y
	mov 	r3, r8		//draw colour
	mov 	r0, #'i'	//draw character
	bl 	drawChar	//call to subroutine
	add 	r1, r6, #30	//draw x
	mov 	r2, r7	        //draw y
	mov 	r3, r8		//draw colour
	mov 	r0, #'t'	//draw character
	bl 	drawChar	//call to subroutine
	
	mov	r6, #150 	//x
	
	cmp	r4, #0
	bne	ifPauseNotResume
	mov	r0, r6
	mov	r1, #60
	b	afterPauseIfs
	ifPauseNotResume:
	cmp	r4, #1
	bne	ifPauseElse
	mov	r0, r6
	mov	r1, #80
	b	afterPauseIfs
	ifPauseElse:
	mov	r0, r6
	mov	r1, #100
	afterPauseIfs:
	
	pop	{r4-r10}
	bx	lr

drawGameOverScreen: //in the "loss" situation
	// background colour will be initialized to losingColour
	// "GAME OVER!" at ( 400 , 380)
	ldr	r0, =losingColour
	ldr	r0, [r0]
	bl	drawBG
	mov	r0, #400	//set first character x
	mov	r1, #380	//set first character y
	bl	drawGameOverWords
	bx	lr
	
drawVictoryScreen:
	// background colour will be initialized to winningColour
	// "VICTORY!" at (400, 380)
	// "Congratulations!" at (370,400)
	push	{r4}
	ldr	r0, =victoryBGColour
	ldr	r0, [r0]
	bl	drawBG
	ldr	r4, =victoryTextColour
	ldr	r4, [r4]
	mov 	r1, #400	//draw x
	mov 	r2, #380	//draw y
	mov 	r3, r4		//draw colour
	mov 	r0, #'V'	//draw character
	bl 	drawChar	//call to subroutine
	mov 	r1, #410	//draw x
	mov 	r2, #380	//draw y
	mov 	r3, r4		//draw colour
	mov 	r0, #'I'	//draw character
	bl 	drawChar	//call to subroutine
	mov 	r1, #420	//draw x
	mov 	r2, #380	//draw y
	mov 	r3, r4		//draw colour
	mov 	r0, #'C'	//draw character
	bl 	drawChar	//call to subroutine
	mov 	r1, #430	//draw x
	mov 	r2, #380	//draw y
	mov 	r3, r4		//draw colour
	mov 	r0, #'T'	//draw character
	bl 	drawChar	//call to subroutine
	mov 	r1, #440	//draw x
	mov 	r2, #380	//draw y
	mov 	r3, r4		//draw colour
	mov 	r0, #'O'	//draw character
	bl 	drawChar	//call to subroutine
	mov 	r1, #450	//draw x
	mov 	r2, #380	//draw y
	mov 	r3, r4		//draw colour
	mov 	r0, #'R'	//draw character
	bl 	drawChar	//call to subroutine
	mov 	r1, #460	//draw x
	mov 	r2, #380	//draw y
	mov 	r3, r4		//draw colour
	mov 	r0, #'Y'	//draw character
	bl 	drawChar	//call to subroutine
	mov 	r1, #470	//draw x
	mov 	r2, #380	//draw y
	mov 	r3, r4		//draw colour
	mov 	r0, #'!'	//draw character
	bl 	drawChar	//call to subroutine
	//"VICTORY!" drawn
	//commence drawing of "Congratulations!"
	mov 	r1, #370	//draw x
	mov 	r2, #400	//draw y
	mov 	r3, r4		//draw colour
	mov 	r0, #'C'	//draw character
	bl 	drawChar	//call to subroutine
	mov 	r1, #380	//draw x
	mov 	r2, #400	//draw y
	mov 	r3, r4		//draw colour
	mov 	r0, #'o'	//draw character
	bl 	drawChar	//call to subroutine
	mov 	r1, #390	//draw x
	mov 	r2, #400	//draw y
	mov 	r3, r4		//draw colour
	mov 	r0, #'n'	//draw character
	bl 	drawChar	//call to subroutine
	mov 	r1, #400	//draw x
	mov 	r2, #400	//draw y
	mov 	r3, r4		//draw colour
	mov 	r0, #'g'	//draw character
	bl 	drawChar	//call to subroutine
	mov 	r1, #410	//draw x
	mov 	r2, #400	//draw y
	mov 	r3, r4		//draw colour
	mov 	r0, #'r'	//draw character
	bl 	drawChar	//call to subroutine
	mov 	r1, #420	//draw x
	mov 	r2, #400	//draw y
	mov 	r3, r4		//draw colour
	mov 	r0, #'a'	//draw character
	bl 	drawChar	//call to subroutine
	mov 	r1, #430	//draw x
	mov 	r2, #400	//draw y
	mov 	r3, r4		//draw colour
	mov 	r0, #'t'	//draw character
	bl 	drawChar	//call to subroutine
	mov 	r1, #440	//draw x
	mov 	r2, #400	//draw y
	mov 	r3, r4		//draw colour
	mov 	r0, #'u'	//draw character
	bl 	drawChar	//call to subroutine
	mov 	r1, #450	//draw x
	mov 	r2, #400	//draw y
	mov 	r3, r4		//draw colour
	mov 	r0, #'l'	//draw character
	bl 	drawChar	//call to subroutine
	mov 	r1, #460	//draw x
	mov 	r2, #400	//draw y
	mov 	r3, r4		//draw colour
	mov 	r0, #'a'	//draw character
	bl 	drawChar	//call to subroutine
	mov 	r1, #470	//draw x
	mov 	r2, #400	//draw y
	mov 	r3, r4		//draw colour
	mov 	r0, #'t'	//draw character
	bl 	drawChar	//call to subroutine
	mov 	r1, #480	//draw x
	mov 	r2, #400	//draw y
	mov 	r3, r4		//draw colour
	mov 	r0, #'i'	//draw character
	bl 	drawChar	//call to subroutine
	mov 	r1, #490	//draw x
	mov 	r2, #400	//draw y
	mov 	r3, r4		//draw colour
	mov 	r0, #'o'	//draw character
	bl 	drawChar	//call to subroutine
	mov 	r1, #500	//draw x
	mov 	r2, #400	//draw y
	mov 	r3, r4		//draw colour
	mov 	r0, #'n'	//draw character
	bl 	drawChar	//call to subroutine
	mov 	r1, #510	//draw x
	mov 	r2, #400	//draw y
	mov 	r3, r4		//draw colour
	mov 	r0, #'s'	//draw character
	bl 	drawChar	//call to subroutine
	mov 	r1, #520	//draw x
	mov 	r2, #400	//draw y
	mov 	r3, r4		//draw colour
	mov 	r0, #'!'	//draw character
	bl 	drawChar	//call to subroutine
	pop	{r4}
	bx	lr

drawGameOverWords:
	// should draw "GAME OVER!" at start location ( x=r0 , y=r1)
	push	{r4-r6}
	mov	r4, r0
	mov	r5, r1
	ldr	r6, =losWordColour
	ldr	r6, [r6]
	add 	r1, r4, #0	//draw x
	mov 	r2, r5	        //draw y
	mov 	r3, r6		//draw colour
	mov 	r0, #'G'	//draw character
	bl 	drawChar	//call to subroutine
	add 	r1, r4, #10	//draw x
	mov 	r2, r5	        //draw y
	mov 	r3, r6		//draw colour
	mov 	r0, #'A'	//draw character
	bl 	drawChar	//call to subroutine
	add 	r1, r4, #20	//draw x
	mov 	r2, r5	        //draw y
	mov 	r3, r6		//draw colour
	mov 	r0, #'M'	//draw character
	bl 	drawChar	//call to subroutine
	add 	r1, r4, #30	//draw x
	mov 	r2, r5	        //draw y
	mov 	r3, r6		//draw colour
	mov 	r0, #'E'	//draw character
	bl 	drawChar	//call to subroutine
	add 	r1, r4, #50	//draw x (skips one position because of space)
	mov 	r2, r5	        //draw y
	mov 	r3, r6		//draw colour
	mov 	r0, #'O'	//draw character
	bl 	drawChar	//call to subroutine
	add 	r1, r4, #60	//draw x
	mov 	r2, r5	        //draw y
	mov 	r3, r6		//draw colour
	mov 	r0, #'V'	//draw character
	bl 	drawChar	//call to subroutine
	add 	r1, r4, #70	//draw x
	mov 	r2, r5	        //draw y
	mov 	r3, r6		//draw colour
	mov 	r0, #'E'	//draw character
	bl 	drawChar	//call to subroutine
	add 	r1, r4, #80	//draw x
	mov 	r2, r5	        //draw y
	mov 	r3, r6		//draw colour
	mov 	r0, #'R'	//draw character
	bl 	drawChar	//call to subroutine
	add 	r1, r4, #90	//draw x
	mov 	r2, r5	        //draw y
	mov 	r3, r6		//draw colour
	mov 	r0, #'!'	//draw character
	bl 	drawChar	//call to subroutine
	pop	{r4-r6}
	bx	lr

refreshGameScreen:
	//r0 will be the memory address for all toDraws
	bx	lr

setPlayerSize:
	//r0 is the new size
	ldr	r1, =playerSize
	str	r0, [r1]
	bx	lr

setBeeStingerSize:
	//r0 is the new "height"
	ldr	r1, =beeStingSize
	str	r1, [r0]
	bx	lr

setLazerDirection:
	//r0 is direction
	//0 is horizontal
	//anything else is vertical
	mov	r1, #50		//hard-coded length of lazer
	mov	r2, #1		//hard-coded width of lazer
	cmp	r0, #0
	bne	makeLazerVertical
	ldr	r0, =lazerSize
	str	r1, [r0]
	str	r2, [r0,#4]
	b	endOfSetLazerDirection
	makeLazerVertical:
	ldr	r0, =lazerSize
	str	r1, [r0,#4]
	str	r2, [r0]
	endOfSetLazerDirection:
	bx	lr

drawAuthorNames:
	bx	lr

drawGameTitle:
	bx	lr

.section .data
// Colour codes from http://www.nthelp.com/colorcodes.htm
beeBlackColour: .word	0x000000	//black
beeRedColour:	.word	0xFF6600	//lightish red
beeYellowColour: .word	0xFFFF00	//yellow
beeStingColour:	.word	0x003300	//almost-black
beeWingColour:	.word	0xFFFFCC	//white-ish (different white-ish from helmet)
bushColour:	.word	0x33CC00	//green
crownColour:	.word	
cursorColour:	.word	0xFFFFFF	//white
lazerColour:	.word	0xFF0000	//red
losingColour:	.word	0x000099	//dark blue
losWordColour:	.word	0xFFCCFF	//pink
inGameBGColour:	.word
pauseMenuMC:	.word	
pauseMenuBC:	.word	
playerBodyColour: .word	0x996600	//brown
playerHelmColour: .word	0xCCFFFF	//white-ish
victoryBGColour: .word	
victoryTextColour: .word 
beeStingSize:  .int   6		//
playerSize:	.int	75	//
cursorSize:	.int	10 	//triangle height
lazerSize:     .int   50, 1 	//rectangle length by width
wingLength:	.int   25
font:	.incbin		"font.bin"
