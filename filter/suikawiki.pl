package suikawiki;
use strict;
require 'util.pl';
require 'gfilter.pl';

sub mediatype () { q#text/x-suikawiki; version=0.9# }

sub status () { 'yes' }

sub recursive () { 0 }

sub pre_codeconv () { 1 }

sub post_codeconv () { 0 }

sub add_magic ($) {
  my $magic = shift;
  $magic->addSpecials('text/x-suikawiki; version=0.9', '#?SuikaWiki/0.9');
}

sub filter ($$$$$) {
  my ($orig_cfile, $contref, $weighted_str, $headings, $fields) = @_;
  my $cfile = ref $orig_cfile ? $$orig_cfile : '';
  
  util::vprint ("Processing SuikaWiki/0.9 file ...\n");
  $$contref =~ s/^\#\?[^\x0D\x0A]+[\x0D\x0A]+//s;	## Remove magic line
  
  if ($cfile =~ /([0-9A-F]+)\.txt/) {	## Get title from filename
    $fields->{title} = $1;
    $fields->{title} =~ s/([0-9A-F]{2})/chr hex $1/ge;
  }
  $fields->{author} = 'Wiki people';
  my $weight = $conf::Weight{html}->{title};
  $$weighted_str .= "\x7F$weight\x7F$fields->{title}\x7F/$weight\x7F\n";
  return undef;
}

=head1 NAME

suikawiki.pl --- Namazu: (totemo tenuki na) filter for SuikaWiki/0.9 documents

=head1 DESCRIPTION

This perl script is the filter for Wiki pages in SuikaWiki/0.9 format.

=head1 TO DO

SuikaWiki notations -> weighted-string

=head1 LICENSE

Copyright 2002 Wakaba <w@suika.fam.cx>.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; see the file COPYING.  If not, write to
the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
Boston, MA 02111-1307, USA.

=cut

1; # $Date: 2003/09/04 02:14:12 $
