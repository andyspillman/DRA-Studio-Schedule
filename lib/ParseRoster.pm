use DBI;

use warnings; 
use strict;
use Spreadsheet::ParseExcel;

# This assumes worksheet is arranged with columns, in order: (realname,
# username, x, Role), with column headings in first row (0) and data beginning
# in next row.  If roster is exported from Oncourse in different format,
# change the following values, furthest left column is 0.

package ParseRoster;

sub parse{

  my $realname_col = 0;   #column of real name
    my $username_col = 1;   #column of User ID
    my $role_col = 3;       #column of Role
    my $first_data_row = 1;  #first row containing useful data

   $DatabaseUtil::rosters_dbh->do("CREATE TABLE IF NOT EXISTS faculty (username primary key, realname)");

    my $sth = $DatabaseUtil::rosters_dbh->prepare("INSERT INTO '$main::which_room' VALUES (?, ?)");
  my $faculty_sth = $DatabaseUtil::rosters_dbh->prepare("INSERT INTO 'faculty' VALUES (?, ?)");

  my ($username,$realname,$role);

  my $workbook = Spreadsheet::ParseExcel::Workbook->Parse($main::roster_fh);
  my $worksheet =$workbook->worksheet(0);

  my @row_range = $worksheet->row_range();

  for(my $iR = 1; $iR <= $row_range[1]; $iR++) {
    $username = $worksheet->get_cell($iR, $username_col)->value();
    my $name = $worksheet->get_cell($iR, $realname_col)->value();
    $name =~ /(\w*),\s(\w*)\s?/;
    $realname =  $2." ".$1; 
# ^ "Lastname, First Middle" -> "First Lastname"
    $role = $worksheet->get_cell($iR, $role_col)->value();
    if($role eq 'student'){
      $sth->execute($username, $realname);
      print "<span>added $realname ($username) to $main::which_room<BR></span>"; 
   }elsif($role eq 'instructor'){
      $faculty_sth->execute($username, $realname);
      print "<span>added or kept $realname ($username) as faculty<BR></span>"; 
    };
    };
};
return 1;
