#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012-2013 -- leonerd@leonerd.org.uk

package Tickit::Widget::MenuBar;

use strict;
use warnings;

use base qw( Tickit::Widget::Menu::base );
use Tickit::Style;

our $VERSION = '0.04';

use Tickit::RenderBuffer qw( LINE_SINGLE );
use Tickit::Utils qw( textwidth );
use List::Util qw( sum max );

=head1 NAME

C<Tickit::Widget::MenuBar> - display a menu horizontally

=head1 SYNOPSIS

 use Tickit;
 use Tickit::Widget::Menu;
 use Tickit::Widget::Menu::Item;
 use Tickit::Widget::MenuBar;
 use Tickit::Widget::VBox;

 my $tickit = Tickit->new;

 my $vbox = Tickit::Widget::VBox->new;
 $tickit->set_root_widget( $vbox );

 $vbox->add( Tickit::Widget::MenuBar->new(
    items => [
       ...
    ]
 );

 $vbox->add( ... );

 $tickit->run;

=head1 DESCRIPTION

This widget class acts as a container for menu items similar to
L<Tickit::Widget::Menu> but displays them horizonally in a single line. This
widget is intended to display long-term, such as in the top line of the root
window, rather than being used only transiently as a pop-up menu.

This widget should be used similarly to L<Tickit::Widget::Menu>, except that
its name is never useful, and it should be added to a container widget, such
as L<Tickit::Widget::VBox>, for longterm display. It does not have a C<popup>
or C<dismiss> method.

=head1 STYLE

The default style pen is used as the widget pen. The following style pen 
prefixes are also used:

=over 4

=item highlight => PEN

The pen used to highlight the active menu selection

=back

=cut

style_definition base =>
   rv => 1,
   highlight_rv => 0,
   highlight_bg => "green";

use constant WIDGET_PEN_FROM_STYLE => 1;

sub lines
{
   return 1;
}

sub cols
{
   my $self = shift;
   return sum( map { textwidth $_->name } $self->items ) + 2 * ( $self->items - 1 );
}

sub reshape
{
   my $self = shift;

   $self->{itemcols} = \my @cols;
   $self->{itemwidths} = \my @widths;

   my $items = $self->{items};
   my $col = 0;
   foreach my $idx ( 0 .. $#$items ) {
      $cols[$idx] = $col;
      $col += ( $widths[$idx] = textwidth $items->[$idx]->name );
      $col += 2;
   }

   push @cols, $col;
}

sub pos2item
{
   my $self = shift;
   my ( $line, $col ) = @_;

   $line == 0 or return ();

   my $cols   = $self->{itemcols};
   my $widths = $self->{itemwidths};

   foreach my $idx ( 0 .. $#$widths ) {
      next unless $col < $cols->[$idx+1];
      $col -= $cols->[$idx];

      return () if $col >= $widths->[$idx];
      return ( $self->{items}->[$idx], $idx, $col );
   }

   return ();
}

sub render_item
{
   my $self = shift;
   my ( $idx, $rb ) = @_;

   my $item = $self->{items}->[$idx];

   $rb->goto( 0, $self->{itemcols}->[$idx] );

   my $is_highlight = defined $self->{active_idx} && $idx == $self->{active_idx};
   $rb->text( $item->name, $is_highlight ? $self->get_style_pen( "highlight" ) : undef );

   $rb->erase( 2 );
}

sub render_to_rb
{
   my $self = shift;
   my ( $rb, $rect ) = @_;

   if( $rect->top == 0 ) {
      my @items = $self->items;
      foreach my $idx ( 0 .. $#items ) {
         $self->render_item( $idx, $rb );
      }

      $rb->erase_to( $rect->right );
   }

   foreach my $line ( $rect->linerange( 1, undef ) ) {
      $rb->erase_at( $line, $rect->left, $rect->cols );
   }
}

sub popup_item
{
   my $self = shift;
   my ( $idx ) = @_;

   my $items = $self->{items};

   my $col = $self->{itemcols}->[$idx];
   $items->[$idx]->popup( $self->window, 1, $col );
}

sub activated
{
   my $self = shift;
   $self->dismiss;
}

sub dismiss
{
   my $self = shift;
   $self->SUPER::dismiss;

   # Still have a window after ->dismiss
   $self->redraw;
}

sub on_mouse_item
{
   my $self = shift;
   my ( $args, $item, $item_idx, $item_col ) = @_;

   # We only ever care about button 1
   return unless $args->button == 1;

   my $event = $args->type;
   if( $event eq "press" ) {
      # A second click on an active item deactivates
      if( defined $self->{active_idx} and $item_idx == $self->{active_idx} ) {
         $self->dismiss;
      }
      else {
         $self->expand_item( $item_idx );
      }
   }
   elsif( $event eq "drag" ) {
      $self->expand_item( $item_idx );
   }

   return 1;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
