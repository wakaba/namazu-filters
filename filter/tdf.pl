# -*- Perl -*-
# TDF Filter for Namazu 2.0
# version 0.1.1
# 2001/02/05  TANAKA Yoji as Osakana <osakana@dive-in.to>
# 2001/02/06  TANAKA Tomonari <tom@morito.mgmt.waseda.ac.jp>
#
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
################################################################

package tdf;
no strict;
require 'util.pl';
require 'gfilter.pl';
require 'html.pl';

sub mediatype() {
    return ('text/plain; x-type=tdf');
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
    $magic->addFileExts('\\.tdf$', 'text/plain; x-type=tdf');
    $magic->addFileExts('\\.h2h$', 'text/plain; x-type=tdf');
    $magic->addFileExts('\\.hnf$', 'text/plain; x-type=tdf');
    return;
}

sub filter ($$$$$) {
    my ($orig_cfile, $contref, $weighted_str, $headings, $fields)
      = @_;
    my $cfile = defined $orig_cfile ? $$orig_cfile : '';

    my %mark;    # topic mark

    if (util::islang("ja")){
	$mark{'new'} = $tdf::mark->{ja}->{'new'} || "¡û";    # NEW
	$mark{'sub'} = $tdf::mark->{ja}->{'sub'} || "¡÷";    # SUB
	$mark{'end'} = $tdf::mark->{ja}->{'end'} || "¢§";    # end of topic summary
    } else {
	$mark{'new'} = $tdf::mark->{en}->{'new'} || "# ";
	$mark{'sub'} = $tdf::mark->{en}->{'sub'} || "@ ";
	$mark{'end'} = $tdf::mark->{en}->{'end'} || "--";
    }
    # start
    util::vprint("Processing tdf file ...\n");

    get_uri($cfile, $fields);
    tdf_filter($contref, $fields, $cfile, %mark);
    html::html_filter($contref, $weighted_str, $fields, $headings);
    $fields->{'summary'} = 
	make_summary($contref, $headings);

    gfilter::line_adjust_filter($contref);
    gfilter::line_adjust_filter($weighted_str);
    gfilter::white_space_adjust_filter($contref);
    gfilter::show_filter_debug_info($contref, $weighted_str,
			   $fields, $headings);
    return undef;
}

sub tdf_filter ($$$$)
{
    my ($contref, $fields, $cfile, %mark) = @_;
    
    $$contref =~ s/</&lt;/g;
    $$contref =~ s/>/&gt;/g;

    # convert filename to title (pickup as date)
    my $title;
    $title = $fields->{'title'};
    $$contref = "<title>$title</title>\n" . ($$contref) if $$contref;
    # /~$/
    $$contref =~ s/~\n/\n/g;
    
    # hide secret part
    my @lines = split("\n", $$contref);
    my $l = "";
    for (@lines){
	next if /^#/;
	next if /^HIDE/.../^\/HIDE/;
	next if /^SECRET/.../^\/SECRET/;	
	next if /^COMMENT/.../^\/COMMENT/;

	if (/^SNEW/.../^NEW/){
	    next unless /^NEW/;
	}
	if (/^SSUB/.../^(NEW|SUB)/){
	    next unless /^(NEW|SUB)/;
	}
	$l .= "$_\n";
    }
    $$contref = $l;

    # command transform
    $$contref =~ s!^NEW (.*)!<h1>$mark{'new'}$1</h1>$mark{'new'}$1!gm;
    $$contref =~ s!^SUB (.*)!<h1>$mark{'sub'}$1</h1>$mark{'sub'}$1!gm;
    $$contref =~ s/^CAT (.*)/\[$1\]/gm;

    # footer
    $$contref .= "<h1>$mark{'end'}</h1>" if $$contref;
#    $$contref .= $cfile;
}

sub make_summary ($$) {
    my ($contref, $headings) = @_;

    # pick up $conf::MAX_FIELD_LENGTH bytes string
    my $tmp = "";
    if ($$headings ne "") {
        $$headings =~ s/^\s+//;
        $$headings =~ s/\s+/ /g;
        $tmp = $$headings;
    }

    my $offset = 0;
    my $tmplen = 0;
    my $tmp2 = $$contref;

    while (($tmplen = $conf::MAX_FIELD_LENGTH + 1 - length($tmp)) > 0
           && $offset < length($tmp2))
    {
        $tmp .= substr $tmp2, $offset, $tmplen;
        $offset += $tmplen;
        $tmp =~ s/(([\xa1-\xfe]).)/$2 eq "\xa8" ? '': $1/ge;
        $tmp =~ s/([-=*\#])\1{2,}/$1$1/g;
    }

    my $summary = substr $tmp, 0, $conf::MAX_FIELD_LENGTH;
    my $kanji = $summary =~ tr/\xa1-\xfe/\xa1-\xfe/;
    $kanji ||= 0;
    $summary .= substr($tmp, $conf::MAX_FIELD_LENGTH, 1) if $kanji %2;
    $summary =~ s/^\s+//;
    $summary =~ s/\s+/ /g;   # normalize white spaces

    return $summary;
    
    return $$headings;
}

sub get_uri ($$)
{
    my ($cfile, $fields) = @_;
    
    if ($cfile =~ /^(.*)(\d{4,})\/(\d\d)\/(\d\d)\.tdf$/) {
	my $year = $2;
	my $month = $3;
	my $day = $4;
	my $part = "";
	if ($day < 10) {
	    $part = "a";
	} elsif ($day < 20) {
	    $part = "b";
	} else {
	    $part = "c";
	}
	my $uri;
	if ($tdf::mode eq 'static'){  # static
	    $uri = "d$year$month$part.html#$day";
	} else {
	    $uri = "?$year$month$day#$day";
#	    $uri = "?$year$month$part#$day";    # partly
	}
	$uri = $tdf::diary_url . $uri;
	$uri =~ s/%7E/~/i;
	$fields->{'uri'} = $uri;
	$fields->{'title'} = "$year/$month/$day";
	$fields->{'author'} = $tdf::author;
    }
}
1;

# ChangeLog
# 2001/02/06  TANAKA Tomonari <tom@morito.mgmt.waseda.ac.jp>
#   * revise tdf_filter()

