#
# Tribunal Case Analyser w/ Fork
# PersianMG
#

#!/usr/bin/perl

use LWP::Simple;
use Parallel::ForkManager;

use warnings;

print "Tribunal Checker by PersianMG\n";
print "*********************\n\n";

my $host = "http://na.leagueoflegends.com/";

my $startNum = 6000000; 
my $endNum = 6010000;
my $sep = ' | ';

my $totalpunished = 0;
my $totalpardoned = 0;
my $totalinvalid = 0;

# Set up Fork Manager
my $pm = Parallel::ForkManager->new(15);

# Count results
$pm->run_on_finish (
sub {
	if (defined($_[-1])) {
		my $result = ${$_[-1]};
		
		if ($result eq "Punish") {
			$totalpunished++;
		}
		else {
			$totalpardoned++;
		}
	}
	else {
		$totalinvalid++;
	}
}
);

for (my $i = $startNum; $i <= $endNum; $i++) {
	$pm->start and next; # do the fork

	my $source = get($host . "tribunal/en/case/" . $i) || ($pm->finish and next);
	
	#Output

	#decision
	if ($source !~ /<p>Decision<\/p>
        <p class="verdict-stat">(Punish|Pardon)<\/p>
    <\/div>/) {
		$pm->finish;
		next;
	};

	print "Case #" . $i . $sep;
	print $1 . $sep;

	my $result = $1;

	#agreement
	$source =~  /<p>Agreement<\/p>
        <p class="verdict-stat agreement">(.*)<\/p>
    <\/div>/;

	print $1 . $sep;

	#punishment
	$source =~  /<div class="verdict-block">
        <p>Punishment<\/p>
        <p class="verdict-stat">(.*)<\/p>
    <\/div>/;

	print $1 . $sep;

	#link to page
	print $host . "tribunal/en/case/" . $i . "/";

	print "\n";
	
	$pm->finish(0, \$result);
}

$pm->wait_all_children;

print "\n\n*********************\n\n";
print "Total Cases Reviewed: " . (($endNum - $startNum + 1) - $totalinvalid) . "\n";
print "Total Punished: " . $totalpunished . "\n";
print "Total Pardoned: " . $totalpardoned . "\n";
printf("Percentage Punished: %.2f %%\n", ($totalpunished/($endNum - $startNum + 1)) * 100);


exit;