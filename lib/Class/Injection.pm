package Class::Injection; ## Injects methods to other classes

# use Data::Dumper;
use 5.006; 
use Class::Inspector;
use strict;

our $VERSION = '1.01';


## The Injection class is a elegant way to manipulate existing classes without editing them.
## It is done during runtime. It is a good way to write plugins without creating special plugins
## technologies.
##
## SYNOPSIS
## ========
##
##
##  # Here an original class
##  # Imagine you want to overwrite the test() method.
## 
##  package Foo::Target;
##
##  use Moose; # creates an constructor
##
## 
##  sub test{
##    my $this=shift;
##  
##    print "this is the original method.\n";
##    
##  }
##
##
## In a simple Perl file you can use that class:
##
##  use Foo::Target;
## 
##  my $foo = Foo::Target->new();
## 
##  my $foo = Over->new();
## 
##  $foo->test(); # outout is: 'this is the original method'
##
##
## So far nothing happened
##
## If you want to change the test() method without editing the original code, you can use Class::Injection.
## First create a new class, like this:
## 
##  package Bar::Over;
## 
## 
##  use Class::Injection qw/Foo::Target/; # define the target
##
## 
##  sub test {
##    my $this=shift;
## 
##    print "this is the new method\n";
##   
##  }
## 
## 
## To define the class which should be overwritten, you set the name after the 'use Class::Injection' call, here Foo::Target.
##
## In the calling Perl script to need to initialize that:
##
##
##  use Foo::Target;
##  use Bar::Over1;
## 
##  Class::Injection::install(); # installs the new methods from Bar::Over
##
##  my $foo = Foo::Target->new();
##  
##  $foo->test(); # Output is: 'this is the new method'
## 
##   
## The example above uses the default copymethod 'replace', which just replaces the methods.
## Class::Injection can do more complicated things, depending on your need you can stack methods
## to run several different variations e.g. of a test(). You can also define the way of returning a value.
## 
## ADD A METHOD
## ============
##
## The simplest way to add a method to an existing one you can see in the example below. To add a method means to
## execute the original method and the new method.
##
##  package Over;
##
##  use Class::Injection qw/Target add/;
##
##  sub test { ... };
##
## This example overwrites a class 'Target'. You can see the second value after the target class is the copymethod.
## Here it is 'add'. It is equivalent to 'append'.
##
## PRIORITY
## ========
##
## You can add more than one method. To finetune the position, you can set as a third value a priority. The original
## class has the priority 0. Every positive number comes later and negative numbers before.
##
##  package Over;
##
##  use Class::Injection qw/Target add -5/;
##
##  sub test { ... };
##
## If you dont care about a priority, but just want the same order like it is listed, you can use 'insert' (before) or
## 'append'.
##
##  use Class::Injection qw/Target append/;
##  ...
##  use Class::Injection qw/Target insert/;
##
## Inserted class's method will be called before the appended class's method.
##
##
## RETURN TYPES
## ============
##
## You can configure the return types of a method. Please be aware of the its behaviours:
##
## 1. It is a class-wide configuration.
##
## 2. If you use more than one overwriting class, The last called, defines the overwriting rules.
##
## At first have a look into the following example how to set complex parameters:
##
##  use Class::Injection 'Target', {
##                                     'how'           =>  'add',
##                                     'priority'      =>  4,
##                                     'returnmethod'  =>  'collect',
##                                 };
##
## The first parameter is still the target class, but then follows, seperated by a comma, a hashref with some values.
## 
## how - defines the way of adding the method. Default is 'replace'. You can also use 'add' (same as 'append') or 'insert'.
## 
## copymethod - same as 'how'.
##
## priority - please see the chapter PRIORITY for that.
## 
## returns - defines the return-type. (see below)
##
## returntype - same as 'returns'.
##
## returnmethod - defines which method(s) return values are used. (see below)
##
## 
## The returntype is currently set to 'array' for any type. What means it is not further implemented to returns something else.
## I have to see if there changes are neccessary during praxis. So far it looks like a return of array is ok.
## 
## The returntype is currently more automatically defined by context! It means if you e.g. call a
##
##  my @x = test();
##
## It gives you an array, and if you do
##
##  my $x = test();
##
## It gives you an scalar. But it depends on the used 'returnmethod' what exaclty you will get! With 'collect' it returns an
## arrayref, with anything else it will be the first value, if in scalar context.
##
##
## RETURNMETHOD
## ============
##
## The returnmethod can have the following values:
##
## last, all, original, collect.
##
## Before you start dealing with returnmethods, please note, that it might get compilcated, because you are changing the way of
## returning values of the original method. If you just use 'replace' you dont change the returnmethods. It can be used to build
## a plugin system and handling the results of several parallel classes.
##
## If you want to manipulate values with the methods (functions), I recommend using references as a part of the given 
## parameters and not the output of a method. For example:
##
##  # not good:
##  my $string = 'abcdefg';
##  my $new_string = change_text($stgring)
##
## The example above will make trouble if you use 'collect' as returnmethod. 
##
##  # better:
##  my $string = 'abcdefg';
##  change_text(\$stgring)
##
## Here each new installed method just takes the reference and can change the text. No return values needed.
##
##
## The default is 'last', what means the last called method's return values are used. This is the most save
## way to handle, because this method is usually used somewhere already and a specific returntype is expected.
## If you just change it, maybe the code stops working.
##
## Also save is 'orginal' that will just return the original's method value.
##
## With 'all' it merges all return values into an array, what must be handled in context. If you previosly used that call:
##
##  my $x = test();
##
## It will give you now only the first value, what is maybe not what you want. Expect with 'all' an array as return value and handle it:
##
##  my @x = test();
##
##
## PLUGINS
## =======
##
## How to use Class::Injection to build a plugin system?
##
## I see two type of plugins here:
##
## 1. Just replacing existing methods and returning ONE value, like the original method.
##
## 2. The caller expects plugins, what means he may handle different return values, that can occour when e.g. used 'collect' as
## a copymethod.
##
## For both types you will need to scan a folder for perl modules and 'use' them. Of course I assume they have the Class::Injection in use.
##
## If the calller expects plugins, I recommend using an abstract class as a skelleton, which the caller uses to instantiate the class.
## The methods of the abstract class should already return an arrayref. And in the plugins use the key " replace => 'true' " in the 
## Class::Injection line. That will overwrite the abstract class's methods.
##
##     package Abstract;
## 
##     use Moose; ## for constructor only
## 
##     sub test{
##     my $this=shift;
## 
## 
##     return [];
##     }
## 
##     1;
##
##
## Here a plugin:
##
##
##  package Plugin1;
##  
##  use base 'Abstract';
##  
##  use Class::Injection 'Abstract', {
##                                    'how'           => 'add',
##                                    'returnmethod'  => 'collect',
##                                    'replace'       => 'true',
##                                   };
##  
##  sub test{
##    my $this=shift;
##  
##    return "this is plugin 1";
##  }
##  
##  1;
##
## The main script:
##
##     eval('use Plugin1;'); # only to show it might be dynamically loaded
## 
##     use Class::Injection;
##     use Abstract;
## 
##     Class::Injection::install();
## 
##     my $foo = Abstract->new();
##





## The import function is called by Perl when the class is included by 'use'.
## It takes the parameters after the 'use Class::Injection' call.
## This function stores your intention of injection in the static collector
## variable. Later you can call install() function to overwrite or append the methods.
sub import{
    my $pkg=shift;
    my $target=shift; # the first parameter, which is the target

    if (!$target){return};

    my $secondvalue = shift;

    my $copymethod;
    my $priority;
    my $returntype;
    my $returnmethod;
    my $replacetarget;

    ## if the second value is a hashref, asign the elements
    if ( ref($secondvalue) ){

      $copymethod = $secondvalue->{'how'} || $secondvalue->{'copymethod'};
      $priority   = $secondvalue->{'priority'};
      $returntype = $secondvalue->{'returns'} || $secondvalue->{'returntype'} || '';
      $returnmethod = $secondvalue->{'returnmethod'} || 'last';

      $replacetarget = $secondvalue->{'replace'} =~ m/^(true|yes)$/i ? 1 : 0;

    }else{ ## if the second value is NOT a ref, take copymethod and prio
      $copymethod = $secondvalue || 'replace';
      $priority   = shift; ## default prio is 1 
    }

    if ( $copymethod eq 'replace' ){
      $replacetarget = 1;
    }

    
    my @caller=caller;
    my $class = shift @caller; # calling class (which has 'use Class::Injection')

    ## used for insert and append
    $Class::Injection::counter_neg--;
    $Class::Injection::counter_pos++;
    
    if ($priority < $Class::Injection::counter_neg){
      $Class::Injection::counter_neg = $priority - 1;
    }

    if ($priority < $Class::Injection::counter_pos){
      $Class::Injection::counter_pos = $priority + 1;
    }

    

    ## setting default priorities
    if ( $priority eq "" ){
        if ( $copymethod eq 'insert'){
            $priority = $Class::Injection::counter_neg;
        }else{ ## add or append
            $priority = $Class::Injection::counter_pos;
        }
    }
    

    
    if (!$target) {
      die __PACKAGE__." expects a parameter as target class in the use line."
    }
    
    
    ## collection the classnames using the injector
    $__PACKAGE__::collector ||= {};
    $__PACKAGE__::collector->{$class} = { target          =>  $target,
                                          priority        =>  $priority,
                                          copymethod      =>  $copymethod,
                                          returntype      =>  $returntype,
                                          returnmethod    =>  $returnmethod,
                                          replacetarget   =>  $replacetarget,
                                        };
}





## Installs the methods to existing classes. Do not try to call this method in a BEGIN block,
## the needed environment does not exist so far.
sub install{

  my $col = $__PACKAGE__::collector;
#    print Dumper($col);

  my $sources_by_target={};

  foreach my $source (keys %{ $col }) { ## loop per source class
 
    my $target      = $col->{$source}->{'target'};
    my $copymethod  = $col->{$source}->{'copymethod'};
    my $priority    = $col->{$source}->{'priority'};

    ## check if source exists on the memory (is loaded via 'use')
    if (!Class::Inspector->loaded( $source )) {
      if (!Class::Inspector->installed($source)) {
        die "Class \'$source\' not installed on this machine or path not in \@INC.";
      }
      die "Class \'$source\' not loaded.";
    }

    ## read the methods of the source class
    my $functions = Class::Inspector->functions( $source );


    ## build an array of sources by target
    ## its the reverse way to see what sources wants
    ## to inject a target
    foreach my $method (@$functions) {
        $sources_by_target->{$target}->{$method} ||= [];
        push @{ $sources_by_target->{$target}->{$method} }, $source;
    }


#     print Dumper($sources_by_target);
    
  
    
  } # end each $source
  
  
  ## sorting the source by its priority
  foreach my $target (keys %{ $sources_by_target }){
    foreach my $method (keys %{ $sources_by_target->{$target} }){

      my @tosortarray = @{ $sources_by_target->{$target}->{$method} };
      @tosortarray = sort { $col->{$b}->{'priority'} <=> $col->{$a}->{'priority'} } @tosortarray;
      $sources_by_target->{$target}->{$method} = \@tosortarray;

    }
  }
  
  
  #print Dumper($sources_by_target);



  ## collects replace tags for target.
  ## if there is at least one class which wants
  ## to replace the target, it will not keep the
  ## original target method.
  my $replace_target={};
  foreach my $target (keys %{ $sources_by_target }){
    foreach my $method (keys %{ $sources_by_target->{$target} }){

        foreach my $source ( @{$sources_by_target->{$target}->{$method}} ){
            
            if ( $col->{$source}->{'replacetarget'} ){
                $replace_target->{$target} = 1;    
            }

        }
    }
  }


  
  
  ## building the injection code
  my @cmd;
  foreach my $target (keys %{ $sources_by_target }){

    foreach my $method (keys %{ $sources_by_target->{$target} }){

        my $returntype = 'array';
        my $returnmethod = 'last';

        my @cmd_pos;
        my @cmd_neg;
        my @cmd_zer;


        push @cmd, ' my $orgm=\&'.$target.'::'.$method.';';

#         push @cmd, '*'.$target.'::_INJBAK_'.$method.'=\&'.$target.'::'.$method.';';

        push @cmd, '*'.$target.'::'.$method.' = sub {';

        push @cmd, ' my @ret_org;';
        push @cmd, ' my @ret;';
        push @cmd, ' my @ret_refs;';

        
        if (!$replace_target->{$target}){ ## if no replace, reimplement original method
             push @cmd_zer, ' @ret_org = &$orgm(@_);';

#             push @cmd_zer, ' @ret_org = '.$target.'::_INJBAK_'.$method.'(@_);';
            push @cmd_zer, ' push @ret, @ret_org;';

            push @cmd_zer, ' push @ret_refs, \@ret_org;';


        }
        
        foreach my $source ( @{$sources_by_target->{$target}->{$method}} ){

            my $priority = $col->{$source}->{'priority'};
            my $met_returntype = $col->{$source}->{'returntype'};
            my $met_returnmethod = $col->{$source}->{'returnmethod'};
            
            if ($met_returntype) { ## a different returntype set?
                $returntype = $met_returntype;
            }

            if ($met_returnmethod) { ## a different returntype set?
                $returnmethod = $met_returnmethod;
            }

            #my $copymethod = $col->{$source}->{'copymethod'};

            my $waitcmd;
            $waitcmd .= ' my @ret_tmp = '.$source.'::'.$method.'(@_);'."\n";
            $waitcmd .= ' push @ret, @ret_tmp;'."\n";
            $waitcmd .= ' push @ret_refs, \@ret_tmp;'."\n"; ## collecting references
            
            ## depending on the priority place it before or after
            if ($priority < 0){
                push @cmd_neg, $waitcmd;
            }

            if (0 < $priority){
                push @cmd_pos, $waitcmd;
            }
            
        }

        push @cmd, @cmd_neg;
        push @cmd, @cmd_zer;
        push @cmd, @cmd_pos;

        ## type of return - all the same at the moment
        my $ret_sign='@';
        if ( $returntype eq 'array' ){
            $ret_sign = '@';            
        }
        elsif ( $returntype eq 'scalar' ){
            $ret_sign = '@';            
        }
        elsif ( $returntype eq 'hash' ){
            $ret_sign = '@';            
        }
        
        

        # what to return
        my $ret_meth='ret';
        if ( $returnmethod eq 'last' ){
            $ret_meth = 'ret_tmp';
        }
        if ( $returnmethod eq 'all' ){
            $ret_meth = 'ret';
        }
        if ( $returnmethod eq 'original' ){
            $ret_meth = 'ret_org';
        }
        if ( $returnmethod eq 'collect' ){
            $ret_meth = 'ret_refs';
        }

        my $retv = $ret_sign.$ret_meth;

        if ($returnmethod eq 'collect'){
          push @cmd, ' return wantarray ? '.$retv.' : \\'.$retv.';'; ## assembles to a returnvalue
        } else {
          push @cmd, ' return wantarray ? '.$retv.' : shift '.$retv.';'; ## assembles to a returnvalue
        }

        #push @cmd, ' return wantarray ? @ret : \@ret;'     if $returntype eq 'array';
        
        push @cmd, '};';
        

    } # end method
  } ## end building injection code
  
  
  
  my $cmd = join("\n",@cmd);
#   print "\n\n\n".$cmd;
  
  eval($cmd);
  if ($@){
    die __PACKAGE__." ERROR when injecting: ".$cmd.$@;
  }

}









1;


#################### pod generated by Pod::Autopod - keep this line to make pod updates possible ####################

=head1 NAME

Class::Injection - Injects methods to other classes


=head1 SYNOPSIS



 # Here an original class
 # Imagine you want to overwrite the test() method.

 package Foo::Target;

 use Moose; # creates an constructor


 sub test{
   my $this=shift;
 
   print "this is the original method.\n";
   
 }


In a simple Perl file you can use that class:

 use Foo::Target;

 my $foo = Foo::Target->new();

 my $foo = Over->new();

 $foo->test(); # outout is: 'this is the original method'


So far nothing happened

If you want to change the test() method without editing the original code, you can use Class::Injection.
First create a new class, like this:

 package Bar::Over;


 use Class::Injection qw/Foo::Target/; # define the target


 sub test {
   my $this=shift;

   print "this is the new method\n";
  
 }


To define the class which should be overwritten, you set the name after the 'use Class::Injection' call, here Foo::Target.

In the calling Perl script to need to initialize that:


 use Foo::Target;
 use Bar::Over1;

 Class::Injection::install(); # installs the new methods from Bar::Over

 my $foo = Foo::Target->new();
 
 $foo->test(); # Output is: 'this is the new method'

  
The example above uses the default copymethod 'replace', which just replaces the methods.
Class::Injection can do more complicated things, depending on your need you can stack methods
to run several different variations e.g. of a test(). You can also define the way of returning a value.



=head1 DESCRIPTION

The Injection class is a elegant way to manipulate existing classes without editing them.
It is done during runtime. It is a good way to write plugins without creating special plugins
technologies.



=head1 REQUIRES


L<Class::Inspector> 



=head1 METHODS

=head2 import

 $this->import();

The import function is called by Perl when the class is included by 'use'.
It takes the parameters after the 'use Class::Injection' call.
This function stores your intention of injection in the static collector
variable. Later you can call install() function to overwrite or append the methods.


=head2 install

 $this->install();

Installs the methods to existing classes. Do not try to call this method in a BEGIN block,
the needed environment does not exist so far.


=head2 test

 $this->test();


=head1 RETURN TYPES


You can configure the return types of a method. Please be aware of the its behaviours:

1. It is a class-wide configuration.

2. If you use more than one overwriting class, The last called, defines the overwriting rules.

At first have a look into the following example how to set complex parameters:

 use Class::Injection 'Target', {
                                    'how'           =>  'add',
                                    'priority'      =>  4,
                                    'returnmethod'  =>  'collect',
                                };

The first parameter is still the target class, but then follows, seperated by a comma, a hashref with some values.

how - defines the way of adding the method. Default is 'replace'. You can also use 'add' (same as 'append') or 'insert'.

copymethod - same as 'how'.

priority - please see the chapter PRIORITY for that.

returns - defines the return-type. (see below)

returntype - same as 'returns'.

returnmethod - defines which method(s) return values are used. (see below)


The returntype is currently set to 'array' for any type. What means it is not further implemented to returns something else.
I have to see if there changes are neccessary during praxis. So far it looks like a return of array is ok.

The returntype is currently more automatically defined by context! It means if you e.g. call a

 my @x = test();

It gives you an array, and if you do

 my $x = test();

It gives you an scalar. But it depends on the used 'returnmethod' what exaclty you will get! With 'collect' it returns an
arrayref, with anything else it will be the first value, if in scalar context.




=head1 RETURNMETHOD


The returnmethod can have the following values:

last, all, original, collect.

Before you start dealing with returnmethods, please note, that it might get compilcated, because you are changing the way of
returning values of the original method. If you just use 'replace' you dont change the returnmethods. It can be used to build
a plugin system and handling the results of several parallel classes.

If you want to manipulate values with the methods (functions), I recommend using references as a part of the given 
parameters and not the output of a method. For example:

 # not good:
 my $string = 'abcdefg';
 my $new_string = change_text($stgring)

The example above will make trouble if you use 'collect' as returnmethod. 

 # better:
 my $string = 'abcdefg';
 change_text(\$stgring)

Here each new installed method just takes the reference and can change the text. No return values needed.


The default is 'last', what means the last called method's return values are used. This is the most save
way to handle, because this method is usually used somewhere already and a specific returntype is expected.
If you just change it, maybe the code stops working.

Also save is 'orginal' that will just return the original's method value.

With 'all' it merges all return values into an array, what must be handled in context. If you previosly used that call:

 my $x = test();

It will give you now only the first value, what is maybe not what you want. Expect with 'all' an array as return value and handle it:

 my @x = test();




=head1 PRIORITY


You can add more than one method. To finetune the position, you can set as a third value a priority. The original
class has the priority 0. Every positive number comes later and negative numbers before.

 package Over;

 use Class::Injection qw/Target add -5/;

 sub test { ... };

If you dont care about a priority, but just want the same order like it is listed, you can use 'insert' (before) or
'append'.

 use Class::Injection qw/Target append/;
 ...
 use Class::Injection qw/Target insert/;

Inserted class's method will be called before the appended class's method.




=head1 PLUGINS


How to use Class::Injection to build a plugin system?

I see two type of plugins here:

1. Just replacing existing methods and returning ONE value, like the original method.

2. The caller expects plugins, what means he may handle different return values, that can occour when e.g. used 'collect' as
a copymethod.

For both types you will need to scan a folder for perl modules and 'use' them. Of course I assume they have the Class::Injection in use.

If the calller expects plugins, I recommend using an abstract class as a skelleton, which the caller uses to instantiate the class.
The methods of the abstract class should already return an arrayref. And in the plugins use the key " replace => 'true' " in the 
Class::Injection line. That will overwrite the abstract class's methods.

    package Abstract;

    use Moose; ## for constructor only

    sub test{
    my $this=shift;


    return [];
    }

    1;


Here a plugin:


 package Plugin1;
 
 use base 'Abstract';
 
 use Class::Injection 'Abstract', {
                                   'how'           => 'add',
                                   'returnmethod'  => 'collect',
                                   'replace'       => 'true',
                                  };
 
 sub test{
   my $this=shift;
 
   return "this is plugin 1";
 }
 
 1;

The main script:

    eval('use Plugin1;'); # only to show it might be dynamically loaded

    use Class::Injection;
    use Abstract;

    Class::Injection::install();

    my $foo = Abstract->new();



=head1 ADD A METHOD


The simplest way to add a method to an existing one you can see in the example below. To add a method means to
execute the original method and the new method.

 package Over;

 use Class::Injection qw/Target add/;

 sub test { ... };

This example overwrites a class 'Target'. You can see the second value after the target class is the copymethod.
Here it is 'add'. It is equivalent to 'append'.



=cut

