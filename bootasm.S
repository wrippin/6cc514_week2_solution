# When the PC starts, the processor is essentially emulating an 8086 processor, i.e. 
# a 16-bit processor.  So our initial boot loader code is 16-bit code that will 
# eventually switch the processor into 32-bit mode.

# This code is linked to assume a starting address of 0x7C00 which is where the BIOS
# will load a boot segment.

.code16                         # Assemble for 16-bit mode
.globl start
start:
    jmp     real_start

# Write to the console using BIOS.
# 
# Input: SI contains the address of the null-terminated string to be displayed

cons_write:
    movb    $0x0e, %ah           # 0x0e is the INT 10h BIOS call to output the value contained in AL to screen

cons_write_rpt:
    movb    (%si), %al          # Load the byte at the location contained in the SI register into AL   
    inc     %si                 # Add 1 to the value in SI
    cmp     $0, %al             # Compare the value in AL with 0
    jz      cons_write_done     # If it is zero, then we are done
    int     $0x10               # Output the character in AL to the screen
    jmp     cons_write_rpt      # and continue

cons_write_done:                # Something that is called will never return 
    ret                         # until a 'ret' instruction is encountered.  Labels do 
                                # not give a program any structure.  They just give a 
                                # memory location a name that we can use in our code. 

cons_write_crlf:
    movb    $0x0e, %ah          # Output CR
    movb    $0x0d, %al
    int     $0x10
    movb    $0x0a, %al          # Output LF
    int     $0x10
    ret

cons_writeline:
    call    cons_write
    call    cons_write_crlf
    ret    

# Output the 16-bit value in BX to the screen has a 4 digit hex value	
#
# Input:  BX = Value to output	

HexChars:	.ascii "0123456789ABCDEF"

cons_write_hex:
	movw	$4, %cx
    movb    $0x0E, %ah
	
hexloop:
    rol     $4, %bx
    movw    %bx, %si
    and     $0x000F, %si
    movb    HexChars(%si), %al
	int		$0x10
	loop	hexloop
	ret

# Output the value in BX as an unsigned integer
#
# Input: BX = Value to output
	
cons_write_int:
    movw    $IntBuffer + 4, %si
    movw    %bx, %ax
	
getdigit:
	xor		%dx, %dx
	movw	$10, %cx
	div		%cx
	addb	$48, %dl
	movb	%dl, (%si)
	dec		%si
	cmp		$0, %ax
	jne		getdigit
	inc		%si
	call	cons_write
	ret
	
IntBuffer:   .string "     "

real_start:
    cli                         # BIOS enabled interrupts; disable

    # Zero data segment registers DS, ES, and SS.
    xorw    %ax, %ax            # Set %ax to zero
    movw    %ax, %ds            # -> Data Segment
    movw    %ax, %es            # -> Extra Segment
    movw    %ax, %ss            # -> Stack Segment

    movw    $0, %sp             # Set the stack to the top of the segment
    movw    $boot_message, %si  # Display our boot message
    call    cons_writeline
    movw    $65535, %bx         # Display numbers in hex
    call    cons_write_hex
    call    cons_write_crlf
    movw    $4660, %bx
    call    cons_write_hex
    call    cons_write_crlf
    movw    $0, %bx
    call    cons_write_hex
    call    cons_write_crlf
    movw    $65535, %bx         # Display unsigned short numbers
    call    cons_write_int
    call    cons_write_crlf
    movw    $1234, %bx
    call    cons_write_int
    call    cons_write_crlf
    movw    $0, %bx
    call    cons_write_int
    call    cons_write_crlf

endless_loop:                   # Loop forever more
    jmp     endless_loop    

boot_message:                  # Definition of our boot message 
    .string "Boot Loader V1.0"

