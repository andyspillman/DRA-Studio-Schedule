use strict;
use warnings;

use CGI qw/:standard/;

$CGI::POST_MAX=1024 * 100;  # max 100K posts
$CGI::DISABLE_UPLOADS = 1;  # no uploads

use FindBin qw($Bin);
use lib "$Bin/../lib/";
use DatabaseUtil;

my $filename = url(-relative=>1);
my ($path_to_here) = (url(-full=>1) =~ /(.+)\/$filename/);

##START HTML
print header(-expires=>'now');
print start_html(-title=>'DRA Studio Selection',
    -style=>{'src'=>'/room/draStudioSched.css'},
    -head=>meta({-http_equiv => 'Content-Language',
      -content => 'en'}));
print p($path_to_here.$filename);

  print h2("Which Schedule would you like?");
  foreach my $eachroom (@{DatabaseUtil::roomnames()}){
    print p(a({-href=>"schedule.pl?room=$eachroom"}, "$eachroom"))
      unless !(DatabaseUtil::is_visible($eachroom));
#    print (DatabaseUtil::is_visible($eachroom));
  };
print end_html();
# END HTML


