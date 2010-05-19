package App::QuoteCC;

use perl5i::latest;
use Moose;
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

    my $dynaload = sub {
        my ($vars, $new_args) = @_;
        my ($self_method_type, $class_type) = @$vars;
        my %args = %$new_args;

        my $x_class_short = $self->$self_method_type;
        my $x_class = "App::QuoteCC::${class_type}::" . $x_class_short;
        $x_class->require;
        my $obj = $x_class->new(%args);
        return $obj;
    };

    my $input  = $dynaload->(
        [ qw/ input_format Input / ],
        { file => $self->input },
    );
    my $quotes = $input->quotes;
    my $output = $dynaload->(
        [ qw/ output_format Output / ],
        {
            file => $self->output,
            quotes => $quotes,
        },
    );
    $output->output;

    return;
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

