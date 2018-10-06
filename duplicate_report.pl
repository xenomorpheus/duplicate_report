#!/usr/bin/env perl

=encoding utf8

=head1 NAME

duplicate_report.pl - Scan directory(s) looking for exact file duplicates.

=head1 SYNOPSIS

duplicate_report.pl [options]

=head1 DESCRIPTION

Scan directory(s) looking for exact file duplicates.

Hint:
When reporting duplicates, the file found first will be reported as the original,
so order the directories on the command line with preferred directories first.

=head1 OPTIONS

=over 4

=item B<--dir>              directory to scan. Multiple dirs permitted.

=item B<--duplicate-delete> delete duplicates if set

=item B<--debug>            debug level

=item B<--help>             display brief help message

=item B<--version>          display program version

=back

=head1 DIAGNOSTICS

Each file match is reported to STDOUT as follows:

 Match:
 ORIG: myPath/myFile1
 DUPE: myPath/myFile2

 WARN: prefix used for warnings.
 INFO: prefix used for information

=head1 EXAMPLES

./duplicate_report.pl --dir dir1 

./duplicate_report.pl --dir dir1 --dir dir2

./duplicate_report.pl --dir dir1 --dir dir2 --duplicate-delete=1

=head1 FILES

Only reads files in the dirs you specify as options.

=head1 AUTHOR

Written by Mike Bruins 20/6/2012, 13/3/2015, 6/10/2018.

Years from now we will look back at this code style and think
how dated it looks. In my defence PBP reports no criticisms.

=cut

######################################################################
## Pragmas

use Modern::Perl;

# Program version
our $VERSION = '1.01';

######################################################################
## Required Libraries

# CPAN
use Carp qw(carp confess);
use autodie;
use Getopt::Long qw(:config auto_help auto_version);
use Pod::Usage;
use File::Find;
use Digest::MD5;
use FileHandle;

# Custom

######################################################################
## Constants


######################################################################
## Global

my $global_debug = 0;
my $global_duplicate_delete = 0;
my $global_md5_digest = Digest::MD5->new;
my %global_seen_file;
my $global_file_count = 0;

######################################################################

=head2 wanted

=head3 DESCRIPTION

This routine is called by find().

=head3 ASSUMPTIONS

=head3 PARAMETERS

   NONE

=head3 Calling Example
   
     find(\&wanted, $dir);

=cut

# Note file is fully pathed and we don't chdir.
sub wanted {
    my $file = $_;
    if ($global_debug >= 5){
      warn "DEBUG:(5): file: - $file\n";
    }
    # Skip non-plain files.
    if (not -f $file){
        return;
    }
    # Skip empty files
    if (not -s _){
        return;
    }
    # Skip empty files
    if (not -r _){
        warn "WARN: Warning: Can't read file $file\n";
        return;
    }
    if ((++$global_file_count % 200 ) == 0 ){
        warn "INFO: File count $global_file_count\n";
    }
    $global_md5_digest->reset;
    my $fh = FileHandle->new($file,'r') || confess "Failed to read $file because $!";
    $global_md5_digest->addfile($fh);
    my $digest = $global_md5_digest->hexdigest();
    if ($global_seen_file{$digest}){
        print "Match:\n";
        print "ORIG: ".$global_seen_file{$digest}."\n";
        if ($global_duplicate_delete){
          if (unlink($file)){
            print "DUPE: Deleted $file\n";
          }
          else{
            warn "WARN: Failed to delete '$file' because $!";
          }
        }
        else{
          print "DUPE: $file\n";
        }
    }
    else{
        $global_seen_file{$digest} = $file;
    }
    return;

} ## end sub wanted

MAIN: {

    my (@dir);
    GetOptions( 
       'debug=i'            => \$global_debug,
       'duplicate-delete=i' => \$global_duplicate_delete,
       'dir=s@'             => \@dir
    ) or pod2usage(1);

    if (! @dir){
            pod2usage( -verbose => 1, -message => "Error: no folders supplied\n", );
    }

    foreach my $dir (@dir){
        if ( not -d $dir ) {
            pod2usage( -verbose => 1, -message => "Error: Non-directory supplied - '$dir'\n", );
        }
    }
    warn "INFO: Working. dir(s): ".join(',',@dir)."\n";
    find( { wanted => \&wanted, no_chdir => 1, } , @dir );
    warn "INFO: Done. Total files checked=$global_file_count\n";
} ## end sub main

