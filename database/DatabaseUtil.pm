use strict;
use warnings;

my $databasename = './database/test.db';
my $sessionsdbname='sessions.db';
package DatabaseUtil;

use DBI;

my $dbfile="test.db";

my $dbh = DBI->connect("dbi:SQLite:dbname=$databasename","{RaiseError => 1}","");

  my $realname;
my $sth_owner;
my $user;

sub getowner{

  my $day = shift @_;
  my $time = shift @_;
my $sql = 'SELECT user FROM blocks 
                           WHERE day =(0+?) AND time = (0+?)';

  $sth_owner = $dbh->prepare($sql);
  $sth_owner->execute($day,$time)
            or die "Couldn't execute statement: " . $sth_owner->errstr;

$sth_owner->bind_columns(\$user);
$sth_owner->fetch();
#my @result = $sth_owner->fetchrow_array();

return $user;

#  my $owner =`sqlite3 database/test.db 'SELECT time$time from days where day=$date'`;
 # chomp ($owner);
 # return $owner;
};


sub prepblank{
use DateTime;

use DateTime::Format::Strptime;
my $ymdformatter = DateTime::Format::Strptime->new(
  pattern => '%Y%m%d',
);

my $startdate=DateTime->today()->truncate(to=>'week')->subtract(days=>1);
$startdate->set_formatter($ymdformatter);
my $enddate=$startdate->clone()->add(months=>5);
print "startdate=".$startdate;
print "enddate=".$enddate;
  for(my $i=$startdate->clone();$i<$enddate;$i->add(days=>1)){
      for(my $j=0; $j<5; $j++){
      $dbh->do('INSERT INTO blocks VALUES ('.$i.','. $j.',\'-open-\')');
    };
  };
};

sub setowner{

  my $date = shift @_;
  my $time = shift @_;
  my $newuser = shift @_;

my $sql = 'UPDATE blocks SET user =? WHERE day =(?+0) AND time =(?+0)';
$sth_owner = $dbh->prepare($sql);
$sth_owner->execute($newuser,$date,$time);
#return `sqlite3 database/test.db 'update days time$time=$newuser from days where day=$date'`;
};

sub insertrows{
  for(my $i=0; $i<$_[0];$i++){
     print `sqlite3 test.db 'INSERT INTO days DEFAULT VALUES'`;
  };
};
#print `pwd`;

sub getrealname{
  $sth_owner = $dbh->prepare('SELECT realname FROM users WHERE username=?');
  $sth_owner->execute($_[0]);
  $sth_owner->bind_columns(\$realname);
  $sth_owner->fetch(); 
 return $realname;

}

sub makelabels{

  $sth_owner = $dbh->prepare('SELECT username, realname FROM users');
  $sth_owner->execute();

  my (@labels, $username, $realname);

  while (($username, $realname) = $sth_owner->fetchrow_array) {
    push(@labels,($username, $realname));
  }
  push (@labels, ('-open-', '-open-','-reserved-','-reserved-'));
  return \@labels;

};

sub isfaculty{
  $sth_owner = $dbh->prepare('SELECT role FROM users where username=?');
  $sth_owner->execute($_[0]);
  my $isfaculty=(($sth_owner->fetchrow_array eq 'instructor') ? 1 : 0);
  return $isfaculty; 
}

#sub recreatesessionsdb{

 # my $dbh = DBI->connect("dbi:SQLite:dbname=$sessionsdbname","{RaiseError => 1}","");
 # $dbh->do('CREATE TABLE sessions ( id CHAR(32) NOT NULL PRIMARY KEY,
 #       a_session TEXT NOT NULL');
#}
return 1;
