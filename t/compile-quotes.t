use 5.010;
use Test::More;
use App::QuoteCC;
use Encode;
use File::Temp qw<tempdir tempfile>;

plan skip_all => "Need curl / gcc to test"
    unless
        qx[ curl --version ] =~ /^curl \d+\..*\nProtocols:/s and
        qx[ gcc --version ]  =~ /Free Software Foundation/;
plan tests => 380;

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

sub test_quotes_encoding {
    my ($output, $quote, $url) = @_;

    # The program just spews raw octets, but we know
    # they're UTF-8 octets.
    Encode::_utf8_on($quote);

    ok($quote, "Got quote from $output --all");
    cmp_ok(length($quote), '>', 1000, "All quotes were long enough");
    if ($url =~ /failo/) {
        like $quote, qr/mosque on Phobos/, "sanity check";
        like $quote, qr/Blökkumaður/, "sanity check";
        like $quote, qr/botti líka/, "sanity check";
    }
}

for my $compiler (qw/Perl C Lua/) {
    for my $test (@test) {
        my $url = $test->{url};
        my $fmt = $test->{fmt};

        # Dir to store our stuff
        my $dir = tempdir( "app-quotecc-XXXX", CLEANUP => 1, TMPDIR => 1 );
        ok(-d $dir, "tempdir $dir exists");
        my ($fh1, $quotes) = tempfile( DIR => $dir, SUFFIX => '.quotes', EXLOCK => 0 );
        my ($fh2, $output) = tempfile( DIR => $dir, SUFFIX => '.' . lc($compiler), EXLOCK => 0 );
        ok(-f $_, "tempfile $_ exists") for $quotes, $output;

        my $cmd = qq[curl --user-agent 'App::QuoteCC/$App::QuoteCC::VERSION' -s '$url' --output '$quotes'];
        system $cmd;
        App::QuoteCC->new(
            input => $quotes,
            input_format => $fmt,
            output => $output,
            output_format => $compiler,
        )->run;
        ok(-s $quotes, "$quotes is non-zero size");
        ok(-s $output, "$output is non-zero size");

        given ($compiler) {
            when ('Lua') {
                for (1..10) {
                  SKIP: {
                    skip "Don't have a Lua on this system", 6
                        unless qx[ lua -e 'require "posix"; print(string.format("The time is %s", os.time()));' ] =~ /^The time is \d+$/;
                    skip "Lua escaping with multilines is buggy", 6 unless $url =~ /failo/;
                    system "chmod +x $output";

                    chomp(my $quote = qx[lua $output]);
                    ok($quote, "Got quote from $output");

                    chomp($quote = qx[lua $output --all]);
                    ok($quote, "Got quote from $output --all");
                    test_quotes_encoding($output, $quote, $url);
                  }
                }
            }
            when ('C') {
                $cmd = qq[gcc -Wall $output -o $output.exe];
                system $cmd;

                for (1..10) {
                    chomp(my $quote = qx[$output.exe]);
                    ok($quote, "Got quote from $output.exe");

                    chomp($quote = qx[$output.exe --all]);
                    ok($quote, "Got quote from $output.exe --all");
                    test_quotes_encoding($output, $quote, $url);
                }
            }
            when ('Perl') {
                for (1..10) {
                    chomp(my $quote = qx[$^X $output]);
                    ok($quote, "Got quote from $^X $output");
                    cmp_ok(length($quote), '>', 5, "quote was long enough");

                    chomp($quote = qx[$^X $output --all]);
                    test_quotes_encoding($output, $quote, $url);
                }
            }
        }
    }
}
