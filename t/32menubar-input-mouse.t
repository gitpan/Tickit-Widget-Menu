#!/usr/bin/perl

use strict;

use Test::More tests => 6;

use Tickit::Test;

use Tickit::Widget::MenuBar;
use Tickit::Widget::Menu;
use Tickit::Widget::Menu::Item;

my ( $term, $win ) = mk_term_and_window;

{
   my $activated;

   my $menubar = Tickit::Widget::MenuBar->new(
      items => [
         Tickit::Widget::Menu->new( name => "File",
            items => [
               Tickit::Widget::Menu::Item->new( name => "File 1", on_activate => sub { $activated = "F1" } ),
               Tickit::Widget::Menu::Item->new( name => "File 2", on_activate => sub { $activated = "F2" } ),
            ],
         ),
         Tickit::Widget::Menu->new( name => "Edit",
            items => [
               Tickit::Widget::Menu::Item->new( name => "Edit 1", on_activate => sub { $activated = "E1" } ),
            ],
         ),
      ]
   );

   $menubar->set_window( $win );
   flush_tickit;

   is_display( [ [TEXT("File  Edit",rv=>1)] ],
               'Display initially' );

   pressmouse( press => 1, 0, 3 );
   flush_tickit;

   is_display( [ [TEXT("File",rv=>0,bg=>2), TEXT("  Edit",rv=>1)],
                 [TEXT("+--------+",rv=>1)],
                 [TEXT("| File 1 |",rv=>1)],
                 [TEXT("| File 2 |",rv=>1)],
                 [TEXT("+--------+",rv=>1)] ],
               'Display after mouse press on File' );

   pressmouse( drag => 1, 0, 9 );
   flush_tickit;

   is_display( [ [TEXT("File  ",rv=>1), TEXT("Edit",rv=>0,bg=>2)],
                 [BLANK(6), TEXT("+--------+",rv=>1)],
                 [BLANK(6), TEXT("| Edit 1 |",rv=>1)],
                 [BLANK(6), TEXT("+--------+",rv=>1)] ],
               'Display after mouse drag to Edit' );

   pressmouse( drag => 1, 2, 9 );
   flush_tickit;

   is_display( [ [TEXT("File  ",rv=>1), TEXT("Edit",rv=>0,bg=>2)],
                 [BLANK(6), TEXT("+--------+",rv=>1)],
                 [BLANK(6), TEXT("| ",rv=>1), TEXT("Edit 1",rv=>0,bg=>2), TEXT(" |",rv=>1)],
                 [BLANK(6), TEXT("+--------+",rv=>1)] ],
               'Display after mouse drag to Edit 1' );

   pressmouse( release => 1, 2, 9 );
   flush_tickit;

   is( $activated, "E1", '$activated is E1 after mouse release on Edit 1' );

   is_display( [ [TEXT("File  Edit",rv=>1)] ],
               'Display after mouse release on Edit 1' );
}
