This is a the MONDEB monitor debugger, written by Don Peters and
described in the book "MONDEB, An Advanced M6800 Monitor Debugger".

Summary of Commands:

REG
SET <address> <value> [<value>...]
SET <address range> <value>
SET .<register> <value>
DISPLAY <address range> [DATA|USED]
DBASE [?|HEX|DEC|OCT|BIN]
IBASE [?|HEX|DEC|OCT]
GOTO [<address>]
BREAK [?|<address>]
CONTINUE
TEST <address range>
VERIFY [<address range>]
SEARCH <address range> <value> [<value>...]
COPY <address range> <address>
COMPARE <value1> <value2
DUMP <address range> [TO <address>]
LOAD [FROM <address>]
DELAY <value>
INT <address>
NMI <address>
SWI <address>
SEI
CLI

Commands can be abbreviated to fewer letters as long as they are unique.
An address range is in the form <start>:<end>

I typed in the listing from the book and adapted it to build with the
crasm cross-compiler. I have confirmed that it produces binary output
identical to the one in the book

For a port to my single board computer, see the folder ../sbc/software

To use the code or port it to another computer, you will want to
obtain a copy of the book.
