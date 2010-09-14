
use lib '../../lib';

use Data::Dumper;

eval('use Plugin1;');
eval('use Plugin2;');

use Class::Injection;
use Abstract;

Class::Injection::install();


my $foo = Abstract->new();



print "\n---- context is scalar ---\n\n";

my $res = $foo->test();

print Dumper($res);



print "\n---- context is array ---\n\n";



my @res = $foo->test();

print Dumper(@res);

