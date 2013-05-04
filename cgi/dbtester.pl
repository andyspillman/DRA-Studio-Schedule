use strict;
use warnings;

require DatabaseUtil;
require DBMaintenance;
use FindBin qw($Bin);
use lib "$Bin/../lib";

DBMaintenance::prepdays();

#DatabaseUtil::setowner(1,2,'bob');

#DatabaseUtil::makelabels();


#print DatabaseUtil::getowner(1,1);
