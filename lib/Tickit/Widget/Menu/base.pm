#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012 -- leonerd@leonerd.org.uk

package Tickit::Widget::Menu::base;

use strict;
use warnings;
use feature qw( switch );

use base qw( Tickit::Widget );

our $VERSION = '0.02';

use Carp;

use constant CLEAR_BEFORE_RENDER => 0;

use constant separator => [];

use Tickit::WidgetRole::Penable
   name => 'active', default => { rv => 0, bg => 'green' };

sub new
{
   my $class = shift;
   my %args = @_;

   foreach my $method (qw( pos2item on_mouse_item render_item popup_item activated )) {
      $class->can( $method ) or 
         croak "$class cannot ->$method - do you subclass and implement it?";
   }
   my $self = $class->SUPER::new( %args );

   # Default?
   $self->pen->chattrs( { rv => 1 } );
   $self->_init_active_pen;

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

sub activate_item
{
   my $self = shift;
   my ( $idx ) = @_;

   return if defined $self->{active_idx} and $idx == $self->{active_idx};

   if( defined( my $old_idx = $self->{active_idx} ) ) {
      undef $self->{active_idx};
      my $old_item = $self->{items}[$old_idx];
      if( $old_item->isa( "Tickit::Widget::Menu" ) ) {
         $old_item->dismiss;
      }
      $self->render_item( $old_idx );
   }

   $self->{active_idx} = $idx;
   $self->render_item( $idx );

   my $item = $self->{items}[$idx];
   if( $item->isa( "Tickit::Widget::Menu" ) ) {
      $self->popup_item( $idx );
      $item->set_on_activated( sub {
         undef $self->{active_idx};
         $self->activated
      } );
   }

   $self->window->term->flush;
}

sub set_on_activated
{
   my $self = shift;
   ( $self->{on_activated} ) = @_;
}

sub dismiss
{
   my $self = shift;

   $self->window->hide;

   $self->set_window( undef );

   if( defined $self->{active_idx} ) {
      my $item = $self->{items}[$self->{active_idx}];
      $item->dismiss if $item->isa( "Tickit::Widget::Menu" );
   }

   undef $self->{active_idx};
}

sub on_key
{
   my $self = shift;
   my ( $type, $str ) = @_;

   return 1 unless $type eq "key"; # don't react to text

   for( $str ) {
      when( "Escape") {
         $self->dismiss;
      }
      when( "Enter" ) {
         return 1 unless defined( my $idx = $self->{active_idx} );

         undef $self->{active_idx};
         $self->dismiss;
         $self->{items}[$idx]->activate;
      }
   }

   return 1;
}

sub on_mouse
{
   my $self = shift;
   my ( $event, $button, $line, $col ) = @_;

   if( $line < 0 or $line >= $self->window->lines or
       $col  < 0 or $col  >= $self->window->cols ) {
      $self->dismiss, return 0 if $event eq "press";
      return 0;
   }

   my ( $item, $item_idx, $item_col ) = $self->pos2item( $line, $col );
   $item or return 1;

   $self->on_mouse_item( $event, $button, $line, $col, $item, $item_idx, $item_col );
}

0x55AA;
