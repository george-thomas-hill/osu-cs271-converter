# osu-cs271-converter

[![A screenshot of this program.](https://raw.githubusercontent.com/george-thomas-hill/osu-cs271-converter/main/cs271-converter-screenshot.png "Click to see screencast.")](http://georgethomashill.com/gh/osu/cs271/cs271-converter-screencast.mp4)

CS 271 was Oregon State University's computer architecture and assembly language course.

The assignment was to write an assembly language program that would include procedures for converting between strings and integers.

The main instructions were as follows:

> * Implement and test your own _ReadVal_ and _WriteVal_ procedures for unsigned integers. Your _ReadVal_ implementation will accept a numeric string input from the keyboard and will compute the corresponding integer value. For example, if the user entered a string "1234" then the numeric value 1234 would be computed (and stored in the requested OFFSET). _WriteVal_ will perform the opposite transformation. For example, _WriteVal_ can accept a 32 bit unsigned int and display the corresponding ASCII representation on the console (e.g. if _WriteVal_ receives the value 49858 then the text "49858" will be displayed on the screen).
>
> * Implement macros _getString_ and _displayString_. The macros may use [Irvine’s](http://asmirvine.com/gettingStartedVS2017/index.htm) _ReadString_ to get input from the user, and _WriteString_ to display output.
>
> * Additional details are as follows:
>
>   * _getString_ should display a prompt, then get the user’s keyboard input into a memory location.
>
>   * _displayString_ should print the string which is stored in a specified memory location.
>
>   * _ReadVal_ should invoke the _getString_ macro to get the user’s string of digits. It should then convert the digit string to numeric, while validating the user’s input.
>
>   * _WriteVal_ should convert a numeric value to a string of digits and invoke the _displayString_ macro to produce the output.
>
> * Once you have implemented the two procedures you will then demonstrate their usage by creating a small test program. The program will get 10 valid integers from the user and store the numeric values into an array. The program will then display the list of integers, their sum, and the average value of the list.

Please see [Assignment.pdf](https://github.com/george-thomas-hill/osu-cs271-converter/blob/main/Assignment.pdf) for further details.

The program that I wrote is contained in [converter.asm](https://github.com/george-thomas-hill/osu-cs271-converter/blob/main/converter.asm).

A working build of it is contained in [converter.exe](https://github.com/george-thomas-hill/osu-cs271-converter/blob/main/converter.exe), but I wouldn't expect you to download and run that. (For that matter, it actually triggers my antivirus software.)

To build it yourself, you could use Visual Studio and follow [Kip Irvine's](http://asmirvine.com/) [instructions](http://asmirvine.com/gettingStartedVS2017/index.htm).

Please note that my code requires Irvine's [libraries](http://asmirvine.com/gettingStartedVS2017/Irvine.zip).

A screencast of my program's execution can be viewed [here](http://georgethomashill.com/gh/osu/cs271/cs271-converter-screencast.mp4).

Sample output:

```
C:\CS271\Project 6 - Converter>converter.exe

String/Integer Converter
By George Hill

**EC: Numbers each line of user input and displays running subtotal.
**EC: Correctly handles signed input.

Please provide 10 decimal integers in the range [-2147483648, +2147483647].
This program will then display those integers, their sum, and their average.

#1: Please enter an integer: -3
The sum of your integers so far is: -3

#2: Please enter an integer: -2
The sum of your integers so far is: -5

#3: Please enter an integer: -1
The sum of your integers so far is: -6

#4: Please enter an integer: 0
The sum of your integers so far is: -6

#5: Please enter an integer: 1
The sum of your integers so far is: -5

#6: Please enter an integer: 2
The sum of your integers so far is: -3

#7: Please enter an integer: 3
The sum of your integers so far is: 0

#8: Please enter an integer: 4
The sum of your integers so far is: 4

#9: Please enter an integer: 5
The sum of your integers so far is: 9

#10: Please enter an integer: 6
The sum of your integers so far is: 15

You entered the following numbers:
-3, -2, -1, 0, 1, 2, 3, 4, 5, 6

The sum of those numbers is: 15

The (rounded) average of those numbers is: 1

I hope you find this helpful. Thank you. Good-bye.

Press any key to exit.

C:\CS271\Project 6 - Converter>
```
