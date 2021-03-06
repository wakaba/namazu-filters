#
# -*- Perl -*-
# $Id: tex.pl,v 1.1 2001/11/30 07:56:45 wakaba Exp $
# Copyright (C) 1999 Satoru Takabayashi ,
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

package tex;
use strict;
require 'util.pl';
require 'gfilter.pl';

my $texconvpath = undef;

sub mediatype() {
    return ('application/x-tex');
}

sub status() {
    $texconvpath = util::checkcmd('detex');
    return 'yes' if (defined $texconvpath);
    return 'no';
}

sub recursive() {
    return 0;
}

sub pre_codeconv() {
    return 1;
}

sub post_codeconv () {
    return 0;
}

sub add_magic ($) {
    my ($magic) = @_;

    $magic->addSpecials("application/x-tex",
			"^\\\\document(style|class)",
			"^\\\\begin\\{document\\}",
			"^\\\\section\\{[^}]+\\}");
    $magic->addFileExts('\\.tex$', 'application/x-tex');
    return;
}

sub filter ($$$$$) {
    my ($orig_cfile, $cont, $weighted_str, $headings, $fields)
      = @_;
    my $cfile = defined $orig_cfile ? $$orig_cfile : '';

    if ($$cont =~ m/\\title\{(.*?)\}/s) {
	$fields->{'title'} = $1;
	$fields->{'title'} =~ s/\\\\/ /g;
    }
    if ($$cont =~ m/\\author\{(.*?)\}/s) {
	$fields->{'author'} = $1;
	$fields->{'author'} =~ s/\\\\/ /g;
    }
    if ($$cont =~ m/\\begin\{abstract\}(.*?)\\end\{abstract\}/s) {
	$fields->{'summary'} = $1;
	$fields->{'summary'} =~ s/\\\\/ /g;
    }

    my $tmpfile = util::tmpnam('NMZ.tex');
    util::vprint("Processing tex file ... (using  '$texconvpath')\n");

    {
	my $fh = util::efopen("| $texconvpath > $tmpfile");
	print $fh $$cont;
    }

    {
	my $fh = util::efopen("< $tmpfile");
	$$cont = util::readfile($fh);
    }

    gfilter::line_adjust_filter($cont);
    gfilter::line_adjust_filter($weighted_str);
    gfilter::white_space_adjust_filter($cont);
    $fields->{'title'} = gfilter::filename_to_title($cfile, $weighted_str)
      unless $fields->{'title'};
    gfilter::show_filter_debug_info($cont, $weighted_str,
			   $fields, $headings);
    return undef;
}

1;
