use strict;
use warnings;

use CGI qw/:standard/;
use CGI::Session;
use IO::Handle;
$CGI::POST_MAX=1024 * 100;  # max 100K posts

use FindBin qw($Bin);
use lib "$Bin/../lib/";
use DateTime;
use DateTime::Format::Strptime;
use DatabaseUtil;
use HTMLGenerate;

##load session if logged in

our $dbdir='../db';
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
  my $session = CGI::Session->new('driver:sqlite',undef,
      {Handle=>$DatabaseUtil::sessions_dbh}) or die (CGI::Session->errstr);
  our $username = $session->param('username') // "";
  my ($path_to_here, $filename) = (url(-full=>1) =~ /(.+)(\/.+\.pl)/);
    my ($sth,@names,$row,$timeblock_length,$visible);
  print $session->header(-expires=>'now');
  print start_html(-title=>'DRA Studio Sign out sheet',
      -style=>{'src'=>'/room/draStudioSched.css'},
      -head=>meta({-http_equiv => 'Content-Language',
        -content => 'en'}));
  if (!$username) { 
    print a({-href=>'cas_basic.cgi'}, "CAS Login");
  } else{
    print p("Currently logged in as ".DatabaseUtil::getrealname($username)).
      a({-href=>"$path_to_here/Logout.pl"}, "Logout");
  }; 
#my $faculty = DatabaseUtil::isfaculty($username) unless !$username;
  my $faculty = 1;
  if($faculty){

#database connection for config
    my $config_dbh = DBI->connect("dbi:SQLite:dbname=$dbdir/config.db",
        "{RaiseError => 1}","")or die;
    $config_dbh->do('CREATE TABLE IF NOT EXISTS rooms (name TEXT DEFAULT new
          PRIMARY KEY, timeblock_length TEXT DEFAULT \'2 hours\', visible TEXT
          DEFAULT 1)');
    if(param('which_room')){
      if(param('delete')){
          $sth = $config_dbh->prepare('DELETE FROM rooms WHERE name=?');
          $sth->execute(param('which_room'));
          }else{
          $sth = $config_dbh->prepare('UPDATE rooms SET timeblock_length=?,
            visible=? WHERE name=?');
          $sth->execute(param('timeblock_length'),(param('visible')? 1 : 0),
            param('which_room'));
          print ("hey".param('timeblock_length').(param('visible')? 1 : 0));
          };
          Delete_all();
          }elsif(param('new_room')){
          $sth = $config_dbh->prepare('INSERT INTO rooms (name) VALUES (?)');
          $sth->execute(param('new_room'));
          Delete_all();
          }; 

#generate array of room titles
   $sth = $config_dbh->prepare('SELECT name from rooms');
    $sth->execute();
    $sth->bind_col(1,\$row);
    while ($sth->fetch()){
      push (@names, $row);
    }

    print h1("Schedule Options:");
    foreach my $room_name (@names){
      $sth = $config_dbh->prepare("SELECT timeblock_length, visible  from rooms where name=?");
      $sth->execute($room_name);
      $sth->bind_columns(\$timeblock_length,\$visible);
      $sth->fetch();
      print $timeblock_length.$visible; 
      print h2("$room_name Configuration").
        start_multipart_form().
        span("Length of time blocks:").
        popup_menu('timeblock_length',['1 hour','2 hours','4 hours'],
            $timeblock_length).
        span("roster upload:").
        filefield(-name=>"roster", -size=>50, -maxlength=>400).
        checkbox(-name=>'visible',-checked=>$visible,-value=>1,
            -label=>"Show $room_name?").
        checkbox(-name=>'delete',checked=>0,-value=>1,
            -label=>"Delete this room?").
        hidden(-name=>'which_room',-value=>$room_name).        
        submit().
        end_multipart_form();
      print'<BR><BR>';

    }
    print "<BR><BR>.start_form().
     h1("Create new schedule.").
      textfield(-name=>'new_room',-value=>'new-schedule-name',-size=>20,
          -maxlength=>20).
      submit(-value=>'Create Schedule').
      end_form();

  }else{
    print p("You don't appear to be faculty. Try logging out and revist this page.").
      a({-href=>url(-base=>1)."/room/cgi-bin/Logout.pl"}, "Logout");
  };
  print end_html();

