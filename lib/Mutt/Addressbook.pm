package Mutt::Addressbook;
use strict;
use warnings;
no warnings 'io';
use XML::Simple;
use File::Copy;
use Carp;
use Data::Dumper;

BEGIN {

  use Mutt::Addressbook::Record;

  use vars qw ($VERSION);
  $VERSION = (split(/\s/, q($Id: Addressbook.pm,v 1.12 2004/02/04 10:52:32 andre Exp andre $)))[2];

  use Class::MethodMaker
    get_set => [qw(
      datafile
      confdir
      content
      dump_content
      verbose
      err
      errstr
    )],
    new_with_init => 'new',
    new_hash_init => 'hash_init',
  ;

  use constant DEFAULTS => (
    datafile=>"$ENV{HOME}/.mph/addresses.xml",
    confdir=>"$ENV{HOME}/.mph",
    verbose=>0,
  );
}


sub import_data {
  my $self = shift;
  my %params = @_;

  # Give back what they deserve
  my $errors = {
    IMP01 => 'Unknown import format',
  };
    

  my $file = $params{file};
  my $category = $params{category};
  my $format = $params{format} || 'mbox';

  INNER: {

    unless ($format =~ /^(CSV|mbox)$/i) {
      $self->err('IMP01');
      $self->errstr($errors->{$self->err()});
      last INNER;
    }
    
    my $IN;
    my @from_lines;
  
    $self->read(); # fills $self->content();

    my $addresses = $self->content();
  
    my $e_mail_address;
    my $full_name;
  
    unless ($file) {
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
      s/^ //; s/ $//;
      s/[^a-zA-Z0-9 ._()+&-]//g;
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

  return $self->err()?0:1;
}

sub read {
  my $self = shift;
  my %params = @_;

  my $category = $params{category} || '';
  my $lookup = $params{lookup} || ".";

  my $matchparams = '';

  $self->debug("Read: Lookup: $lookup - Category: $category");

  if ($category ne '') {
    $matchparams .= 'category=>$category,';
  }

  $matchparams .= 'lookup=>$lookup';
  $matchparams = '$rec->matches(' . $matchparams . ')';

  my @addresses;

  INNER: {
    unless (-f $self->datafile()) {
      my @retaddr;
      ## No datafile exists. Creating a new one.
      my $rec = new Mutt::Addressbook::Record;
      $rec->full_name("Andre Bonhote");
      $rec->e_mail_address('andre@bonhote.org');
      $rec->comment('Coder of mph');
      $rec->category("Coder");

      push @addresses,$rec;

      push @retaddr,$rec if (eval($matchparams));
      $self->content(\@addresses);
      $self->store;
      @addresses = @retaddr;
      last INNER;
    }
      
    my $ref = XMLin($self->datafile,KeepRoot=>1);

    # There's more than one entry in the file ...
    if (ref($ref->{mph}->{address}) eq "ARRAY") {
      foreach my $address (@{$ref->{mph}->{address}}) {
        my $rec = new Mutt::Addressbook::Record;
        $rec->full_name($address->{full_name});
        $rec->e_mail_address($address->{email});
        $rec->category($address->{category});
        $rec->comment($address->{comment}) if (ref($address->{comment}) ne 'HASH');
        push @addresses,$rec if (eval($matchparams));
      }
    } else {
      my $rec = new Mutt::Addressbook::Record;
      my $short = $ref->{mph}->{address};
      $rec->full_name($short->{full_name});
      $rec->e_mail_address($short->{email});
      $rec->category($short->{category});
      push @addresses,$rec if (eval($matchparams));
    }
  }

  $self->content(\@addresses);
  return;
}  

sub dump {
  my $self = shift;
  my %params = @_;

  my $category = $params{category} || '';
  my $format = $params{format} || 'mutt';
  my $lookup = $params{lookup} || '';

  $self->debug("Dump: Lookup: $lookup - Category: $category");

  my $errors = {
    DMP01 => 'Unknown dump format',
  };

  INNER: {
  
    unless ($format =~ /^(CSV|mutt|procmail)$/i) {
      $self->err('DMP01');
      $self->errstr($errors->{$self->err()});
      last INNER;
    }
    
    $self->read(category=>$params{category},lookup=>$params{lookup});
    my $addresses = $self->content();

    my @ret;

  
    ## Find out what is wanted
    ## This is $a=$b=$c?$d:$e - syntax
  
    my $cmd = 'sprintf(';
    $cmd .= $format =~ /^CSV$/i      ? '"%s;%s;%s;%s\n",
              $addr->full_name(),
              $addr->e_mail_address(),
              $addr->category(),
              $addr->comment()' :
            $format =~ /^mutt$/i     ? '"%s\t%s\n",$addr->e_mail_address(),$addr->full_name()' :
            $format =~ /^procmail$/i ? '"%s\n",$addr->e_mail_address()':undef;
  
    $cmd .= ')';
      
    foreach my $addr (@{$addresses}) {
      push @ret, eval($cmd) || die "Uh! Unable do do evil eval! $!";
    }

    @ret = sort(@ret);
    $self->dump_content(join("",@ret));
  
  }

  return $self->err()?0:1;
}


sub store {
  my $self = shift;
  my $addresses = $self->content() || croak "Uh! There's no content! I won't dare to overwrite the data!";
  my $ref;
  my $OUT;

  if (scalar(@{$addresses}) > 0) {
    $self->debug("No: ".scalar(@{$addresses}));

    for (@{$addresses}) {
      $self->debug(sprintf("%s <%s> (%s)",$_->full_name(),$_->e_mail_address(),$_->category()));
      $ref->{mph}->{address}->{$_->full_name()} = { 
        email => [ $_->e_mail_address() ],
        full_name => [ $_->full_name() ],
        comment => [ $_->comment() ],
        category => [ $_->category() ],
      };
    }

    my $xml = XMLout($ref,
      KeepRoot=>1,
      KeyAttr=>{address=>"full_name"},
    );


    my $filename = $self->datafile();
    copy($filename,$filename."~");
    open($OUT,">$filename") || croak "Uh! Unable to open $filename for writing! $!";
    print $OUT $xml;
    close($OUT);
      
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

Mutt::Addressbook - OO Module for mph

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
