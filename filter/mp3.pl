package mp3;
use strict;
require 'util.pl';
require 'gfilter.pl';


sub mediatype () { q#audio/mpeg# }

sub status () { eval q{require MP3::Tag} ? 'yes' : 'no' }

sub recursive () { 0 }

sub pre_codeconv () { 0 }

sub post_codeconv () { 1 }

sub add_magic ($) {
  my $magic = shift;
  $magic->addSpecials('audio/mpeg', 'ID3');
  $magic->addFileExts ('\\.mp3$' => 'audio/mpeg');
}

sub filter ($$$$$) {
  my ($orig_cfile, $contref, $weighted_str, $headings, $fields) = @_;
  my $cfile = defined $orig_cfile ? $$orig_cfile : '';
  
  util::vprint ("Processing mp3 file ...\n");
  
  unless ($cfile) {
    ## TBD
  }
  
  my $mp3 = MP3::Tag->new ($cfile);
  $mp3->get_tags;
  my $album = '';
  if (exists $mp3->{ID3v1}) {
    my $m = $mp3->{ID3v1};
    $fields->{title} = $m->song;
    $fields->{author} = $m->artist;
    $album = $m->album;
    $fields->{summary} = sprintf "%s %s %s", $album, $m->year, $m->comment;
    $$contref = sprintf "%s %s %s", $fields->{title}, $fields->{author}, $fields->{summary};
  } elsif (exists $mp3->{ID3v2}) {
    my $m = $mp3->{ID3v2};
    $fields->{title} = $m->get_frame ('TIT2');
    $fields->{author} = $m->artist;
    $album = $m->album;
    $fields->{summary} = $album;
    $$contref = sprintf "%s %s %s", $fields->{title}, $fields->{author}, $fields->{summary};
    for my $frame (keys %{$m->get_frame_ids}) {
      my ($info) = $m->get_frame ($frame);
      $$contref .= "\n" . $info if $info && not ref $info;
    }
  } else {
    $$contref = '';
  }
  
  my $weight = $conf::Weight{html}->{title};
  $$weighted_str .= "\x7F$weight\x7F$fields->{title}\x7F/$weight\x7F\n";
  $weight = $conf::Weight{metakey};
  $$weighted_str .= "\x7F$weight\x7F$fields->{author}\x7F/$weight\x7F\n";
  $$weighted_str .= "\x7F$weight\x7F$album\x7F/$weight\x7F\n";
  return undef;
}

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
