package Plugin2;

use base 'Abstract';

use Class::Injection 'Abstract', {
                                  'how'           => 'add',
                                  'returnmethod'  => 'collect',
                                  'replace'       => 'true',
                              };



sub test{
  my $this=shift;

  return "this is plugin 2";
}
 



1;