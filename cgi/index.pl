use strict;
use warnings;

use CGI qw/:standard/;

$CGI::POST_MAX=1024 * 100;  # max 100K posts
$CGI::DISABLE_UPLOADS = 1;  # no uploads

use FindBin qw($Bin);
use lib "$Bin/../lib/";
use DatabaseUtil;


##START HTML
print header(-expires=>'now').
start_html(-title=>'DRA Studio Selection',
    -style=>{'src'=>'/room/draStudioSched.css'},
    -head=>meta({-http_equiv => 'Content-Language',
      -content => 'en'}));

  print h2("Which Schedule would you like?");
  foreach my $eachroom (@{DatabaseUtil::roomnames()}){
    print p(a({-href=>"schedule.pl?room=$eachroom"}, "$eachroom"))
      unless !(DatabaseUtil::is_visible($eachroom));
  };
print end_html();
# END HTML


