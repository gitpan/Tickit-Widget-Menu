#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012-2013 -- leonerd@leonerd.org.uk

package Tickit::Widget::Menu::base;

use strict;
use warnings;
use feature qw( switch );

use base qw( Tickit::Widget );

our $VERSION = '0.04';

use Carp;

use constant CLEAR_BEFORE_RENDER => 0;

use constant separator => [];

sub new
{
   my $class = shift;
   my %args = @_;

   foreach my $method (qw( pos2item on_mouse_item render_item popup_item activated )) {
      $class->can( $method ) or 
         croak "$class cannot ->$method - do you subclass and implement it?";
   }
   my $self = $class->SUPER::new( %args );

   $self->{items} = [];
   $self->{name} = $args{name};

   $self->{active_idx} = undef; # index of keyboard-selected highlight

   if( $args{items} ) {
      $self->push_item( $_ ) for @{ $args{items} };
   }

   return $self;
}

sub name
{
   my $self = shift;
   return $self->{name};
}

sub items
{
   my $self = shift;
   return @{ $self->{items} };
}

sub push_item
{
   my $self = shift;
   my ( $item ) = @_;

   push @{ $self->{items} }, $item;
}

sub highlight_item
{
   my $self = shift;
   my ( $idx ) = @_;

   return if defined $self->{active_idx} and $idx == $self->{active_idx};

   my $win = $self->window;
   my $rb = Tickit::RenderBuffer->new( lines => $win->lines, cols => $win->cols );
   $rb->setpen( $self->pen );

   if( defined( my $old_idx = $self->{active_idx} ) ) {
      undef $self->{active_idx};
      my $old_item = $self->{items}[$old_idx];
      if( $old_item->isa( "Tickit::Widget::Menu" ) ) {
         $old_item->dismiss;
      }
      $self->render_item( $old_idx, $rb );
   }

   $self->{active_idx} = $idx;
   $self->render_item( $idx, $rb );

   $rb->flush_to_window( $win );
}

sub expand_item
{
   my $self = shift;
   my ( $idx ) = @_;

   $self->highlight_item( $idx );

   my $item = $self->{items}[$idx];
   if( $item->isa( "Tickit::Widget::Menu" ) ) {
      $self->popup_item( $idx );
      $item->set_supermenu( $self );
   }
   # else don't bother expanding non-menus
}

sub activate_item
{
   my $self = shift;
   my ( $idx ) = @_;

   my $item = $self->{items}[$idx];
   if( $item->isa( "Tickit::Widget::Menu" ) ) {
      $self->expand_item( $idx );
   }
   else {
      $self->activated;
      $item->activate;
   }
}

sub set_on_activated
{
   my $self = shift;
   ( $self->{on_activated} ) = @_;
}

sub dismiss
{
   my $self = shift;

   if( defined $self->{active_idx} ) {
      my $item = $self->{items}[$self->{active_idx}];
      $item->dismiss if $item->isa( "Tickit::Widget::Menu" );
   }

   undef $self->{active_idx};
}

sub on_key
{
   my $self = shift;
   my ( $args ) = @_;

   return 1 unless $args->type eq "key"; # don't react to text

   for( $args->str ) {
      when( "Escape") {
         $self->dismiss;
      }
      when( "Enter" ) {
         return 1 unless defined( my $idx = $self->{active_idx} );
         $self->activate_item( $idx );
      }
   }

   return 1;
}

sub on_mouse
{
   my $self = shift;
   my ( $args ) = @_;

   my $line = $args->line;
   my $col  = $args->col;

   if( $line < 0 or $line >= $self->window->lines or
       $col  < 0 or $col  >= $self->window->cols ) {
      $self->dismiss, return 0 if $args->type eq "press";
      return 0;
   }

   my ( $item, $item_idx, $item_col ) = $self->pos2item( $line, $col );
   $item or return 1;

   $self->on_mouse_item( $args, $item, $item_idx, $item_col );
}

0x55AA;
