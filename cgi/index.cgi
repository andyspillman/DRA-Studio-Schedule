#IU Department of Recording Arts Studio Sign Out v0.1
#
#Allows students and faculty to reserve time in rooms, or anything else suited
#for a schedule.
#
#Copyright (C) 2013 Andy Spillman - andy at andyspillman dot com
#
#IU Department of Recording Arts Studio Sign Out is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.
#
#IU Department of Recording Arts Studio Sign Out is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with IU Department of Recording Arts Studio Sign Out.  If not, see <http://www.gnu.org/licenses/>.
#

#!/usr/bin/perl
use strict;
use warnings;

use CGI qw/:standard/;

$CGI::POST_MAX        = 1024 * 100;    # max 100K posts
$CGI::DISABLE_UPLOADS = 1;             # no uploads

use FindBin qw($Bin);
use lib "$Bin/../lib/";
use DatabaseUtil;

##START HTML
print header( -expires => 'now' )
  . start_html(
    -title => 'DRA Studio Selection',
    -style => { 'src' => '/room/draStudioSched.css' },
    -head  => meta(
        {
            -http_equiv => 'Content-Language',
            -content    => 'en'
        }
    )
  );

print h2("Which Schedule would you like?");
foreach my $eachroom ( @{ DatabaseUtil::roomnames() } ) {
    print p( a( { -href => "schedule.cgi?room=$eachroom" }, "$eachroom" ) )
      unless !( DatabaseUtil::is_visible($eachroom) );
}
print end_html();

# END HTML

