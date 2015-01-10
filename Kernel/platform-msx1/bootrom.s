		.area _CODE

		.db 'A'
		.db 'B'
		.dw wtfami + 0x4000
		.dw 0,0,0,0,0,0

;
;	Entered at 0x4000 but linked at 0x0000 so be careful
;
wtfami:		di

		ld a, #0x23		; Debug port
		out (0x2e), a
		ld a, #':'
		out (0x2f), a

; Select RAM subslot in all pages
		ld a,(0xffff)		; Subslot register
		cpl
		and #0xc0		; RAM subslot (RAM in page 3)
		ld e, a
		rrca			; Propogate into other pages
		rrca
		or e
		rrca
		rrca
		or e
		rrca
		rrca
		or e
		ld (0xffff),a		; All pages with the same subslot
		in a, (0xA8)
		ld d, a
		and #0x0C		; bits for 0x4000
		ld b, a
		rlca
		rlca			; to 0x8000
		or b			; and 0x4000
		rlca
		rlca			; to 0xC000/8000
		or b			; and 0x4000
		ld b, a			; B is now the bits for
					; putting 48K of cartridge
					; in place
; Select RAM in page 0
		ld a,d			; Page 3 must be RAM
		and #0xc0
		rlca
		rlca
		or b			; Pages 3-1 = Cartridge, Page 0 = RAM
		ld e, a			; Save in E
		out (0xA8), a		; Map cartridge

; Select the subslot of the cartridge in pages 3, 2, 1
		ld a, (0xffff)
		cpl
		and #0x0C		; Cartridge in page 1
		ld c, a
		rlca
		rlca			; to 0x8000
		or c			; and 0x4000
		rlca
		rlca			; to 0xC000/8000
		or c			; and 0x4000
		ld (0xffff), a		; Select the subslot of the cartridge
; Old code used mapped ram to copy the code to ram... Not sure if
; this is the better way to copy the code from rom to ram without 
; mapped ram...
		ld a, #'1'
		out (0x2f), a
		ld a, e
		exx
		ld hl, #0x4000		; Cartridge 0x4000 -> RAM 0
		ld de, #0x0
		ld bc, #0x4000
		ldir
		rlca
		rlca
		rlca
		rlca			; Pages 3, 1, 0 -> Cartridge. Page 2 Ram
		out (0xA8), a 
		ld hl, #0xC000		; Cartridge 0xC000 -> RAM 0x8000
		ld de, #0x8000
		ld bc, #0x4000
		ldir
		rlca
		rlca			; Pages 2, 1, 0 -> Cartridge. Page 3 Ram
		out (0xA8), a
		ld hl, #0x4000 + copypage2to1
		ld de, #0xC000
		ld bc, #endramgo - copypage2to1
		ldir			; Copy routine to transfer cartridge page 2, to ram page 3		
		and #0xF3
		ld e, a
		and #0xC0
		rlca
		rlca
		rlca
		rlca
		or e			; Pages 2, 0 -> Cartridge. Page 3, 1 Ram
		jp 0xC000		; Routine to transfer cartridge page 2, to ram page 3 and start
copypage2to1:
		out (0xA8), a
		ld hl, #0x8000		; Cartridge 0xC000 -> RAM 0x8000
		ld de, #0x4000
		ld bc, #0x4000
		ldir			
		ld a, #'G'
		out (0x2f), a
		exx
		ld a, d
		and #0xC0		; RAM in 0xC000 slot bits
		ld e, a			
		rra			; Propogate into other banks
		rra
		or e
		rra
		rra
		or e
		rra
		rra
		or e
		ld e, a			; E is now "all RAM"
		and #0xF3
		ld c, a
		ld a, d			; Get original status
		and #0x0c		; bits for 0x4000 as cartridge
		or c			; bits for the RAM
		out (0xA8), a
		ld a, #'O'
		out (0x2f), a
		jp ramgo
		;
		;	We now have RAM where we need it
		;
ramgo:		
		ld a, #'!'
		out (0x2f), a
		ld a, e
		out (0xA8), a		; Now go all ram
		jp 0x100
endramgo:
		; Put start at 0x100 so we can boot the MSXDOS .com too
		; Hack
		.ds 0x36