#
# -*- Perl -*-
# $Id: html.pl,v 1.1 2001/11/30 07:56:45 wakaba Exp $
# Copyright (C) 1997-1999 Satoru Takabayashi All rights reserved.
# Copyright (C) 2000 Namazu Project All rights reserved.
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

package html;
use strict;
require 'gfilter.pl';
my %map_entity_jisx0213 = (
    #nbsp => "a9a2",
    iexcl => "a9a3",	curren => "a9a4",	brvbar => "a9a5",
    copy => "a9a6",	ordf => "a9a7",	laquo => "a9a8",
    shy => "a9a9",	reg => "a9aa",	macr => "a9ab",
    sup2 => "a9ac",	sup3 => "a9ad",	middot => "a9ae",
    cedil => "a9af",	sup1 => "a9b0",	ordm => "a9b1",
    raquo => "a9b2",	frac14 => "a9b3",	frac12 => "a9b4",
    frac34 => "a9b5",	iquest => "a9b6",	Agrave => "a9b7",
    Aacute => "a9b8",	Acirc => "a9b9",	Atilde => "a9ba",
    Auml => "a9bb",	Aring => "a9bc",	AElig => "a9bd",
    Ccedil => "a9be",	Egrave => "a9bf",	Eacute => "a9c0",
    Ecirc => "a9c1",	Euml => "a9c2",	Igrave => "a9c3",
    Iacute => "a9c4",	Icirc => "a9c5",	Iuml => "a9c6",
    ETH => "a9c7",	Ntilde => "a9c8",	Ograve => "a9c9",
    Oacute => "a9ca",	Ocirc => "a9cb",	Otilde => "a9cc",
    Ouml => "a9cd",	Oslash => "a9ce",	Ugrave => "a9cf",
    Uacute => "a9d0",	Ucirc => "a9d1",	Uuml => "a9d2",
    Yacute => "a9d3",	THORN => "a9d4",	szlig => "a9d5",
    agrave => "a9d6",	aacute => "a9d7",	acirc => "a9d8",
    atilde => "a9d9",	auml => "a9da",	aring => "a9db",
    aelig => "a9dc",	ccedil => "a9dd",	egrave => "a9de",
    eacute => "a9df",	ecirc => "a9e0",	euml => "a9e1",
    igrave => "a9e2",	iacute => "a9e3",	icirc => "a9e4",
    iuml => "a9e5",	eth => "a9e6",	ntilde => "a9e7",
    ograve => "a9e8",	oacute => "a9e9",	ocirc => "a9ea",
    otilde => "a9eb",	ouml => "a9ec",	oslash => "a9ed",
    ugrave => "a9ee",	uacute => "a9ef",	ucirc => "a9f0",
    uuml => "a9f1",	yacute => "a9f2",	thorn => "a9f3",
    yuml => "a9f4",	OElig => "abab",	oelig => "abaa",
    Scaron => "aaa6",	scaron => "aab2",	ndash => "a3fc",
    euro => "a9a1",	sigmaf => "a6d9",	bull => "a3c0",
    alefsym => "a3dc",	harr => "a2f1",	empty => "a2c7",
    notin => "a2c6",	cong => "a2ed",	asymp => "a2ee",
    nsub => "a2c2",	oplus => "a2d1",	otimes => "a2d3",
    spades => "a6ba",	clubs => "a6c0",	hearts => "a6be",
    diams => "a6bc",
);

sub mediatype() {
    return ('text/html');
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
    my $magic = shift;
    $magic->addSpecials("text/html", "<!DOCTYPE HTML PUBLIC");
    $magic->addSpecials("text/html", "<!DOCTYPE html PUBLIC");
    $magic->addSpecials("text/html", "-//W3C//DTD XHTML");
    $magic->addSpecials("text/html", "-//W3C//DTD HTML");
    $magic->addSpecials("text/html", 'xmlns="http://www.w3.org/1999/xhtml"');
    $magic->addSpecials("text/html", "<meta http-equiv");
    $magic->addSpecials("text/html", "</HTML>");
    $magic->addSpecials("text/html", "</Html>");
    $magic->addSpecials("text/html", "</html>");
    $magic->addFileExts('\\.html$' => 'text/html');
    $magic->addFileExts('\\.html\\..+$' => 'text/html');
    return;
}

sub filter ($$$$$) {
    my ($orig_cfile, $cont, $weighted_str, $headings, $fields)
      = @_;
    my $cfile = defined $orig_cfile ? $$orig_cfile : '';

    util::vprint("Processing html file ...\n");

    if ($var::Opt{'robotexclude'}) {
	my $err = isexcluded($cont);
	return $err if $err;
    }

    html_filter($cont, $weighted_str, $fields, $headings);
    
    gfilter::line_adjust_filter($cont);
    gfilter::line_adjust_filter($weighted_str);
    gfilter::white_space_adjust_filter($cont);
    gfilter::show_filter_debug_info($cont, $weighted_str,
			   $fields, $headings);
    return undef;
}

# Check wheter or not the given URI is excluded.
sub isexcluded ($) {
    my ($contref) = @_;
    my $err = undef;

    if ($$contref =~ /META\s+NAME\s*=\s*([\'\"]?)ROBOTS\1\s+[^>]*
	CONTENT\s*=\s*([\'\"]?).*?(NOINDEX|NONE).*?\2[^>]*>/ix)  #"
    {
	$err = _("is excluded because of <meta name=\"robots\" ...>");
    }
    return $err;
}


sub html_filter ($$$$) {
    my ($contref, $weighted_str, $fields, $headings) = @_;

    html::escape_lt_gt($contref);
    $fields->{'title'} = html::get_title($contref, $weighted_str);
    html::get_author($contref, $fields);
    html::get_meta_tags($contref, $weighted_str, $fields);
    html::get_img_alt($contref);
    html::get_table_summary($contref);
    html::get_title_attr($contref);
    html::normalize_html_element($contref);
    html::erase_above_body($contref);
    html::weight_element($contref, $weighted_str, $headings);
    html::remove_html_elements($contref);
    # restore entities of each content.
    html::decode_entity($contref);
    html::decode_entity($weighted_str);
    html::decode_entity($headings);
    for my $key (keys %{$fields}) {
	html::decode_entity(\$fields->{$key});
    }
}

# Convert independent < > s into entity references for escaping.
# Substitute twice for safe.
sub escape_lt_gt ($) {
    my ($contref) = @_;

    $$contref =~ s/\s<\s/ &lt; /g;
    $$contref =~ s/\s>\s/ &gt; /g;
    $$contref =~ s/\s<\s/ &lt; /g;
    $$contref =~ s/\s>\s/ &gt; /g;
}

sub get_author ($$) {
    my ($contref, $fields) = @_;

    # <LINK REV=MADE HREF="mailto:ccsatoru@vega.aichi-u.ac.jp">

    if ($$contref =~ m!META\s+NAME\s*=\s*([\'\"]?)AUTHOR\1\s+[^>]*
	CONTENT\s*=\s*([\'\"]?)(.*?)\2[^>]*>!ix) { #"
	$fields->{'author'} = $3;
    } elsif ($$contref =~ m!<LINK\s[^>]*?HREF=([\"\'])mailto:(.*?)\1\s*>!i) { #"
	    $fields->{'author'} = $2;
    } elsif ($$contref =~ m!.*<ADDRESS[^>]*>([^<]*?)</ADDRESS>!i) {
	my $tmp = $1;
#	$tmp =~ s/\s//g;
	if ($tmp =~ /\b([\w\.\-]+\@[\w\.\-]+(?:\.[\w\.\-]+)+)\b/) {
	    $fields->{'author'} = $1;
	}
    }
}


# Get title from <title>..</title>
# It's okay to exits two or more <title>...</TITLE>. 
# First one will be retrieved.
sub get_title ($$) {
    my ($contref, $weighted_str) = @_;
    my $title = '';
    
    if ($$contref =~ s!<TITLE[^>]*>([^<]+)</TITLE>!!i) {
	$title = $1;
	$title =~ s/\s+/ /g;
	$title =~ s/^\s+//;
	$title =~ s/\s+$//;
	my $weight = $conf::Weight{'html'}->{'title'};
	$$weighted_str .= "\x7f$weight\x7f$title\x7f/$weight\x7f\n";
    } else {
	$title = $conf::NO_TITLE;
    }

    return $title;
}

# get foo bar from <META NAME="keywords|description" CONTENT="foo bar"> 
sub get_meta_tags ($$$) {
    my ($contref, $weighted_str, $fields) = @_;
    
    # <meta name="keywords" content="foo bar baz">

    my $weight = $conf::Weight{'metakey'};
    $$weighted_str .= "\x7f$weight\x7f$3\x7f/$weight\x7f\n" 
	if $$contref =~ /<meta\s+name\s*=\s*([\'\"]?) #"
	    keywords\1\s+[^>]*content\s*=\s*([\'\"]?)([^>]*?)\2[^>]*>/ix; #"

    # <meta name="description" content="foo bar baz">
    $$weighted_str .= "\x7f$weight\x7f$3\x7f/$weight\x7f\n" 
	if $$contref =~ /<meta\s+name\s*=\s*([\'\"]?)description #"
	    \1\s+[^>]*content\s*=\s*([\'\"]?)([^>]*?)\2[^>]*>/ix; #"

    if ($var::Opt{'meta'}) {
	my @keys = split '\|', $conf::META_TAGS;
	for my $key (@keys) {
	    while ($$contref =~ /<meta\s+name\s*=\s*([\'\"]?)$key #"
	       \1\s+[^>]*content\s*=\s*([\'\"]?)([^>]*?)\2[^>]*>/gix) 
	    {
		$fields->{$key} .= $3 . " ";
	    }
	    util::dprint("meta: $key: $fields->{$key}\n") 
		if defined $fields->{$key};
	}
    }
}

# Get foo from <IMG ... ALT="foo">
# It's not to handle HTML strictly.
sub get_img_alt ($) {
    my ($contref) = @_;

    $$contref =~ s/<IMG[^>]*\s+ALT\s*=\s*[\"\']?([^\"\']*)[\"\']?[^>]*>/ $1 /gi; #"
}

# Get foo from <TABLE ... SUMMARY="foo">
sub get_table_summary ($) {
    my ($contref) = @_;

    $$contref =~ s/<TABLE[^>]*\s+SUMMARY\s*=\s*[\"\']?([^\"\']*)[\"\']?[^>]*>/ $1 /gi; #"
}

# Get foo from <XXX ... TITLE="foo">
sub get_title_attr ($) {
    my ($contref) = @_;

    $$contref =~ s/<[A-Z]+[^>]*\s+TITLE\s*=\s*[\"\']?([^\"\']*)[\"\']?[^>]*>/ $1 /gi; #"
}

# Normalize elements like: <A HREF...> -> <A>
sub normalize_html_element ($) {
    my ($contref) = @_;

    $$contref =~ s/<([!\w]+)\s+[^>]*>/<$1>/g;
}

# Remove contents above <body>.
sub erase_above_body ($) {
    my ($contref) = @_;

    $$contref =~ s/^.*<body>//is;
}


# Weight a score of a keyword in a given text using %conf::Weight hash.
# This process make the text be surround by temporary tags 
# \x7fXX\x7f and \x7f/XX\x7f. XX represents score.
# Sort keys of %conf::Weight for processing <a> first.
# Because <a> has a tendency to be inside of other tags.
# Thus, it does'not processing for nexted tags strictly.
# Moreover, it does special processing for <h[1-6]> for summarization.
sub weight_element ($$$ ) {
    my ($contref, $weighted_str, $headings) = @_;

    for my $element (sort keys(%{$conf::Weight{'html'}})) {
	my $tmp = "";
	$$contref =~ s!<($element)>(.*?)</$element>!weight_element_sub($1, $2, \$tmp)!gies;
	$$headings .= $tmp if $element =~ /^H[1-6]$/i && ! $var::Opt{'noheadabst'} 
	    && $tmp;
	my $weight = $element =~ /^H[1-6]$/i && ! $var::Opt{'noheadabst'} ? 
	    $conf::Weight{'html'}->{$element} : $conf::Weight{'html'}->{$element} - 1;
	$$weighted_str .= "\x7f$weight\x7f$tmp\x7f/$weight\x7f\n" if $tmp;
    }
}

sub weight_element_sub ($$$) {
    my ($element, $text, $tmp) = @_;

    my $space = element_space($element);
    $text =~ s/<[^>]*>//g;
    $$tmp .= "$text " if (length($text)) < $conf::INVALID_LENG;
    $element =~ /^H[1-6]$/i && ! $var::Opt{'noheadabst'}  ? " " : "$space$text$space";
}


# determine whether a given element should be delete or be substituted with space
sub element_space ($) {
    $_[0] =~ /^($conf::NON_SEPARATION_ELEMENTS)$/io ? "" : " ";
}

# remove all HTML elements. it's not perfect but almost works.
sub remove_html_elements ($) {
    my ($contref) = @_;

    # remove all comments
    $$contref =~ s/<!--.*?-->//gs;

    # remove all elements
    $$contref =~ s!</?([A-Z]\w*)(?:\s+[A-Z]\w*(?:\s*=\s*(?:(["']).*?\2|[\w\-.]+))?)*\s*>!element_space($1)!gsixe;

}

# Decode a numberd entity. Exclude an invalid number.
sub decode_numbered_entity ($) {
    my ($num) = @_;
    return ""
	if $num >= 0 && $num <= 8 ||  $num >= 11 && $num <= 31 || $num >=127;
    sprintf ("%c",$num);
}

sub decode_entity_jisx0213($) {
    my $name = shift;
    my $euc = $map_entity_jisx0213{$name};
    if ($euc) {
      return pack "H4", $euc;
    } else {
      return '&'.$name.';';
    }
}

# Decode an entity. Ignore characters of right half of ISO-8859-1.
# Because it can't be handled in EUC encoding.
# This function provides sequential entities like: &quot &lt &gt;
sub decode_entity ($) {
    my ($text) = @_;

    return unless defined($$text);

    $$text =~ s/&#(\d{2,3})[;\s]/decode_numbered_entity($1)/ge;
    $$text =~ s/&#x([\da-f]+)[;\s]/decode_numbered_entity(hex($1))/gei;
    $$text =~ s/&quot[;\s]/\"/g; #"
    $$text =~ s/&amp[;\s]/&/g;
    $$text =~ s/&lt[;\s]/</g;
    $$text =~ s/&gt[;\s]/>/g;
    $$text =~ s/&nbsp[;\s]/ /g;
    $$text =~ s/&([A-Za-z0-9]+)[;\s]/&decode_entity_jisx0213($1)/ge;
}


# encode entities: only '<', '>', and '&'
sub encode_entity ($) {
    my ($tmp) = @_;

    $$tmp =~ s/&/&amp;/g;    # &amp; should be processed first
    $$tmp =~ s/</&lt;/g;
    $$tmp =~ s/>/&gt;/g;
    $$tmp;
}

1;
