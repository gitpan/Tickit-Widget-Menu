#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012-2013 -- leonerd@leonerd.org.uk

package Tickit::Widget::Menu;

use strict;
use warnings;
use feature qw( switch );

use Tickit::Window 0.18; # needs ->make_popup

our $VERSION = '0.03';

# Much of this code actually lives in a class called T:W:Menu::base, which is
# the base class used by T:W:Menu and T:W:MenuBar
use base qw( Tickit::Widget::Menu::base );
use Tickit::Style;

use Tickit::RenderContext qw( LINE_SINGLE );
use Tickit::Utils qw( textwidth );
use List::Util qw( max min );

# Re-import the constant for compiletime use
use constant separator => __PACKAGE__->separator;

=head1 NAME

C<Tickit::Widget::Menu> - display a menu of choices

=head1 SYNOPSIS

 use Tickit;
 use Tickit::Widget::Menu;
 use Tickit::Widget::Menu::Item;

 my $tickit = Tickit->new;

 my $menu = Tickit::Widget::Menu->new(
    items => [
       Tickit::Widget::Menu::Item->new(
          name => "Exit",
          on_activate => sub { $tickit->stop }
       ),
    ],
 );

 $menu->popup( $tickit->rootwin, 5, 5 );

 $tickit->run;

=head1 DESCRIPTION

This widget class acts as a display container for a list of items representing
individual choices. It can be displayed as a floating window using the
C<popup> method, or attached to a L<Tickit::Widget::MenuBar> or as a child
menu within another C<Tickit::Widget::Menu>.

This widget is intended to be displayed transiently, either as a pop-up menu
over some other widget, or as a child menu of another menu or an instance of
a menu bar. Specifically, such objects should not be directly added to
container widgets.

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

# These methods come from T:W:Menu::base but better to document them here so
# the reader can find them

=head1 CONSTRUCTOR

=head2 $menu = Tickit::Widget::Menu->new( %args )

Constructs a new C<Tickit::Widget::Menu> object.

Takes the following named arguments:

=over 8

=item name => STRING

Optional. If present, gives the name of the menu item for a submenu. Not used
in a top-level menu.

=item items => ARRAY

Optional. If present, contains a list of C<Tickit::Widget::Menu::Item> or
C<Tickit::Widget::Menu> objects to add to the menu. Equivalent to psasing each
to the C<push_item> method after construction.

=back

=head1 METHODS

=cut

sub lines
{
   my $self = shift;
   return 2 + $self->items;
}

sub cols
{
   my $self = shift;
   return 4 + max( map { $_ == separator ? 0 : textwidth $_->name } $self->items );
}

=head2 $name = $menu->name

Returns the string name for the menu.

=head2 @items = $menu->items

Returns the list of items currently stored.

=head2 $menu->push_item( $item )

Adds another item.

=cut

=head2 $menu->popup( $win, $line, $col )

Makes the menu appear at the given position relative to the given window. Note
that as C<< $win->make_popup >> is called, the menu is always displayed in a
popup window, floating over the root window. Passed window is used simply as
the origin for the given line and column position.

=cut

sub popup
{
   my $self = shift;
   my ( $parentwin, $line, $col ) = @_;

   my $win = $parentwin->make_popup( $line, $col, $self->lines, $self->cols );

   $self->set_window( $win );

   $win->show;
}

=head2 $menu->dismiss

Hides a menu previously displayed using C<popup>.

=cut

sub pos2item
{
   my $self = shift;
   my ( $line, $col ) = @_;

   $line > 0 or return ();
   $line--;

   $col > 1 or return ();
   $col < $self->cols - 1 or return ();
   $col -= 2;

   my @items = $self->items;
   $line < @items or return ();

   return ( $items[$line], $line, $col );
}

sub render_item
{
   my $self = shift;
   my ( $idx ) = @_;

   my $win = $self->window or return;
   $self->render(
      rect => Tickit::Rect->new( top => $idx+1, left => 1, lines => 1, cols => $win->cols - 2 )
   );
}

sub render
{
   my $self = shift;
   my %args = @_;

   my $win = $self->window or return;
   $win->is_visible or return;
   my $rect = $args{rect};

   my $rc = Tickit::RenderContext->new( lines => $win->lines, cols => $win->cols );
   $rc->clip( $rect );
   $rc->setpen( $self->pen );

   my $highlight_pen = $self->get_style_pen( "highlight" );

   my $lines = $win->lines;
   my $cols  = $win->cols;

   $rc->hline_at( 0, 0, $cols-1, LINE_SINGLE );
   $rc->hline_at( $lines-1, 0, $cols-1, LINE_SINGLE );
   $rc->vline_at( 0, $lines-1, 0, LINE_SINGLE );
   $rc->vline_at( 0, $lines-1, $cols-1, LINE_SINGLE );

   # This is clipped anyway, but useful to avoid overhead if we can
   foreach my $line ( max($rect->top, 1) .. min($rect->bottom-1, $win->lines-2) ) {
      my $idx = $line - 1;

      my $item = $self->{items}[$idx];
      if( $item == separator ) {
         $rc->hline_at( $line, 0, $cols-1, LINE_SINGLE );
      }
      else {
         $rc->erase_at( $line, 1, 1 );
         if( $item->isa( "Tickit::Widget::Menu" ) ) {
            $rc->text_at( $line, $cols-2, ">" );
         }
         else {
            $rc->erase_at( $line, $cols-2, 1 );
         }

         my $pen = defined $self->{active_idx} && $idx == $self->{active_idx}
                     ? $highlight_pen : undef;

         $rc->erase_at( $line, 2, $cols-4, $pen );
         $rc->text_at( $line, 2, $item->name, $pen );
      }
   }

   $rc->flush_to_window( $win );
}

sub popup_item
{
   my $self = shift;
   my ( $idx ) = @_;

   my $item = $self->{items}[$idx];

   $item->popup( $self->window, $idx + 1, $self->window->cols );
}

sub activated
{
   my $self = shift;
   $self->dismiss;

   $self->{on_activated}->() if $self->{on_activated};
}

sub on_key
{
   my $self = shift;
   my ( $type, $str ) = @_;

   my $items = $self->{items};

   for( $str ) {
      when( "Down" ) {
         my $idx = $self->{active_idx};
         if( defined $idx ) {
            $idx++, $idx %= @$items;
         }
         else {
            $idx = 0;
         }

         $idx++, $idx %= @$items while $items->[$idx] == separator;

         $self->activate_item( $idx );
      }
      when( "Up" ) {
         my $idx = $self->{active_idx};
         if( defined $idx ) {
            $idx--, $idx %= @$items;
         }
         else {
            $idx = $#$items;
         }

         $idx--, $idx %= @$items while $items->[$idx] == separator;

         $self->activate_item( $idx );
      }
      default {
         return $self->SUPER::on_key( @_ );
      }
   }

   return 1;
}

sub on_mouse_item
{
   my $self = shift;
   my ( $event, $button, $line, $col, $item, $item_idx, $item_col ) = @_;

   # Separators do not react to mouse
   return 1 if $item == separator;

   if( $event eq "press" || $event eq "drag" and $button == 1 ) {
      $self->activate_item( $item_idx );
   }
   elsif( $event eq "release" ) {
      if( defined $self->{active_idx} and $self->{active_idx} == $item_idx and
          !$item->isa( "Tickit::Widget::Menu" ) ) {
         $self->activated;
         $item->activate;
      }
   }

   return 1;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
