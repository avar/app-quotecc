package App::QuoteCC;

use perl5i::latest;
use Moose;
use File::Slurp qw/ write_file /;
use Template;
use namespace::clean -except => 'meta';

with qw/ MooseX::Getopt::Dashes /;

has help => (
    traits        => [ qw/ Getopt / ],
    cmd_aliases   => 'h',
    cmd_flag      => 'help',
    isa           => 'Bool',
    is            => 'ro',
    default       => 0,
    documentation => 'This help message',
);

has input => (
    traits        => [ qw/ Getopt / ],
    cmd_aliases   => 'i',
    cmd_flag      => 'input',
    isa           => 'Str',
    is            => 'ro',
    documentation => 'The quotes file to compile from. - for STDIN',
);

has input_format => (
    traits        => [ qw/ Getopt / ],
    cmd_aliases   => 'I',
    cmd_flag      => 'input-type',
    isa           => 'Str',
    is            => 'ro',
    documentation => 'The format of the input quotes file. Any App::QuotesCC::Input::*',
);

has output => (
    traits        => [ qw/ Getopt / ],
    cmd_aliases   => 'o',
    cmd_flag      => 'output',
    isa           => 'Str',
    is            => 'ro',
    default       => '-',
    documentation => 'Where to output the compiled file, - for STDOUT',
);

has output_format => (
    traits        => [ qw/ Getopt / ],
    cmd_aliases   => 'F',
    cmd_flag      => 'output-type',
    isa           => 'Str',
    is            => 'ro',
    documentation => 'The format of the output file. Any App::QuotesCC::Output::*',
);

sub run {
    my ($self) = @_;

    # Get quotes
    my $quotes = do {
        my $quotes_class_short = $self->input_format;
        my $quotes_class = "App::QuoteCC::Input::" . $quotes_class_short;
        $quotes_class->require;
        $quotes_class->new(
            file => $self->input,
        )->quotes;
    };

    # Get output
    my $out = _process_template($quotes);

    # Spew output
    given ($self->output) {
        when ('-') {
            print $out;
        }
        default {
            write_file($_, $out);
        }
    }

    return;
}

sub _process_template {
    my ($quotes) = @_;
    my $out;

    Template->new->process(
        \*DATA,
        {
            quotes => $quotes,
            size => scalar(@$quotes),
            escape => sub {
                my $text = shift;
                $text =~ s/"/\\"/g;
                my $was = $text;
                $text =~ s/\\(\$)/\\\\$1/g;
                given ($text) {
                    when (/\n/) {
                        return join(qq[\\n"\n], map { qq["$_] } split /\n/, $text). q["];
                    }
                    default {
                        return qq["$text"];
                    }
                }
            },
        },
        \$out
    );

    return $out;
}

__PACKAGE__->meta->make_immutable;

=encoding utf8

=head1 NAME

App::QuoteCC - Take a quote file and emit a C program that spews a random quote

=head1 SYNOPSIS

Compile a quotes file to a stand-alone binary:

    curl http://v.nix.is/~failo/quotes.yml | quotecc --quotes=- --format=YAML | gcc -x c -o /usr/local/bin/failo-wisdom -
    curl http://www.trout.me.uk/quotes.txt | quotecc --quotes=- --format=Fortune | gcc -x c -o /usr/local/bin/perl-wisdom -

See how small it is!:

    du -sh /usr/local/bin/*-wisdom
    56K     /usr/local/bin/failo-wisdom
    80K     /usr/local/bin/perl-wisdom

Emit a random quote:

    time /usr/local/bin/failo-wisdom
    Support Batman - vote for the British National Party

    real    0m0.003s
    user    0m0.000s
    sys     0m0.004s

Emit all quotes:

    /usr/local/bin/failo-wisdom --all > /tmp/quotes.txt

Emit quotes to interactive shells on login, in F</etc/profile>:

    # spread failo's wisdom to interactive shells
    if [[ $- == *i* ]] ; then
        failo-wisdom
    fi

=head1 DESCRIPTION

I wrote this program because using L<fortune(1)> and Perl in
F</etc/profile> to emit a random quote on login was too slow. On my
system L<fortune(1)> can take ~100 ms from a cold start, although
subsequent invocations when it's in cache are ~10-20 ms.

Similarly using Perl is also slow, this is in the 80 ms range:

    perl -COEL -MYAML::XS=LoadFile -E'@q = @{ LoadFile("/path/to/quotes.yml") }; @q && say $q[rand @q]'

Either way, when you have a 40 ms ping time to the remote machine
showing that quote is the major noticeable delay when you do I<ssh
machine>.

L<quotecc> solves that problem, showing a quote takes around 4 ms
now. That's comparable with any hello wold program in C that I
produce.

=head1 AUTHOR

E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__DATA__
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/time.h>

const char* const quotes[[% size %]] = {
[% FOREACH quote IN quotes
%]    [% escape(quote) %],
[% END
%]};

/* returns random integer between min and max, inclusive */
const int rand_range(const int min, const int max)
{
    struct timeval tv;
    gettimeofday(&tv, NULL);
    const long int n = tv.tv_usec * getpid();
    srand(n);

    return (rand() % (max + 1 - min) + min);
}

const int main(const int argc, const char **argv)
{
    int i;
    const char* const all = "--all";
    const size_t all_length = strlen(all);

    if (argc == 2 &&
        strlen(argv[1]) == all_length &&
        !strncmp(argv[1], all, all_length)) {
        for (i = 0; i < [% size %]; i++) {
            puts(quotes[i]);
        }
    } else {
        const int quote = rand_range(0, [% size %]);
        puts(quotes[quote]);
    }

    return EXIT_SUCCESS;
}
