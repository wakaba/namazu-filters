# -*- Perl -*-

=head1 NAME

pod.pl -- namazu filter for pod

=cut

package pod;
use strict;
use File::Copy;
require 'util.pl';
require 'gfilter.pl';
require 'html.pl';

sub mediatype() {
    return ('application/x-perl');
}

sub status() {
    return 'yes';
}

sub recursive() {
    return 1;
}

sub pre_codeconv() {
    return 0;
}

sub post_codeconv () {
    return 1;
}

sub add_magic ($) {
    my ($magic) = @_;
    $magic->addSpecials("application/x-perl", "#!perl");
    $magic->addSpecials("application/x-perl", "#!/usr/bin/perl");
    $magic->addSpecials("application/x-perl", "#!/usr/local/bin/perl");
    $magic->addSpecials("application/x-perl", "=pod");
    $magic->addSpecials("application/x-perl", "=head");
    $magic->addSpecials("application/x-perl", "=cut");
    $magic->addSpecials("application/x-perl", "use strict");
    $magic->addSpecials("application/x-perl", "no strict");
    $magic->addSpecials("application/x-perl", "package ");
    $magic->addSpecials("application/x-perl", "-*- Perl -*-");
    $magic->addFileExts('\\.pl$', 'application/x-perl');
    $magic->addFileExts('\\.pm$', 'application/x-perl');
    $magic->addFileExts('\\.ph$', 'application/x-perl');
    $magic->addFileExts('\\.cgi$', 'application/x-perl');
    $magic->addFileExts('\\.pod$', 'application/x-perl');
    return;
}

sub filter ($$$$$) {
    my ($orig_cfile, $cont, $weighted_str, $headings, $fields)
      = @_;
    my $tmpfile  = util::tmpnam('NMZ.pod');
    my $tmpfile2  = util::tmpnam('NMZ.pod2');
    util::vprint("Processing pod file...\n");
    {
        util::vprint("temp: >$tmpfile\n");
        my $fh = util::efopen("> $tmpfile");
        print $fh $$cont;
    }
    {
        require Pod2Html;
        if ($$orig_cfile =~ m#/.*?([^/]+)$#) {
          $Pod2Html::pConfig{title} = "$1 (Perl)";
        }
        Pod2Html::pod2html("--infile=$tmpfile",
            "--outfile=$tmpfile2");
    }
    {
        util::vprint("temp: <$tmpfile\n");
        my $fh = util::efopen("< $tmpfile2");
        $$cont = util::readfile($fh);
        util::vprint("$$cont\n");
    }
    unlink($tmpfile);
    unlink($tmpfile2);
    
    return undef;
}

=head1 LICENSE

Copyright wakaba 2001  All rights reserved.

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

=head1 CHANGE

2001-11-09  wakaba <wakaba@suika.fam.cx>

	* new.

=cut

1;
