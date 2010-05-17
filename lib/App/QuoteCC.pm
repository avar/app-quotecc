package App::QuoteCC;

use perl5i::latest;
use Moose;
use File::Slurp qw/ write_file /;
use Template;
use namespace::clean -except => [ qw< meta plugins > ];

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

has quotes => (
    traits        => [ qw/ Getopt / ],
    cmd_aliases   => 'q',
    cmd_flag      => 'quotes',
    isa           => 'Str',
    is            => 'ro',
    documentation => 'The quotes file to compile from. - for STDIN',
);

has format => (
    traits        => [ qw/ Getopt / ],
    cmd_aliases   => 'f',
    cmd_flag      => 'format',
    isa           => 'Str',
    is            => 'ro',
    documentation => 'The format of the file. Any App::QuotesCC::Format::*',
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

sub run {
    my ($self) = @_;

    # Get quotes
    my $quotes = do {
        my $quotes_class_short = $self->format;
        my $quotes_class = "App::QuoteCC::Format::" . $quotes_class_short;
        $quotes_class->require;
        $quotes_class->new(
            file => $self->quotes,
        )->quotes;
    };

    # Get output
    my $out = $self->process_template($quotes);

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

sub process_template {
    my ($self, $quotes) = @_;
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

    /usr/local/bin/failo-wisdom --all > /usr/local/bin/quotes.txt

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
