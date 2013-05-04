use strict;
use warnings;
use DateTime;
use DateTime::Format::Strptime;
package DBMaintenance;

sub prepdays{

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
      $DatabaseUtil::dbh->do('INSERT INTO blocks VALUES ('.$i.','. $j.',\'-open-\')');
    };
  };
};


#sub recreatesessionsdb{

 # my $dbh = DBI->connect("dbi:SQLite:dbname=$sessionsdbname","{RaiseError => 1}","");
 # $dbh->do('CREATE TABLE sessions ( id CHAR(32) NOT NULL PRIMARY KEY,
 #       a_session TEXT NOT NULL');
#}


return 1;
