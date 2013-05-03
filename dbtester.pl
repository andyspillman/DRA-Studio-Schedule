use strict;
use warnings;

require DatabaseUtil;
use FindBin qw($Bin);
use lib "$Bin/database";

#DatabaseUtil::setowner(1,2,'bob');

DatabaseUtil::makelabels();


#print DatabaseUtil::getowner(1,1);
