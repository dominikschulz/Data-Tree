# ABSTRACT: a hash-based tree-like data structure

use 5.012_000;
use feature ':5.12';
use mop;

class Data::Tree {
  has $data   is ro = {};
  has $debug  is rw;

  method debug {
    if(!defined $debug) {
      if($ENV{'DATA_TREE_DEBUG'}) {
          $debug = 1;
      }
  
      $debug = 0;
    }
  }

  method set ( $key, $value, $force) {
      $force ||= 0;
  
      my ( $ref, $last_key ) = $self->_find_leaf($key);
      if ( ref( $ref->{$last_key} ) eq 'HASH' && !$force ) {
          return;
      }
      $ref->{$last_key} = $value;
      return $value;
  }

  method increment ($key, $increment) {
      $increment //= 1;
  
      my $value = $self->get($key) || 0;
  
      # bail out if value != numeric
      if($value !~ m/^\d+$/) {
          return $value;
      }
  
      $value += $increment;
      $self->set( $key, $value );
  
      return $value;
  }
  
  method decrement ($key, $decrement) {
      $decrement ||= 1;
  
      my $value = $self->get($key) || 0;
  
      # bail out if value != numeric
      if($value !~ m/^\d+$/) {
          return $value;
      }
  
      $value -= $decrement;
      $self->set( $key, $value );
  
      return $value;
  }
  
  method _find_leaf ($key) {
      my @path = ();
      if ( ref($key) eq 'ARRAY' ) {
          @path = map { lc($_); } @{$key};
      }
      else {
          $key = lc($key);
          @path = split /::/, $key;
      }
  
      my $ref       = $self->data();
      my $last_step = undef;
      while ( my $step = shift @path ) {
          $last_step = $step;
          if ( @path < 1 ) {
              last;
          }
          elsif ( ref( $ref->{$step} ) eq 'HASH' ) {
              $ref = $ref->{$step};
          }
          elsif ( @path >= 1 ) {
              $ref->{$step} = {};
              $ref = $ref->{$step};
          }
          else {
              warn "Unhandled condition in _find_leaf w/ key $key in step $step in Data::Tree::_find_leaf().\n" if $self->debug();
          }
      }
  
      # ref contains the hash ref one step above the wanted entry,
      # last_step is the key in this hash to access the wanted
      # entry.
      # this is necessary or
      return ( $ref, $last_step );
  }
  
  method get ($key, $opts) {
      $opts ||= {};
  
      my ( $ref, $last_key ) = $self->_find_leaf($key);
  
      if ( exists( $ref->{$last_key} ) ) {
          return $ref->{$last_key};
      }
      else {
          if ( exists( $opts->{'Default'} ) ) {
              return $opts->{'Default'};
          }
          else {
              return;
          }
      }
  }
  
  # return a single value out of an array
  method get_scalar ($key) {
      my $value = $self->get($key);
  
      if ( $value && ref($value) && ref($value) eq 'ARRAY' ) {
          return $value->[0];
      }
      elsif ( $value && ref($value) && ref($value) eq 'HASH' ) {
          return ( keys %{$value} )[0];
      }
      else {
          return $value;
      }
  }
  
  method get_array ($key, $opts) {
      $opts ||= {};
  
      my $ref = $self->get($key);
  
      if ( $ref && ref($ref) eq 'HASH' ) {
          warn "Returning only the keys of a hashref in Data::Tree::get_array($key).\n" if $self->debug();
          return ( keys %{$ref} );
      }
      elsif ( $ref && ref($ref) eq 'ARRAY' ) {
          return @{$ref};
      }
      elsif ($ref) {
          return ($ref);
      }
      elsif ( defined( $opts->{'Default'} ) && ref($opts->{'Default'}) eq 'ARRAY' ) {
          return @{$opts->{'Default'}};
      }
      else {
          ## no critic (ProhibitMagicNumbers)
          my $caller = ( caller(1) )[3] || 'n/a';
          ## use critic
          warn "Returning empty array in Data::Tree::get_array($key) to $caller.\n" if $self->debug();
          return ();
      }
  }
  
  method delete ($key) {
      my ( $ref, $last_key ) = $self->_find_leaf($key);
  
      if ( ref($ref) eq 'HASH' ) {
          delete $ref->{$last_key};
          return 1;
      }
      else {
  
          # don't know how to handle non hash refs
          return;
      }
  }
}

1;

__END__

=head1 NAME

Data::Tree - A simple hash-based tree.

=head1 SYNOPSIS

    use Data::Tree;
    my $DT = Data::Tree::->new();

    $DT->set('First::Key',[qw(a b c]);
    $DT->get('First::Key'); # should return [a b c]
    $DT->get_scalar('First::Key'); # should return a
    $DT->get_array('First::Key'); # should return (a, b, c)

=head1 DESCRIPTION

A simple hash-based nested tree.

=cut

