#!/usr/bin/perl

use warnings;
use strict;

# In addition to the modules expliclty included, LWP::UserAgent
# uses Crypt::SSLeay to enable SSL support.  Please ensure you
# have it installed, or LWP may generate some cryptic error messages. 
use LWP::UserAgent;
use CGI qw/:standard/;

use CGI::Session;
require CGI::Session::Driver::DBI;

# Create application objects
my $cgi = new CGI;
my $ua = new LWP::UserAgent;

# Configuration parameters
# casurl should be set to the url of this application.
# There are several different possible values for cassvc.  For more information, search 
# for 'cas application code' in the knowledge base (kb.iu.edu)
my $cassvc = 'IU';
my $casurl = 'http://silo.cs.indiana.edu:11304/room/cgi-bin/cas_basic.cgi';

# Check for a CAS ticket
my $cas_ticket = $cgi->param('casticket');

# Check to see if the CAS ticket is defined and that it appears to be a legal CAS ticket.
if (defined($cas_ticket) && $cas_ticket =~ m/^ST-\d+-[A-Za-z0-9]+-casprd\d\d.uits.iu.edu$/){


# Retrieve the contents of the validation response
  my $req = new HTTP::Request('GET', "https://cas.iu.edu/cas/validate?cassvc=$cassvc&casticket=$cas_ticket&casurl=$casurl");
  my $res = $ua->request($req);
  my $validate_reply = $res->content;

# If the validate response begins with 'yes', then we know that the authentication was successful.
# We need to obtain the appropriate username from the auth block, which is a string 'yes\r\nusername'
  if ($validate_reply =~ m/^yes/){
    my $cas_username_tainted = (split("\r\n", $validate_reply))[1];

# Ensure that the username response is valid; either an IU username for IU users or a sequence number for guests
    our $cas_username;
    if ($cas_username_tainted =~ m/^([a-z0-9]+)$/){
      $cas_username = $1;
    } else {
      die("Username is malformed.");
    }

# Take whatever action is appropriate for a successful authentication.
#        print $cgi->header();


    my $session = CGI::Session->new('driver:sqlite',undef, {DataSource=>'database/session.db'}) or die (CGI::Session->errstr);
#   $CGISESSID = $session->id();
    $session->expire("15s");
    $session->param('username',$cas_username);
    print $session->header(-Refresh=>"0; URL=index.pl");
    print "$cas_username was authenticated.";


  } else {
# Take whatever action is appropriate for a failed authentication; note that this is an unusual case.
# It means that CAS generated a ticket which we were unable to validate.  Bad passwords and invalid usernames
# should be stopped at the CAS server.  
    print $cgi->header();
    print "Authentication failed.\n";
  }
} else {
# If we get here, that means we have no CAS ticket to work on.  To obtain one,
# we need to redirect the user to the CAS logon page.
  print $cgi->header(-Refresh=>"0; URL=https://cas.iu.edu/cas/login?cassvc=$cassvc&casurl=$casurl");
  print "Redirecting to CAS server.\n";
}






