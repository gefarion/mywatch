#!/usr/bin/perl -w
use strict;
use DBI;
use Getopt::Long qw(GetOptions);
use utf8;
binmode STDOUT, 'encoding(utf8)';

my %args;
GetOptions(\%args, '--help', 'h=s', 'u=s', 'p=s', 's=i');
if ($args{help} || @ARGV != 1) {
	die "Usage: $0 [-h HOST] [-u USERNAME] [-p PASSWORD] [-s SECONDS_UPDATE_TIME] QUERY";
}
$args{h} //= 'localhost';
$args{u} //= 'root';
$args{s} //= 1;
my $query = $ARGV[0];

my $url = sprintf("dbi:mysql:database=%s;host=%s", 'test', $args{h});
my $dbh = DBI->connect($url, $args{u}, $args{p})
	or die "Error al conectar a $url: " . $DBI::errstr;

my $sth = $dbh->prepare($query)
	or die "Error on statement preparation";

my @fheaders;

while (1) {
	system("clear");

	$sth->execute()
		or die "Error on execute statement";

	my %attr;
	my @headers = @{$sth->{NAME}};
	my $result = $sth->fetchall_arrayref();

	my @lengths = map { length($_) } @headers;
	foreach my $row (@$result) {
		for (0..$#lengths) {
			if ($lengths[$_] < length($row->[$_] || "NULL")) {
				$lengths[$_] = length($row->[$_]);
			}
		}
	}

	print("Watching (Every $args{s} sec.): $query\n\n");

	unless (@fheaders) {
		for (0..$#headers) {
			push @fheaders, sprintf("%$lengths[$_]s", $headers[$_]);
		}
	}
	print(join(" | ", @fheaders) . "\n");

	foreach my $row (@$result) {
		my @frows;
		for (0..$#headers) {
			push @frows, sprintf("%$lengths[$_]s", $row->[$_] || 'NULL');
		}
		print(join(" | ", @frows) . "\n");
	}

	sleep $args{s};
}

exit 0;
