package App::QuoteCC::Role::Output;

use 5.010;
use strict;
use warnings;
use Moose::Role;
use namespace::clean -except => 'meta';

has file => (
    isa           => 'Str',
    is            => 'ro',
    documentation => 'The output file to compile to. - for STDOUT',
);

has quotes => (
    isa           => 'ArrayRef[Str]',
    is            => 'ro',
    documentation => 'The quotes to compile to',
);

sub file_handle {
    my ($self) = @_;
    my $file   = $self->file;

    given ($file) {
        when ('-') {
            return *STDOUT;
        }
        default {
            open my $fh, '>', $file;
            return $fh;
        }
    }
}

requires 'output';

1;

=encoding utf8

=head1 NAME

App::QuoteCC::Role::Output - A role representing a L<App::QuoteCC> output format

=head1 AUTHOR

E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason.

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

