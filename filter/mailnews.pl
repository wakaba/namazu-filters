#
# -*- Perl -*-
# $Id: mailnews.pl,v 1.1 2001/11/30 07:56:45 wakaba Exp $
# Copyright (C) 1997-2000 Satoru Takabayashi ,
#               1999 NOKUBI Takatsugu All rights reserved.
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

package mailnews;
use strict;
require 'util.pl';
require 'gfilter.pl';

sub mediatype() {
    return ('message/rfc822', 'message/news');
}

sub status() {
    return 'yes';
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
    $magic->addFileExts('\\.822$' => 'message/rfc822');
    return;
}

sub filter ($$$$$) {
    my ($orig_cfile, $cont, $weighted_str, $headings, $fields)
      = @_;
    my $cfile = defined $orig_cfile ? $$orig_cfile : '';

    util::vprint("Processing mail/news file ...\n");

    uuencode_filter($cont);
    mailnews_filter($cont, $weighted_str, $fields);
    mailnews_citation_filter($cont, $weighted_str);

    gfilter::line_adjust_filter($cont);
    gfilter::line_adjust_filter($weighted_str);
    gfilter::white_space_adjust_filter($cont);
    gfilter::white_space_adjust_filter($weighted_str);
    gfilter::show_filter_debug_info($cont, $weighted_str,
			   $fields, $headings);
    return undef;
}

# Original of this code was contributed by <furukawa@tcp-ip.or.jp>. 
sub mailnews_filter ($$$) {
    my ($contref, $weighted_str, $fields) = @_;

    my $boundary = "";
    my $line     = "";
    my $partial  = 0;

    $$contref =~ s/^\s+//;
    # Don't handle if first like doesn't seem like a mail/news header.
    return unless $$contref =~ /(^\S+:|^from )/i;

    my @tmp = split(/\n/, $$contref);
  HEADER_PROCESSING:
    while (@tmp) {
	$line = shift @tmp;
	last if ($line =~ /^$/);  # if an empty line, header is over
	# Connect the two lines if next line has leading spaces
	while (defined($tmp[0]) && $tmp[0] =~ /^\s+/) {
	    # if connection is Japanese character, remove spaces
	    # from Furukawa-san's idea [1998-09-22]
	    my $nextline = shift @tmp;
	    $line =~ s/([\xa1-\xfe])\s+$/$1/;
	    $nextline =~ s/^\s+([\xa1-\xfe])/$1/;
	    $line .= $nextline;
	}

	# Handle fields.
	if ($line =~ s/^subject:\s*//i){
	    $fields->{'title'} = $line;
	    # Skip [foobar-ML:000] for a typical mailing list subject.
	    # Practically skip first [...] for simple implementation.
	    $line =~ s/^\[.*?\]\s*//;

	    # Skip 'Re:'
	    $line =~ s/\bre:\s*//gi;

	    my $weight = $conf::Weight{'html'}->{'title'};
	    $$weighted_str .= "\x7f$weight\x7f$line\x7f/$weight\x7f\n";
 	} elsif ($line =~ s/^content-type:\s*//i) {
	    if ($line =~ /multipart.*boundary="(.*)"/i){
		$boundary = $1;
		util::dprint("((boundary: $boundary))\n");
  	    } elsif ($line =~ m!message/partial;\s*(.*)!i) {
		# The Message/Partial subtype routine [1998-10-12]
		# contributed by Hiroshi Kato <tumibito@mm.rd.nttdata.co.jp>
  		$partial = $1;
  		util::dprint("((partial: $partial))\n");
	    }
	} elsif ($line =~ /^(\S+):\s*(.*)/i) {
	    my $name = $1;
	    my $value = $2;
	    $fields->{lc($name)} = $value;
	    if ($name =~ /^($conf::REMAIN_HEADER)$/io) {
		# keep some fields specified REMAIN_HEADER for search keyword
		my $weight = $conf::Weight{'headers'};
		$$weighted_str .= 
		    "\x7f$weight\x7f$value\x7f/$weight\x7f\n";
	    }
	} 
    }
    if ($partial) {
	# MHonARC makes several empty lines between header and body,
	# so remove them.
	while(@tmp) {
	    last if (! $line =~ /^\s*$/);
	    $line = shift @tmp;
	}
	undef $partial;
	goto HEADER_PROCESSING;
    }
    $$contref = join("\n", @tmp);

    # Handle MIME multipart message.
    if ($boundary) {
	$boundary =~ s/(\W)/\\$1/g;
	$$contref =~ s/This is multipart message.\n//i;


	# MIME multipart processing,
	# modified by Furukawa-san's patch on [1998/08/27]
 	$$contref =~ s/--$boundary(--)?\n?/\xff/g;
 	my (@parts) = split(/\xff/, $$contref);
 	$$contref = '';
 	for $_ (@parts){
 	    if (s/^(.*?\n\n)//s){
 		my ($head) = $1;
 		$$contref .= $_ if $head =~ m!^content-type:.*text/plain!mi;
 	    }
 	}
    }
}

# Make mail/news citation marks not to be indexed.
# And a greeting message at the beginning.
# And a meaningless message such as "foo wrote:".
# Thanks to Akira Yamada for great idea.
sub mailnews_citation_filter ($$) {
    my ($contref, $weighted_str) = @_;

    my $omake = "";
    $$contref =~ s/^\s+//;
    my @tmp = split(/\n/, $$contref);
    $$contref = "";

    # Greeting at the beginning (first one or two lines)
    for (my $i = 0; $i < 2 && defined($tmp[$i]); $i++) {
	if ($tmp[$i] =~ /(^\s*((([\xa1-\xfe][\xa1-\xfe]){1,8}|([\x21-\x7e]{1,16}))\s*(。|．|\.|，|,|、|\@|＠|の)\s*){0,2}\s*(([\xa1-\xfe][\xa1-\xfe]){1,8}|([\x21-\x7e]{1,16}))\s*(です|と申します|ともうします|といいます)(.{0,2})?\s*$)/) {
	    # for searching debug info by perl -n00e 'print if /^<<<</'
	    util::dprint("\n\n<<<<$tmp[$i]>>>>\n\n");
	    $omake .= $tmp[$i] . "\n";
	    $tmp[$i] = "";
        }
    }

    # Isolate citation parts.
    for my $line (@tmp) {
	# Don't do that if there is an HTML tag at first.
	if ($line !~ /^[^>]*</ &&
	    $line =~ s/^((\S{1,10}>)|(\s*[\>\|\:\#]+\s*))+//) {
	    $omake .= $line . "\n";
	    $$contref .= "\n";  # Insert LF.
	    next;
	}
	$$contref .= $line. "\n";
    }
	
    # Process text as chunks of paragraphs.
    # Isolate meaningless message such as "foo wrote:".
    @tmp = split(/\n\n+/, $$contref);
    $$contref = "";
    my $i = 0;
    for my $line (@tmp) {
	# Complete excluding is impossible. I tnink it's good enough.
        # Process only first five paragrahs.
	# And don't handle the paragrah which has five or longer lines.
	# Hmm, this regex looks very hairly.
	if ($i < 5 && ($line =~ tr/\n/\n/) <= 5 && $line =~ /(^\s*(Date:|Subject:|Message-ID:|From:|件名|差出人|日時))|(^.+(返事です|reply\s*です|曰く|いわく|書きました|言いました|話で|wrote|said|writes|says)(.{0,2})?\s*$)|(^.*In .*(article|message))|(<\S+\@([\w\-.]\.)+\w+>)/im) {
	    util::dprint("\n\n<<<<$line>>>>\n\n");
	    $omake .= $line . "\n";
	    $line = "";
	    next;
	}
	$$contref .= $line. "\n\n";
        $i++;
    }
    $$weighted_str .= "\x7f1\x7f$omake\x7f/1\x7f\n";
}

# Skip uuencode and BinHex texts.
# Original of this code was contributed by <furukawa@tcp-ip.or.jp>. 
sub uuencode_filter ($) {
    my ($content) = @_;
    my @tmp = split(/\n/, $$content);
    $$content = "";
    
    my $uuin = 0;
    while (@tmp) {
	my $line = shift @tmp;
	$line .= "\n";

	# Skip BinHex texts.
	# All lines will be skipped.
	last if $line =~ /^\(This file must be converted with BinHex/; #)

	# Skip uuencode texts.
	# References : SunOS 4.1.4: man 5 uuencode
	#              FreeBSD 2.2: uuencode.c
	# For avoiding accidental matching, check a format.
	#
	# There are many netnews messages which is separated into several 
	# files. This kind of files has usually no "begin" line. 
	# This function handle them as well.
	#
	# There are two fashion for line length 62 and 63.
	# This function handle both.
	#
	# In the case of following the specification strictly,
	# int((ord($line) - ord(' ') + 2) / 3)
	#     != (length($line) - 2) / 4
	# but it can be transformed into a simple equation.
	# 4 * int(ord($line) / 3) != length($line) + $uunumb;

        # Hey, SunOS's uuencode use SPACE for encoding.
        # But allowing SPACE is dangerous for misrecognizing.
	# For compromise, only the following case are acceptable.
        #   1. inside of begin - end
        #   2. previous line is recognized as uuencoded line 
	#      and ord is identical with previous one.
	
	# a line consists of only characters of 0x20-0x60 is recognized 
	# as uuencoded line. v1.1.2.3 (bug fix)

        $uuin = 1, next if $line =~ /^begin [0-7]{3,4} \S+$/;
        if ($line =~ /^end$/){
            $uuin = 0,next if $uuin;
        } else {
            # Restrict ord value in range of 32-95.
	    my $uuord = ord($line);
	    $uuord = 32 if $uuord == 96;

            # if the line of uunumb = 38 is over this loop,
	    # a normal line of 63 length can be ruined accidentaly.
            my $uunumb = (length($line)==63)? 37: 38;

            if ((32 <= $uuord && $uuord < 96) &&
                length($line) <= 63 &&
                (4 * int($uuord / 3) == length($line) + $uunumb)){

                if ($uuin == 1 || $uuin == $uuord){
                    next if $line =~ /^[\x20-\x60]+$/;
                } else {
		    # Be strict for files which doesn't begin with "begin".
                    $uuin = $uuord, next if $line =~ /^M[\x21-\x60]+$/;
                }
            }
        }
        $uuin = 0;
        $$content .= $line;
    }
}


1;
