#!/usr/bin/env perl

# execute this before running:
# export PATH=/home/wiki/texlive/2015/bin/x86_64-linux:$PATH
use utf8;
use strict;
use warnings;
use Dancer qw/:script/;
use Dancer::Plugin::DBIC;
use File::Spec;
binmode STDOUT, ':encoding(UTF-8)';



my $schema = schema;
my $conference = config->{conference_name};
my $outdir = File::Spec->catdir(config->{appdir}, 'lanyards');
my $output = 'lanyards';
my $outtex = $output . '.tex';
my $outpdf = $output . '.pdf';

my @users = $schema->resultset('Conference')
  ->search({ name => $conference })
  ->search_related(conferences_attendees => { confirmed => 1 })
  ->search_related(user => {} => { order_by => 'last_name' })
  ->all;

my @chunks;


my $preamble = <<'EOF';
\documentclass[12pt]{article}
\usepackage{fontspec}
\setmainfont{TeX Gyre Pagella}
\usepackage[paperwidth=85mm,paperheight=60mm,%
  margin=5mm,nohead,nofoot]{geometry}
\usepackage[pages=all]{background}
\backgroundsetup{scale=0.75,color=black,opacity=0.2,angle=0,%
  contents={\includegraphics[width=\paperwidth]{bw-logo.png}}}

\pagestyle{empty}
\begin{document}
EOF


push @chunks, $preamble;

foreach my $user (@users) {
    my $name = $user->first_name . ' ' . $user->last_name;
    my $nick = $user->nickname || "~";
    my $body = <<"LATEX";

\\begin{center}
$conference

\\vfill

{\\LARGE\\textbf{$name}}

\\vfill

{\\large \\textbf{$nick}}

\\end{center}
\\clearpage

LATEX
    push @chunks, $body;
}

my $end = <<'EOF';
\end{document}
EOF

push @chunks, $end;

open (my $fh, '>:encoding(UTF-8)', File::Spec->catfile($outdir, $outtex))
  or die "Cannot open $outtex in $outdir: $!";
print $fh @chunks;
close $fh;

chdir $outdir or die $!;
for (1..3) {
    system(xelatex => '-interaction=nonstopmode', $outtex) == 0 or die;
}

