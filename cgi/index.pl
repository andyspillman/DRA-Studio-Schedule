use strict;
use warnings;

use CGI qw/:standard/;
use CGI::Session;
use FindBin qw($Bin);
use lib "$Bin/../lib/";
use DateTime;
use DateTime::Format::Strptime;
use DatabaseUtil;

##load session if logged in
my $session = CGI::Session->new('driver:sqlite',undef,
    {Handle=>$DatabaseUtil::sessions_dbh}) or die (CGI::Session->errstr);


#####Declare,Define DateTime Objs from query
my $ymdformatter = DateTime::Format::Strptime->new(
    pattern => '%Y%m%d',
    );
my $weekstart = DateTime->now();
my $weekend = DateTime->now();
my $curr_dt = DateTime->now( time_zone => 'local') ->set_time_zone('floating');
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


my $dropdowndate;
my $tablecol = 0;
my $timeblock = 1;


###make labels for users' real names for drop downs from user table
my @labels=@{DatabaseUtil::makelabels()};
my %labels=@labels;


#define currently logged in user, if any
my $username = $session->param('username') // param('pretend') // "";


#set to determine permissions

my $faculty;
$faculty = DatabaseUtil::isfaculty($username) unless !$username;


updatedb();#updates database based on query

###START HTML
print $session->header(-expires=>'now');
print start_html(-title=>'DRA Studio Sign out sheet',
    -style=>{'src'=>'/room/draStudioSched.css'},
    -head=>meta({-http_equiv => 'Content-Language',
      -content => 'en'}));
    if (!$username) { #ADD || $SESSION->IS_EMPTY probably
      print a({-href=>'cas_basic.cgi'}, "CAS Login");
    } else{
      print p("Currently logged in as ".DatabaseUtil::getrealname($username));
      print a({-href=>url(-base=>1)."/room/cgi-bin/Logout.pl"}, "Logout");
      if(DatabaseUtil::isfaculty($username)){
        print p("You are faculty");
      };
    };
#print p("Current date:$curr_dt");
print span({class=>'week'},"Week of: ".$weekstart->strftime('%B %d')." - ".
    $weekstart->clone()->add(days=>6)->strftime('%B %d')."<BR>");
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

buildtable();
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

sub buildtable{
  until ($timeblock>4){
    print "<tr>";
    until ($tablecol>7){
      makecell();
      $tablecol++;
    };
    print "</tr>\n";
    $timeblock++;
    $tablecol=0;
  };
  print "</table>";
}

sub makecell{
  my @timeblockname = ("",
      "8 am - 12 pm",
      "12 pm - 4 pm",
      "4-pm - 8 pm",
      "8 pm - 12 am",
      );
  print "<td>";
  if ($tablecol==0) {
    print "<p class=\"timecol\">", $timeblockname[$timeblock],"</p>";
  } else {
    fillcell();
  };
  print "</td>";
}


sub fillcell{
  my $timeblockowner = DatabaseUtil::getowner($weekstart->clone->add(days=>$tablecol-1), $timeblock);


  $dropdowndate = $weekstart->clone->add(days=>$tablecol-1)->ymd('');
  if (($username eq $timeblockowner)||$faculty){
    if ($labels{$timeblockowner}){
      dropdown($timeblockowner);
    }else{
      push(@labels, ($timeblockowner,$timeblockowner));
      %labels=@labels;
      dropdown($timeblockowner);
    };
  }
  elsif (($timeblockowner eq '-open-')&& $username){
    print a({-href=>url(-relative=>1)."?weekstart=$weekstart&targetdate=$dropdowndate&timeblock=$timeblock&newowner=$username"},"take");

  }else{
    print $labels{$timeblockowner} //$timeblockowner;
  }
};

sub dropdown{

  print popup_menu(
#      -name=>$day.','.$timeblock,
      -values=>[sort(keys %labels)],
      -default =>$_[0],
      -labels=>\%labels,
      -onChange=>"window.location.href='index.pl?weekstart=$weekstart&targetdate=$dropdowndate&timeblock=$timeblock&newowner='+this.value",
      ); 

};

#if there is owner
#if current user is owner or faculty, provide dropdown with all names
#else print name of owner
#else provide checkbox for taking ownership


sub updatedb{
  my $newowner = param('newowner');
  if ($newowner){

    my $targetdate = param('targetdate');
    my $timeblock = param ('timeblock');
    my $targetowner=DatabaseUtil::getowner($targetdate, $timeblock);
    my $isfaculty =  DatabaseUtil::isfaculty($username);

    if ($targetowner eq $username ||$targetowner eq '-open-' || $targetowner eq '-reserved-' || $isfaculty){ 
      DatabaseUtil::setowner($targetdate, $timeblock, $newowner);
      print("updated");
    }else{
      print "You are not authorized to change that timeblock.  Either there is a bug
        or you tried to do some tricky URL modification.  Only open timeblocks,
           timeblocks the current user owns can be changed, unless you are faculty, in which case you can change anything.";
    };
  }
};
