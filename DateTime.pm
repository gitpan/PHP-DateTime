package PHP::DateTime;

use strict;
use 5.006;

our $VERSION = '0.02';
our %cache;
our %modules;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
	&checkdate &date &getdate &gettimeofday &mktime 
);


#---------------------------------------------------#
# Private methods.
#---------------------------------------------------#

# Loads up miscellaneous data if it has not already been cached in the %cache hash.
sub load_cache {
	my $key = shift;
	if($key eq 'days_short'){ $cache{$key} ||= ['Sun','Mon','Tue','Wed','Thr','Fri','Sat']; }
	elsif($key eq 'days_long'){ $cache{$key} ||= ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday']; }
	elsif($key eq 'months_short'){ $cache{$key} ||= ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']; }
	elsif($key eq 'months_long'){ $cache{$key} ||= ['January','February','March','April','May','June','July','August','September','October','November','December']; }
	elsif($key eq 'mktime_args'){ $cache{$key} ||= ['hour','minute','second','day','month','year','dst']; }
	return $cache{$key};
}

# Loads up a module via require if it hasn't already been loaded.
# TODO: This code is bogus, there's gotta be a more straight forward global way.
sub if_require {
	my $modname = shift;
	if(!$modules{$modname}){
		eval('require '.$modname);
		$modules{$modname}=1;
	}
}

#---------------------------------------------------#
# Exported/public methods.
#---------------------------------------------------#

# Refer to the PHP documentation for descriptions of these.

sub checkdate {
	if_require('Time::DaysInMonth');

	my($month,$day,$year) = @_;
	return (
		$year>=1 and $year<=32767 and 
		$month>=1 and $month<=12 and 
		$day>=1 and $day <= Time::DaysInMonth::days_in($year,$month)
	);
}

sub date {
	my $format = shift;
	my $esecs = (@_?shift():time());
	my $tzoffset;
	if(@_){
		$tzoffset = shift;
		if($tzoffset=~/^-?[0-9]+\.[0-9]+$/s){ $tzoffset=$tzoffset*60*60; }
		elsif($tzoffset=~/^(-?)([0-9]+):([0-9]+)$/s){ $tzoffset=(($1*$2*60)+($1*$3))*60; }
		else{ $tzoffset+=0; }
	}else{
		if_require('Time::Timezone');
		$tzoffset = Time::Timezone::tz_local_offset();
	}
	$esecs += $tzoffset;
	my @times = gmtime($esecs);
	
	my $str;
	my @chars = split(//,$format);
	foreach (@chars){
		if($_ eq 'D'){ load_cache('days_short'); $str.=$cache{days_short}->[$times[6]]; }
		elsif($_ eq 'M'){ load_cache('months_short'); $str.=$cache{months_short}->[$times[4]]; }
		elsif($_ eq 'd'){ $str.=($times[3]<10?'0':'').$times[3]; }
		elsif($_ eq 'Y'){ $str.=$times[5]+1900; }
		elsif($_ eq 'g'){ $str.=($times[2]==0?12:$times[2]-($times[2]>12?12:0)); }
		elsif($_ eq 'i'){ $str.=($times[1]<10?'0':'').$times[1]; }
		elsif($_ eq 'a'){ $str.=($times[2]>=12?'pm':'am'); }
		else{ $str.=$_; }
	}
	
	return $str;
}

sub getdate {
	my($esecs) = (@_?shift():time);
	my @times = localtime($esecs);
	load_cache('months_long');
	load_cache('days_long');
	@times = (
		$times[0],$times[1],$times[2],
		$times[3],$times[6],$times[4]+1,$times[5]+1900,$times[6],
		$cache{days_long}->[$times[6]],$cache{months_long}->[$times[4]],
		$esecs
	);
	if(wantarray){ return @times; }
	else{ return [@times]; }
}

sub gettimeofday {
	if_require('Time::HiRes');
	if_require('Time::Timezone');

	my($sec,$usec) = Time::HiRes::gettimeofday();
	my $minuteswest = int((-1 * Time::Timezone::tz_local_offset())/60);
	my $dsttime = ((localtime(time))[8]?1:0);
	return {sec=>$sec,usec=>$usec,minuteswest=>$minuteswest,dsttime=>$dsttime};
}

sub mktime {
	if_require('Time::ParseDate');

	my @times = localtime(time);
	my %args = (hour=>$times[2],minute=>$times[1],second=>$times[0],day=>$times[3],month=>$times[4]+1,year=>$times[5]+1900,dst=>-1);
	my $arg_keys = load_cache('mktime_args');
	
	for(my $i=@$arg_keys-1; $i>=0; $i--){
		last if(!@_);
		next if($arg_keys->[$i] eq 'dst' and $_[@_-1]>1);
		$args{$arg_keys->[$i]} = pop();
	}
	
	my $esecs = Time::ParseDate::parsedate(
		$args{month}.'/'.$args{day}.'/'.$args{year}.' '.
		$args{hour}.':'.$args{minute}.':'.$args{second}
	);
	if($args{dst}==1){
		$esecs+=60;
	}elsif($args{dst}==-1){
		$esecs+=((localtime(time))[8]?60:0);
	}
	
	return $esecs;
}

#---------------------------------------------------#
1;
__END__

=head1 NAME

PHP::DateTime - Clone of PHP's date and time functions.

=head1 SYNOPSIS

  use PHP::DateTime;
  
  if(checkdate(12,1,1997)){ ... } # Yep
  if(checkdate(13,1,1997)){ ... } # Nope
  
  my $now = time;
  print date('D M d, Y g:i a',$now);
  
  my $d = getdate($now);
  print $d->[8]; # Print the name of the day. (ex: Monday)
  
  my $g = gettimeofday();
  print $d->{usec}; # Print the number of miliseconds since epoch.
  
  my $then = mktime(11,23,45,28,11,2004,-1);
  print date('D M d, Y g:i a',$then); 
  # prints: Sun Nov 28, 2004 11:23 am

=head1 DESCRIPTION

Coming soon.

=head1 METHODS

All these are exported in to your namespace.

=head2 CHECKDATE

http://www.php.net/manual/en/function.checkdate.php

=head2 DATE

http://www.php.net/manual/en/function.date.php

=head2 GETDATE

http://www.php.net/manual/en/function.getdate.php

=head2 GETTIMEOFDAY

http://www.php.net/manual/en/function.gettimeofday.php

=head2 MKTIME

http://www.php.net/manual/en/function.mktime.php

=head1 TODO

Tons.

=head1 BUGS

Barely tested.

=head1 AUTHOR

Copyright (C) 2003 Aran Clary Deltac (CPAN: BLUEFEET)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

Address bug reports and comments to: E<lt>aran@bluefeet.netE<gt>. When sending bug reports, 
please provide the version of Geo::Distance, the version of Perl, and the name and version of the 
operating system you are using.  Patches are welcome if you are brave!

=head1 SEE ALSO

http://www.php.net/manual/en/ref.datetime.php
