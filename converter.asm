TITLE String/Integer Converter          (converter.asm)

; Author: George Hill
; Last Modified: 2019-12-03
; OSU email address: hillge@oregonstate.edu
; Course number/section: CS 271-400
; Project Number: Program #6
; Due Date: 2019-12-08 (PT)
; Description: This program demonstrates the procedures ReadVal and WriteVal. ReadVal uses
;    the macro getString, which uses Irvine's ReadString, to get a string from the user; ReadVal
;    then converts that string to an integer (if possible) and returns that integer. WriteVal
;    accepts an integer, converts it to a string, and then displays that string by using the
;    macro displayString, which in turn uses Irvine's WriteString. To demonstrate these
;    procedures, this program asks the user to enter ten integers; the program then displays
;    those integers, their sum, and their average.

INCLUDE Irvine32.inc

LONGEST_LEN = 12                        ; When WriteVal generates a string, the string
                                        ; will have at most this many characters (including
                                        ; the null terminator).
ARRAY_LEN = 10                          ; We will ask for 10 integers.
USER_STRING_LEN = 16                    ; We will accept input of a string of up to
                                        ; 16 characters (including the null terminator).

; The following macro is adapted from demo8.asm, one of the demo programs provided in this
;    course.

mWrite MACRO buffer
     push      edx                      ; Preserve register.

     mov       edx, OFFSET buffer
     call      WriteString

     pop       edx                      ; Restore register.
ENDM

getString MACRO prompt, response, response_length
     push      ecx
     push      edx

     mov       edx, prompt
     call      WriteString

     mov       edx, response
     mov       ecx, [response_length]
     call      ReadString

     pop       edx
     pop       ecx
ENDM

displayString MACRO buffer
     push      edx

     mov       edx, buffer
     call      WriteString

     pop       edx
ENDM

.data

lowestString   BYTE      "-2147483648", 0

greeting1      BYTE      "String/Integer Converter", 0
greeting2      BYTE      "By George Hill", 0

extraCredit1   BYTE      "**EC: Numbers each line of user input and displays running subtotal.", 0
extraCredit2   BYTE      "**EC: Correctly handles signed input.", 0

introduction1a BYTE      "Please provide ", 0
introduction1b BYTE      " decimal integers in the range [-2147483648, +2147483647].", 0
introduction2  BYTE      "This program will then display those integers, their sum, and their average.", 0

array          SDWORD    ARRAY_LEN DUP(1)

prompt1a       BYTE      "#", 0
prompt1b       BYTE      ": ", 0
prompt2        BYTE      "Please enter an integer: ", 0

criticism      BYTE      "You entered an invalid value. Please try again.", 0

subtotalStr    BYTE      "The sum of your integers so far is: ", 0

sum            SDWORD    0
average        SDWORD    0

youEntered     BYTE      "You entered the following numbers:", 0
delimiter      BYTE      ", ", 0
theSum         BYTE      "The sum of those numbers is: ", 0
theAverage     BYTE      "The (rounded) average of those numbers is: ", 0

valediction1   BYTE      "I hope you find this helpful. Thank you. Good-bye.", 0

exitMessage    BYTE      "Press any key to exit.", 0

.code

main PROC

     call      introduction             ; Displays greeting1, greeting2, extraCredit1, extraCredit2,
                                        ; introduction1a, introduction1b, introduction2.

     push      OFFSET array
     push      ARRAY_LEN
     call      getArrayVals             ; Fills array with ARRAY_LEN user-submitted integers.

     push      OFFSET array
     push      ARRAY_LEN
     push      OFFSET sum
     push      OFFSET average
     call      calculate                ; Calculates sum and average of array.

     push      OFFSET array
     push      ARRAY_LEN
     push      sum
     push      average
     call      report                   ; Displays array, sum, and average.

     call      valediction              ; Displays valediction1 and exitMessage.

     exit                               ; Exits to operating system.

main ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadVal PROC

; Procedure to accept numeric string input from the keyboard and return the
;    corresponding number value.
;
; Receives: The address of a prompt string and the address that is to receive
;    the numeric value of the user's input.
; Returns: The numeric value of the user's input.
; Preconditions: None.
; Postconditions: The address that is to receive the numeric value of the user's
;    input will in fact contain the numeric value of the user's input.
; Registers changed: None.

     push      ebp                      ; Preserve ebp.
     mov       ebp, esp                 ; Make stack frame for accessing parameters.

PROMPT_param   EQU [ebp + 12]
RESPONSE_param EQU [ebp + 8]

     sub       esp, 32                  ; Reserve space for local variables.

VALUE_local    EQU SDWORD PTR [ebp - 4]
IS_NEG_local   EQU SDWORD PTR [ebp - 8]
IS_VALID_local EQU DWORD PTR [ebp - 12]
STRING_local   EQU BYTE PTR [ebp - 28]
MAX_LEN_local  EQU DWORD PTR [ebp - 32]

     push      eax                      ; Preserve these registers.
     push      ebx
     push      ecx
     push      edx
     push      esi

initializeAndPrompt:

     mov       VALUE_local, 0           ; This will be where we store the numeric value
                                        ; that we are building.
     mov       IS_NEG_local, 0          ; 0 = maybe, 1 = no, positive, -1 = yes, negative.
     mov       IS_VALID_local, 0        ; 0 = not yet, 1 = we have a valid value.

;    mov       edx, PROMPT_param        ; For debuggging only.
;    call      WriteString
;
;    mov       eax, 12345
;    mov       edx, RESPONSE_param
;    mov       [edx], eax

     mov       ebx, ebp
     sub       ebx, 28                  ; ebx contains the address of STRING_local.

;    getString PROMPT_param, ebx, USER_STRING_LEN
                                        ; Originally, I was going to have just this. But then
                                        ; I re-read Requirement 4, and I concluded that I
                                        ; need to do the following . . .

     mov       MAX_LEN_local, USER_STRING_LEN
     mov       eax, ebp
     sub       eax, 32                  ; eax contains the address of MAX_LEN_local.

     getString PROMPT_param, ebx, eax

;    mov       eax, ebp                 ; For debugging only.
;    sub       eax, 28
;    mov       edx, eax
;    call      WriteString
;    call      CrLF

     cld                                ; Set direction = forward.
     mov       esi, ebx                 ; ebx still contains the address of STRING_local.

processString:

     mov       eax, 0                   ; Clear the register.
     lodsb                              ; Load a byte from the string into AL.

     cmp       eax, 0                   ; See if we are at the end.
     je        reachedEndOfString

     cmp       eax, 43                  ; See if we have a plus-sign character.
     je        processPlusSign

     cmp       eax, 45                  ; See if we have a minus-sign character.
     je        processMinusSign

     cmp       eax, 48                  ; See if the character comes before "0".
     jb        illegalCharacterOrOverflow

     cmp       eax, 57                  ; See if the chracter comes after "9".
     ja        illegalCharacterOrOverflow

; Otherwise we have a legal digit:

     mov       IS_VALID_local, 1        ; Having at least one digit makes it possible to have
                                        ; a valid value.

     cmp       IS_NEG_local, 0          ; If IS_NEG_local == -1 or 1, then we have already
                                        ; seen and processed a sign character.
     jne       weHaveAlreadySeenASignCharacter

     mov       IS_NEG_local, 1          ; Otherwise, the first legal digit makes us default
                                        ; to a positive number.

weHaveAlreadySeenASignCharacter:

     sub       eax, 48                  ; Convert ASCII to numeric value.

     mov       ebx, IS_NEG_local        ; Multiply by IS_NEG_local so that we only deal
     imul      ebx                      ; with one kind of number (i.e. only negative or
                                        ; only positive).

     mov       ecx, eax                 ; Save this digit for later.

     mov       eax, VALUE_local         ; Recall our previously constructed value and
     mov       ebx, 10                  ; multiply by 10 to shift it one decimal place
     imul      ebx                      ; left.

     jo        illegalCharacterOrOverflow

     add       eax, ecx                 ; Add the current digit back in at the right.

     jo        illegalCharacterOrOverflow

     mov       VALUE_local, eax         ; Store the current value for later.

     jmp       processString

processPlusSign:

     cmp       IS_NEG_local, 0          ; Make sure that we haven't seen a sign character yet.
     jne       illegalCharacterOrOverflow

     mov       IS_NEG_local, 1

     jmp       processString

processMinusSign:

     cmp       IS_NEG_local, 0          ; Make sure that we haven't seen a sign character yet.
     jne       illegalCharacterOrOverflow

     mov       IS_NEG_local, -1

     jmp       processString

reachedEndOfString:

     cmp       IS_VALID_local, 0        ; Make sure that we have seen at least one digit!
     je        illegalCharacterOrOverflow

     mov       eax, VALUE_local
     mov       edx, RESPONSE_param
     mov       [edx], eax               ; Return VALUE_local in the memory location pointed
                                        ; to by RESPONSE_param.

     jmp       cleanUp

illegalCharacterOrOverflow:

     mWRite    criticism
     call      CrLf

     jmp       initializeAndPrompt

cleanUp:

     pop       esi                      ; Restore these registers.
     pop       edx
     pop       ecx
     pop       ebx
     pop       eax

     mov       esp, ebp                 ; Unreserve space for local variables.

     pop       ebp                      ; Restore old ebp.
     ret       8                        ; Skip over parameters.

ReadVal ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteVal PROC

; Procedure to convert an SDWORD numeric value into a string, and then display
;    the string.
;
; Receives: The value to be displayed on the system stack.
; Returns: Nothing.
; Preconditions: Global constant LONGEST_LEN must equal 12, which is the longest
;    number of chacters necessary for a string to contain an SDWORD value; the 12
;    characters includes a null character at the end. Global string variable
;    lowestString must contain "-2147483648", which is the string representation of
;    the lowest value possible for an SDWORD.
; Postconditions: The passed value will be displayed.
; Registers changed: None.

     push      ebp                      ; Preserve ebp.
     mov       ebp, esp                 ; Make stack frame for accessing parameters.

VALUE_param    EQU [ebp + 8]

     sub       esp, LONGEST_LEN         ; Reserve space for local variables.

BUFFER_local   EQU BYTE PTR [ebp - LONGEST_LEN]

     push      eax                      ; Preserve these registers.
     push      ebx
     push      ecx
     push      edx
     push      edi
     push      esi

; Initialize BUFFER_local:

     mov       edi, ebp
     sub       edi, LONGEST_LEN

     mov       ecx, LONGEST_LEN

     mov       al, 0

     cld

     rep       stosb                    ; Fill BUFFER_local with null characters.

; Initialize for STOSBing values into BUFFER_local:

     mov       edi, ebp
     sub       edi, LONGEST_LEN

     cld                                ; For redundancy.

; See if the value is negative:

     mov       eax, VALUE_param
     cmp       eax, 0
     jge       valueIsNotNegative

; See if the negative value is too low to be inverted:

; (The plan for most negative numbers is to generate a less-than sign, then flip the sign
;    on the number so that it becomes its positive counterpart. However, an SDWORD's lowest
;    value [-2147483648], has a positive counterpart [+2147483648] that doesn't fit in an
;    SDWORD, so that plan won't work for that particular case.)

     mov       eax, VALUE_param         ; For redundancy.
     cmp       eax, -2147483648
     jne       weCanJustPrefixAndInvert

; It _is_ too low to be inverted, so we're going to have to set the string's value directly:

     mov       esi, OFFSET lowestString

     mov       edi, ebp                 ; For redundancy.
     sub       edi, LONGEST_LEN

     mov       ecx, LONGEST_LEN

     cld                                ; For redundancy.

copyLoop:                               ; We will copy lowestString into our output string.

     lodsb
     stosb
     loop      copyLoop

     jmp       displayTheString

weCanJustPrefixAndInvert:

; At this point, we're dealing with a negative value; we're going to generate a less-than
;    sign and then invert the value to its positive counterpart.

     mov       AL, '-'                  ; Prefix.
     stosb

     mov       eax, VALUE_param         ; Invert.

     mov       ebx, -1

     imul      ebx

valueIsNotNegative:

; At this point, eax still contains the correct value (i.e. either VALUE_param or
;    VALUE_param * -1).

     mov       ecx, 0                   ; ecx will track the number of times we have pushed
                                        ; a digit to the stack.

     mov       ebx, 10                  ; We're going to be dividing eax by 10 repeatedly.

divisionLoop:

     mov       edx, 0                   ; We need a clean top register for idiv.

     cmp       eax, 10
     jl        foundLastDigit

     mov       ebx, 10                  ; For redundancy.

     idiv      ebx

     push      edx                      ; Push the remainder to the stack; it's one of the
                                        ; digits that we are going to want to display.
     inc       ecx

     jmp       divisionLoop

foundLastDigit:

     push      eax
     inc       ecx

; Now pop and concatenate:

; (At this point, ecx contains the number of single digits we have pushed to the stack.)

popLoop:

     pop       ebx                      ; This is one of our digits.
     add       ebx, 48                  ; We just converted it to its ASCII value.

     mov       al, bl
     stosb                              ; Stick that digit into our output string.

     loop      popLoop

displayTheString:

; Actually display the created string:

     mov       esi, ebp
     sub       esi, LONGEST_LEN

     displayString  esi

; Clean up:

     pop       esi                      ; Restore these registers.
     pop       edi
     pop       edx
     pop       ecx
     pop       ebx
     pop       eax

     mov       esp, ebp                 ; Unreserve space for local variables.

     pop       ebp                      ; Restore old ebp.
     ret       4                        ; Skip over parameters.

WriteVal ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

introduction PROC

; Procedure to display introductory information for the user.
;
; Receives: Nothing from the stack or via the registers. However, per lectures,
;    it uses global string variables to display strings for the user.
; Returns: Nothing.
; Preconditions: Global string variables greeting1, greeting2, exraCredit1,
;    extraCredit2, introduction1a, introduction1b, introduction2. Global constant
;    ARRAY_LEN.
; Postconditions: Information displayed for the user.
; Registers changed: None.

     push      eax                      ; Preserve this register.

     call      CrLf                     ; When run from the command line, this puts
                                        ; a blank line between the command and the program's
                                        ; output.

     mWrite    greeting1
     call      CrLf

     mWrite    greeting2
     call      CrLf

     call      CrLf

     mWrite    extraCredit1
     call      CrLf

     mWrite    extraCredit2
     call      CrLf

     call      CrLf

     mWrite    introduction1a

     mov       eax, ARRAY_LEN
     call      WriteDec

     mWrite    introduction1b
     call      CrLf

     mWrite    introduction2
     call      CrLf

     call      CrLf

     pop       eax                      ; Restore this register.

     ret

introduction ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

getArrayVals PROC

; Procedure to fill an array with the necessary number of user-submitted integers
;    while numbering each line of input and reporting the running subtotal.
;
; Receives: The address of the array and the value that tells how many elements
;    the array contains.
; Returns: The array.
; Preconditions: The value that tells how many elements the array contains must be
;    correct.
; Postconditions: The array will be filled with user-submitted integers.
; Registers changed: None.

     push      ebp                      ; Preserve ebp.
     mov       ebp, esp                 ; Make stack frame for accessing parameters.

ARRAY_param    EQU [ebp + 12]
LEN_param      EQU [ebp + 8]

     sub       esp, 12                  ; Reserve space for local variables:

STEP_local     EQU DWORD PTR [ebp - 4]
USER_VAL_local EQU SDWORD PTR [ebp - 8]
SUBTOTAL_local EQU SDWORD PTR [ebp - 12]

     push      eax                      ; Preserve these registers.
     push      ebx
     push      ecx
     push      edx

     mov       STEP_local, 1            ; Initialize.
     mov       SUBTOTAL_local, 0

inputLoop:

     mWrite    prompt1a

     mov       eax, STEP_local
     call      WriteDec

     mWrite    prompt1b

     push      OFFSET prompt2
     mov       eax, ebp
     sub       eax, 8
     push      eax                      ; Push the address of USER_VAL_local.
     call      ReadVal

; At this point, USER_VAL_local contains the numeric value that the user typed in.

;    mov       eax, USER_VAL_local      ; For debugging only.
;    call      WriteInt
;    call      CrLf

; Now, we need to store USER_VAL_local in the right spot in the array that starts
; at [ARRAY_param]:

     mov       eax, ebp
     add       eax, 12

     mov       ecx, [eax]

     mov       ebx, STEP_local
     dec       ebx
     shl       ebx, 2

     mov       edx, USER_VAL_local

     mov       [ecx + ebx], edx

; We also need to add USER_VAL_local to SUBTOTAL_local:

     mov       eax, USER_VAL_local
     add       SUBTOTAL_local, eax

; And we need to display the subtotal:

     mWrite    subtotalStr

;    mov       eax, SUBTOTAL_local      ; For debugging only.
;    call      WriteInt

     push      SUBTOTAL_local
     call      WriteVal
     call      CrLf

; And we need a blank line for formatting's sake.

     call      CrLf

; Now increment STEP_local and see if STEP_local > LEN_param:

     inc       STEP_local

     mov       eax, STEP_local
     cmp       eax, LEN_param

     ja        weAreDoneHere

     jmp       inputLoop

weAreDoneHere:

     pop       edx                      ; Restore these registers.
     pop       ecx
     pop       ebx
     pop       eax

     mov       esp, ebp                 ; Unreserve space for local variables.

     pop       ebp                      ; Restore old ebp.
     ret       8                        ; Skip over parameters.

getArrayVals ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

calculate PROC

; Procedure to calculate the sum and the average of the values in an array.
;
; Receives: The address of array, a value with the number of elements in array,
;    the address of a variable to receive the sum of the array, and the address
;    of a variable to receive the average of the array.
; Returns: The sum and the average of the values in an array.
; Preconditions: The array must be full of numeric values, and the number passed
;    with the number of elements in the array must be correct.
; Postconditions: The intended variables will contain the sum and the average of
;    the values in the array.
; Registers changed: None.

     push      ebp                      ; Preserve ebp.
     mov       ebp, esp                 ; Make stack frame for accessing parameters.

ARRAY_param2   EQU [ebp + 20]
LEN_param2     EQU [ebp + 16]
SUM_param2     EQU [ebp + 12]
AVERAGE_param2 EQU [ebp + 8]

                                        ; No local variables.

     push      eax                      ; Preserve these registers.
     push      ebx
     push      ecx
     push      edx
     push      esi

     mov       eax, ebp
     add       eax, 20
     mov       esi, [eax]               ; Now esi points to the start of the array.

     mov       ebx, 0                   ; We'll start with the 0th element.

     mov       ecx, LEN_param2          ; We have to process this many elements

     mov       eax, 0                   ; Initialize.

sumLoop:

     mov       edx, SDWORD PTR [esi + ebx]
     add       eax, edx

     add       ebx, 4

     loop      sumLoop

;    call      WriteInt                 ; For debugging only.
;    call      CrLf

; At this point, eax contains the sum; now we need to move it into SUM_param2.

     mov       ebx, ebp
     add       ebx, 12                  ; Now ebx contains the address, on the stack, of
                                        ; SUM_param2, which itself contains the address, in
                                        ; main memory, of sum.
     mov       ecx, [ebx]               ; Now ecx contains the address, in main memory, of
                                        ; sum.
     mov       [ecx], eax               ; Now sum = eax.

; Now it's time to calculate the average.

     cdq
     mov       ebx, LEN_param2
     idiv      ebx

;    call      WriteInt                 ; For debugging only.
;    call      CrLf

; At this point, eax contains the average (rounded down).

     mov       ebx, ebp
     add       ebx, 8                   ; Now ebx contains the address, on the stack, of
                                        ; AVERAGE_param, which itself contains the address, in
                                        ; main memory, of average.
     mov       ecx, [ebx]               ; Now ecx contains the address, in main memory, of
                                        ; average.
     mov       [ecx], eax               ; Now average = eax.

; We're done now!

     pop       esi                      ; Restore these registers.
     pop       edx
     pop       ecx
     pop       ebx
     pop       eax

                                        ; No local variables.

     pop       ebp                      ; Restore old ebp.
     ret       16                       ; Skip over parameters.

calculate ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

report PROC

; Procedure to display the contents of a numeric array, the sum of those values,
;    and the average of those values.
;
; Receives: The address of a numeric array, a value containing the number of elements
;    in that array, a value containing the sum of the array's values, and a value
;    containing the average of the array's values.
; Returns: Nothing.
; Preconditions: The value containing the sum of the arrays values and the value
;    containing the average of the array's values must actually be correct.
; Postconditions: The array and its statistics will be displayed.
; Registers changed: None.

     push      ebp                      ; Preserve ebp.
     mov       ebp, esp                 ; Make stack frame for accessing parameters.

ARRAY_param3   EQU [ebp + 20]
LEN_param3     EQU [ebp + 16]
SUM_param3     EQU [ebp + 12]
AVERAGE_param3 EQU [ebp + 8]

                                        ; No local variables.

     push      eax                      ; Preserve these registers.
     push      ecx
     push      esi

; List the array:

     mWrite    youEntered
     call      CrLf

     mov       eax, ebp
     add       eax, 20
     mov       esi, [eax]               ; Now esi points to the start of the array.

     mov       ebx, 0                   ; We'll start with the 0th element.

     mov       ecx, LEN_param3          ; We have to process this many elements

writeLoop:

     push      SDWORD PTR [esi + ebx]
     call      WriteVal

     cmp       ecx, 1
     je        skipDelimiter

     mWrite    delimiter

skipDelimiter:

     add       ebx, 4

     loop      writeLoop

     call      CrLf

     call      CrLf

; Display their sum:

     mWrite    theSum

     push      SUM_param3
     call      WriteVal
     call      CrLf

     call      CrLf

; Display their average:

     mWrite    theAverage

     push      AVERAGE_param3
     call      WriteVal
     call      CrLf

     call      CrLf

; Clean up:

     pop       esi                      ; Restore these registers.
     pop       ecx
     pop       eax

                                        ; No local variables.

     pop       ebp                      ; Restore old ebp.
     ret       16                       ; Skip over parameters.

report ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

valediction PROC

; Procedure to display valedictory information for the user.
;
; Receives: Nothing from the stack or via the registers. However, per lectures,
;    it uses global string variables to display strings for the user.
; Returns: Nothing.
; Preconditions: Global string variables valediction1 and exitMessage.
; Postconditions: Information displayed for the user.
; Registers changed: None.

     push      eax                      ; Preserve this register.

     mWrite    valediction1
     call      CrLf

     call      CrLf

     mWrite    exitMessage

     call      ReadChar                 ; This modifies AL (and hence eax).

     call      CrLf

     pop       eax                      ; Restore this register.

     ret

valediction ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

END main