#
# -*- Perl -*-
# $Id: compress.pl,v 1.1 2001/11/30 07:56:45 wakaba Exp $
# Copyright (C) 2000 Namazu Project All rights reserved ,
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

package compress;
use strict;
require 'util.pl';

my $zcatpath = undef;

sub mediatype() {
    return ('application/x-compress');
}

sub status() {
    $zcatpath = util::checkcmd('zcat');
    return 'no' unless (defined $zcatpath);
    return 'yes';
}

sub recursive() {
    return 1;
}

sub pre_codeconv() {
    return 0;
}

sub post_codeconv () {
    return 0;
}

sub add_magic ($) {
    return;
}

sub filter ($$$$$) {
    my ($orig_cfile, $cont, $weighted_str, $headings, $fields)
      = @_;

    my $tmpfile = util::tmpnam('NMZ.compr');

    util::vprint("Processing compress file ... (using  '$zcatpath')\n");

    my $fh = util::efopen("|$zcatpath > $tmpfile");
    print $fh $$cont;
    undef $fh;
    $fh = util::efopen("$tmpfile");
    my $size = util::filesize($fh);
    if ($size > $conf::FILE_SIZE_MAX) {
	return 'too_large_gzipped_file';
    }
    $$cont = util::readfile($fh);
    undef $fh;
    unlink $tmpfile;
    return undef;
}

1;
