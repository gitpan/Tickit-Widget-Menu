#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Tickit::Test;

use Tickit::Widget::Menu::Item;

my $activated;

my $item = Tickit::Widget::Menu::Item->new(
   name => "Some item",
   on_activate => sub { $activated++ },
);

ok( defined $item, '$item defined' );
isa_ok( $item, "Tickit::Widget::Menu::Item", '$item isa Tickit::Widget::Menu::Item' );

$item->activate;
is( $activated, 1, '$activated is 1 after ->activate' );

done_testing;
