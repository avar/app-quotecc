package App::QuoteCC::Format::Fortune;

use perl5i::latest;
use Moose;
use namespace::clean -except => 'meta';

with qw/ App::QuoteCC::Role::Format /;

sub quotes {
    my ($self) = @_;
    my $handle = $self->file_handle;

    my $content = join '', <$handle>;
    my @quotes = split /\n%\n/, $content;
    return \@quotes;
}

__PACKAGE__->meta->make_immutable;

=encoding utf8

=head1 NAME

App::QuoteCC::Format::Fortune - Read quotes from a L<fortune(1)> file

=head1 AUTHOR

E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
