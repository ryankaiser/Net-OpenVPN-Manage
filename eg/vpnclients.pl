#!/usr/bin/perl

#  vpnclients.pl
#
#  Copyright (C) 2015 Ryan Kaiser <ryandkaiser@gmail.com>
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

use strict;
use warnings;
use Net::OpenVPN::Manage;
use Pod::Usage;
use Getopt::Long;

Getopt::Long::Configure ("bundling");

my $total_clients = 0;
my $conf_dir = "/etc/openvpn";
my ($help, $verbose) = (0, 0);
my ($host, $port);
my @vpns;

GetOptions(
    "host|h=s"    => \$host,
    "port|p=i"    => \$port,
    "conf-dir=s"  => \$conf_dir,
    "verbose|v"   => sub { $verbose++ },
    "help|?"      => sub { $help++ },
) or pod2usage(
    -exitval => 1,
    -output  => \*STDERR,
);

pod2usage(
    -exitval   => 0,
    -noperldoc => 1,
    -verbose   => 2,
) if ($help && $verbose);

pod2usage(0) if $help;

unless (defined($host) || defined($port)) {
    opendir(my $dh, $conf_dir) ||
        die "can't open $conf_dir: $!";
    my @confs = grep {/\.conf$/ && -f "$conf_dir/$_"}
        readdir($dh);
    closedir($dh);

    for my $conf ( @confs ) {
        my %parts;
        open(my $input, "<", "${conf_dir}/${conf}") ||
            die "Can't open ${conf_dir}/${conf}: $!\n";

        local $_;
        while(<$input>) {
            if (/^management (.*) (\d+)/) {
                %parts = (host => $1, port => $2);
                last;
            }
        }

        close($input);
        next unless defined($parts{port});

        push (@vpns,
            Net::OpenVPN::Manage->new({
                host => $parts{host},
                port => $parts{port},
            })
        );
    }
}
else {
    push(@vpns,
        Net::OpenVPN::Manage->new({
            host => $host || '127.0.0.1',
            port => $port || 5000,
        })
    );
}

for my $vpn (@vpns) {
    unless ($vpn->connect()) {
        print "$vpn->{error_msg}\n";
        exit 1;
    }
    $vpn->{nclients} = $vpn->load_stats_ref()->{nclients};
    $total_clients += $vpn->{nclients};
}

if ( $total_clients > 0 ) {
    for (my $i = 0; $i < scalar(@vpns); $i++) {
        my $vpn = \$vpns[$i];
        my $sref = \$$vpn->status_ref();
        my $headers = \$$sref->{HEADER};
        my $clients = \$$sref->{CLIENT_LIST};
        my $routers = \$$sref->{ROUTING_TABLE};

        if ( $$vpn->{nclients} > 0 ) {
            for (my $j = 0; $j < $$vpn->{nclients}; $j++) {
                if ($verbose) {
                    printf("%2s %-16s: %-29s\n","", # Common Name
                        $$headers->{CLIENT_LIST}[0],
                        $$clients->[$j][0]);
                    printf("%2s %-16s: %-29s\n","", # Virtual Address
                        $$headers->{CLIENT_LIST}[2],
                        $$clients->[$j][2]);
                    printf("%2s %-16s: %-29s\n","", # Real Address
                        $$headers->{CLIENT_LIST}[1],
                        $$clients->[$j][1]);
                    printf("%2s %-16s: %-29s\n","", # Connected Since
                        $$headers->{CLIENT_LIST}[5],
                        $$clients->[$j][5]);
                    printf("%2s %-16s: %-29s\n","", # Last Ref
                        $$headers->{ROUTING_TABLE}[3],
                        $$routers->[$j][3]);
                    if ($verbose > 1) {
                        printf("%2s %-16s: %-29s\n","", # Bytes Received
                            $$headers->{CLIENT_LIST}[3],
                            $$clients->[$j][3]);
                        printf("%2s %-16s: %-29s\n","", # Bytes Sent
                            $$headers->{CLIENT_LIST}[4],
                            $$clients->[$j][4]);
                    }
                }
                else {
                    printf("%-s %-s\n",
                        $$routers->[$j][0],  # Virtual Address
                        $$routers->[$j][1]); # Common Name
                    next;
                }
                print "\n" if
                    ( $j != ( $$vpn->{nclients} - 1 ) );
            }
        }
        else {
            printf("No clients are currently connected (%s:%d)\n",
                $$vpn->{host},
                $$vpn->{port}) if ($verbose);
        }
        print "\n" if
            ($i != ( (scalar @vpns) - 1) && $verbose);
    }
    exit 0;
}
else {
    print "No clients are currently connected.\n";
}

__END__

=head1 SYNOPSIS

vpnclients [OPTION]...

=head1 OPTIONS

=over 8

=item S<--conf-dir=PATH    OpenVPN config directory (default=/etc/openvpn)>

=item S<-h, --host=NAME    Host to which to connect (default=127.0.0.1)>

=item S<-p, --port=PORT    Port to which to connect (default=parse .conf[s])>

=item S<-v, --verbose      Increase verbosity>

=item S<-?, --help         Show this message and exit>

=back

B<If either --host or --port are given, only one host:port
is assumed. If only --host is given, files in --conf-dir
are not not parsed, and --port simply defaults to 5000.>

=head1 DESCRIPTION

B<This program> will display information about clients
connected to a running OpenVPN server that was started
with the '--management HOST PORT' option.

=cut
