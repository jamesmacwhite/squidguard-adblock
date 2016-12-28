############################################################################
## patterns.sed
## Description: sed expression rules that are used in the conversion
## Last Modified: 16/06/2015
## 
## Notes:
## These rules have been adapted from older working examples with tweaks
## Tests are run regularly to confirm the conversion process is accurate
## Updates to this file may be required if upstream changes to lists occur
##

s/\r//g;
/Adblock/d;
/.*\$.*/d;
/\n/d;
/.*\#.*/d;
/@@.*/d;
/^!.*/d;
/^\[.*\]$/d;
s#http://#||#g;
s/\/\//||/g;
s,[+.?&/|],\\&,g;
s/\[/\\\[/g;
s/\]/\\\]/g;
s#*#.*#g;
s,\$.*$,,g;
s/\\|\\|\(.*\)\^\(.*\)/(^|\\\.)\1\\\/\2/g;
s/\\|\\|\(.*\)/(^|\\\.)\1/g;
/^\.\*$/d;
/^$/d;
