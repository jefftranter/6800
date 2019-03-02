        NAM   MONDEB
        CPU   6800
;THIS SOURCE CODE WAS SENT TO WALTER BANKS AT
;THE UNIVERSITY OF WATERLOO BY DON PETERS ON PAPER TAPE
;CROSS ASSEMBLY WAS DONE ON THE U OF W HONEYWELL 66/60
;THE BARCODE AND LISTING WERE SET ON A PHOTON PHOTO-
;TYPESETTER DRIVEN BY THE HONEYWELL.
;
;       M O N D E B  - A MONITOR/DEBUGGER FOR THE M6800
;                        MICROPROCESSOR

; AUTHOR: DON PETERS
; DATE: APRIL 1977
; MEMORY REQ'D: 3K BYTES AT HIGH END OF ADDRESS SPACE

; SEE USER MANUAL FOR CAPABILITIES & INSTRUCTIONS ON
;                       USE

;      * =     $400    ;DEBUG ORG AT 1K
       * =    $F400    ;NORMAL ORIGIN AT 61K



;I/O DEVICE ADDRESSES
ACIA1  EQU    $7F43    ;ACIA #1 - MAIN TERMINAL ACIA
ACIA2  EQU    $7F45    ;ACIA #2 - AUXILIARY TERMINAL
;                       ACIA

;OTHER CONSTANTS
CR     EQU    13       ;CARRIAGE RETURN
LF     EQU    10       ;LINE FEED



START  EQU    *        ;PROGRAM ENTRY POINT
       LDS    #STACK   ;INITIALIZE THE STACK POINTER
       STS    SP       ;SAVE THE POINTER
       JSR    INITAL   ;INITIALIZE VARIABLES


;TYPE OUT MONITOR NAME & VERSION
       JSR    DOCCRLF  ;ADVANCE TO A CLEAN LINE
       LDX    #MSGHED  ;GET ADDRESS OF HEADER
       JSR    OUTSTR   ;TYPE IT

;SET UP DESTINATION OF INPUT LINE
;DEFINE BEGINNING OF INPUT BUFFER
       LDX    #TTYBUF-1   ;GET ADDRESS OF TERMINAL
;                       INPUT BUFFER
       STX    BUFREF   ;SAVE IT

;DEFINE END OF INPUT BUFFER - 72 CHAR CAPACITY, INCL CR
       LDX    #TTYEND
       STX    BUFEND

;DELIMITER CLASS DEFINITION - SPACE OR COMMA (CODE 3)
       LDAA   #3
       STAA   DELIM
       BRA    PROMP1



;PREPARE TO GET A NEW COMMAND
PROMPT JSR    DOCRLF   ;TYPE CR-LF
       INC    BOLFLG   ;SET "BEGINNING OF LINE" FLAG
       LDX    SYNPTR   ;POINT TO CURRENT CHARACTER
       LDAA   X        ;GET IT
       CMPA   #';'     ;SEMICOLON?
       BEQ    GETCMD   ;CONTINUE SCAN IF IT IS,
;                        SKIPPING THE PROMPT

;TYPE PROMPT
PROMP1 LDX    #MSGPRM
       JSR    OUTSTR

       JSR    GETLIN  ;GET LINE OF INPUT

;ABORT LINE ON A CONTROL-C
       CMPB   #3
       BEQ    PROMPT

;SET SYNTAX SCANNING POINTER TO BEGINNING OF
;                       BUFFER/LINE
       LDX    BUFBEG
       STX    SYNPTR

;REPROMPT ON AN EMPTY LINE (FIRST CHAR = CR, LF, OR ;)
       LDAA   1,X      ;GET FIRT CHAR
       JSR    TSTEOL   ;TEST IT
       BEQ    PROMPT   ;IF IT IS, PROMPT AGAIN

;USE LIST 1 WHEN MATCHING
GETCMD LDAA   #1

;NOW GO FOR A MATCH
       JSR    COMAND

;-AND TEST THE RESULT OF THE SCAN
       BEQ    PROMPT   ;REPROMPT IF JUST A CR WAS TYPED
       BGT    JMPCMD   ;GOOD COMMAND IF POSITIVE

;*****
;UNRECOGNIZABLE SYNTAX - POINT TO ERROR
BADSYN LDX    BUFREG   ;GET START OF LINE
;SPACE OVER TO ERROR IN SYNTAX
BADS1  CPX    LINPTR   ;AT ERROR?

       BEQ    BADS2
       JSR    OUTSP    ;OUTPUT A SPACE
       INX             ;NO, MOVE ON
       BRA    BADS1

;THE "EXTRA" CHAR "1" IS COMPENSATED FOR BY THE PROMPT
;                       CHAR ON THE PRECEEDING LINE
BADS2  LDAA   #'1'     ;AT ERROR - GET AN UP-ARROW
       JSR    OUTCHR   ;PRINT IT
       JSR    DOCRLR
       BRA    PROMP1   ;IGNORE ANY SUCCEEDING PACKED
;                        COMMANDS

;*****
;THERE SHOULD BE NO MORE CHARACTERS ON THE INPUT LINE
;                       (EXCEPT DELIMITERS)
NOMORE JSR    SKPDLM
       BCS    PROMPT   ;IF CARRY BIT SET, END OF LINE
;                        (NORMAL)
;THERE IS SOMETHING THERE BUT SHOULDN'T BE
       BRA    BADSYN

;*****
;EXECUTE A COMPUTED "GOTO" TO THE PROPER COMMAND
JMPCMD TAB             ;SAVE COMMAND # IN ACCB
       ASLA            ;MULTIPLY COMMAND BY 2
       ABA             ;ACCA NOW HOLDS COMMAND #
;                       MULTIPLIED BY 3
;ADD IT TO BASE OF JUMP TABLE
       LDAB   #JMPHI   ;GET HI BYTE OF START OF JUMP
;                       TABLE IN ACCB
       ADDA   #JMPLO   ;ADD LO BYTE OF START OF JUMP
;                       TABLE TO ACCA
       ADCB   #0       ;ADD CARRY IF THERE WAS
;                       ONE
;MOVE ACCA & ACCB TO IX (CODE IS WEIRD, BUT BRIEF)
       PSHA
       PSHB
       TSX             ;PUT ADDRESS OF "GOTO" INTO X
       LDX    X        ;GET THE ADDRESS ITSELF
       PULB            ;RESTORE THE STACK
       PULA

       JMP    X        ;JUMP TO RIGHT COMMAND

JMPTBL EQU    *-3

JMPHI  EQU    JMPTBL/256
JMP256 EQU    JMPHI*256
JMPLO  EQU    JMPTBL-JMP256

       JMP    REG
       JMP    GOTO
       JMP    LSEI
       JMP    LCLI
       JMP    COPY
       JMP    BREAL
       JMP    IBASE
       JMP    DBASE
       JMP    CONTIN
       JMP    DISPLA
       JMP    SET
       JMP    VERIFY
       JMP    SEARCH
       JMP    TEST
       JMP    INT
       JMP    LNMI
       JMP    LSWI
       JMP    COMPAT
       JMP    DUMP
       JMP    LOAD
       JMP    DELAY
;*****
;REG - DISPLAY REGISTERS
REG    EQU    *
;PRINT STACK STORED SWI DATA
DISREG LDX    SP       ;GET SAVED STACK POINTER
       INX
;REGISTER NAME TYPEOUT INITIALIZATION
       CLR    COMMNUM  ;START AT BEGINNING OF THE
;                        REGISTER NAME LIST

       BSR    OUT2     ;TYPE CONDITION CODES
       BSR    OUT2     ;TYPE ACCB
       BSR    OUT2     ;TYPE ACCA

       BSR    OUT4     ;TYPE INDEX REG
       BSR    OUT4     ;TYPE PROGRAM COUNTER

;TYPE THE STACK POINTER LOCATION
       BSR    OUT2A4   ;TYPE STACK POINTER ID
       LDX    #SP
       JSR    OUT2BY   ;TYPE THE VALUE

       JMP    NOMORE

;OUTPUT CONTENT OF A 1 BYTE REGISTER
OUT2   BSR    OUT2A4
       JSR    OUT1BY
       INX
       RTS

;OUTPUT CONTENT OF A 2 BYTE RESISTER
OUT4   BSR    OUT2A4
       JSR    OUT2BY
       INX             ;SKIP TO NEXT BYTE IN STACK
       INX             ;SKIP TO NEXT BYTE IN STACK
       RTS

;MISC SETUP FOR REGISTER DISPLAY
OUT2A4 JSR    OUTSP    ;OUTPUT A SPACE
       INC    COMNUM   ;SKIP TO NEXT REGISTER NAME
       LDAA   #5       ;REGISTER NAME IS IN LIST 5
       JSR    TYPCMD   ;TYPE IT
       JSR    OUTEQ    ;TYPE AN "="
       RTS

;ENTER HERE FROM SOFTWARE INTERRUPT
TYPSWI LDX    OUTSTR
;DECREMENT PC SO IT POINTS TO "SWI" INSTRUCTION
       LDX    SP
       TST    7,X      ;TEST LO BYTE OF PC FOR PENDING
;                        BORROW
       BNE    TYPSW1
       DEC    6,X      ;NEED TO BORROW, DEC HI BYTE OF
;                        PC
TYPSW1 DEC    7,X      ;DECR LO BYTE OF PC
       BRA    DISREG   ;GO DISPLAY REGISTERS
;*****
;GOTO - GO TO MEMORY ADDRESS
GOTO   JSR    NUMBER   ;GET DESTINATION
       BEQ    GOTO1    ;IF NONE, USE DEFAULT
       LDX    NBRHI
       STX    LASTGO   ;SAV IT
       JMP    X        ;GO TO DESTINATION

GOTO1  LDX   LASTGO    ;GET LAST GOTO ADDRESS
       JMP    X        ;GO TO IT
;*****
;SEI - SET INTERRUPT MASK
LSEI   SEI
       BRA    COPY3

;*****
;CLI - CLEAR INTERRUPT MASK
LCLI   CLI
       BRA    COPY3

;*****
;COPY - COPY FROM ONE LOCATION TO ANOTHER
COPY   JSR    GTRANG   ;GET SOURCE RANGE INTO RANGLO &
;                        RANGHI
       BLE    COPY2    ;ERROR IF NO SOURCE
       JSR    NUMBER   ;GET DESTINATION
       BLE    COPY2    ;ERROR IF NO DESTINATION

       LDX    RANGLO   ;GET SOURCE ADDRESS POINTER
COPY1  LDAA   X        ;GET BYTE FROM SOURCE
       LDX    NBRHI    ;GET DESTINATION ADDRESS POINTER
       STAA   X        ;SAVE BYTE IN DESTINATION
       INX             ;INC DESTINATION POINTER
       STX    NBRHI    ;SAVE IT
       LDX    RANGLO   ;GET SOURCE ADDRESS POINTER
       CPX    RANGHI   ;COMPARE TO END OF INPUT RANGE
       BEQ    COPY3    ;DONE IF EQUAL
       INX             ;NOT EQUAL, INC SOURCE POINTER
       STX    RANGLO   ;SAVE IT
       BRA    COPY1    ;LOOP FOR NEXT BYTE

       JMP    BADSYN   ;BAD SYNTAX
       JMP    NOMORE   ;SHOULD BE NO MORE ON THE INPUT
;                        LINE

;*****
;BREAK - SET BREAKPOINT AT SPECIFIED ADDRESS & REMOVE
;                       OLD ONE
BREAK  JSR    NUMBER   ;GET BREAKPOINT LOCATION
       BMI    BREAK3   ;IF NOT NUMERIC, LOOK FOR "?"
       BEQ    BREAK2   ;IF NO MODIFIER, REMOVE OLD
;                        BREAKPOINT

;*****
;CHECK IF A "SWI" IS STORED AT THE BREAK ADDRESS
       LDX    BRKADR   ;GET CURRENT BREAK ADDRESS
       LDAA   X        ;AND THE CHAR THERE
       CMPA   #$3F     ;COMPARE TO "SWI"
       BNE    BREAK1   ;EQUAL?
;YES, RESTORE THE OLD INSTRUCTION
       LDAA   BRKINS   ;GET IT
       STAA   X        ;RESTORE IT

;PUT BREAK AT NEWLY SPECIFIED LOCATION
BREAK1 LDX    NBRHI    ;GET NEW BREAKPOINT (BREAK
;                        ADDRESS
       STX    BRKADR   ;SAVE IT
       LDAA   X        ;GET INSTRUCTION STORED THERE
       STAA   BRKINS   ;SAVE IT
       LDAA   #$3F     ;GET CODE FOR SOFTWARE INTERRUPT
       STAA   X        ;PUT IT AT BREAKPOINT
       BRA    BREAK5   ;ALL DONE

;REMOVE BREAKPOINT
BREAK2 LDX    BRKADR   ;GET ADDRESS OF BREAK
       LDAA   X        ;GETINST. THERE
       CMPA   #$3F     ;SWI?
       BNE    BREAK5   ;IF NOT,, RETURN & PROMPT
       LDAA   BRKINS   ;WAS A SWI - GET PREVIOUS INST.
       STAA   X        ;& RESTORE IT
       BRA    BREAK5

;LOOK FOR A QUESTION MARK IN LIST 4
BREAK3 LDAA   #4
       JSR    COMAND   ;SCAN FOR IT
       BLE    BREAK6   ;BAD SYNTAX IF NOT "?"
       LDX    BRKADR   ;IT IS, GET BREAK ADDRESS
       LDAA   X        ;GET INSTRUCTION THERE
       CMPA   #$3F     ;IS IT A "SWI"?
       BEQ    BREAK4   ;IF YES, SAY SO
;NO BREAKPOINT SET
       LDX    #MSBNBR  ;GET THAT MESSAGE
       JSR    OUTSTR   ;SAY IT
       BRA    BREAK5
;BREAKPOINT SET
BREAK4 LDX    #MSGBAT  ;GET THAT MESSAGE
       JSR    OUTSTR   ;SAY IT
       LDX    #BRKADR  ;GET BREAK ADDRESS
       JSR    OUT2BY   ;TYPE IT

BREAK5 JMP    NOMORE
BREAK6 JMP    BADSYN

;*****
;IBASE - SET INPUT BASE
;LOOK FOR HEX, DEC, OR OCT IN LIST #3
IBASE  LDAA   #3
       JSR    COMAND
       BMI    IBASE2   ;UNRECOGNIZABLE BASE, TRY "?"
       BGT    IBASE1
       LDAA   #1       ;NO BASE GIVEN - DEFAULT TO HEX
IBASE1 STAA   IBCODE   ;SAVE BASE CODE
       BRA    BREAK5

;LOOK FOR "?" IN LIST #4
IBASE2 LDAA   IBCODE   ;GET IB CODE IN CASE ITS NEEDED
       PSHA            ;SAVE IT ON STACK TEMPORARILY
       BRA    DBASE4

;*****
;DBASE - SET DISPLAY BASE
;LOOK FOR HEX,DEC,OCT OR BIN IN LIST #3
DBASE  LDAA   #3
       JSR    COMAND
       BMI    DBASE3   ;UNRECOGNIZABLE BASE, TRY "?"
       BGT    DBASE1
       LDAA   #1       ;NO BASE GIVEN - DEFAULT TO HEX
DBASE1 STAA   DBCODE

;COMPUTE THE NUMERIC DISPLAY BASE (FOR THE "DISPLAY"
;                       COMMAND)
       LDX    #DBTBL-1 ;POINT TO HEAD OF
;                        DISPLAY BASE TABLE
DBASE2 INX             ;INC TABLE POINTER
       DECA            ;DECR DISPLAY BASE CODE
       BNE    DBASE2   ;LOOP IF NOT EQUAL
       LDAA   X        ;EQUAL - GET NUMERIC BASE FROM
;                        TABLE
       STAA   DBNR     ;SAVE IT
       BRA    BREAK5   ;DONE

;DISPLAY BASE TABLE
DBTBL  DB     16
       DB     10
       DB     8
       DB     2

;LOOK FOR "?" IN LIST #4
DBASE3 LDAA   DBCODE   ;GET DB CODE IN CASE ITS NEEDED
       PSHA            ;SAVE IT ON STACK TEMPORARILY
DBASE4 LDAA   #4
       JSR    COMAND
       PULB            ;RETRIEVE INPUT BASE/DISPLAY
;                        BASE CODE
       BLE    BREAK6   ;ERROR IF THE "SOMETHING" WAS
;                        NOT AN "?"
;SET UP FOR TYPEOUT OF BASE CODE
       LDAA   #3       ;ITS IN LIST
       STAB   COMNUM   ;STORE BASE CODE
       JSR    TYPCMD   ;TYPE OUT BASE
       BRA    BREAK5
;*****
;CONTINUE - CONTINUE FROM A "SWI"
;RETURN TO LOCATION WHERE SWI WAS
CONTIN LDS    SP       ;IN CASE SP WAS MODIFIED VIA SET
;                       COMMAND
       RTI

;*****
;DISPLAY - DISPLAY MEMORY DATA
DISPLA JSR    GTRANG   ;GET MEMORY DISPLAY RANGE
       BLE    DISPL9   ;ADDRESS IS REQUIRED

;INITIALIZE ADDRESS POINTER TO START OF MEMORY
       LDX    RANGLO
       STX    MEMADR

;SEARCH LIST 6 FOR DISPLAY MODIFIERS "DATA" OR "USED"
       LDAA   #6
       JSR    COMAND
       BMI    DISPL9   ;ANY OTHER MODIFIER IS ILLEGAL
;ADJ DISPLAY MODIFIER CODE SO THAT: -1=ADDR & DATA,
;                       0=DATA, I=USED
       DECA
       STAA   COMNUM   ;SAVE FOR LATER TESTS
;INIT "DATA VALUES PER LINE" COUNTER
       CLRB
       INCB
DISPL1 LDX    #MEMADR
       TST    COMNUM   ;WHICH DISPLAY OPTION?
       BMI    DISPL6   ;IF "ADDRESS & DATA", GO THERE

;OUTPUT DATA WITH ADDRESS ONLY AT LINE BEGINNING
       DECB            ;COUNT DATA VALUES PER LINE
       BNE    DISPL2   ;IF COUNT NOT UP, SKIP ADDRESS
;                        OUTPUT

       JSR    DOCRLF   ;GET TO LINE BEGINNING
       JSR    OUT2BY   ;OUTPUT ADDRESS
       JSR    OUTSP    ;AND A SPACE
       LDAB   DBNBR    ;RESET LINE COUNTER

DISPL2 LDX    MEMADR   ;POINT TO DATA AT THAT ADDRESS
       TST    COMNUM   ;WANT "DATA" OPTION?
       BGT    DISPL3   ;IF NOT, GO TO "USES" CODE

;"DATA" OPTION
       JSR    OUTSP    ;OUTPUT PRECEEDING SPACE
       BRA    DISPL7
;"USED" OPTION
DISPL3 LDAA   X        ;GET THE DATA
       TSTA            ;EXAMINE IT FOR ZERO
       BNE    DISPL4
       LDAA   #'.'     ;ITS ZERO, GET A "."
       BRA    DISPL5
DISPL4 LDAA   #'+'     ;ITS NON-ZERO. GET A "+"
DISPL5 JSR    OUTCHR   ;OUTPUT THE "." OR "+"
       BRA    DISPL8

DISPL6 JSR    OUTSP    ;OUTPUT A PRECEEDING SPACE
       JSR    OUT2BY   ;TYPE ADDRESS
       JSR    OUTEQ    ;TYPE "="
       LDX    X        ;GET CONTENT
       JSR    OUT1BY   ;TYPE IT

DISPL8 CPX    RANGHI   ;ARE WE DONE?
       BEQ    DISP10   ;IF YES, BACK TO PROMPT
       INX             ;NO, INC MEMORY ADDRESS
       STX    MEMADR   ;SAVE IT
       BRA    DISPL1

DISPL9 JMP    BADSYN
DISP10 JMP    NOMORE

;*****
;SET - SET MEMORY LOCATIONS
SET    JSR    GETRANG  ;GET MEMORY LOCATION/RANGE
       BMI    SET5     ;IF NOT AN ADDRESS, LOOK FOR A
;                        REGISTER NAME
       BEQ    DISPL9   ;AN ADDRESS MODIFIER IS REQUIRED

;RANGE OF ADDRESSES SPECIFIED?
       LDX    RANGLO
       CPX    RANGHI
       BEQ    SET2     ;IF SINGLE ADDRESS, SET UP
;                        ADDRESSES INDIVIDUALLY
;SET A RANGE OF ADDRESSES TO A SINGLE VALUE
       JSR    NUMBER   ;GET THAT VALUE
       BLE    DISPL9   ;ITS REQUIRED
       LDAA   NBRLO    ;PUT IT IN ACCA
SET1   STAA   X        ;STORE IT IN DESTINATION
       CPX    RANGHI   ;END OF RANGE HIT?
       BEQ    DISP10   ;IF YES,ALL DONE
       INX             ;NO, ON TO NEXT ADDRESS IN RANGE
       BRA    SET1     ;LOOP TO SET IT
;SET ADDRESSES UP INIDIVIDUALLY
SET2   STX    MEMADR   ;SAVE MEMORY LOC
SET3   JSR    NUMBER   ;GEET DATA TO PUT THERE
       BEQ    SET4     ;END OF LINE?
       BLT    DISPL9   ;ABORT IF BAD SYNTAX
       LDAA   NBRLO    ;LOAD DATA BYTE
       LDX    MEMADR   ;LOAD ADDRESS
       STAA   X        ;STORE DATA

;INCREMENT ADDRESS IN CASE USER WANTS TO INDIVIDUALLY
;                       SET SEVERERL
;SUCCESSIVE LOCATIONS
       INX
       BRA    SET2

;END OF LINE - WAS IT TERMINATED WITH A LINE FEED?
SET4   LDX    SYNPTR   ;POINT TO END OF LINE
       LDAA   X        ;GET CHAR THERE
       CMPA   #LF      ;LINE FEED?
       BNE    SET12    ;IF NOT, BACK TO PROMPT
       LDX    #MEMADR  ;YES, GET NEXT ADDRESS TO BE SET
       JSR    OUT2BY   ;TYPE IT
       JSR    OUTSP    ;AND A SPACE
       JSR    GETLIN   ;GET A NEW LINE
       LDX    BUFREG   ;GET BUFFER BEGINNING
       STX    SYNPTR   ;EQUATE IT TO SYNTAX SCAN POINTER
       BRA    SET3     ;GO PICK UP DATA


;LOOK FOR (REGISTER NAME, REGISTER VALUE) PAIRS
SET5   LDAA   #5
       JSR    COMAND   ;PICK UP A REGISTER NAME
       BMI    SET11    ;ERROR IF UNRECOGNIZABLE
       BEQ    SET12    ;DONE IF END OF LINE
       PSHA            ;SAVE REGISTER NAME(NUMBER)
       JSR    NUMBER   ;GET NEW REGISTER VALUE
       PULA            ;RESTORE REGISTER NAME(NUMBER)
       BLE    SET11    ;GOT GOOD REGISTER VALUE?
       LDX    SP       ;YES, POINT TO TOP OF STACK
       LDAB   NBRLO    ;GET REGISTER VALUE

;CONDITION CODES
       CMPA   #1
       BNE    SET6
       STAB   1,X
       BRA    SET5
;ACCB
SET6   CMPA   #2
       BNE    SET7
       STAB   2,X
       BRA    SET5

;ACCA
SET7   CMPA   #3
       BNE    SET8
       STAB   3,X
       BRA    SET5

;IX
SET8   CMPA   #4
       BNE    SET9
       LDAA   NBRHI
       STAA   4,X      ;UPDATE HI BYTE
       STAB   5,X      ;UPDATE LO BYTE
       BRA    SET5

;PC
SET9   CMPA   #5
       BNE    SET10
       LDAA   NBRHI
       STAA   6,X      ;UPDATE HI BYTE
       STAB   7,X      ;UPDATE LO BYTE
       BRA    SET5

;SP
SET10  CMPA   #6
       BNE    SET11
       LDX    NBRHI    ;DON'T NEED IX TO SET SP
       STX    SP
       BRA    SET5

SET11  JMP    BADSYN
SET12  JMP    NOMORE
;*****
;VERIFY - CHECKSUM VERIFY A BLOCK OF MEMORY
VERIFY JSR    GTRANG   ;GET A NUMBER RANGE
       BEQ    VERIF1   ;NO MODIFIER MEANS CHECK WHAT WE
;                        HAVE
       BMI    SET11    ;ANYTHING ELSE IS ILLEGAL
;GOOD RANGE GIVEN, TRANSFER IT TO CHECKSUM ADDRESSES
       LDX    RANGLO
       STX    VERFRM
       LDX    RANGHI
       STX    VERTO

       BSR    CKSUM    ;COMPUTE CHECKSUM
       STAA   CHKSUM   ;SAVE IT
       LDX    #CHKSUM  ;TYPE THE CHECKSUM
       JSR    OUT1BY
       BRA    SET12

;NO MODIFIER GIVEN - JUST VERIFY CHECKSUM
VERIF1 BSR    CKSUM    ;COMPUTE CHECKSUM
       CMPA   CHKSUM   ;SAME AS STORED CHECKSUM?
       BNE    VERIF2

;THEY VERIFY - SAY SO
       LDX    #MSGVER
       JSR    OUTSTR
       BRA    SET12

;THEY DON'T - SAY SO
VERIF2 LDX    #MSGNVE
       JSR    OUTSTR
       BRA    SET12

;COMPUTE THE CHECKSUM FROM ADDRESSES VERFRM TO VERTO
;RETURN THE CHECKSUM IN ACCA
CKSUM  CLRA            ;INIT CHECKSUM TO ZERO
       LDX    VERFRM   ;GET FIRST ADDRESS
       DEX             ;INIT TO ONE LESS
CKSUM1 INX             ;START OF CHECKSUM LOOP
       ADDA   Z        ;UPDATE CHECKSUM IN ACCA WITH
;                        BYTE POINTED TO
       CPX    VERTO    ;HIT END OF RANGE?
       BNE    CKSUM1   ;IF NOT, LOOP BACK
       COMA            ;COMPLEMENT THE SUM
       RTS             ;RETURN WITH IT
;*****
;SEARCH - SEARCH MEMORY FOR A BYTE STRING

;GLOVAL VARIABLES USED
;LINPTR - INPUT LINE CHARACTER POINTER
;LISPTR - COMMAND LIST CHARACTER POINTER
;RANGLO - "SEARCH FROM" ADDRESS
;RANHI - "SEARCH TO" ADDRESS

;LOCAL VARIABLES USE
;MEMADR - STARTING MEMORY ADDRESS WHERE A MATCH
;                       OCCURRED
;BYTPTR - ADDRESS POINTER USED TO FILL BYTSTR AND
;                       SUBSTR BUFFERS
;NBYTES - NUMBER OF BYTES IN BYTE STRING
;NBRFMT - NUMBER OF CHARS THAT MATCH SO FAR IN THE
;                       MATCHING PROCESS
;BYTSTR - STARTING ADDRESS OF 6 CHARACTER BYTE STRING
;                       BUFFER

;THE SEARCH STRING OCCUPIES TEMP4, TEMP5, & TEMP6 (6
;                       BYTES MAX)

;GET SEARCH RANGE BEGINNING (RANGLO) & END (RANGHI)
SEARCH JSR    GTRANG
       BLE    SEARC9   ;ABORT IF NO PAIR

;INITIALIZED BYTE STRING POINTER
       LDX    #BYTSTR  ;GET START OF BYTE STRING TO
;                        SEARCH FOR
       STX    BYTPTR   ;SET POINTER TO IT

       CLR    NBYTES   ;ZERO # OF BYES IN BYTE STRING

;GET BYTE STRING
SEARC1 JSR    NUMBER   ;GET A BYTE
       BEQ    SEARC2   ;BEGIN SEARCH IF EOL
       BLT    SEARC9

;GOOD BYTE, ADD IT TO STRING
       INC    NBYTES   ;COUNT THIS BYTE
;DON'T ACCEPT OVER 6 BYTES
       LDAA   NBYTES
       CMPA   #6
       BGT    SEARC9

       LDAA   NBRLO    ;GET (LOW ORDER) BYTE
       LDX    BYTPTR   ;GET BYTE POINTER
       STAA   X        ;SAVE BYTE
;                       MOVE BYTE POINTER TO NEXT
;                        LOCATION IN STRING
       STX    BYTPR    ;SAVE IT
       BRA    SEARC1

;BEGIN SEARCH FOR BYTE STRING
;IS # OF BYTES TO LOOK FOR >0
SEARC2 TST    NBYTES
       BEQ    SEARC9   ;IF NOT, BAD SYNTAX

;MAKE USE OF INOUT LINE CHARACTER FETCH & COMMAND LIST
;                       CHAR FETCH ROUTINES

;INITIALIZE BYE POINTER TO START OF BYTE STRING
SEARC3 LDX    #BYTSTR-1
       STX    LISPTR

       CLR    NBRFMT   ;SET "NUMBER OF BYTES THAT
;                           MATCHED" TO ZERO
;GET BYTE FROM BYTE STRING & RETURN IT IN ACCA
       JSR    GETLST
;GET BYTE FROM MEMORY RANGE & RETURN IT IN ACCB
SEARC4 JSR    GETCHR

       CBA             ;COMPARE MEMORY & BYTE STRING
;                        CHARACTERS
       BEQ    SEARC5   ;IF NO MATCH, TEST FOR RANGE END
       CPX    RANGHI   ;HAVE WE REACHED THE RANGE
;                        SEARCH UPPER LIMIT?
       BEQ    SEAR10   ;YES, GO PROMPT FOR NEXT COMMAND
       BRA    SEARC4

;MATCH ACHIEVED - SAVE ADDRESS OF MATCH
SEARC5 STX    MEMADR
SEARC6 INC    NBRFMT   ;BUMP NUMBER MATCHED
       LDAA   NBRFMT
       CMPA   NBYTES   ;HAVE ALL CHARACTERS MATCHED?
       BEQ    SEARC8   ;IF SO, MATCH ACHIEVED
;HAVEN'T MATCHED ALL YET, GO GET NEXT PAIR EVEN IF PAST "SEARCH TO" ADDRESS
       JSR    GETLST
       JSR    GETCHR
       CBA
       BEQ    SEARC6
;MISMATCH ON SOME BYTE PAST THE FIRST ONE
;RESET THE MEMORY POINTER TO GET NEXT UNTESTED MEMORY
;                       LOCATION
SEARC7 LDX    MEMADR
;THIS TEST HANDLES SPECIAL CASE OF A MATCH ON RANGE END
       CPX    RANHI
       BEQ    SEAR10
       STX    LINPTR
;GO RESET THE BYTE STRING POINTER
       BRA    SEARC3

;MATCH ON BYTE STRING ACHIEVED, TYPE OUT MEMOY ADDRESS
SEARC8 LDX    #MEMADR
       JSR    OUT2BY
       JSR    OUTSP    ;AND A SPACE
;ASSUME A MISMATCH (I.E., RESET MEMORY & BYTE STRING
;                       POINTERS & CONTINUE
       BRA    SEARC7

SEARC9 JMP    BADSYN
SEAR10 JMP    NOMORE

;*****
;TEST - TEST RAM FOR BAD BYTES
;GET AN ADDRESS RANGE
TEST   JSR    GTRANG
       BLE    SEARC9   ;ABORT IF NO PAIR
;RANGLO HOLS STARTING ADDRESS OF RANGE
;RANGHI HOLDS ENDING ADDRESS OF RANGE
       LDX    RANGLO
       STX    MEMADR
;GET BYTE STORED AT TEST LOCATION & SAVE IT
TEST1  LDAA   X
       PSHA

       CLR    X        ;ZERO THE LOCATION
       TST    X        ;TEST IT
       BEQ    TEST2    ;OK IF = ZERO

;CAN'T CLEAR LOCATION
       LDX    #MSGCCL
       BRA    TEST4

TEST2  DEC    X        ;SET LOCATION TO FF
       LDAA   #FF
       CMPA   A        ;FIF IT GET SET TO FF?
       BEQ    TEST3

;CAN'T SET LOCATION TO ONE'S
       LDX    #MSGCSO
       BRA    TEST4

TEST3  LDX    MEMADR   ;GET LOCATION BEING TESTED
       PULA
       STAA   X        ;RESTORE PREVIOUS CONTENT

;HIT END OF TEST RANGE?
       CPX    RANGHI
       BEQ    SEAR10   ;YES, ALL DONE

;NO, MOVE TO TEST NEXT LOCATION
       INX
       STX    MEMADR
       BRA    TEST1

;*LOCATION IS BAD
TEST4  STX    TEMP3    ;SAVE ERROR MESSAGE TEMPORARILY

       LDX    #MEMADR
       JSR    OUT2BY   ;TYPE OUT BAD ADDRESS.
       JSR    OUTEQ    ;AN EQUAL SIGN

       LDX    MEMADR
       JSR    OUT1BY   ;ITS CONTENT.
       JSR    OUTSP    ;A SPACE.
       LDX    TEMP3
       JSR    OUTSTR   ;AND THE TYPE OF ERROR

       JSR    DOCRLF   ;SEND CR-LF
       BRA    TEST3
;*****
;INT - SET UP INTERRUPT POINTER
INT    JSR    NUMINX   ;GET POINTER IN IX
       STX    INTVEC   ;SAVE IT
       BRA    COMPA1

;*****
;NMI - SET UP NON-MASKABLE INTERRUPT POINTER
NMI    JSR    NUMINX   ;GET POINTER IN IX
       STX    NMIVEV   ;SAVE IT
       BRA    COMPA1

;*****
;SWI - SET UP SWI POINTER
LSWI   JSR    NUMINX   ;GET POINTER TO IX
       STX    SWIVEC   ;SAVE IT
       BRA    COMPA1

;*****
;COMPARE - OUTPUT SUM & DIFFERENCE OF TWO INPUT NUMBERS
COMPAR JSR    NUMINX   ;GET FIRST NUMBER
       STX    RANGLO   ;PUT IT IN RANGLO

       JSR    NUMINC   ;GET SECOND NUMBER
       STX    NBRHI    ;SAVE IT IN NBRHI

;COMPUTE AND OUTPUT THE SUM
       JSR    SUMNUM   ;COMPUTE SUM
       LDX    #MSGIS   ;GETS ITS TITLE
       BSR    OUTSD    ;OUTPUT TITLE & SUM

       JSR    DIFNUM   ;COMPUTE DIFFERENCE
       LDX    #MSGDIS  ;GET ITS TITLE
       BSR    OUTSD    ;OUTPUT TITLE & DIFFERENCE

COMPA1 JMP    NOMORE

;COMPUTE AND OUTPUT THE RESULT
OUTSD  JSR    OUTSTR   ;OUTPUT IT
       LDX    #RANGHI  ;GET RESULT
       JSR    OUT2BY   ;DISPLAY RESULT
       RTS
;*****
;DUMP - DUMP A PORTION OF MEMORY, IN MIKBUG FORMAT, TO
;       A SPECIFIED ACIA ADDRESS

;GET ADDRESS RANGE: START IN RANGLO (2 BYTES), END IN
;                       RANGHI (2 BYTES)
;IF NO ADDRESS RANGE IS GIVEN, USE WHATEVER IS IN
;                       RANGLO & RANGHI
DUMP   JSR    GTRANG

       CLR    TEMP5    ;INITIALIZETO DUMP TO TERMINAL

;LOOK FOR A "TO" MODIFIER
DUMP1  LDAA   #2
       JSR    COMAND
       BEQ    DUMP4
DUMP2  BLE    DUMP10   ;ERROR IF BAD SYNTAX
       CMPA   #1       ;TO?
       BEQ    DUMP3
       BRA    DUMP1    ;GO LOOK FOR ANOTHER MODIFIER

DUMP3  JSR    NUMINX   ;GET "TO" ADDRESS
       STX    OUTADR   ;SAVE IT
       INC    TEMP5    ;REMEMBER THIS
       BRA    DUMP1    ;GO LOOK FOR ANOTHER MODIFIER

DUMP4  TST    TEMP5
       BEQ    DUMP5
       INC    OUTFLG   ;SET FLAG FOR PROPER OUTPUT
;                        DEVICE
DUMP5  BSR    NULLS    ;SEND SOME NULLS

;MIKBUG MODE
;OUTPUT AN "S0" TYPE RECORD
       LDX    #MSGS0
       JSR    OUTSTR

;COMPUTER # OF BYTES TO OUTPUT (RANGE END - RANGE START
;                       + 1)
;SUBTRACT LO BYTES
DUMP6  LDAA   RANGHI+1
       SUBA   RANGLO+1
;SUBTRACT HI BYTES
       LDAB   RANGHI
       SBCB   RANGLO
;NON-ZERO HI BYTE IMPLIES LOTS TO OUTPUT
       BNE    DUMP7
;HI BYTE DIFF IS ZERO
       CMPA   #16      ;LO BYTE OF DIFF 0 TO 15
       BCS    DUMP8    ;IF YES, TO DUMP8
DUMP7  LDAA   #15      ;NO, LO BYTE IS 16-255; SET
;                        BYTES TO 15
;TO GET FRAME COUNT, ADD 1 (DIFF OF 0 IMPLIES 1
;                       OUTPUT) + # OF DATA BYTES,
; + 2 ADDR BYTES + 1 CHECKSUM BYTE
DUMP8  ADDA   #4
       STAA   TEMP3    ;TEMP3 IS THE FRAME COUNT
       SUBA   #3
       STAA   TEMP4    ;TEMP4 IS THE RECORD BYTE COUNT
;OUTPUT A MIKBUG "S1" HEADER DATA RECORD
       LDX    #MSG1
       JSR    OUTSTR
       CLRB            ;ZERO CHECKSUM
;PUNCH FRAME COUNT
       LDX    #TEMP3
       BSR    OUTP2

;PUNCH ADDRESS
       LDX    #RANGLO
       BSR    OUTP2
       BSR    OUTP2

;OUTPUT DATA
       LDX    RANGLO
DUMP9  BSR    OUTP2    ;OUTPUT DATA BYTE
       DEC    TEMP4    ;DEC BYTE COUNT
       BNE    DUMP9

;COMPLEMENT AND PUNCH THE CHECKSUM
       STX    RANGLO   ;SAVE MEMORY POINTER
       COMB            ;COMPLEMENT CHECKSUM
       PSHB            ;PUT IT ON STACK
       TSX             ;LET IX POINT TO IT
       BSR    OUTP2    ;OUTPUT CHECKSUM
       PULB            ;PULL IT OFF STACK
       LDX    RANGLO   ;RESTORE MEMORY POINTER
       DEX
       CPX    RANGHI   ;HIT END OF RANGE?
       BNE    DUMP6

;YES, OUTPUT AN "S9" RECORD
       LDX    #MSGS9
       JSR    OUTSTR
       BSR    NULLS    ;GENERATE BLANK TAPE
       CLR    OUTFLG   ;SET TO TERMINAL OUTPUT
       JMP    NOMORE   ;ALL DONE
DUMP10 JMP    BADSYN   ;BAD SYNTAX

;SEND A STRING OF NULLS
NULLS  LDAB   #30
       CLRA
NULLS1 JSR    OUTCHR
       DECB
       BNE    NULLS1
       RTS

;OUTPUT A BYTE POINTED TO BY IX AS 2 HEX CHARACTERS
OUTP2  ADDB   X        ;UPDATE CHECKSUM
       JSR    OUT1BY
       INX
       RTS
;*****
;LOAD - LOAD A MIKBUG TAPE
;LOOK FOR A "FROM" MODIFIER
LOAD   LDAA   #7       ;IN LIST 7
       JSR    COMAND
       BMI    DUMP10   ;ERROR, UNRECOGNIZABLE MODIFIER
       BEQ    LOAD2

       JSR    NUMINX   ;GET "FROM" ADDRESS
       STX    INPADR   ;SAVE IT
       INC    INPFLG   ;SET FLAG FOR NON-TERMINAL ACIA

;KEEP READING CHARACTERS UNTIL AN "S" IS READ
LOAD1  JSR    INPCHR   ;GET A CHAR
       CMPA   #'S'     ;IS IT AN S?
       BNE    LOAD1

;GOT AN "S", EXAMINE NEXT CHARACTER
       JSR   INPCHR
       CMPA   #'9'     ;DONE IF ITS A "9"
       BEQ    LOAD4

       CMPA   #'1'     ;IS IT A "1"?
       BNE    LOAD1    ;IF NOT, LOOK FOR NEXT "S"
;VALID S1 RECORD
       CLR    CKSM     ;CLEAR CHECKSUM
;READ RECORD BYTE COUNT
       JSR    RDBYTE
       SUBA   #2
       STAA   BYTECT   ;SAVE COUNT MINUS 2 ADDRESS BYTES

       BSR    BLDAR    ;BUILD ADDRESS

LOAD2  BSR    RDBYTE   ;READ A DATA BYTE INTO ACCA
       BEQ    LOAD3    ;IF DONE WITH RECORD, CHECK
;                        CHECKSUM
       STAA   X        ;NOT DONE, STORE BYTE IN MEMORY
       INX             ;ON TO NEXT MEMORY ADDRESS
       BRA    LOAD2

;RECORD READ IN COMPLETE
LOAD3  INC    CKSM     ;TEST CHECKSUM BY ADDING 1
       BEQ    LOAD1    ;IF OK, RESULT SHOULD BE ZERO

;RECORD CHECKSUM ERROR
       LDX    #MSGNVE  ;SAY SO
       JSR    OUTSTR
       LDX    #TEMP1   ;GET RECORD ADDRESS OF IT   
       JSR    OUT2BY   ;TYPE IT TOO
LOAD4  CLR    INPFLG   ;RESET FLAG TO NORMAL TERMINAL
;                        INPUT
       JMP    NOMORE

;BUILD ADDRESS
BLDADR BSR    RDBYTE
       STAA   TEMP1
       BSR    RDBYTE
       STAA   TEMP1+1
       LDX    TEMP1
       RTS
RDBYTE BSR    INHEX    ;GET LEFT HEX DIGIT
;MOVE TO HI 4 BITS
       ASLA
       ASLA
       ASLA
       ASLA
       TAB             ;SAVE IT IN ACCA
       BSR    INHEX    ;GET RIGHT HEX DIGIT
       ABA             ;COMBINE THEM IN ACCA
;UPDATE THE CHECKSUM
       TAB
       ADDB   CKSUM
       STAB   CKSUM
       RTS

;INPUT A HEX CHAR & CONVERT TO INTERNAL FORM
INHEX  JSR    INPCHR   ;INPUT A CHAR
       SUBA   #$30
       BMI    INHEX2   ;NOT HEX IF BELOW ASCII "1"
       CMPA   #$09
       BLE    INHEX1   ;OK IF ASCII "9" OR LESS
       CMPA   #$11     ;BELOW ASCII "A"?
       BMI    INHEX2   ;ERROR IF IT IS
       CMPA   #$16     ;OVER ASCII "F"?
       BGT    INHEX2   ;ERROR IF IT IS
       SUBA   #7       ;CONVERT ASCII A-F TO HEX A-F
INHEX1 RTS
;ERROR - CHAR NOT HEX, SAY SO
INHEX2 LDX    #MSGCNH
       JSR    OUTSTR
       RTS

;*****
;DELAY - DELAY SPECIFIED # OF MILLISECONDS
DELAY  JSR    NUMINX   ;GET DELAY TIME
       BSR    TIMDEL
       JMP    NOMORE

;**
;TIME DELAY SUBROUTINE
;IX IS INPUT AS THE # OF MILLISECONDS TO DELAY
;ACCA IS ALTERED
;ACCB IS PRESERVED
;ADJ TIMCON SO (6*TIMCON*CYCLE TIME=1 MS)
TIMDEL LDAA   TIMCON
;ENTER A 6 CYCLE LOOP
TIMDE1 DECA
       BNE    TIMDE1

       DEX             ;DECREMENT MILLISECOND COUNTER
       BNE    TIMDEL
       RTS

;====================================================

;  C O M M A N D     L I S T     S C A N N I N G    R O U T I N E

;THIS ROUTINE SEEKS A MATCH OF THE CHARATERS POINTED
;                       AT
;BY THE INPUT LINE SCANNING POINTER TO ONE OF THE
;                       COMMANDS
;IN A LIST SPECIFIED BY ACCA.
;
; AS FOLLOWS:
;
;      ACCA=-1: THE MATCH WAS UNSUCCESSFUL.  THE SYNTAX
;               POINTER (SYNPTR) WAS NOT UPDATED
;                       (ADVANCED).
;
;      ACCA= 0: THE MATCH WAS UNSUCCESSFUL SINCE THERE
;                       WERE
;               NO MORE CHARACTERS, I.E., THE END IF
;                       THE
;               LINE WAS REACHED.
;
;      ACCA=+N: SUCCESSFUL MATCH.  THE SYNTAX POINTER
;                       WAS UPDATED
;               TO THE FIRST CHARACTER FOLLOWING THE
;                       COMMAND
;               DELIMITER.  ACCA HOLDS THE NUMBER OF
;                       THE
;               COMMAND MATCHEC.
;GLOBAL VARIABLED FOR EXTERNAL COMMUNICATION
;SYNPTR - GOOD SYNTAX INPUT CHAR LINE POINTER
;LINPTR - INPUT LINE CHARACTER POINTER
;DELIM - CLASS OF PERMISSIBLE COMMAND DELIMITERS

;TEMPORARY 2 BYTE INTERNAL VARIABLES
;LISPTR - COMMAND LIST CHARACTER POINTER

;TEMPORARY 1 BYTE INTERNAL VARIABLES
;NUMMAT - NUMBER OF CHARACTERS THAT SUCCESSFULLY MATCH
;LISNUM - # OF LIST WITHIN WHICH A MATCH WILL BE SIUGHT
;COMNUM - COMMAND NUMBER MATCHED

;CONSTANTS USED
;CR - CARRIAGE RETURN
;LF - LINE FEED

;ACCB & IX ARE NOT PRESERVED.

COMAND STAA   LISNUM   ;SAVE LIST # TO MATCH WITHIN
;TEST IF WE ARE AT THE END OF THE LINE
       JSR    SKPDLM
       BCC    INILST
       CLRA
       RTS


;INITIALIZE THE COMMAND LIST POINTER TO ONE LESS THAN
;                       THE BEGINNING OF THE COMMAND LI
;                       STS
INILST LDX    COMADR   ;ENTRY POINT

;MOVE TO THE BEGINNING OF THE DESIRED COMMAND LIST
       LDAA   LISNUM   ;SEARCH FOR "STRING" # LISNUM
       LDAB   #LF      ;USE LF AS A "STRING" TERMINATOR
       BSR    FNDSTR
       STX    LISPTR

;THE LIST POINTER, LISPTR, NOW POINTS TO ONE LESS THAN
;                       THE FIRST CHARACTER
;OF THE FIRST COMMAND IN THE DESIRED LIST
; INITIALIZE THE COMMAND # TO 1
       LDAA   #1
       STAA   COMNUM

;RESET INPUT LINE POINTER TO: 1) BEGINNING OF LINE, OR
;                       TO
;  2) POINT WHERE LAST SUCCESSFUL SCAN TERMINATED
CMD3   LDX    SYNPTR
       STX    LNPTR

       CLR    NUMBAT   ;CLEAR NUMBER OF CHARACTERS
;                        MATCHED
CMD4   JSR    GETCHR   ;GET INPUT LINE CHAR IN ACCB
       JSR    TSTDLM   ;TEST FOR A DELIMITER
       BNE    MATCH    ;SUCCESS (FOUND DELIMITER) IF
;                        NOT = ZERO

       JSR    GETLST   ;GET COMMAND LIST CHAR IN ACCA
       CMPA   #LF      ;HAS END OF COMMAND LIST BEEN REACHED?
       BEQ    NMATCH   ;IF SO, POTENTIAL MATCH FAILURE

       CBA             ;COMPARE THE TWO CHARACTERS
       BNE    NEXCOM   ;MATCH NOT POSSIBLE ON THIS COMMAND

;THEY MATCH, COMPARE THE SUCCEEDING CHARACTERS
       INC    NUMMAT   ;INC NUMBER OF CHARACTERS MATCHED
       BRA    CMD4

;;;
;SUCCESSFUL MATCH - RETURN COMMAND NUMBER MATCHED IN ACCA
MATCH  LDAA   COMNUM
       LDX     LINPTR
       STX     SYNPTR  ;UPDATE GOOD SYNTAX POINTER
       RTS




;......YYYYYYYZZZZZZZZZ;
