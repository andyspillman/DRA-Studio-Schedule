#!/usr/bin/perl
use strict;
use warnings;

use CGI qw/:standard -nosticky/;
use CGI::Session;

#use IO::Handle;
$CGI::POST_MAX = 1024 * 100;    # max 100K posts
use CGI::Carp qw(fatalsToBrowser);
use FindBin qw($Bin);
use lib "$Bin/../lib/";
use DateTime;
use DateTime::Format::Strptime;
use DatabaseUtil;
use HTMLGenerate;
use ParseRoster;
##load session if logged in

our $dbdir = '../db';
use DBI;

## undef may be returned if it's not a valid file handle
#      my $roster_405_fh  = upload('roster_405');
#      if (defined $roster_405_fh) {
## Upgrade the handle to one compatible with IO::Handle:
#      my $io_handle = $roster_405_fh->handle;
#      open (OUTFILE,">>","$Bin/temp");
#      while (my $I = $io_handle->read(my $buffer,1024)) {
#      print OUTFILE $buffer;
#
#      };
##open (INFILE,'<',"$Bin/../temp");
##print INFILE;
#      close OUTFILE or die;
##Delete() or die;
##undef $io_handle or die;
#

#database connection for CGI Session
my $session =
  CGI::Session->new( 'driver:sqlite', undef,
    { Handle => $DatabaseUtil::sessions_dbh } )
  or die( CGI::Session->errstr );
our $username = $session->param('username') // "";
my ( $sth, @roomnames, $row, $timeblock_length, $visible );
print $session->header( -expires => 'now' );
print start_html(
    -title => 'DRA SSOS Configuration',
    -style => { 'src' => '/room/draStudioSched.css' },
    -head  => meta(
        {
            -http_equiv => 'Content-Language',
            -content    => 'en'
        }
    )
);
if ( !$username ) {
    print a( { -href => 'cas_basic.cgi' }, "CAS Login" );
}
else {
    print p("Currently logged in as $username")
      . a( { -href => "Logout.cgi" }, "Logout" );
}
our $faculty = DatabaseUtil::isfaculty($username) unless !$username;

if ($faculty) {

    $DatabaseUtil::config_dbh->do(
        'CREATE TABLE IF NOT EXISTS rooms (name TEXT DEFAULT new
          PRIMARY KEY, timeblock_length TEXT DEFAULT \'2 hours\', visible TEXT
          DEFAULT 1)'
    );
    if ( our $which_room = param('which_room') ) {
        if ( param('delete') ) {
            $sth = $DatabaseUtil::config_dbh->prepare(
                'DELETE FROM rooms WHERE name=?');
            $sth->execute( param('which_room') );
            $DatabaseUtil::rosters_dbh->do("DROP TABLE '$which_room'");
            $DatabaseUtil::timeblocks_dbh->do("DROP TABLE '$which_room'");
        }
        else {
            $sth = $DatabaseUtil::config_dbh->prepare(
                'UPDATE rooms SET timeblock_length=?,
            visible=? WHERE name=?'
            );
            $sth->execute(
                param('timeblock_length'),
                ( param('visible') ? 1 : 0 ),
                param('which_room')
            );
            if ( param('roster') ) {
                our $roster_fh = upload('roster');

                $DatabaseUtil::rosters_dbh->do("DROP TABLE '$which_room'");
                $DatabaseUtil::rosters_dbh->do(
                    "CREATE TABLE '$which_room' (username,realname);")
                  or die;
                ParseRoster::parse( $roster_fh, $which_room );

            }
        }
    }
    elsif ( param('new_room') ) {
        my $new_room = ( param('new_room') );
        $sth = $DatabaseUtil::config_dbh->prepare(
            'INSERT INTO rooms (name) VALUES (?)');

        $sth->execute($new_room);
        $DatabaseUtil::rosters_dbh->do(
            "CREATE TABLE IF NOT EXISTS '$new_room' (username,realname,role);")
          or die;

    }
    elsif ( param('semester_setup_room') ) {
        my $start_date          = param('start_date');
        my $end_date            = param('end_date');
        my $semester_setup_room = param('semester_setup_room');

#check for super out-of-range dates that would crash server or make gigantic databases, this should limit it to roughly 5 years.
        if (   ( $start_date > $end_date )
            || ( ( $start_date + 50000 ) < $end_date ) )
        {
            print p(
"Dates seem out-of-range.  Limit of ~5 years.  Make sure start<end."
            );
        }
        else {

            DatabaseUtil::semestersetup( param('start_date'), param('end_date'),
                param('semester_setup_room') );
            print p( "Inserted  timeblock dates for "
                  . param('semester_setup_room') );
        }
    }

    #generate array of room titles
    Delete_all(); #delete all params, possibly unnecessary because of CGI (-nosticky)
 print h1("Schedule Options:");
    foreach my $room_name ( @{ DatabaseUtil::roomnames() } ) {
        $sth = $DatabaseUtil::config_dbh->prepare(
            "SELECT timeblock_length, visible  from rooms where name=?");
        $sth->execute($room_name);
        $sth->bind_columns( \$timeblock_length, \$visible );
        
$sth->fetch();
        print h2("$room_name Configuration")
          . start_multipart_form()
          . span("Length of time blocks:")
          . popup_menu( 'timeblock_length', [ '1 hour', '2 hours', '4 hours' ],
            $timeblock_length )
          . span("roster upload:")
          . filefield( -name => "roster", -size => 50, -maxlength => 400 )
          . checkbox(
            -name    => 'visible',
            -checked => $visible,
            -value   => 1,
            -label   => "Show $room_name?"
          )
          . checkbox(
            -name   => 'delete',
            checked => 0,
            -value  => 1,
            -label  => "Delete this room?"
          )
          . hidden( -name => 'which_room', -value => $room_name )
          . submit()
          . end_multipart_form();
        print '<BR><BR>';

    }
    print start_form() 
      . h1("Create new schedule.")
      . textfield(
        -name      => 'new_room',
        -value     => 'new-schedule-name',
        -size      => 20,
        -maxlength => 20
      )
      . submit( -value => 'Create Schedule' )
      . end_form();

    print h1 ("Semester Setup")
      . span(
"Make sure everything above is correct for a given room, then below,  Carefully enter dates as YYYYMMDD. This will DELETE all existing records for a room, no matter the dates.  Only click once, it may take a few seconds."
      )
      . start_form()
      . textfield(
        -name      => 'start_date',
        -value     => 'start',
        -size      => 8,
        -maxlength => 8
      )
      . textfield(
        -name      => 'end_date',
        -value     => 'end',
        -size      => 8,
        -maxlength => 8
      )
      . popup_menu(
        -name   => 'semester_setup_room',
        -values => DatabaseUtil::roomnames()
      )
      . submit()
      . end_form();
    print p(a( { -href => 'index.cgi' }, "Back to Index" ));

    print p(a( { -href => "README.txt"},"README" ));
}
else {
    print p(
        "You don't appear to be faculty. Try logging out and revist this page.")
      . a( { -href => url( -base => 1 ) . "/room/cgi-bin/Logout.cgi" },
        "Logout" );
}

print end_html();

