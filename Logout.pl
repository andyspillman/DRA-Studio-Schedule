
use CGI qw/:standard/;
use CGI::Session;
#use FindBin qw($Bin);
#:w
#use lib "$Bin/database";

my $session = CGI::Session->load('driver:sqlite',undef, {DataSource=>'database/session.db'}) or die (CGI::Session->errstr);
    $session->delete();
print header(-Refresh=>'0;url='.url(-base=>1).'/room/cgi-bin/index.pl');
    


