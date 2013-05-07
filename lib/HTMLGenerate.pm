use strict;
use warnings;


use FindBin qw($Bin);
use lib "$Bin/../lib/";
use DateTime;
use DateTime::Format::Strptime;
use DatabaseUtil;

package HTMLGenerate;
use CGI qw/:standard/;
use CGI::Session;

#file vars
my $celldate;
my $tablecol = 0;
my $timeblock = 1;##this correlates with row, and row 0 is the headings, days
                  #of the week, so it makes sense to start on 1


###called in main, builds table 
sub buildtable{
  until ($timeblock>4){
    print "<tr>";
    until ($tablecol>7){
      makecell();
      $tablecol++;
    };
    print "</tr>\n";
    $timeblock++;
    $tablecol=0;
  };
  print "</table>";
}

###called in buildtable(), makes headings and calls fillcell() for the juicy stuff
sub makecell{
  my @timeblockname = ("",
      "8 am - 12 pm",
      "12 pm - 4 pm",
      "4-pm - 8 pm",
      "8 pm - 12 am",
      );
  print "<td>";
  if ($tablecol==0) {
    print "<p class=\"timecol\">", $timeblockname[$timeblock],"</p>";
  } else {
    fillcell();
  };
  print "</td>";
}



###called in makecell(), gives us the meat (juicy stuff)

#behaves differently if time block is set to -reserved-, -shared-, or a username
# each case also behaves differently if user is faculty

#-reserved- can only be set by faculty, and allows a custom string to be inserted
#describing how the time will be used

#-shared- can also only be set by faculty, it means the time is initially
# shared by multiple users, selecting it causes a text area to appear, users are
# set by inserting multiple usernames into text field seperated by spaces.
# Those users can give up their time, but that's all.

#-open- spots can be claimed by anyone on the roster for a given rooom

#timeblock owners can give out their time to anyone else, or give it up (-open-)

#faculty can do all of the above


sub fillcell{
  my $timeblockowner = DatabaseUtil::getowner($main::weekstart->clone->add(days=>$tablecol-1), $timeblock);
  $celldate = $main::weekstart->clone->add(days=>$tablecol-1)->ymd('');
  if ($timeblockowner =~ /^-reserved-(.*)/){
    if ($main::faculty){
      dropdown('-reserved-');
      print startform().textarea(-name=>'reserved_details',-default=>$1,-rows=>5,
          -columns=>25,-maxlength=>50).
        hidden(-name=>'target_submit_block',
            -value=>$celldate.".".$timeblock).
       "<BR>".submit().endform();

    }else{
      print p({class=>'details'},$1);
    };

  }elsif ($timeblockowner =~ /^-shared-(.*)/){
    if ($main::faculty){
      dropdown('-shared-');
      print startform().textarea(-name=>'shared_names',-default=>$1,-rows=>5,
          -columns=>25,-maxlength=>50).
        hidden(-name=>'target_submit_block',
            -value=>$celldate.".".$timeblock).
        "<BR>".submit().endform();
    }else{
      my @timeblockowners = ($timeblockowner =~ /(\w+)/g);
      foreach (@timeblockowners){
        if ($_ && !($_ eq'shared')){        
          print p($main::labels{$_});
        }; 
 };
      if ($main::username ~~ @timeblockowners){
        print a({-href=>url(-relative=>1)."?weekstart=$main::weekstart&targetdate=$celldate&timeblock=$timeblock&newowner=-open-"},"give up");
      };

    };
  }elsif (($main::username eq $timeblockowner)||$main::faculty){
    dropdown($timeblockowner);
  }elsif (($timeblockowner eq '-open-')&& $main::username){
    print a({-href=>url(-relative=>1)."?weekstart=$main::weekstart&targetdate=$celldate&timeblock=$timeblock&newowner=$main::username"},"take");

  }else{
    print $main::labels{$timeblockowner} //$timeblockowner;
  }
  };

#generates dropdown menu.  Single argument taken is the default selection: username
#or special option (-open-,-reserved-,-shared-).
sub dropdown{
  print popup_menu(
      -values=>[sort(keys %main::labels)],
      -default =>$_[0],
      -labels=>\%main::labels,
      -onChange=>"window.location.href='index.pl?weekstart=$main::weekstart&targetdate=$celldate&timeblock=$timeblock&newowner='+this.value",
      ); 
};

return 1;
