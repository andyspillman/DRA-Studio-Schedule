use strict;
use warnings;


use FindBin qw($Bin);
use lib "$Bin/../lib/";
use DateTime;
use DateTime::Format::Strptime;
use DatabaseUtil;

package HTMLGenerate;
use CGI qw/:standard/;
#use CGI::Session;

#file vars
my ($celldate,$maxtimeblock,$timeblocklength);
my $tablecol = 0;
my $timeblock = 1;##this correlates with row, and row 0 is the headings, days
                  #of the week, so it makes sense to start on 1

###called in main, builds table 
sub buildtable{
$maxtimeblock = DatabaseUtil::numberoftimeblocksforroom($main::room);
$timeblocklength = (16/$maxtimeblock);
  until ($timeblock>$maxtimeblock){##check for how many timeblocks there actually are
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
my @timeblockname;
if ($timeblocklength==1){
   @timeblockname = ("",
      "8 am - 9 am",
      "9 am - 10 am",
      "10 am - 11 am",
      "11 am - 12 pm",
      "12 am - 1 pm",
      "1 pm - 2 pm",
      "2 pm - 3 pm",
      "3 pm - 4 pm",
      "4 pm - 5 pm",
      "5 pm - 6 pm",
      "6 pm - 7 pm",
      "7 pm - 8 pm",
      "8 pm - 9 pm",
      "9 pm - 10 pm",
      "10 pm - 11 pm",
      "11 pm - 12 am",
      );

} elsif ($timeblocklength==2){
 @timeblockname = ("",
      "8 am - 10 am",
      "10 am - 12 pm",
      "12 pm - 2 pm",
      "2 pm - 4 pm",
      "4 pm - 6 am",
      "6 pm - 8 pm",
      "8 pm - 10 pm",
      "10 pm - 12 am",
      );
 
}else{
 @timeblockname = ("",
      "8 am - 12 pm",
      "12 pm - 4 pm",
      "4-pm - 8 pm",
      "8 pm - 12 am",
      );
}
  print "<td>";
  if ($tablecol==0) {
    print "<p class=\"timecol\"> $timeblockname[$timeblock]</p>";
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

#if DatabaseUtil::getowner returns undef, likely the user has gone out of the range of defined
#days, in which case nothing happens and the cell is blank
  if (my $timeblockowner = DatabaseUtil::getowner($main::weekstart->clone->add(days=>$tablecol-1),
        $timeblock)){ ###change to include $celldate instead???
    $celldate = $main::weekstart->clone->add(days=>$tablecol-1)->ymd('');
  if ($timeblockowner =~ /^-reserved-(.*)/){
    if ($main::faculty){
      dropdown('-reserved-');

#note:  excplitily defining -action="" ensures the browser uses the same URL after submitting
#without it, CGI.pm puts in other action values, leading to the loss of URL query elements in some
#cases
      print start_form(-action=>"",-enctype=>'application/x-www-form-urlencoded').textarea(-name=>'reserved_details',-default=>$1,-rows=>5,
          -columns=>25,-maxlength=>50).
        hidden(-name=>'target_submit_block',
            -value=>$celldate.".".$timeblock).
       "<BR>".submit().endform();

    }else{
      print p({class=>'details'},$1);
    };

  }elsif ($timeblockowner =~ /^-shared-(.*)/){### is the paren necessary?
    if ($main::faculty){
      dropdown('-shared-');
### same note as above
      print startform(-action=>"").textarea(-name=>'shared_names',-default=>$1,-rows=>5,
          -columns=>25,-maxlength=>50).
        hidden(-name=>'target_submit_block',
            -value=>$celldate.".".$timeblock).
        "<BR>".submit().endform();
    }else{
      my @timeblockowners = ($timeblockowner =~ /(\w+)/g);
      foreach (@timeblockowners){
        if ($_ && !($_ eq'shared')){###perhaps a better regex call would remove the need for this
          print p($main::labels{$_});
        }; 
      };
      if ($main::username ~~ @timeblockowners){###give user the option to give up if user is an owner
        print a({-href=>url(-relative=>1)."?room=$main::room&weekstart=$main::weekstart&targetdate=$celldate&timeblock=$timeblock&newowner=-open-"},"give up");
      };

    };
  }
#if user owns time block or is faculty, give dropdown menu to assign to anyone
  elsif (($main::username eq $timeblockowner)||$main::faculty){
    dropdown($timeblockowner);
  }
#if timeblock is open, give ability to clam if a user is logged in
#need to add restriction, user needs to be part of room roster
elsif (($timeblockowner eq '-open-')&& $main::labels{$main::username}){
    print a({-href=>url(-relative=>1)."?room=$main::room&weekstart=$main::weekstart&targetdate=$celldate&timeblock=$timeblock&newowner=$main::username"},"take");

  }else{
    print $main::labels{$timeblockowner} //$timeblockowner;
  }
  }
};

#generates dropdown menu.  Single argument taken is the default selection: username
#or special option (-open-,-reserved-,-shared-).
sub dropdown{

my $default = shift;


# if the username that is susposed to be selected is not on the labels, push the username to the label
#
if (!($main::labels{$default})){
    $main::labels{$default}=$default;
    };

  print popup_menu(
      -values=>[sort(keys %main::labels)],
      -default =>$default,
      -labels=>\%main::labels,
      -onChange=>"window.location.href='schedule.cgi?room=$main::room&weekstart=$main::weekstart&targetdate=$celldate&timeblock=$timeblock&newowner='+this.value",

      -autocomplete=>"off"      ); 

};

return 1;
