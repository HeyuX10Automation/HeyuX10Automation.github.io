#!/usr/bin/perl

###############################################
#This is a web interface for the HEYU program #
#Which was written by Dan Suthers dbs@tanj.com#
#Website is at http://heyu.tanj.com           #
#This program reads in from the configuration #
#file the aliases, and then utilizes them via #
#CGI.                                         #
#This program is licensed under the GPL       #
#Just chmod 755 heyu.pl, plonk it in your cgi #
#directory, and you're good to go.            #   
#Written By: William Platnick                 #
#AIM: CafeEblana Email: wp7599@albany.edu     #
#http://www.kradcomputing.com                 #
###############################################

use CGI qw(:standard);

#Declare variables

#$config is the location of your heyu configuration
#$heyupath is the path to the heyu binary
$config = "/etc/x10.conf";
$heyupath = "/usr/bin/heyu";

#Don't edit past here
$view = param('view');


if($view eq '') {
open(CONFIG,"$config");
@contents = <CONFIG>;
close(CONFIG);

foreach $temp(@contents)
{
    @dummy = split(" ", $temp);
    if (substr($dummy[0],0,1) eq '#') { next; }
    elsif ($dummy[0] ne 'HOUSECODE' && $dummy[0] ne 'TTY') { 
	$alias[$i] = "$dummy[0]";
	$i++;
    }
}

print "Content-Type: text/html\n\n";
print '<html><head><title>Krad HEYU CGI Interface</title></head><body bgcolor="#006699">';
print '<div align="center">';
print '<h2>Welcome to the Krad CGI HEYU Interface</h2><P>';
print '<form action="heyu.pl" method="post">';
print '<input type="hidden" name="view" value="1">';
print '<table border="1"><tr>';
foreach $temp(@alias)
{
    print "<input type=\"hidden\" name=\"array$j\" value=\"$temp\">";
    print "<td>$temp</td><td>On<input type=\"radio\" name=\"$temp\" value=\"on\"></td><td>Off<input type=\"radio\" name=\"$temp\" value=\"off\"></td><td>Nothing<input type=\"radio\" name=\"$temp\" checked value=\"nothing\"></td><td>Brighten<select name=\"brighten$j\"><option value=\"\" label=\"\" SELECTED> </option>";
    for($q = 1;$q <=20; $q++) {
    	print "<option value=\"$q\" label=\"$q\">$q</option>";
    }
    print "</select></td><td>
    Dim<select name=\"dim$j\"><option value=\"\" label=\"\" SELECTED> </option>";
    for($q = 1;$q <=20; $q++) {
    	print "<option value=\"$q\" label=\"$q\">$q</option>";
    }
    
    
    print "</select></td><tr>\n";
    $j++;
}
print '<td colspan="6"><div align="center"><input type="submit" value="Submit"></div></td></tr>';
print '</table></form></div>';
}

else {
    print "Content-Type: text/html\n\n";
print '<html><head><title>Execution Status</title></head><body bgcolor="#006699">';
    while(!$done)
    {
	$text[$i] = param("array$i");
	$brighten[$i] = param("brighten$i");
	$dim[$i] = param("dim$i");
	if($brighten[$i] ne '' && $brighten[$i] ne ' ') { system("$heyupath turn $text[$i] bright $brighten[$i]"); print "I just brightened $text[$i] by a value of $brighten[$i]<br>"; }
	if($dim[$i] ne '' && $dim[$i] ne ' ') { system("$heyupath turn $text[$i] dim $dim[$i]"); print "I just dim'd $text[$i] by a value of $dim[$i]<br>"; }
	if($text[$i] eq '' || $text[$i] eq ' ') { $done = 1; next; }
	$value[$i] = param("$text[$i]");
	if($value[$i] eq 'off') { system("$heyupath turn $text[$i] $value[$i]"); print "I just turned $text[$i] $value[$i] <br>"; }
	if($value[$i] eq 'on') { system("$heyupath turn $text[$i] $value[$i]"); print "I just turned $text[$i] $value[$i] <br>"; }
       	$i++;	
    }
}

print '<div align="center">Back to the <a href="heyu.pl">Main</a> Page<P><P><div align="center"><h6>This CGI script has been written by William Platnick of <a href="http://www.kradcomputing.com">Krad Computing</a><br><a href="http://www.kradcomputing.com"><img src="http://www.kradcomputing.com/button.jpg" border="1"></a></body></html>';




