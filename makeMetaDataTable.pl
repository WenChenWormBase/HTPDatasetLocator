#!/usr/bin/perl -w

use strict;
use Ace;

my @mrExp;
my @anaExp;
my @tmp;
my @stuff;
my @remark;
my %PaperGDS;
my %PaperPMID;
my %PaperGPL;
my %mrExpGSM;
my ($line, $TotalColumns, $r, $m, $gsm, $gse, $paper, $pmid, $p, $platform, $gpl, $condition, $database, $spe, $type);

my ($condA, $condB, $aoTerm, $aoTermA, $aoTermB, $lsTerm, $lsTermA, $lsTermB, $strain, $geno, $genoA, $genoB, $treatment, $treatmentA, $treatmentB);

print "This script create Microarray_experiment table from current WS release.\n";

my $acedbpath='/home/citace/WS/acedb/';
#my $acedbpath='/home/citace/citace/';
my $tace='/usr/local/bin/tace';

print "connecting to database... ";
my $db = Ace->connect(-path => $acedbpath,  -program => $tace) || die print "Connection failure: ", Ace->error;

open (OUT1, ">allMetaDataTable.csv") || die "cannot open $!\n";
print OUT1 "Paper\tPMID\tGSE\tPlatform\tExperiment\tType\tGSM\tTissue\tLife_stage\tGenotype\tTreatment\tSpecies\n";

#---------------Get GEO info -----------------------------

open (GEOT, "/home/wen/LargeDataSets/Microarray/CurationLog/FindID/MAPaperGSETable.txt") || die "can't open $!";
while($line = <GEOT>){
    chomp ($line);
    @tmp=split("\t", $line);
    $TotalColumns = @tmp;
    #print "$TotalColumns\n";
    next unless ($TotalColumns == 5);
    $PaperGDS{$tmp[1]} = $tmp[4];
    $PaperGPL{$tmp[1]} = $tmp[3];
    #$PaperPMID{$tmp[1]} = $tmp[2];
    #print "$tmp[1] $PaperGDS{$tmp[1]} $PaperGPL{$tmp[1]}\n";
}
close (GEOT);

#---------Build PMID-WBPaper ID hash --------------------
my $query="query find Paper Database = MEDLINE";
my @paperList=$db->find($query);
my $totalPaper = @paperList;

foreach $paper (@paperList) {
        $database = $paper->get('Database', 2);
	if ($database eq "PMID") {
	    $pmid=$paper->get('Database', 3);
	    $PaperPMID{$paper} = $pmid;
	} 
}
print "$totalPaper WormBase papers found with medline accession number.\n"; 

#------------Build AO Name hash-------------------------------------------
$query="QUERY FIND Condition Tissue; follow Tissue";
my ($a, $aname, $def);
my %AOName;
my @AO = $db->find($query);

open (OUT2, ">AnatomyTable.csv") || die "cannot open $!\n";
print OUT2 "Anatomy name\tAnatomy term\tDefinition\n";
foreach $a (@AO) {
        if ($a->Term) {
	    $aname = $a->Term;
	    $AOName{$a} = $aname;
	    if ($a->Definition) {
		$def = $a->Definition;
		print OUT2 "$aname\t$a\t$def\n";
	    }
	}
}
close (OUT2);
print scalar @AO, " Anatomy_term involved in Microarray.\n";
#------------------Done--------------------------------------------------


#------------Build Life stage Name hash-------------------------------------------
$query="QUERY FIND Condition Life_stage; follow Life_stage";
my ($ls, $lsname);
my %LSName;
my @LS = $db->find($query);

open (OUT3, ">LifeStageTable.csv") || die "cannot open $!\n";
print OUT3 "Anatomy name\tAnatomy term\tDefinition\n";
foreach $ls (@LS) {
        if ($ls->Public_name) {
	    $lsname = $ls->Public_name;
	    $LSName{$ls} = $lsname;
	    if ($ls->Definition){
		$def = $ls->Definition;
		print OUT3 "$lsname\t$ls\t$def\n";
	    }
	}
}
close (OUT3);

print scalar @LS, " Life_stage involved in Microarray.\n";
#------------------Done--------------------------------------------------


#-----------------Build Microarray Experiment table---------------------------
$query="find Microarray_experiment";

@mrExp = $db->find($query);
foreach $m (@mrExp) {
        $type = "microarray"; 
        if ($m->Reference) {
	    @tmp = $m->Reference;
	    $paper = $tmp[0];
	    @tmp = ();
	    
	    if ($PaperPMID{$paper}) {
		$pmid = $PaperPMID{$paper};
	    } else {
		$pmid = "N.A.";
	    }

	    if ($m-> Species) {
		$spe = $m-> Species;
	    } else {
		$spe = "N.A.";
	    }
	    
	    if ($PaperGDS{$paper}) {
		$gse = $PaperGDS{$paper};
	    } else {
		$gse = "N.A.";
	    }

	    if ($PaperGPL{$paper}) {
		$gpl = $PaperGPL{$paper};	
	    } else {
		$gpl = "GPL?";
	    }
	    
	    if ($m->Microarray) {
	       $p = $m->Microarray;
	       if ($p =~ /^GPL/) {
		   $gpl = $p;
		   $platform = $p->Chip_info;  
	       } else {
		   $platform = $p;
	       }
	    } else {
		$platform = "N.A.";
	    }	 	    
	    #$platform = "$gpl($platform)";


	} else { # if there is no reference
	    $paper = "N.A.";
	    $pmid = "N.A.";
	    $gse = "N.A.";
	    if ($m->Microarray) {
		$platform = $m->Microarray;
	    } else {
		$platform = "N.A.";
	    }
	}

	#get GSM record
	$gsm = "N.A.";
	if ($m->Remark) {
	    @remark = $m->Remark;
	} 
	foreach $r (@remark) {
	    if ($r =~ /GEO record/) {
		$gsm = $r;
		#($stuff[0], $stuff[1]) = split '"', $r;
		#($stuff[3], $stuff[4]) = split 'GSM', $stuff[1];
		#$gsm = "GSM$stuff[3]";
		#print "$gsm\n";
	    }
	}

	#get condition objects
	if ($m->Microarray_sample) { #single channel experiment
	    $condition = $m->Microarray_sample; 

	    $geno = GetGenotype($condition);
	    $aoTerm = GetTissue($condition);
	    $lsTerm = GetLifeStage($condition);
	    $treatment = GetTreatment($condition);

	} elsif ($m->Sample_A) { #dual channel experiment
	    $condition = $m->Sample_A;
	    $genoA = GetGenotype($condition);
	    $aoTermA = GetTissue($condition);
	    $lsTermA = GetLifeStage($condition);
	    $treatmentA = GetTreatment($condition);

	    if ($m->Sample_B) {
		$condition =  $m->Sample_B;

		$genoB = GetGenotype($condition);
		$aoTermB = GetTissue($condition);
		$lsTermB = GetLifeStage($condition);
		$treatmentB = GetTreatment($condition);
	    } else {
		print "ERROR! no Sample_B for $m!\n";
		$aoTermB = "N.A.";
		$lsTermB = "N.A.";
		$genoB = "N.A.";
		$treatmentB = "N.A."		
	    }
	    
	    $geno = join " vs. ", $genoA,, $genoB;
	    $aoTerm = join " vs. ", $aoTermA, $aoTermB;
	    $lsTerm = join " vs. ", $lsTermA, $lsTermB;
	    $treatment = join " vs. ", $treatmentA, $treatmentB;

	} else {
	    #$condition = "N.A.";
	    $aoTerm = "N.A.";
	    $lsTerm = "N.A.";
	    $geno = "N.A.";
	    $treatment = "N.A."
	}


	#print the results
	if ($platform) {
	    #do nothing
	} else {
	    print "ERROR! $m contains no platform info!\n";
	}
	print OUT1 "$paper\t$pmid\t$gse\t$gpl($platform)\t$m\t$type\t$gsm\t$aoTerm\t$lsTerm\t$geno\t$treatment\t$spe\n";

}
print scalar @mrExp, " microarray experiments found in database.\n";


$query="QUERY Find Analysis RNAseq* OR TAR* OR MassSpec*; Title = *";

@anaExp = $db->find($query);
foreach $m (@anaExp) {
  
    if ($m->Reference) {
	    @tmp = $m->Reference;
	    $paper = $tmp[0];
	    @tmp = ();
	    
	    if ($PaperPMID{$paper}) {
		$pmid = $PaperPMID{$paper};
	    } else {
		$pmid = "N.A.";
	    }

	    #if ($PaperGDS{$paper}) {
		#$gse = $PaperGDS{$paper};
	    #} else {
		$gse = "N.A.";
	    #}

	    #if ($PaperGPL{$paper}) {
		#$gpl = $PaperGPL{$paper};	
	    #} else {
		$gpl = "N.A.";
	    #}
	    
	    $gsm = "N.A.";
	    if ($m -> Database) {
		        $database = $m->get('Database', 2);
			if ($database eq "SRA") {
			    #print "SRA entry: $m\n";
			    $gsm=$m->get('Database', 3);
			    $gsm = "SRA ID: $gsm";
			}
	    }
	    
	    if ($m =~ /^RNASeq/) {
		$platform = "RNASeq";
		$type = "RNASeq";
	    } elsif ($m =~ /^TAR/)  {
		$platform = "Tiling Array";
		$type = "Tiling Array";
	    } elsif ($m =~ /^MassSpec/) {	 	    
		$platform = "Proteomics";
		$type = "Proteomics";
	    } else {
		$platform = "N.A.";
		$type = "N.A.";
	    }
	    
     } else { # if there is no reference
	    $paper = "N.A.";
	    $pmid = "N.A.";
	    $gse = "N.A.";
	    $gpl = "N.A.";
	    $gsm = "N.A.";
	    $platform = "N.A.";
	    $type = "N.A.";
	    
     }

	#get condition objects
	if ($m->Sample) { #single channel experiment
	    $condition = $m->Sample; 
	    
	    if ($condition -> Species) {
		$spe = $condition -> Species;
	    } else {
		$spe = "N.A.";
	    }

	    $geno = GetGenotype($condition);
	    $aoTerm = GetTissue($condition);
	    $lsTerm = GetLifeStage($condition);
	    $treatment = GetTreatment($condition);
	} else { 
	    #$condition = "N.A.";
	    $aoTerm = "N.A.";
	    $lsTerm = "N.A.";
	    $geno = "N.A.";
	    $treatment = "N.A."
	}
	
	#print the results
	if ($platform) {
	    #do nothing
	} else {
	    print "ERROR! $m contains no platform info!\n";
	}
	print OUT1 "$paper\t$pmid\t$gse\t$gpl($platform)\t$m\t$type\t$gsm\t$aoTerm\t$lsTerm\t$geno\t$treatment\t$spe\n";

}
print scalar @anaExp, " RNAseq, tiling array, or proteomics experiments found in database.\n";


close (OUT1);
$db->close();


sub GetGenotype {

	    if ($condition -> Genotype) {
		@tmp = $condition -> Genotype;
		$geno = join "\|", @tmp;
		@tmp = ();
	    } elsif ($condition -> Strain) {
		$strain = $condition -> Strain;
		if ($strain-> Genotype) {
		    $geno = $strain -> Genotype;
		} else {
		    $geno = $strain;
		}
	    } else {
		$geno = "N.A.";
	    }

	    return $geno;
}


sub GetTissue {

	    if ($condition->Tissue) {
		@tmp = $condition->Tissue;
		
		foreach (@tmp) {
		    if ($AOName{$_}) {
			$aname = $AOName{$_};
			$_ = "$_($aname)";
		    }
		}

		$aoTerm = join ",", @tmp;
		#print "$paper - $aoTerm\n";
		@tmp = ();
	    } else {
		$aoTerm = "Whole Animal";
	    }

	    return $aoTerm;
}

sub GetLifeStage {
    
	    if ($condition -> Life_stage) {
		@tmp = $condition -> Life_stage;

		foreach (@tmp) {
		    if ($LSName{$_}) {
			$lsname = $LSName{$_};
			$_ = "$_($lsname)";
		    }
		}

		$lsTerm = join ",", @tmp;
		@tmp = ();
	    } else {
		$lsTerm = "N.A.";
	    }

	    return $lsTerm;
}

sub GetTreatment {
    
	    if ($condition -> Treatment) {
		@tmp = $condition -> Treatment;
		$treatment = join "\|", @tmp;
		@tmp = ();
	    } else {
		$treatment = "N.A.";
	    }

	    return $treatment;
}

