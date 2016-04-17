#!/usr/bin/perl
#
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

my @args = ();

for my $i (0..1) {
    next unless defined(my $arg = $ARGV[$i]);
    if ( $arg eq '-' ) {
        next unless defined($arg = <STDIN>);
        chomp( $arg );
    }
    $args[$i] = $arg ? $arg : undef ;
}

my $vpn = Net::OpenVPN::Manage->new({
    port => $args[0] || 5000,
    host => $args[1] || 'localhost'
});

unless ( $vpn->connect() ) {
    print "$vpn->{error_msg}\n";
    exit 1;
}

my $sref = $vpn->status_ref();
my $nclients = $vpn->load_stats_ref()->{nclients};

if ( $nclients > 0 ) {
    for ( my $i = 0; $i < $nclients; $i++ ) {
        printf("%2s %-16s: %-29s\n","",
            ${$sref->{HEADER}{CLIENT_LIST}}[0],
            ${$sref->{CLIENT_LIST}}[$i][0]);
        printf("%2s %-16s: %-29s\n","",
            ${$sref->{HEADER}{CLIENT_LIST}}[2],
            ${$sref->{CLIENT_LIST}}[$i][2]);
        printf("%2s %-16s: %-29s\n","",
            ${$sref->{HEADER}{CLIENT_LIST}}[1],
            ${$sref->{CLIENT_LIST}}[$i][1]);
        printf("%2s %-16s: %-29s\n","",
            ${$sref->{HEADER}{CLIENT_LIST}}[5],
            ${$sref->{CLIENT_LIST}}[$i][5]);
        printf("%2s %-16s: %-29s\n","",
            ${$sref->{HEADER}{ROUTING_TABLE}}[3],
            ${$sref->{ROUTING_TABLE}}[$i][3]);
        if ( $i != ( $nclients - 1 ) ) {
            print "\n";
        }
    }
}
else {
    print "No clients are currently connected.\n";
    exit 2;
}
