#
# SquidGuard Sed Patterns
# Used to create SquidGuard compatible expressions list
# Last tested: 16/06/2015
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