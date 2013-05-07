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
my $session = CGI::Session->new('driver:sqlite',undef,
    {Handle=>$DatabaseUtil::sessions_dbh}) or die (CGI::Session->errstr);

our $username = $session->param('username') // "";

my ($path_to_here, $filename) = (url(-full=>1) =~ /(.+)(\/.+\.pl)/);
sub roster_update_display(){
  print start_multipart_form();
  print filefield(-name=>'roster_405',
      -size=>50,
      -maxlength=>400).submit().end_multipart_form();


# undef may be returned if it's not a valid file handle
  my $roster_405_fh  = upload('roster_405');
  if (defined $roster_405_fh) {
# Upgrade the handle to one compatible with IO::Handle:
    my $io_handle = $roster_405_fh->handle;
    open (OUTFILE,">>","$Bin/temp");
    while (my $I = $io_handle->read(my $buffer,1024)) {
      print OUTFILE $buffer;
    };
#open (INFILE,'<',"$Bin/../temp");
#print INFILE;
close OUTFILE or die;
#Delete() or die;
#undef $io_handle or die;
  };
};
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
  }; 
#my $faculty = DatabaseUtil::isfaculty($username) unless !$username;
my $faculty = 1;
if($faculty){

roster_update_display();

}else{
  print p("You don't appear to be faculty. Try logging out and revist this page.").
 a({-href=>url(-base=>1)."/room/cgi-bin/Logout.pl"}, "Logout");
};





print end_html();

