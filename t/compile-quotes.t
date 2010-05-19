use Test::More;
use App::QuoteCC;
use File::Temp qw<tempdir tempfile>;

plan skip_all => "Need curl / gcc to test" unless qx[ which curl && which gcc ];
plan 'no_plan';

my @test = (
    {
        url => 'http://v.nix.is/~failo/quotes.yml',
        fmt => 'YAML',
    },
    {
        url => 'http://www.trout.me.uk/quotes.txt',
        fmt => 'Fortune',
    }
);

for my $test (@test) {
    my $url = $test->{url};
    my $fmt = $test->{fmt};

    # Dir to store our stuff
    my $dir = tempdir( "app-quotecc-XXXX", CLEANUP => 0, TMPDIR => 1 );
    ok(-d $dir, "tempdir $dir exists");
    my ($fh1, $quotes) = tempfile( DIR => $dir, SUFFIX => '.quotes', EXLOCK => 0 );
    my ($fh2, $output) = tempfile( DIR => $dir, SUFFIX => '.c', EXLOCK => 0 );
    ok(-f $_, "tempfile $_ exists") for $quotes, $output;

    my $cmd = qq[curl -s '$url' --output '$quotes'];
    #diag "executing $cmd";
    system $cmd;
    App::QuoteCC->new(
        input => $quotes,
        input_format => $fmt,
        output => $output,
        output_format => 'C',
    )->run;
    ok(-s $quotes, "$quotes is non-zero size");
    ok(-s $output, "$output is non-zero size");

    $cmd = qq[gcc -Wall $output -o $output.exe];
    #diag "executing $cmd";
    system $cmd;

    for (1..10) {
        chomp(my $quote = qx[$output.exe]);
        ok($quote, "Got quote from $output.exe");

        chomp($quote = qx[$output.exe --all]);
        ok($quote, "Got quote from $output.exe --all");
    }
}
