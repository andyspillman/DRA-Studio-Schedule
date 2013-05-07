use FindBin qw($Bin);
use lib "$Bin/../lib/";
use DatabaseUtil;


use CGI qw/:standard/;
use CGI::Session;
$CGI::POST_MAX=1024 * 100;  # max 100K posts
$CGI::DISABLE_UPLOADS = 1;  # no uploads
#use FindBin qw($Bin);
#:w
#use lib "$Bin/database";

my $session = CGI::Session->load('driver:sqlite',undef, {Handle=>$DatabaseUtil::sessions_dbh}) or die (CGI::Session->errstr);
    $session->delete();
#print header();
#print start_html(-title=>'DRA Studio Sign out sheet',
#    -style=>{'src'=>'/room/draStudioSched.css'},
#    -head=>meta({-http_equiv => 'Content-Language',
#      -content => 'en'}));
 
my ($path_to_here, $filename) = (url(-full=>1) =~ /(.+)(\/Logout.pl)/);
#print p($path_to_here.$filename);

print header(-Refresh=>'0;url=https://cas.iu.edu/cas/logout?casurl='.$path_to_here.'/index.pl');
