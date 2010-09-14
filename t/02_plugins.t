#!/usr/bin/perl


use lib '../lib';
use lib '../examples/plugins';

use Data::Dumper;
use Test::More tests => 4;



eval('use Plugin1;');
eval('use Plugin2;');

use Class::Injection;
use Abstract;

Class::Injection::install();


my $foo = Abstract->new();


ok( $foo->test()->[0]->[0] eq 'this is plugin 1' );
ok( $foo->test()->[1]->[0] eq 'this is plugin 2' );


my @res = $foo->test();

ok( $res[0]->[0] eq 'this is plugin 1' );
ok( $res[1]->[0] eq 'this is plugin 2' );

