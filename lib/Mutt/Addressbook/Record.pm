package Mutt::Addressbook::Record;
use strict;

BEGIN {
  use warnings;

  use vars qw ($VERSION);
  $VERSION = (split(/\s/, q($Id: Record.pm,v 1.8 2004/02/04 10:52:14 andre Exp $)))[2];

  use Class::MethodMaker
    get_set => [qw(
      category
      comment
      full_name
      e_mail_address
    )],
    new_with_init => 'new',
    new_hash_init => 'hash_init',
  ;

  use constant DEFAULTS => (
    comment => '',
  );
}

sub matches {
  my $self = shift;
  my %params = @_;


  my $category = $params{category};
  my $lookup   = $params{lookup};

  my $string;

  my $ret;

  die "Uh! Mutt::Record::matches illegally called!" unless ($category || $lookup);
  
  $string = sprintf("%s %s %s",$self->full_name(),$self->e_mail_address(),$self->comment()||"");

  if ($category && $lookup) {
    $ret = $string =~ m/$lookup/i && $self->category() =~ m/$category/i;
  } else {
    $ret = $string =~ m/$lookup/i?1:0;
  }

  return $ret;
}
  

sub init {
  my $self = shift;
  my %values = (DEFAULTS,@_);

  $self->hash_init(%values);
  return $self;
}

1;
__END__

=head1 NAME

Mutt::Addressbook::Record - Record Class for Mutt::Addressbook

=head1 SYNOPSIS

  use Mutt::Addressbook;

  my $ab = new Mutt::Addressbook;

=head1 DESCRIPTION

See Mutt::Addressbook

=head1 SEE ALSO

perl (1)

=head1 AUTHOR

Andre Bonhote, E<lt>andre@bonhote.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by André Bonhôte

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
