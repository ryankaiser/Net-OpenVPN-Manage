use ExtUtils::MakeMaker;
use CPAN;

WriteMakefile(
    NAME         => 'Net::OpenVPN::Manage',
    VERSION_FROM => 'lib/Net/OpenVPN/Manage.pm',
    PREREQ_PM    => { Test::More => 0,},
    BUILD_REQUIRES => { Net::Telnet => 0, },
    EXE_FILES    => ['eg/vpnclients.pl'],
    PL_FILES => {},
    ABSTRACT_FROM => 'lib/Net/OpenVPN/Manage.pm',
    AUTHOR        => 'Aaron Meyer <meyeaard@cpan.org>',
);

open(Makefile, ">>Makefile") or die "$!";
print Makefile<<EOF
install_deps:
\tperl -mCPAN -e 'CPAN::Shell->install("Net::Telnet");'
EOF
;
close(Makefile);
