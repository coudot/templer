
=head1 NAME

Templer::Plugin::Markdown - A simple markdown-formatting plugin

=cut

=head1 DESCRIPTION

This class implements a formatter plugin for C<templer> which allows
pages to be written using markdown.

This allows input such as this to be executed:

=for example begin

    Title: This is my page
    format: markdown
    ----
    **Bold**
    _italic_
    Content!

=for example end

=cut

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the terms of either:

a) the GNU General Public License as published by the Free Software
Foundation; either version 2, or (at your option) any later version,
or

b) the Perl "Artistic License".

=cut

=head1 AUTHOR

Steve Kemp <steve@steve.org.uk>

=cut

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2015 Steve Kemp <steve@steve.org.uk>.

This library is free software. You can modify and or distribute it under
the same terms as Perl itself.

=cut

=head1 METHODS

=cut


use strict;
use warnings;


package Templer::Plugin::Markdown;


=head2 new

Constructor.  No arguments are supported/expected.

=cut

sub new
{
    my ( $proto, %supplied ) = (@_);
    my $class = ref($proto) || $proto;

    my $self = {};
    bless( $self, $class );
    return $self;
}


=head2 available

This plugin is available if we've got the L<Text::Markdown> module.

=cut

sub available
{
    my $str = "use Text::Markdown;";

    ## no critic (Eval)
    eval($str);
    ## use critic

    return ( $@ ? undef : 1 );
}


=head2 format

Format the given text.

=cut

sub format
{
    my ( $self, $str, $data ) = (@_);

    if ( $self->available() )
    {
        Text::Markdown::markdown($str);
    }
    else
    {
        warn
          "Markdown formatting disabled as the Text::Markdown module isn't present.\n";

        $str;
    }
}

Templer::Plugin::Factory->new()
  ->register_formatter( "markdown", "Templer::Plugin::Markdown" );
