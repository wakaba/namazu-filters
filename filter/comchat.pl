# -*- Perl -*-

=head1 NAME

comchat.pl -- namazu filter for comchat log

=cut

package comchat;
use strict;
use Chat::Comchat;
require 'util.pl';
require 'gfilter.pl';
require 'html.pl';

sub mediatype() {
    return ('application/x-comchat-log');
}

sub add_magic ($) {
    my ($magic) = @_;
    $magic->addSpecials("application/x-comchat-log", "<>.*<>.*<>.*<>.*<>");
    $magic->addFileExts('\\.comchat$', 'application/x-comchat-log');
    return;
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

sub filter ($$$$$) {
    my ($orig_cfile, $cont, $weighted_str, $headings, $fields)
      = @_;
    util::vprint("Processing comchat log...\n");
    my $tmpfile  = util::tmpnam('NMZ.pod');
    {
        util::vprint("temp: >$tmpfile\n");
        my $fh = util::efopen("> $tmpfile");
        print $fh $$cont;
    }
    
    my $title = undef;
    if ($$orig_cfile =~ m#.*?/([^/]+)$#) {
      $title = "$1 (chat log)";
    }
    my $chat = Chat::Comchat->open($tmpfile);
    $$cont = <<EOH;
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<title>${title}</title>
</head>
<body><ul>
EOH
    
    for my $m ($chat->get()) {
      for ("<li>", $m->{name}, $m->{text}, $m->{time}, $m->{ip}, "</li>\n") {
        $$cont .= $_." " if $_;
      }
    }
    $$cont .= <<EOH;
</ul></body></html>
EOH
    unlink($tmpfile);
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
