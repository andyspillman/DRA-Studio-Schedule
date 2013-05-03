use DBI;

use warnings; 
use strict;
use Spreadsheet::ParseExcel;

# This assumes worksheet is arranged with columns, in order: (realname, username, x, Role),
# with column headings in first row (0) and data beginning in next row.
# If roster is exported from Oncourse in different format, change the following values, furthest
# left column is 0.


my $realname_col = 0;   #column of Real Name
my $username_col = 1;   #column of User ID
my $role_col = 3;       #column of Role
my $first_data_row = 1;  #first row containing useful data



my $dbfile="test.db";
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile","{RaiseError => 1}","");

$dbh->do('DELETE FROM users');
my $sth = $dbh->prepare('INSERT INTO users VALUES (?, ?, ?)');

my ($username,$realname,$role);

my $workbook = Spreadsheet::ParseExcel::Workbook->Parse('roster.xls');
my $worksheet =$workbook->worksheet(0);

my @row_range = $worksheet->row_range();

  for(my $iR = 1; $iR <= $row_range[1]; $iR++) {
    $username = $worksheet->get_cell($iR, $username_col)->value();
my $name = $worksheet->get_cell($iR, $realname_col)->value();



$name =~ /(\w*),\s(\w*)\s?/;
    $realname =  $2." ".$1; 
              # ^ "Lastname, First Middle" -> "First Lastname"
print ("\"".$realname. "\"\n "); 

    $role = $worksheet->get_cell($iR, $role_col)->value();
    $sth->execute($username, $realname, $role);

  print "added $username, $realname, $role";
  }


