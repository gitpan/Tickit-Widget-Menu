#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012 -- leonerd@leonerd.org.uk

package Tickit::Widget::MenuBar;

use strict;
use warnings;

use base qw( Tickit::Widget::Menu::base );

our $VERSION = '0.01';

use Tickit::Utils qw( textwidth );
use List::Util qw( sum );

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

=cut

sub lines
{
   return 1;
}

sub cols
{
   my $self = shift;
   return sum( map { textwidth $_->name } $self->items ) + 2 * ( $self->items - 1 );
}

sub pos2item
{
   my $self = shift;
   my ( $line, $col ) = @_;

   $line == 0 or return ();

   my @items = $self->items;
   my $idx = 0;
   while( $col >= 0 and $idx < @items ) {
      my $item = $items[$idx];

      my $width = textwidth $item->name;
      return ( $item, $idx, $col ) if $col < $width;
      $col -= $width;
      $idx++;

      return () if $col < 2;
      $col -= 2;
   }

   return ();
}

sub render_item
{
   my $self = shift;
   my ( $idx ) = @_;

   $self->render( first_idx => $idx, last_idx => $idx, rect => $self->window->rect );
}

sub render
{
   my $self = shift;
   my %args = @_;

   my $win = $self->window or return;
   $win->is_visible or return;
   my $rect = $args{rect};

   if( $rect->top == 0 ) {
      my $col = 0;

      my $pen = $self->pen;

      my @items = $self->items;
      foreach my $idx ( 0 .. $#items ) {
         return if defined $args{last_idx} and $idx > $args{last_idx};

         my $item = $items[$idx];
         my $name = $item->name;

         my $start_col = $col;

         $col += textwidth( $name ) + 2;
         next if defined $args{first_idx} and $idx < $args{first_idx};

         $win->goto( 0, $start_col );

         my $is_highlight = defined $self->{active_idx} && $idx == $self->{active_idx};

         $win->print( $name, $is_highlight ? ( $self->active_pen ) : ( $pen ) );

         $win->erasech( 2, 1, $pen );
      }

      $win->erasech( $win->cols - $col, undef, $pen );
   }

   foreach my $line ( $rect->top + 1 .. $rect->bottom ) {
      $win->goto( $line, $rect->left );
      $win->erasech( $rect->cols );
   }
}

sub popup_item
{
   my $self = shift;
   my ( $idx ) = @_;

   my $items = $self->{items};

   my $col = 0;
   for ( my $i = 0; $i < $idx; $i++ ) {
      $col += textwidth( $items->[$i]->name ) + 2;
   }

   $items->[$idx]->popup( $self->window, 1, $col );
}

sub activated
{
   my $self = shift;

   undef $self->{active_idx};
   $self->redraw;
}

sub on_mouse_item
{
   my $self = shift;
   my ( $event, $button, $line, $col, $item, $item_idx, $item_col ) = @_;

   if( $event eq "press" || $event eq "drag" and
       $button == 1 ) {
      $self->activate_item( $item_idx );
   }

   return 1;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
