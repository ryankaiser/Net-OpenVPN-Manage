use ExtUtils::MakeMaker;


WriteMakefile(
    NAME         => 'Net::OpenVPN::Manage',
    VERSION_FROM => 'lib/Net/OpenVPN/Manage.pm',
    PREREQ_PM    => { Test::More => 0, Net::Telnet => 0, },
    EXE_FILES    => ['eg/vpnclients.pl'],
    PL_FILES => {},
    ABSTRACT_FROM => 'lib/Net/OpenVPN/Manage.pm',
    AUTHOR        => 'Aaron Meyer <meyeaard@cpan.org>',
);
