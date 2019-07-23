#!usr/bin/perl
#model POLII binding significance
use warnings;

print "\nFiles should be either tab delimited .gff files, or .bedgraph files, with values for each GATC fragment\n\n";
@infiles = glob("*.bedgraph");
@infiles = glob("*.gff") unless scalar(@infiles);

$file_num = @infiles; if($file_num ==0){die "\nNo files detected! - make sure they are .gff or .bedgraph files\n"};
	
use Cwd;
my $dir = getcwd;
$dir = substr($dir, 2);    # gives current directory for calling up other perl programs


$rep_num = 0;
    
print "Files for processing are:\n\n";

foreach $a (@infiles){
	if($a =~ m/rep1/){$path1 = $a; chomp $path1; print "1st replicate is $a\n"; $rep_num = $rep_num + 1;}
	if($a =~ m/rep2/){$path2 = $a; chomp $path2; print "2nd replicate is $a\n"; $rep_num = $rep_num + 1;}
	if($a =~ m/rep3/){$path3 = $a; chomp $path3; print "3rd replicate is $a\n"; $rep_num = $rep_num + 1;}
	}

if($file_num != $rep_num){die "\n\nNumber of files does not match number of replicate data files\n- make sure all the replicate data files contain \"rep1\" or \"rep2\" etc\n";}


print "\nNumber of replicates is $rep_num\n";
if($rep_num == 1){$paths = $path1;}
if($rep_num == 2){$paths = "$path1\t$path2";}
if($rep_num == 3){$paths = "$path1\t$path2\t$path3";}

print "\nEnter name for analysis\n\n";
$exp_name = <STDIN>;
chomp $exp_name;

print "\nEnter FDR threshold \(usually 0.01 \(1 percent\)\)\n\n";
$FDR_thres = <STDIN>;
chomp $FDR_thres;


#print "\nEnter log2 ratio threshold \(usually 0.585 - 1.5 fold\)\n\n";
#$ratiothres = <STDIN>;
#chomp $ratiothres;

#$ratiothres = 0.2;


mkdir 'POLII_analysis_for_'."$exp_name", 0755 or die "\nCan't make analysis directory!\n";
mkdir 'POLII_analysis_for_'."$exp_name".'/logfiles', 0755 or die "\nCan't make analysis directory!\n";
mkdir 'POLII_analysis_for_'."$exp_name".'/temp', 0755 or die "\nCan't make analysis directory!\n";

mkdir 'POLII_analysis_for_'."$exp_name".'/Filtered_results', 0755 or die "\nCan't make filtered results directory!\n";
mkdir 'POLII_analysis_for_'."$exp_name".'/Filtered_results/Unique_gene_lists', 0755 or die "\nCan't make Unique gene lists directory!\n";

##################################################################

system("$dir/sub_programs/make_average_file.pl", "$exp_name", "$paths", "$rep_num");

#####################  analyse real data from all three replicates #######################

system("$dir/sub_programs/analyse_real_POLII_data.pl", "$exp_name", "$path1", "1");  

if($rep_num > 1){system("$dir/sub_programs/analyse_real_POLII_data.pl", "$exp_name", "$path2", "2");}

if($rep_num > 2){system("$dir/sub_programs/analyse_real_POLII_data.pl", "$exp_name", "$path3", "3");}

##################### now to randomise data and assess FDR ################################

chrom_analysis("2L");
chrom_analysis("2R");
chrom_analysis("3L");
chrom_analysis("3R");
chrom_analysis("4");
chrom_analysis("X");

sub chrom_analysis{  ####don't forget to close bracket!
	
my $chrom = shift;

$replicate = 1;

while($replicate < ($rep_num + 1)){

system("$dir/sub_programs/analyse_distribution.pl", "$exp_name", "$replicate", "$chrom");  

system("$dir/sub_programs/model_FDR_values.pl", "$exp_name", "$replicate", "$chrom"); 

system("$dir/sub_programs/model_variables.pl", "$exp_name", "$replicate", "$chrom"); 

system("$dir/sub_programs/calculate_transcript_FDR_values.pl", "$exp_name", "$replicate", "$chrom"); 


$replicate = $replicate + 1;
}

system("$dir/sub_programs/merge_replicate_data.pl", "$exp_name", "$chrom", "$rep_num"); 

}

system("$dir/sub_programs/make_just_genes_file.pl", "$exp_name");

system("$dir/sub_programs/filter_gene_list.pl", "$exp_name");

system("$dir/sub_programs/make_unique_gene_lists.pl", "$exp_name");


print "\nAll done!\n";


print "\nDo you wish to delete temporary files? \(Yes or No\)\n";
$answer = <STDIN>;
chomp $answer ;

if($answer =~ m/y/i){


use File::Path;

rmtree 'POLII_analysis_for_'."$exp_name".'\logfiles', 0755 or die "\nCan't delete logfiles directory!\n";
rmtree 'POLII_analysis_for_'."$exp_name".'\temp', 0755 or die "\nCan't delete logfiles directory!\n";

print "\nTemporary files deleted\n";

}