use strict;
use warnings;

use DateTime;
use DateTime::Format::Strptime;
use DBI;
use FindBin qw($Bin);

our $dbdir = "$Bin/../db";

package DatabaseUtil;

my $timeblocksdbname = 'rooms.db';#includes all of the actual timeblock ownership
our $sessionsdbname='sessions.db';#CGI session info from CAS login
our $rostersdbname='rosters.db';#room rosters

#database connection for config
our $config_dbh = DBI->connect("dbi:SQLite:dbname=$dbdir/config.db", "{RaiseError => 1}","")or die;
#database connection for CGI Session
our $sessions_dbh = DBI->connect("dbi:SQLite:dbname=$dbdir/$sessionsdbname","{RaiseError => 1}","");

#database connection for time assignments, table names are room names
our $timeblocks_dbh = DBI->connect("dbi:SQLite:dbname=$dbdir/rooms.db","{RaiseError => 1}","");

#database connection for rosters, table names are room names
our $rosters_dbh = DBI->connect("dbi:SQLite:dbname=$dbdir/$rostersdbname","{RaiseError => 1}","");


my $ymdformatter = DateTime::Format::Strptime->new( pattern => '%Y%m%d');
my $realname;
my $sth;
my $user;
our $room;

sub is_visible{
  my $visible;
  $sth = $DatabaseUtil::config_dbh->prepare('SELECT visible FROM rooms WHERE name=?');
  $sth->execute($_[0]);
  $sth->bind_col(1,\$visible);
  $sth->fetch();
  return $visible;
}

#make an array containing all the room names
sub roomnames{
  my ($row,@roomnames);
  $sth = $DatabaseUtil::config_dbh->prepare('SELECT name FROM rooms');
  $sth->execute();
  $sth->bind_col(1,\$row);
  while ($sth->fetch()){
    push (@roomnames, $row);
  }
  return \@roomnames;
}




###since $room is used directly in SQL query, and table names cannot used in
##prepared statements, this runs a simple check to make sure it is an actual
#room that has a row in the config table, else it could be SQL injection attack.
sub verify_room{
  my $row;
  my $room = shift;
  $sth = $config_dbh->prepare('SELECT name FROM rooms');
  $sth->execute();
  $sth->bind_col(1,\$row);
  while ($sth->fetch()){
#    print $row; 
    if ($row eq $room){
      return 1;
    };
  };
  return 0;
};

sub numberoftimeblocksforroom{
  $sth = $config_dbh->prepare('SELECT timeblock_length FROM rooms WHERE name = ?');
  $sth->execute($_[0]);

  my $timeblocklength = ( $sth->fetchrow_array());
 $timeblocklength  =~ /^(\d).*/; ###check
 
return (16/$1);
}

sub semestersetup{
  my $startdatestr = shift;
  my $enddatestr = shift;
  $room = shift;
  if(verify_room($room)){

    $timeblocks_dbh->do("DROP TABLE If EXISTS '$room'");
    $timeblocks_dbh->do("CREATE TABLE '$room' ('day','time','user')") or die;
    my $startdate = $ymdformatter->parse_datetime($startdatestr)or die("Semester Setup failed: check start date formatting.");
    my $enddate = $ymdformatter->parse_datetime($enddatestr)or die("Semester Setup failed: check end date formatting.");
    $startdate->set_formatter($ymdformatter);
    $enddate->set_formatter($ymdformatter);

    for(my $i=$startdate->clone();$i<=$enddate;$i->add(days=>1)){
      for(my $j=1; $j<=numberoftimeblocksforroom($room); $j++){
        $timeblocks_dbh->do("INSERT INTO '$room' VALUES ($i,$j,'-open-')");
      };
    };
  };
}
sub getowner{

  if(verify_room($main::room)){
    my $day = shift @_;
    my $time = shift @_;
    my $user;

    $sth = $timeblocks_dbh->prepare("SELECT user FROM '$main::room' WHERE day =(0+?) AND time =(0+?)") or die "can't open timeblock table for room: $main::room.  Run Semester Setup for this room.";
    $sth->execute($day,$time)
    or die "Couldn't execute statement: " . $sth->errstr;
    $sth->bind_col(1,\$user);
    $sth->fetch();
#my @result = $sth->fetchrow_array();
    return $user;
  }
#  my $owner =`sqlite3 database/test.db 'SELECT time$time from days where day=$date'`;
# chomp ($owner);
# return $owner;
};


sub setowner{

  if(verify_room($main::room)){
  my $date = shift @_;
  my $time = shift @_;
  my $newuser = shift @_;

    my $sql = "UPDATE '$main::room' SET user =? WHERE day =(?+0) AND time =(?+0)";
  
  $sth = $timeblocks_dbh->prepare($sql);
  $sth->execute($newuser,$date,$time);
#return `sqlite3 database/test.db 'update days time$time=$newuser from days where day=$date'`;
  };
};

sub getrealname{

  my $username =shift;

  if(verify_room($main::room)){
    $sth = $rosters_dbh->prepare("SELECT realname FROM (SELECT * FROM '$main::room' UNION SELECT * FROM 'faculty')  WHERE username=?");
    $sth->execute($username);
    $sth->bind_columns(\$realname);  
    $sth->fetch();
    return $realname;
    
  }
}



sub makelabels{

  if(verify_room($main::room)){
    $sth = $rosters_dbh->prepare("SELECT username, realname FROM (SELECT * FROM '$main::room' UNION SELECT * FROM 'faculty')") or die "can't find roster for $main::room.  Is there one uploaded?";;
  
  $sth->execute();
  my (@labels, $username, $realname);
  while (($username, $realname) = $sth->fetchrow_array) {
    push(@labels,($username, $realname));
  }
  push (@labels, ('-open-', '-open-'));
  return \@labels;
  }
};

sub isfaculty{
  $sth = $rosters_dbh->prepare('SELECT * FROM  faculty WHERE username=?');
  $sth->execute($_[0]);
  my $isfaculty=((scalar $sth->fetchrow_array) ? 1 : 0);
    return $isfaculty;  
}
return 1;
