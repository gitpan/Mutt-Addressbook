use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Mutt::Addressbook',
    VERSION_FROM      => 'mabip', # finds $VERSION
    PREREQ_PM         => {
                            'Class::MethodMaker' => 1.10,
                            'XML::Simple' => '2.00',
                         },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Mutt/Addressbook.pm', # retrieve abstract from module
       AUTHOR         => 'Andre Bonhote <andre@bonhote.org>') : ()),
     EXE_FILES        => [ 'mabip' ],
);
