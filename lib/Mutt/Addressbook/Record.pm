package Mutt::Addressbook::Record;
use strict;

BEGIN {
  use warnings;

  use vars qw ($VERSION);
  $VERSION = (split(/\s/, q($Id: Record.pm,v 1.5 2004/01/30 14:22:48 andre Exp andre $)))[2];

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
  );
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

Mutt::Addressbook::Record - Keeps the records

=head1 SYNOPSIS

  use Mutt::Addressbook;

  my $ab = new Mutt::Addressbook;

=head1 DESCRIPTION

bla bla bla

=head1 SEE ALSO

perl (1)

=head1 AUTHOR

Andre Bonhote, E<lt>andre@bonhote.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by André Bonhôte

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
