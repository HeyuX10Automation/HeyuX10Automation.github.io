From rory@tivoli.com  Sun Feb  7 15:02:22 1999
To: Daniel <dbs@tanj.com>
References: <199901302108.NAA18780@joey.tanj.com>
From: Rory Murtagh <rory@tivoli.com>


Here's the script.  And below it a README.  Hope it works for you ...

---- cut here ----
#!/usr/local/bin/perl

# Where to find the `heyu` executable 
$heyu    = "/usr/local/bin/heyu" ;

# Title of the WWW page
$title   = (getpwnam( "heyu" ))[6] ; # gcos

# Where to find .x10config and where to write DB cashes
$home    = (getpwnam( "heyu" ))[7] ; 
q
# Dim/bright accept 1-22.  "slices" divides 22 into chunks and makes
# an html table.  22/4=~5.  Table is thus "dim 5", "dim 10", "dim 15"
# Just play with slices to see ...
$slices  = 4 ;

# Interesting CM11A "feature".  If x10config contains devices on
# different house codes, you'll want to switch these devices and see
# if they are on/off.  But "heyu reset C" both changes the CM11A's
# housecode and resets the CM11A's bitmap of all C devices to 0.  So
# how do we deal with "turn C4 on" when the CM11A's housecode is A.
# Why save everything in a persistant DB.
$onDB    = "$home/cm11a.on" ;
$dimDB   = "$home/cm11a.dim" ;

# Some X11 devices can be dimmed.  If the can some << and >> options
# are generated on the www page.  To say of one X11 can be dimmed,
# make its alias include "light" or "lamp" or something else and
# change the regexp below.  Note, heyu ignores stuff way right on the
# .x10config file so you could just add something there to match this
# regular expression alternatively.
$dimreg  = "light|lamp" ;

# Put .x10config anywhere you want as long as the following line
# points to it and is readable by the UID running the webserver.
$ENV{"X10CONFIG"} = "$home/.x10config" ;


###############################################################################
# No user servicables parts below.  If you find any, please let me know so "we"
# can paramaterize them.
###############################################################################

# Start by reading what's on/off/dimmed
&initDB ;

# Get time from the CM11a 
@lines = &heyudo( "info" ) ;
foreach $line ( @lines )
  {
    $intercl = $line if ( $line =~ /^Interface clock: / );
  }
$intercl =~ s/Interface clock/CM11A/ ;
# local/PC time
chop( $date = `/bin/date +"%a,%H:%M:%S"` );

# Generate start HTML
use CGI qw(:standard);
$query = new CGI ;
print header ;
print "<center>" ;
print start_html($title) ;

# And a little table of times giving the ability to set the CM11a time
# from the PC which could run xntpd so the CM11a becomes synced to
# naval atomic clocks.  Gotta love Linux.
print <<EOF;
<TABLE BORDER=1>
<TR>
<TD><i>$intercl</i></TD>
<TD><A HREF=/~heyu?setclock>Set Clock</A></TD>
<TD><i>HTTPd: $date</i></TD>
</TABLE>
EOF

# Uses $X10CONFIG
&readX10config ;

# What to do is passed as ?arg&options to this cgi script
if ( $todo = $query->param('keywords') )
  {
    if ( $todo =~ /setclock/ )
      {
	&heyudo( "setclock" ) ;
      }
    elsif ( $todo =~ /turn.*(on|off)/ )
      {
	( $turn, $tododev, $state, $value ) = split( /&/, $todo );
	# by including the command in \d, "alias A 1,2,3" is supported
	( $hc, $dev ) = ( $tododev =~ /([A-Z])([\d,]+)/i ) ;

	# do it.
        &heyudo( "turn", $hc, $dev, $state, $value ) ;

	# record what we've just done.
	if ( $dev =~ /,/ )
	  {
	    ( @devs ) = split( /,/, $dev ) ;
	    foreach $dev ( @devs )
	      {
		$ONDB{ $hc . $dev } = ( $state eq "on" ) ;
	      }
	  }
	else
	  {
	    $ONDB{ $tododev } = ( $state eq "on" ) ;
	  }
      }
   elsif ( $todo =~ /turn.*(dim|bright)/ )
      {
	( $turn, $tododev, $state, $value ) = split( /&/, $todo );
	# by including the command in \d, "alias A 1,2,3" is supported
	( $hc, $dev ) = ( $tododev =~ /([A-Z])([\d,]+)/i ) ;

	# do it.
        &heyudo( "turn", $hc, $dev, $state, $value ) ;

	# record what we've just done.
	$DIMDB{ $tododev } = ( $state =~ /bright|dim/ ) ;
      }
    elsif ( $todo =~ /alldevicessoff/ )
      {
	foreach $hc ( @hcs )
	  {
	    &heyudo( "turn", $hc, "*", "off" );

	    for ( $i = 1; $i < 16; $i++ )
	      {
		$ONDB{ "$hc$i" } = 0 ;
		$DIMDB{ "$hc$i" } = 0 ;
	      }
	  }
      }
    elsif ( $todo =~ /alllightson/ )
      {
	foreach $hc ( @hcs )
	  {
	    &heyudo( "turn", $hc, "*", "on" );

	    for ( $i = 1; $i < 16; $i++ )
	      {
		next if ( !( $name{"$hc$i"} =~ /$dimreg/i ) ) ; 
		$ONDB{ "$hc$i" } = 1 ;
		$DIMDB{ "$hc$i" } = 0 ;
	      }
	  }
      }
    else
      {
	# something usual passed as an argument ... 
	print "<BLINK><FONT COLOR=RED>Do not know how to \"$todo\"</FONT></BLINK>" ;
      }
    # this updates the data for colors in the table	
    &heyuinfo ;  
  }
    
# Make the table of options
print "<table border=1 cellpadding=2 cellspacing=0>\n" ;

foreach $tag ( @tags )
  {
    print "<tr>\n" ;

    if ( $devty{$tag} eq "dimmable" )
      {
	  for ( $l = 0, $i = int( 22 / $slices ); $i <= 22; 
		$i += int( 22/$slices ) ) 
	  {
	      print "<td><a href=/~heyu?turn&", 
	      $house{$tag} . $numbe{$tag}, "&dim&$i>&lt;</a></td>\n";
	  }
      }
    else
      {
	print "<td colspan=$slices >&nbsp;</td>\n" ;
      }
    print "<td><a href=/~heyu?turn&", 
    $house{$tag} . $numbe{$tag}, "&off>OFF</a></td>\n";
    $ttag = $tag  ;
    $ttag =~ s/_/ /g;

    # just plain on
    $device = $house{$tag} . $numbe{$tag};
    
    # dimmed
    if ( $DIMDB{ $device } )  
      {
	print "<td COLSPAN=2 align=center><font color=blue>$ttag</font></td>" ;
      }
    # on
    elsif ( $ONDB{ $device } )  
      {
	print "<td COLSPAN=2 align=center><font color=green>$ttag</font></td>";
      }
    # off
    else
      {
	print "<td COLSPAN=2 align=center>$ttag</td>" ;
      }
    # print the ON option
    print "<td><a href=/~heyu?turn&", 
    $house{$tag} . $numbe{$tag}, "&on>ON</a></td>\n";

    if ( $devty{$tag} eq "dimmable" )
      {
	  for ( $l = 0, $i = int( 22 / $slices ); $i <= 22; 
		$i += int( 22/$slices ) )
	  {
	      print "<td><a href=/~heyu?turn&", 
	      $house{$tag} . $numbe{$tag}, "&bright&$i>&gt;</a></td>\n";
	  }
      }
    else
      {
	print "<td colspan=$slices>&nbsp;</td>\n" ;
      }
    print "</tr>\n" ;
  }

# Finish the table with some "All" options.    
print <<EOF;
<tr>
<td colspan=$slices>&nbsp;</td>
<td><a href=/~heyu?alldevicessoff>OFF</a></td>
<td align=center><b>All Devices</b></td>
<td align=center><b>All Lights</b></td>
<td><a href=/~heyu?alllightson>ON</a></td>
<td colspan=$slices>&nbsp;</td>
</tr>
</table>
</center>
</body>
</html>
EOF

# Close the DBs 
&deinitDB ;


# Talk to `heyu`
sub heyudo
  {
    local ( $action, $housecode, $device, $param1, $param2 ) = ( @_ );

    open( HEYU, "$heyu $action $housecode$device $param1 $param2 |" )
      || die "$heyu $action $housecode$device $param1 $param2 : $!\n" ;

    @lines = "" ; 
    while( <HEYU> ) 
      {
	push @lines, $_ ;
      }
    close HEYU ;

    return @lines ;
  }

# heyu info
sub heyuinfo
  {
    @lines = &heyudo( "info" ) ;

    foreach $line ( @lines )
      {
	$mondevs = $line if ( $line =~ /^Status of monitored/ );
	$dimdevs = $line if ( $line =~ /^Status of dimmed/ );
      }
    ( $monitoredbitmap ) = ( $mondevs =~ /\(([01]+)\)/ ) ;
    @a = unpack ( "bbbbbbbbbbbbbbbb", $monitoredbitmap ) ;

    for ( $i=0; $i<= 15; $i++ )
      {
	$num = 16 - $i ;
	$ONDB{ "$defHouseCode$num" } = $a[ $i ] ;
      }
    ( $dimmedbitmap )    = ( $dimdevs =~ /\(([01]+)\)/ ) ;
    @a = unpack ( "bbbbbbbbbbbbbbbb", $dimmedbitmap ) ;
    for ( $i=0; $i<= 15; $i++ )
      {
	$num = 16 - $i ;
	$DIMDB{ "$defHouseCode$num" } = $a[ $i ] ;
      }
  }

# read .x10config and fill in a bunch of arrays
sub readX10config
  {
    $defHouseCode = "A" ;

    open( X10CONFIG, $ENV{"X10CONFIG"} ) || die $ENV{"X10CONFIG"}, ": $!\n" ;

    while( <X10CONFIG> )
      {
	# ignore comments and specials
	next if ( /^\#/ ) ;
	next if ( /^[\s]*$/ ) ;
	next if ( /LONGITUDE/ ) ;
	next if ( /LATITUDE/ ) ;
	next if ( /TTY/ ) ;
	      
	( $tag, $housecode, $device ) = split ;

	if ( $tag =~ /HOUSECODE/ )
	{
	    $defHouseCode = $housecode ;
	    next ;
	}
	# build some handy references for later
	push( @tags, $tag ) ;
	push( @hcs, $housecode ) if ( ! grep( /$housecode/, @hcs ) ) ;
	$house{$tag} = $housecode ;
	$numbe{$tag} = $device ;
	$devty{$tag} = ( /$dimreg/i ) ? "dimmable" : "" ;
	$tag =~ s/_/ /g ;

	$name{$housecode . $device} = $tag ;
      }
  }



# sub writeX10config
#   {
# coming soon.  add devices via www
# maybe also the ability to hide a device from interactive/www control
#   }

sub initDB
  {
    dbmopen( %ONDB, "$onDB", 0666 ) || die "Cannot open $onDB : $! \n" ;
    dbmopen( %DIMDB, "$dimDB", 0666 ) || die "Cannot open $dimDB : $! \n" ;
  }

sub deinitDB
  {
    dbmclose( %ONDB ) ;
    dbmclose( %DIMDB ) ;
  }

---- cut here for README ----

heyu.cgi is a WWW interface to Daniel B. Suthers "heyu".  

"Heyu" is a C program that talks to an X10 CM11A computer interface
unit that in turn controls devices around the home.

heyu.cgi is a PERL WWW executable that generates an HTML table listing
the home devices and a simple click will turn on, off, dim, or
brighten the device.

Setup instructions:
- Set up "heyu".  

- Create a user to host heyu.cgi.  (This isn't strictly necessary but
  it's nice to localize control.  Heyu.cgi will use the GCOS field of
  this user's account as the title of the WWW page.  If you want
  another title just edit the beginning of heyu.cgi.  It's documented in
  the .cgi file.)

- On the command line execute "heyu.cgi".  (It should say "(offline
  mode: enter name=value pairs on standard input)"; if it doesn't it
  means PERL isn't being found or the file isn't executable or it'll
  indicate whatever ails it.  Fix these problems or drop me a note and
  I'll see if I can help.)
  
- Configure heyu.cgi to be executable by your httpd.  (This can by by
  putting it in a cgi-bin directory; renaming it to heyu.pl if your
  httpd is configured to know that all .pl files are executable. )

  Heyu.cgi has been tested with an Apache server on Linux.  I know of
  know theoritical reason why it won't work with other servers.  For
  Apache adding/enabling the line: "AddHandler cgi-script .cgi " in
  srm.conf and bouncing the daemon is enough to make heyu.cgi
  executable.

- Make sure ~heyu/.x10config exists or you have edited heyu.cgi to
  point to .x10config.  heyu.cgi will map a '_' in the device alias to
  a space, and will assume anything called "light" or "lamp" is
  dimmable.
 
- Make sure the www server can write to the DBs as specified at the
  start of heyu.cgi.  

- Load the URL.  The URL might look like
  http://mylinux/~heyu/cgi-bin/heyu.cgi.
 
- If you see the text of heyu.cgi then the server isn't configured to
  treat this file as executable.  Check srm.conf, check heyu.cgi is
  executable again.  Check the httpd's error_log and see if there's
  information there.

- Click and see.




Here's my example .x10config:

# this file should contain x10 appliance aliases, one per line, as:
#   appliance-name  housecode  modulenumber
# for example:
#  mydesklamp	A	4
#  atticfan	B	3
#
# In addition, the devicename for the line the Powerhouse is attached to may
# be specified with:
#  TTY	/dev/tty00
# and the default housecode with:
#  HOUSECODE	A
# this is only used by the switches on the unit itself, and units
# specified by number only on the command line.
#
Rory's_bedside_lamp		A 1 
Sue_Ann's_bedside_lamp		A 2 
Master_bedroom_fan_light	A 3 
Whole_house_fan			A 4
Sitting_room_reading_lamp	A 5 
Outside_garage_lights		A 6 
Front_door_lights		A 7 
Game_room_fan_light		A 8 
Fishtank_florescents		A 9
Kids_bathroom_light		A 10 
Family_room_fan_light        	A 11 
All_3_alcove_lights	        A 12 
Family_room_reading_lamps	A 13 
Upstairs_Corridor_Lights        C 1
Kitchen_breakfast_area_lights   C 2  
Kid's_bedroom_lamp            	C 3
Mud_room_lights                 C 4
Master_bedroom_reading_lamp  	C 5  
Family/Kitchen_lights	       	A 9,11,12,13
#
# Boston:
LATITUDE	42:20
LONGITUDE	71:05
#
# set default housecode -- the one the switches will use
HOUSECODE	A
TTY		/dev/ttyS1

