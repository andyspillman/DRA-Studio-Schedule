#!/usr/bin/perl
use strict;
use warnings;
require 5.10.0;    ##only because smartmatch ~~ is used, I think

use CGI qw/:standard -nosticky/;
use CGI::Session;
use CGI::Carp qw(fatalsToBrowser);

$CGI::POST_MAX        = 1024 * 100;    # max 100K posts
$CGI::DISABLE_UPLOADS = 1;             # no uploads


use FindBin qw($Bin);
use lib "$Bin/../lib/";
use DateTime;
use DateTime::Format::Strptime;
use DatabaseUtil;
use HTMLGenerate;

##create sessions tableif it does not already exist.  The db file should be
#created automatically.  To clean orphan sessions, either sessions table
#should be dropped or the .db file should be deleted regularly (chron)
#
$DatabaseUtil::sessions_dbh->do(
    'CREATE TABLE IF NOT EXISTS sessions (
      id CHAR(32) NOT NULL PRIMARY KEY,
      a_session TEXT NOT NULL)'
);

##load session if logged in
my $session =
  CGI::Session->new( 'driver:sqlite', undef,
    { Handle => $DatabaseUtil::sessions_dbh } )
  or die( CGI::Session->errstr );

#make sure room param is present and room exists in config.db>rooms
if (
    !(
        url_param('room')
        && ( url_param('room') ~~ @{ DatabaseUtil::roomnames() } )
    )
  )
{
    print $session->header( -Refresh => "0; URL=index.cgi" );
    exit 1;
}

#####Declare,Define DateTime Objs from query
our $ymdformatter = DateTime::Format::Strptime->new( pattern => '%Y%m%d', );
our $weekstart = DateTime->now();
my $weekend = DateTime->now();
our $curr_dt = DateTime->now( time_zone => 'local' )->set_time_zone('floating');
$curr_dt->set_formatter($ymdformatter);
my $weekstartstr = url_param('weekstart');
if ( !url_param('weekstart') )
{    #if page is opened without ?weekstart=, assume current week
    $weekstart =
      $curr_dt->clone()->truncate( to => 'week' )->subtract( days => 1 );
}
else {
    $weekstart = $ymdformatter->parse_datetime($weekstartstr);
}

# $weekstart->set_formatter must be called AFTER the above else
# statement, because DateTime::Format::Striptime::parse_datetime() returns
# a NEW DateTime object

$weekstart->set_formatter($ymdformatter);
$weekend = $weekstart + DateTime::Duration->new( days => 7 );

#####End DateTime Defines

#define currently logged in user, if any
our $username = $session->param('username') // "";
our $room = url_param('room');

#set to determine permissions
#our $faculty = 1;

our $faculty = DatabaseUtil::isfaculty($username) unless !$username;

###make labels for users' real names for drop downs from user table

my @labels = @{ DatabaseUtil::makelabels() };

if ($faculty) {    #add special options for faculty
    push( @labels, ( '-reserved-', '-reserved-', '-shared-', '-shared-' ) );
}

our %labels = @labels;    #make hash from array

###START HTML
if ( !url_param('room') ) {
    print $session->header( -Refresh => "0; URL=index.cgi" );
}
print $session->header( -expires => 'now' );
print start_html(
    -title => 'DRA Studio Sign out sheet',
    -style => { 'src' => '/room/draStudioSched.css' },
    -head  => meta(
        {
            -http_equiv => 'Content-Language',
            -content    => 'en'
        }
    )
);

print "<div id=\"header\">";
if ( !$username ) {
    print a( { -href => 'cas_basic.cgi' }, "CAS Login" );
}
else {
    if ( DatabaseUtil::getrealname($username)||$faculty ) {
        print 
            "Currently logged in as " . DatabaseUtil::getrealname($username) ;
    }
    else {
        print span("$username is not registered for this room, read-only");
    }

    print span(a( { -href => url( -base => 1 ) . "/room/cgi-bin/Logout.cgi" },
        "Logout " ));
    if ($faculty) {
        print a( { -href => url( -base => 1 ) . "/room/cgi-bin/admintools.cgi" },
            "Faculty Tools" );
    }
}
print span( { id => 'room_title' }, " " . param('room') . " Schedule " );
print span(
    { id => 'week' },
    "Week of: "
      . $weekstart->strftime('%B %d') . " - "
      . $weekstart->clone()->add( days => 6 )->strftime('%B %d') . "<BR>"
);
print "</div>";
updatedb();    #updates database based on query, prints any info before table
print <<STOP1;
    <table>
      <tr>
      <th></th>
      <th>Sunday</th>
      <th>Monday</th>
      <th>Tuesday</th>
      <th>Wednesday</th>
      <th>Thursday</th>
      <th>Friday</th>
      <th>Saturday</th>

      </tr>
STOP1

#prints HTML for table
HTMLGenerate::buildtable();

###week navigation under table

print "<div id= \"undertable\">";
print p(
    a(
        {
                -href => url( -relative => 1 )
              . "?room=$room&weekstart="
              . $weekstart->clone()->subtract( weeks => 1 )
        },
        "Previous Week"
      )
     ).p( a(
        {
                -href => url( -relative => 1 )
              . "?room=$room&weekstart="
              . $weekstart->clone()->add( weeks => 1 )
        },
        "Next Week"
      )
);

if ( !( ( $weekstart < $curr_dt ) && ( $curr_dt < $weekend ) ) ) {
    print p(
        a( { -href => url( -relative => 1 ) . "?room=$room" }, "Current Week" )
    );
}
print a( { -href => 'index.cgi' }, "Back to Index" );
print "</div>";
print end_html();

# END HTML

##flush because documentation recommends it
$session->flush();

#####start SUBS

sub updatedb {
    my $newowner         = url_param('newowner');
    my $reserved_details = param('reserved_details');
    my $shared_names     = param('shared_names');

    #is user ADDING DETAILS or selecting a dropdown option?
    if ( ( $reserved_details || $shared_names ) && $faculty ) {

        #parses hiddenfield to get desination timeblock and date
        my ( $targetdate, $targettimeblock ) =
          ( param('target_submit_block') =~ /(.*)\.(.*)/ );

        #details get written into database, eg: ' -reserved-Jazz combo setup'
        if (
            ($reserved_details)
            && ( DatabaseUtil::getowner( $targetdate, $targettimeblock ) =~
                /^-reserved-/ )
          )
        {
            DatabaseUtil::setowner( $targetdate, $targettimeblock,
                '-reserved-' . $reserved_details );
        }
        elsif ( DatabaseUtil::getowner( $targetdate, $targettimeblock ) =~
            /^-shared-/ )
        {
            DatabaseUtil::setowner( $targetdate, $targettimeblock,
                '-shared-' . $shared_names );
        }
        Delete_all();    #gotta delete these params or their values
    }
    elsif ($newowner) {
        my $targetdate      = url_param('targetdate');
        my $targettimeblock = url_param('timeblock');
        my $targetowner =
          DatabaseUtil::getowner( $targetdate, $targettimeblock );




###the below giant if statement in English:
   #does the username exist for the room AND is the
   #new owner authorized for this room AND does the currently logged in user own
   #the block, unless it is owned by no one AND is the user not trying to select
   #-reserved-, OR is current user faculty, in which case nothing else matters
if (($faculty)
    ||(($newowner ne '-reserved-')&&($newowner ne '-shared-')&&(($targetowner=~/$username/)||(($targetowner eq '-open-') && (DatabaseUtil::getrealname($username))

))))

        {
            DatabaseUtil::setowner( $targetdate, $targettimeblock, $newowner );
        }



#        if (
#            (    #is someone on the roster logged in?
#                ( DatabaseUtil::getrealname($username) )
#                &&    #does the new owner exist for this room
#                ( $labels{$newowner} )
#                && (    #does the current user own it
#                    ( $targetowner =~ /$username/ )
#                    ||    # or is the timeblock open
#                    ( $targetowner eq '-open-' )
#                )
#                && #is the nonfaculty user trying to choose reserved or shared, only faculty can do this
#                !( $newowner eq '-reserved-' )
#                && !( $newowner eq '-shared' )
#
#                #finally, is the user a godly faculty
#            )
#            || $faculty
#          )
#        {
#            DatabaseUtil::setowner( $targetdate, $targettimeblock, $newowner );
#        }
        else {
            print "Please log in again to make changes.  Only faculty can select
reserved or shared.";
        }
    }
}
