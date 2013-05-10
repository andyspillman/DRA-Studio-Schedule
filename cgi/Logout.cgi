#!/usr/bin/perl

#  IU Department of Recording Arts Studio Sign Out v0.1
#  
#  Allows students and faculty to reserve time in rooms, or anything else suited
#  for a schedule.
#  
#  Copyright (C) 2013 Andy Spillman - andy at andyspillman dot com
#  
#  IU Department of Recording Arts Studio Sign Out is free software: you can
#  redistribute it and/or modify it under the terms of the GNU General Public
#  License as published by the Free Software Foundation, either version 3 of the
#  License, or (at your option) any later version.
#  
#  IU Department of Recording Arts Studio Sign Out is distributed in the hope
#  that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
#  warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  General Public License for more details.
#  
#  You should have received a copy of the GNU General Public License along with
#  IU Department of Recording Arts Studio Sign Out.  If not, see
#  <http://www.gnu.org/licenses/>.

use FindBin qw($Bin);
use lib "$Bin/../lib/";
use DatabaseUtil;

use CGI qw/:standard/;
use CGI::Session;
$CGI::POST_MAX        = 1024 * 100;    # max 100K posts
$CGI::DISABLE_UPLOADS = 1;             # no uploads

#use FindBin qw($Bin);
#:w
#use lib "$Bin/database";

my $session =
  CGI::Session->load( 'driver:sqlite', undef,
    { Handle => $DatabaseUtil::sessions_dbh } )
  or die( CGI::Session->errstr );
$session->delete();

my ( $path_to_here, $filename ) = ( url( -full => 1 ) =~ /(.+)(\/Logout.cgi)/ );

print header( -Refresh => '0;url=https://cas.iu.edu/cas/logout?casurl='
      . $path_to_here
      . '/index.cgi' );
