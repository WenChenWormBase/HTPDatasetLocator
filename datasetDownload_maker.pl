#!/usr/bin/perl -w
#This part of code print out to the screen about its functions.
print "Create a csv file from the current SPELL dataset_table file.\n";
print "------------------------------------------------------------------\n\n";


my ($line, $datasetID, $datasetName, $pubmedID, $wbID, $url, $spe, $exprType, $title, $topicList, $tissue, $tmp_length);
my @tmp;
my @stuff;
my @topic;
my ($i, $s, $stuff_length);

#open (IN, "dataset_table_enriched.txt") || die "can't open dataset_table_enriched.txt!"; 	 
open (IN, "/home/wen/SPELL/TablesForSPELL/dataset_table_enriched.txt") || die "can't open dataset_table_enriched.txt!"; 	 
open (OUT, ">all_SPELL_datasets.csv") || die "can't open all_SPELL_datasets.csv!";
#print OUT "Dataset ID\tDataset Name\tWormBase Paper ID\tMethod\tSpecies\tTissue\tTopics\tTitle\tURL\n";
print OUT "Dataset ID\tDataset Name\tPubMed ID\tMethod\tSpecies\tTissue\tTopics\tTitle\n";

while ($line = <IN>) {
    chomp ($line);
    @tmp = ();
    @stuff = ();
    
    @tmp = split /\t/, $line;
    $tmp_length = @tmp;
    #if ($tmp_length != 17) {
    #	print "ERROR: wrong field column $tmp_length! $line\n";
    #}
    
    
    $datasetID = $tmp[0];
    $title = $tmp[6];
    #print "$tmp[6]\n";
    
    @stuff = split /\./, $tmp[2];
    $wbID = $stuff[0];
    ($datasetName, $stuff[0]) = split ".paper", $tmp[2];
    $datasetName = join '.', $datasetName, "csv";
    #($datasetID, $stuff[0]) = split ".paper", $tmp[2];
    #$datasetName = join '.', $datasetID, "csv";
    $url = "ftp:\/\/caltech.wormbase.org\/pub\/wormbase\/spell_download\/datasets\/$datasetName";

    @stuff = ();
    @stuff = split /\|/, $tmp[16];
    $stuff_length = @stuff;
    #print "$datasetID: $stuff_length ";
    #foreach $s (@stuff) {
	#print "$s, "; 
    #}
    #print "\n";
    
    $exprType = $stuff[0];
    $spe = $stuff[1];
    if ($tmp[16] =~ /Tissue Specific/) {
	$tissue = "Tissue Specific";
    } else {
	$tissue = "Whole Animal";
    }
    
    if ($tmp[16] =~ /Topic/) {
	@topic = ();
	$i = 0;
	foreach $s (@stuff) {
	    if ($s =~ /Topic/) {
		$topic[$i] = $s;
		$i++;
	    }
	}
	$topicList = join "|", @topic;
	#print "$datasetID: $stuff_length $i $topicList\n";

    } else {
	$topicList = "";
    }

    $pubmedID = $tmp[1];	
    #0: dataset ID
    #1: $PMID[$id]
    #2: $PaperID[$id].$specode.rs.paper
    #3: $gds
    #4: $gpl
    #5: $ChannelCount
    #6: $Title[$id]
    #7: $Abstract[$id]
    #8: $Cond_count[$id]
    #9: $numGene
    #10: $First_author[$id]
    #11: $AllAuthors[$id]
    #12: $Title[$id]
    #13: $Journal[$id]
    #14: $Year[$id]
    #15: $Cond_description[$id]
    #16: Method: RNAseq\|Species: $speName{$specode}$topicPaper{$paper}$tissuePaper{$paper}
    #print OUT "$datasetID\t$datasetName\t$wbID\t$exprType\t$spe\t$tissue\t$topicList\t$title\t$url\n";
    print OUT "$datasetID\t$datasetName\t$pubmedID\t$exprType\t$spe\t$tissue\t$topicList\t$title\n";
}
close (IN);


open (SCR, "/home/wen/LargeDataSets/Topic/scRNASeqDatasets.csv") || die "can't open scRNASeqDatasets.csv!"; 
my ($gpl, $gds, $hypGPL, $hypGDS, $labAtlas, $otherlinks);
$line = <SCR>;
while ($line = <SCR>) {
    chomp ($line);
    ($datasetID, $datasetName, $pubmedID, $exprType, $spe, $tissue, $topicList, $title, $gpl, $gds, $labAtlas, $otherlinks) = split /\t/, $line;
    #add color to title for scRNASeq
    $title = "\<font color \= \"green\">$title\<\/font\>";
    #hyperlink GPL
    if ($gpl eq "N.A.") {
	$hypGPL = "N.A.";
    } else {
	$hypGPL = "\<a href\=\"http\:\/\/www.ncbi.nlm.nih.gov\/geo\/query\/acc.cgi\?acc\=$gpl\" target=\"_blank\"\>$gpl\<\/a\>";
    }
    
    #hyperlink GSE 
    if ($gds eq "N.A.") {
	$hypGDS = "N.A.";
    } else {
	$hypGDS = "\<a href\=\"http\:\/\/www.ncbi.nlm.nih.gov\/geo\/query\/acc.cgi\?acc\=$gds\" target=\"_blank\"\>$gds\<\/a\>";
    }
    #build new title
    $title = "$title \<br\> GEO Record: $hypGPL, Platform: $hypGDS";

    if ($labAtlas ne "") {
	$labAtlas = "\<a href\=\"$labAtlas\"\>$labAtlas\<\/a\>";
	$title = "$title \<br\> Lab Atlas: $labAtlas";
    }

    if ($otherlinks ne "") {
	$otherlinks = "\<a href\=\"$otherlinks\"\>$otherlinks\<\/a\>";
	$title = "$title \<br\> Other resources: $otherlinks";
    }
    
    print OUT "$datasetID\t$datasetName\t$pubmedID\t$exprType\t$spe\t$tissue\t$topicList\t$title\n";    
}
close (SCR);
close (OUT);
