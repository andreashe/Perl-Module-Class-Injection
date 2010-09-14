
use lib '../../lib';

use Target;
use Over;


Class::Injection::install();


my $foo = Target->new();


$foo->test();


