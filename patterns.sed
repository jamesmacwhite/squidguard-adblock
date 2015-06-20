#
# ADBLOCK SED PATTERNS FOR SQUIDGUARD
# This is the pattern used to create the expressions lists
# Last tested: 20/06/2015
#

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
s/\\|\\|\(.*\)\^\(.*\)/\.\1\\\/\2/g;
s/\\|\\|\(.*\)/\.\1/g;
/^\.\*$/d;
/^$/d;
