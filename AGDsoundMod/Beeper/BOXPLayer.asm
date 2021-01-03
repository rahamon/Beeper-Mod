
; *****************************************************************************
; * The Music Box Engine, with Drums
; *
; * Based on code written by Mark Alexander for the utility, The Music Box.
; * Modified by Chris Cowley
; * Thanks to introspec for help with optimised DRUM_SET routine :)
; *
; * Produced by Beepola v1.08.01
; ******************************************************************************
 
START:
                          LD    HL,MUSICDATA         ;  <- Pointer to Music Data. Change
                                                     ;     this to play a different song
                          LD   A,(HL)                         ; Get the loop start pointer
                          LD   (PATTERN_LOOP_BEGIN),A
                          INC  HL
                          LD   A,(HL)                         ; Get the song end pointer
                          LD   (PATTERN_LOOP_END),A
                          INC  HL
                          LD   (PATTERNDATA1),HL
                          LD   (PATTERNDATA2),HL
                          LD   A,254
                          LD   (PATTERN_PTR),A                ; Set the pattern pointer to zero
                          DI
                          CALL  NEXT_PATTERN
                          EI
                          RET
NEXTNOTE:
                          DI
                          CALL  PLAYNOTE

                          EI
                          RET                                 ; Return from playing tune

PATTERN_PTR:              DEFB 0
NOTE_PTR:                 DEFB 0


; ********************************************************************************************************
; * NEXT_PATTERN
; *
; * Select the next pattern in sequence (and handle looping if we've reached PATTERN_LOOP_END
; * Execution falls through to PLAYNOTE to play the first note from our next pattern
; ********************************************************************************************************
NEXT_PATTERN:
                          LD   A,(PATTERN_PTR)
                          INC  A
                          INC  A
                          DEFB $FE                      ; CP n
PATTERN_LOOP_END:         DEFB 0
                          JR   NZ,NO_PATTERN_LOOP
; Parche: End of the song flag. -------------------------------------------
PLY_Endofthesong 		defb 0
							ld a,1
							ld (PLY_Endofthesong),a
; fin del parche: fin de cancion. -----------------------------------------
						  DEFB $3E                           ; LD A,n
PATTERN_LOOP_BEGIN:       DEFB 0
                          POP  HL
                          EI
                          RET
NO_PATTERN_LOOP:		  LD   (PATTERN_PTR),A
			              DEFB $21                            ; LD HL,nn
PATTERNDATA1:             DEFW $0000
                          LD   E,A                            ; (this is the first byte of the pattern)
                          LD   D,0                            ; and store it at TEMPO
                          ADD  HL,DE
                          LD   E,(HL)
                          INC  HL
                          LD   D,(HL)
                          LD   A,(DE)                         ; Pattern Tempo -> A
	                	      LD   (TEMPO),A                      ; Store it at TEMPO

                          LD   A,1
                          LD   (NOTE_PTR),A

PLAYNOTE: 
			                    DEFB $21                            ; LD HL,nn
PATTERNDATA2:             DEFW $0000
                          LD   A,(PATTERN_PTR)
                          LD   E,A
                          LD   D,0
                          ADD  HL,DE
                          LD   E,(HL)
                          INC  HL
                          LD   D,(HL)                         ; Now DE = Start of Pattern data
                          LD   A,(NOTE_PTR)
                          LD   L,A
                          LD   H,0
                          ADD  HL,DE                          ; Now HL = address of note data
                          LD   D,(HL)
                          LD   E,1

; IF D = $0 then we are at the end of the pattern so increment PATTERN_PTR by 2 and set NOTE_PTR=0
                          LD   A,D
                          AND  A                              ; Optimised CP 0
                          JR   Z,NEXT_PATTERN

                          CP   $02                            ; $02 = DRUM ESCAPE CODE, byte in Ch2 identifies the drum type
                          JR   Z,DRUM_ESCAPE

                          PUSH DE
                          INC  HL
                          LD   D,(HL)
                          LD   E,1

                          LD   A,(NOTE_PTR)
                          INC  A
                          INC  A
                          LD   (NOTE_PTR),A                   ; Increment the note pointer by 2 (one note per chan)

                          POP  HL                             ; Now CH1 freq is in HL, and CH2 freq is in DE

                          LD   A,H
                          DEC  A
                          JR   NZ,OUTPUT_NOTE

                          LD   A,D                            ; executed only if Channel 2 contains a rest
                          DEC  A                              ; if DE (CH1 note) is also a rest then..
                          JR   Z,PLAY_SILENCE                 ; Play silence

OUTPUT_NOTE:              LD   A,(TEMPO)
                          LD   C,A
                          LD   B,0
                          LD   A,BORDER_COL
                          EX   AF,AF'
                          LD   A,BORDER_COL                   ; So now BC = TEMPO, A and A' = BORDER_COL
                          LD   IXH,D
                          LD   D,$10
EAE5:                     NOP
                          NOP
EAE7:                     EX   AF,AF'
                          DEC  E
                          OUT  ($FE),A
                          JR   NZ,EB04

                          LD   E,IXH
                          XOR  D
                          EX   AF,AF'
                          DEC  L
                          JP   NZ,EB0B

EAF5:                     OUT  ($FE),A
                          LD   L,H
                          XOR  D
                          DJNZ EAE5

                          INC  C
                          JP   NZ,EAE7

                          RET

EB04:
                          JR   Z,EB04
                          EX   AF,AF'
                          DEC  L
                          JP   Z,EAF5
EB0B:
                          OUT  ($FE),A
                          NOP
                          NOP
                          DJNZ EAE5
                          INC  C
                          JP   NZ,EAE7
                          RET

PLAY_SILENCE:
                          LD   A,(TEMPO)
                          CPL
                          LD   C,A
SILENCE_LOOP2:            PUSH BC
                          PUSH AF
                          LD   B,0
SILENCE_LOOP:             PUSH HL
                          LD   HL,0000
                          SRA  (HL)
                          ;SRA  (HL)
                          ;SRA  (HL)
                          NOP
                          POP  HL
                          DJNZ SILENCE_LOOP
                          DEC  C
                          JP   NZ,SILENCE_LOOP
                          POP  AF
                          POP  BC
                          RET

DRUM_ESCAPE:
                          INC  HL
                          LD   D,(HL)                         ; Put the drum type into D
                          LD   A,(NOTE_PTR)
                          INC  A
                          INC  A
                          LD   (NOTE_PTR),A                   ; Increment the note pointer by 2 (one note per chan)

; $02,$C0 = KICK
; $02,%0yyyxxxx. xxxx is the 4 bits of wave activation, yyy == 0,1,2,3,4,5,6,7 wave type

                          LD   A,D
                          BIT  7,A
                          JR   NZ,IS_KICK
                          LD   H,1
                          AND  $70
                          JR   Z,SET_DRUM_P2
DRUMSET_NEXTBIT:          SCF
                          RL   H
                          SUB  $10
                          JR   NZ,DRUMSET_NEXTBIT

SET_DRUM_P2:              LD   A,D
                          OR   %11110000
                          LD   D,H

IS_KICK:                  CALL  DRUM_DELAY
                          CP    $FF
                          JR    Z,WAVE_OUT

                          CP    $C0
                          JP    Z,KICK_DRUM

WAVE_SILENCE:             LD    B,$04
                          LD    C,E
                          RLA
L8120:                    RLA
                          RLA
                          RLA
L8123:                    RLA
                          CALL  C,WAVE_OUT
                          CALL  NC,SILENCE_LOOP2
                          DJNZ  L8123
                          RET

DRUM_DELAY:               PUSH  AF
                          LD    A,(TEMPO)
                          CPL
                          LD    B,A
                          LD    C,A
                          ADD   A,$01
                          SRA   A
                          SRA   A
                          LD    E,A
                          CP    $00
                          JR    NZ,L8140
                          INC   E
L8140:                    POP   AF
                          RET

WAVE_OUT:                 PUSH  AF
                          PUSH  HL
                          PUSH  BC
                          LD    A,BORDER_COL
                          LD    B,$00
                          LD    HL,$03E8
L814D:                    RRC   D
                          JP    NC,L8171
                          INC   HL
                          BIT   0,(HL)
                          JP    Z,L816D
                          SET   4,A
                          XOR   $83
                          XOR   $83
L815E:                    OUT   ($FE),A
L8160:                    NOP
                          DEC   B
                          JP    NZ,L814D
                          DEC   C
                          JP    NZ,L814D
                          POP   BC
                          POP   HL
                          POP   AF
                          RET

L816D:                    RES   4,A
                          JR    L815E

L8171:                    SCF
                          JP    NC,$0000
                          JP    NC,$0000
                          JP    NC,$0000
                          NOP
                          NOP
                          JR    L8160

KICK_DRUM:                LD    E,B
                          LD    D,$00
                          LD    HL,KICK_VALUES
                          ADC   HL,DE
                          LD    A,(HL)
                          LD    B,A
                          LD    HL,$0003
L818C:                    PUSH  BC
                          LD    DE,$0001
                          PUSH  HL
                          CALL  L819E
                          POP   HL
                          LD    DE,$00FF
                          ADC   HL,DE
                          POP   BC
                          DJNZ  L818C
                          RET

L819E:                    LD    A,L
                          SRL   L
                          SRL   L
                          CPL
                          AND   $03
                          LD    C,A
                          LD    B,$00
                          LD    IX,$03D1
                          ADD   IX,BC
                          LD    A,BORDER_COL
                          CALL  $03D4
                          DI
                          RET

KICK_VALUES:              DEFW  $0C0C
                          DEFW  $0D0D
                          DEFW  $0E0E
                          DEFW  $0F0E
                          DEFW  $0F0F
                          DEFW  $1010
                          DEFW  $1111
                          DEFW  $1212
                          DEFW  $1313
                          DEFW  $1414
                          DEFW  $1515
                          DEFW  $1615
                          DEFW  $1717
                          DEFW  $1818
                          DEFW  $1919

; *** DATA ***
BORDER_COL:               EQU $0
TEMPO:                    DEFB 238
