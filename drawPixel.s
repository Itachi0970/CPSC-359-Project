//include(frameBuffer) should have a line to include/reference the frameBuffer initialization file

.section .init
.globl drawPixel
.globl drawRect
.globl drawLine

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
	
	mul    r0,    #1024                  //row-major
	add    r0,    r1                     //
	lsl    r0,    #3                     //8-bit colour assumed
	ldr    r1,    =frameBufferPointer    // should get frameBuffer location from file that contains frameBuffer information
	ldr    r1,    [r1]                   //
	add    r1,    r0                     // add offset
	strh   r2,   [r1]                    //
	
endDrawPixel:
	bx     lr                            //
	
	
drawRect: // in order on stack: {x,y,colour,lenX,lenY}
	push{r3,r4,r5,r6,r7,r8}
	ldr   r7, [sp,#24] //x
	ldr   r8, [sp,#28] //y
	ldr   r2, [sp,#32] //colour
	ldr   r3, [sp,#36] //lenX
	ldr   r4, [sp,#40] //lenY
	mov	  r5, #0 //i
	dRFL1s:
	cmp	  r5, r3
	bge	  dRFL1e
	mov   r6, #0 //j
	dRFL2s:
	cmp   r6, r4
	bge   dRFL2e
	add   r0, r7, r5
	add   r1, r8, r6
	b     drawPixel
	add   r6, #1
	b     dRFL2s
	dRFL2e:
	add   r5, #1
	b     dRFL1s
	dRFL1e:
	pop{r3,r4,r5,r6,r7,r8}
	bx	lr
	
	
drawLine: //takes thickness as a parameter, vertical/horizontal/diagonalU/diagonalD as parameters
	push(r3-r10)
	ldr   r0, [sp,#40] // x
	ldr	  r1, [sp,#44] // y
	ldr   r2, [sp,#60] // colour
	ldr   r3, [sp,#52] // length
	ldr   r4, [sp,#56] // thickness
	ldr   r5, [sp,#48] // direction
	sub   r6, r4, #1
	rsl   r6, #1 // a
	mov   r7, #0 // i
	mov   r8, r0 // x (constant)
	mov   r9, r1 // y (constant)
	dLFL1s:
	cmp   r7, r3
	bge   dLFL1e
	mov   r0, r8
	mov   r1, r9
	b     drawPixel
	cmp   r4, #1
	ble   afterif1
	and   r0, r5, #2
	srl   r0, #1
	and   r1, r5, #4
	srl   r1, #2
	orr   r0, r1
	cmp   r0, #1
	bne   afterif1
	sub   r0, r8, r6
	mov   r1, r9
	mov   r10, #1
	push{r0,r1,r2,r6,r10}
	b     drawRect
	pop{r0,r1,r2,r6,r10}
	mov    r0, r8
	push{r0,r1,r2,r6,r10}
	b     drawRect
	pop{r0,r1,r2,r6,r10}
	afterif1:
	and   r0, r5, #1
	cmp   r0, #1
	bne   afterif2
	cmp	  r4, #1
	ble   afterif3
	push{r4}
	mov   r0, #1
	push{r0}
	push{r2}
	mov   r0,r8
	sub   r1,r9,r4
	push{r0,r1}
	b     drawRect
	pop{r0,r1}
	pop{r0,r1}
	pop{r0}
	push{r4}
	mov   r0, #1
	push{r0}
	mov   r0, r8
	mov   r1, r9
	push{r0,r1,r2}
	b     drawRect
	pop{r0,r1}
	pop{r0,r1}
	pop{r0}
	afterif3:
	add   r8, #1
	afterif2:
	tst  r5, #2
	bne  ifpart2
	add  r9, #1
	ifpart2:
	tst r5, #4
	bne  afterif4
	sub  r9, #1
	afterif4:
	add  r7, #1
	b    dLFL1s
	dLFL1e:	
	pop(r3-r9)
	bx	lr


drawTriangle:

drawDiamond:

drawSquare:

drawStripedCircle:

drawRectB: //rectangle with border

drawBG: //draw background colour

drawBee: //draw a bee with size and colour of yellow stripes being variables

drawBeeP: //draws pawn bee

drawBeeK: //draws knight bee

drawBeeQ: //draws queen bee

drawPlayer: //draws player

drawBush: //draws "bush" cover

drawLazer: //draws player lazer projectile

drawBeeSting: //draws bee bullet projectile

drawCursor: //draws cursor for use on pause menu
