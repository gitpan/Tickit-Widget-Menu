use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Tickit::Widget::Menu',
   requires => {
      'Tickit::RenderBuffer' => '0.43', # flush_to_term, in unit tests
      'Tickit::Test' => 0,
      'Tickit::Widget' => '0.36',
      'Tickit::Window' => '0.43',
      'perl' => '5.010', # feature 'switch'
   },
   build_requires => {
      'Test::More' => '0.88', # done_testing
   },
   auto_configure_requires => 0, # Don't add M::B to configure_requires
   license => 'perl',
   create_makefile_pl => 'traditional',
   create_license => 1,
   create_readme  => 1,
   meta_merge => {
      resources => {
         x_IRC => "irc://irc.freenode.net/#tickit",
      },
   },
);

$build->create_build_script;
