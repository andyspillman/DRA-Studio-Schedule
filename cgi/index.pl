use strict;
use warnings;
require 5.10.0;##only because smartmatch ~~ is used, I think

use CGI qw/:standard/;
use CGI::Session;

$CGI::POST_MAX=1024 * 100;  # max 100K posts
$CGI::DISABLE_UPLOADS = 1;  # no uploads

use FindBin qw($Bin);
use lib "$Bin/../lib/";
use DateTime;
use DateTime::Format::Strptime;
use DatabaseUtil;
use HTMLGenerate;

##create sessions table if it does not already exist.  The db file should be
#created automatically.  To clean orphan sessions, either sessions table
#should be dropped or the .db file should be deleted regularly (chron)
#
$DatabaseUtil::sessions_dbh->do('CREATE TABLE IF NOT EXISTS sessions (
      id CHAR(32) NOT NULL PRIMARY KEY,
      a_session TEXT NOT NULL)'
      );

##load session if logged in
my $session = CGI::Session->new('driver:sqlite',undef,
    {Handle=>$DatabaseUtil::sessions_dbh}) or die (CGI::Session->errstr);


#####Declare,Define DateTime Objs from query
our $ymdformatter = DateTime::Format::Strptime->new(
    pattern => '%Y%m%d',
    );
our $weekstart = DateTime->now();
my $weekend = DateTime->now();
our $curr_dt = DateTime->now( time_zone => 'local') ->set_time_zone('floating');
$curr_dt->set_formatter($ymdformatter);
my $weekstartstr=param('weekstart'); 
if (!param('weekstart')){#if page is opened without ?weekstart=, assume current week
  $weekstart=$curr_dt->clone()->truncate(to=>'week')->subtract(days=>1);
}
else{
  $weekstart= $ymdformatter->parse_datetime($weekstartstr);
};

# $weekstart->set_formatter must be called AFTER the above else
# statement, because DateTime::Format::Striptime::parse_datetime() returns
# a NEW DateTime object

$weekstart->set_formatter($ymdformatter);
$weekend = $weekstart+DateTime::Duration->new(days=>7);

#####End DateTime Defines



#define currently logged in user, if any
our $username = $session->param('username') // "";


#set to determine permissions
our $faculty=1;
#$faculty = DatabaseUtil::isfaculty($username) unless !$username;

###make labels for users' real names for drop downs from user table
my @labels=@{DatabaseUtil::makelabels()};
if($faculty){#add special options for faculty
  push(@labels,('-reserved-','-reserved-','-shared-','-shared-'));
};
our %labels=@labels;#make hash from array

###START HTML
print $session->header(-expires=>'now');
print start_html(-title=>'DRA Studio Sign out sheet',
    -style=>{'src'=>'/room/draStudioSched.css'},
    -head=>meta({-http_equiv => 'Content-Language',
      -content => 'en'}));
    if (!$username) { 
      print a({-href=>'cas_basic.cgi'}, "CAS Login");
    } else{
      print p("Currently logged in as ".DatabaseUtil::getrealname($username)).
        a({-href=>url(-base=>1)."/room/cgi-bin/Logout.pl"}, "Logout");
      if($faculty){
     print a({-href=>url(-base=>1)."/room/cgi-bin/admintools.pl"}, "Faculty Tools");
      };
    };
print span({class=>'week'},"Week of: ".$weekstart->strftime('%B %d')." - ".
    $weekstart->clone()->add(days=>6)->strftime('%B %d')."<BR>");


updatedb();#updates database based on query, prints any info before table

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
print p(a({-href=>url(-relative=>1)."?weekstart=".$weekstart->clone()->
      subtract(weeks=>1)}, "Previous Week").a({-href=>url(-relative=>1).
      "?weekstart=".$weekstart->clone()->add(weeks=>1)}, "Next Week"));

if(!(($weekstart<$curr_dt)&&($curr_dt<$weekend))){
  print p(a({-href=>url(-relative=>1)}, "Current Week"));
};
print end_html();
# END HTML


##flush because documentation recommends it
$session->flush();


#####start SUBS

sub updatedb{
  my $newowner = param('newowner');
  my $reserved_details = param('reserved_details');
  my $shared_names = param('shared_names');
  if(($reserved_details||$shared_names) && $faculty){
#parses hiddenfield to get desination timeblock and date
    my ($targetdate,$targettimeblock)=(param('target_submit_block')=~
        /(.*)\.(.*)/);

#details get written into database, eg: ' -reserved-Jazz combo setup'
    if (($reserved_details) && (DatabaseUtil::getowner($targetdate, $targettimeblock) =~/^-reserved-/)){
      DatabaseUtil::setowner($targetdate, $targettimeblock, '-reserved-'.
          $reserved_details)
    }elsif(DatabaseUtil::getowner($targetdate, $targettimeblock) =~ /^-shared-/){ 
      DatabaseUtil::setowner($targetdate, $targettimeblock, '-shared-'.
          $shared_names);
    };
    Delete_all(); #gotta delete these params or their values 
  };

  if ($newowner){
    my $targetdate = param('targetdate');
    my $targettimeblock = param ('timeblock');
    my $targetowner=DatabaseUtil::getowner($targetdate, $targettimeblock);

###the below giant if state in English:
#does the username exist for the room AND is the
#new owner authorized for this room AND does the currently logged in user own
#the block, unless it is owned by no one AND is the user not trying to select
#-reserved-, OR is current user faculty, in which case nothing else matters

    if (((DatabaseUtil::getrealname($username))&&  #is someone on the roster
                                                  #logged in?
          ($labels{$newowner})&&           #does the new owner exist for this room
          (($targetowner =~ /$username/) ||#does the current user own it
           ($targetowner eq '-open-')) &&  # or is the timeblock open
          !($newowner eq'-reserved-') && #is the user trying to choose 
          !($newowner eq'-shared')) ||    #reserved or shared
          $faculty){                        #finally, is the user a godly faculty
      DatabaseUtil::setowner($targetdate, $targettimeblock, $newowner);
    }else{
      print "Please log in again to make changes.";
    };
  };
};
