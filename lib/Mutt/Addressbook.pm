package Mutt::Addressbook;
use strict;
use warnings;
use XML::Simple;
use File::Copy;
use Carp;
use Data::Dumper;

BEGIN {

  use Mutt::Addressbook::Record;

  use vars qw ($VERSION);
  $VERSION = (split(/\s/, q($Id: Addressbook.pm,v 1.7 2004/01/30 11:24:01 andre Exp andre $)))[2];

  use Class::MethodMaker
    get_set => [qw(
      datafile
      confdir
      content
      verbose
    )],
    new_with_init => 'new',
    new_hash_init => 'hash_init',
  ;

  use constant DEFAULTS => (
    datafile=>"$ENV{HOME}/.mabip/addresses.xml",
    confdir=>"$ENV{HOME}/.mabip",
    verbose=>0,
  );
}


sub import_data {
  my $self = shift;
  my %params = @_;

  my $file = $params{file};
  my $category = $params{category};

  my $IN;
  my @from_lines;

  $self->read(); # fills $self->content();
  my $addresses = $self->content();

  my $e_mail_address;
  my $full_name;

  if ($file eq "STDIN") {
    $IN=*STDIN;
  } else {
    open($IN,"<$file") || croak "Uh! Unable to open $file for reading!$!";
  }

  @from_lines = grep (/^From: /,<$IN>);
  close($IN);

  for (@from_lines) {
    /([\w.-]+\@[\w.-]+)/;
    $e_mail_address = $1;
    s/(^From: |$e_mail_address|[<>"])//g;
    chomp;
    s/^ //;
    s/ $//;
    $full_name=/^$/?$e_mail_address:$_;

    my $rec = new Mutt::Addressbook::Record;
    $rec->full_name($full_name);
    $rec->e_mail_address($e_mail_address);
    $rec->category($category);
    push @{$addresses}, $rec;

  }

  $self->content($addresses);

  $self->store();
}

sub read {
  my $self = shift;
  my @addresses;

  if (-f $self->datafile()) {
    my $ref = XMLin($self->datafile,KeepRoot=>1);
    if (ref($ref->{mabip}->{address}) eq "ARRAY") {
      foreach my $address (@{$ref->{mabip}->{address}}) {
        my $rec = new Mutt::Addressbook::Record;
        $rec->full_name($address->{fullname});
        $rec->e_mail_address($address->{email});
        $rec->category($address->{category});
        push @addresses,$rec;
      }
    } else {
      my $rec = new Mutt::Addressbook::Record;
      $rec->full_name($ref->{fullname});
      $rec->e_mail_address($ref->{email});
      $rec->category($ref->{category});
      push @addresses,$rec;
    }
    $self->content(\@addresses);
  } else {
    ## No datafile exists. Creating a new one.
    my $rec = new Mutt::Addressbook::Record;
    $rec->full_name("Andre Bonhote");
    $rec->e_mail_address('andre@bonhote.org');
    $rec->category("Coder");
    push @addresses,$rec;
    $self->content(\@addresses);
    $self->store;
  }
  return;
}  

sub store {
  my $self = shift;
  my $addresses = $self->content() || croak "Uh! There's no content! I won't dare to overwrite the data!";
  my $ref;

  if (scalar(@{$addresses}) > 0) {
    $self->debug("No: ".scalar(@{$addresses}));

    for (@{$addresses}) {
      $self->debug(sprintf("%s <%s> (%s)",$_->full_name(),$_->e_mail_address(),$_->category()));
      $ref->{mabip}->{address}->{$_->full_name()} = { 
        email => [ $_->e_mail_address() ],
        category => [ $_->category() ],
      };
    }

    my $xml = XMLout($ref,
      KeepRoot=>1,
      KeyAttr=>{address=>"fullname"},
    );


    my $filename = $self->datafile();
    copy($filename,$filename."~");
    open(OUT,">$filename") || croak "Uh! Unable to open $filename for writing! $!";
    print OUT $xml;
    close(OUT);
      
  } else {
    croak "Uh! No Address inside \$self->content!";
  }
}


sub init {
  my $self = shift;
  my %values = (DEFAULTS,@_);
  $self->hash_init(%values);

  unless (-d $self->confdir()) {
    mkdir($self->confdir()) || croak "Uh! Unable to create ",$self->confdir(),"! $!";
  }
  return $self;
}

sub debug {
  my ($self,$msg) = @_;
  print STDERR "[",ref($self),"]: $msg\n" if ($self->verbose()>0);
}

1;
__END__

=head1 NAME

Mutt::Addressbook - OO Module for mabip

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
