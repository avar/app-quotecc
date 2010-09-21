package App::QuoteCC::Role::Input;

use 5.010;
use strict;
use warnings;
use Moose::Role;
use namespace::clean -except => 'meta';

has file => (
    isa           => 'Str',
    is            => 'ro',
    documentation => 'The quotes file to compile from. - for STDIN',
);

sub file_handle {
    my ($self) = @_;
    my $file   = $self->file;

    given ($file) {
        when ('-') {
            binmode STDIN, ":utf8";
            return *STDIN;
        }
        default {
            open my $fh, '<:encoding(UTF-8)', $file;
            return $fh;
        }
    }
}

requires 'quotes';

1;

=encoding utf8

=head1 NAME

App::QuoteCC::Role::Input - A role representing a L<App::QuoteCC> input format

=head1 AUTHOR

E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason.

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

