#
# -*- Perl -*-
# Copyright (C) 2001 wakaba <wakaba@suika.fam.cx>
#     This is free software with ABSOLUTELY NO WARRANTY.
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either versions 2, or (at your option)
#  any later version.
# 
#  This program is distributed in the hope that it will be useful
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
#  02111-1307, USA
#
#  This file must be encoded in EUC-JP encoding
#

package cwj;
no strict;
require 'util.pl';
require 'gfilter.pl';

sub mediatype() {
    return ('application/x-craris-works');
}

sub status() {
    if (defined util::checkcmd('nkf')) {
        return 'yes';
    } else {
        return 'no';
    }
}

sub recursive() {
    return 0;
}

sub pre_codeconv() {
    return 0;
}

sub post_codeconv () {
    return 1;
}

sub add_magic ($) {
    my ($magic) = @_;

    $magic->addSpecials("application/x-craris-works",
			"^\x04\x07\x76\x00\x43\x57\x4B\x4A");
    $magic->addFileExts('\\.cwj$' => 'application/x-craris-works');

    return;
}

sub filter ($$$$$) {
    my ($orig_cfile, $cont, $weighted_str, $headings, $fields)
      = @_;
    my $cfile = defined $orig_cfile ? $$orig_cfile : '';

    util::vprint("Processing Craris Works 4 document...\n");

    #cwj_filter($cont, $weighted_str, $fields);

    {
        use NKF;
        $$cont = nkf("-Se", $$cont);
        $$contref =~ s/[\x0D\x0A\x20]+/\x20/g;
        $$contref =~ s/[\x00-\x1F\x7F-\xA0\xFF]+//g;
    }
    
    gfilter::line_adjust_filter($cont);
    gfilter::line_adjust_filter($weighted_str);
    gfilter::white_space_adjust_filter($cont);
    gfilter::show_filter_debug_info($cont, $weighted_str,
			   $fields, $headings);
    return undef;
}

sub cwj_filter ($$$) {
    my ($contref, $weighted_str, $fields) = @_;

    $$contref =~ s/[\x0D\x0A\x20]+/\x20/g;
    $$contref =~ s/[\x00-\x1F\x7F\xFD-\xFF]+//g;
    my $t = $$contref;  my $r = "";
    $t =~ s{((?:(?:[\x81-\xFC][\x40-\x7E\x80-\xFC])+|(?:[\x20-\x7E]+))+)}{
      $r .= $1;
    }gesx;
    $$contref = $r;
}

1;
