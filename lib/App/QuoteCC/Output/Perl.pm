package App::QuoteCC::Output::Perl;

use 5.010;
use strict;
use warnings;
use Moose;
use Data::Dump 'dump';
use Template;
use Encode;
use Data::Section qw/ -setup /;
use namespace::clean -except => [ qw/ meta merged_section_data section_data / ];

with qw/ App::QuoteCC::Role::Output /;

has template => (
    isa           => 'Str',
    is            => 'ro',
    lazy_build    => 1,
    documentation => "The Template template to emit",
);

sub _build_template {
    my ($self) = @_;
    my $template = $self->section_data( 'program' );
    return $$template;
}

sub output {
    my ($self) = @_;
    my $handle = $self->file_handle;

    # Get output
    my $out  = $self->_process_template;

    # Spew output
    $self->spew_output($out);

    return;
}

sub _process_template {
    my ($self) = @_;
    my $quotes = $self->quotes;
    my $template = $self->template;
    my $out;

    # emit raw octets, not UTF-8 marked strings with clever escaping.
    $_ = encode("utf8", $_) for @$quotes;

    Template->new->process(
        \$template,
        {
            quotes => $quotes,
            size => scalar(@$quotes),
            escape => sub {
                my ($quotes) = @_;
                my $str = dump @$quotes;
                return $str;
            },
        },
        \$out
    );

    return $out;
}

__PACKAGE__->meta->make_immutable;

=encoding utf8

=head1 NAME

App::QuoteCC::Output::Perl - Emit quotes in Perl format

=head1 AUTHOR

E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__DATA__
__[ program ]__
#!/usr/bin/env perl

our @QUOTES = [% escape(quotes) %];

if (@ARGV && $ARGV[0] eq '--all') {
    print $_, "\n" for @QUOTES;
} else {
    print $QUOTES[rand @QUOTES], "\n";
}
