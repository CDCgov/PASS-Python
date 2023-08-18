#!/usr/bin/perl

$filenameA = $ARGV[0];
#$filenameB = $ARGV[1];
#$filenameOut = $ARGV[2];
 
open $FILEA, "< $filenameA";
#open $FILEB, "< $filenameB";
#open $OUTFILE, "> $filenameOut";
my $SabinStart=0;
my $SabinEnd=0;
my $Sabin;

print "qseqid\tsseqid\tpident\tqlen\tlen\tmm\tgap\tqstart\tqend\tsstart\tsend\tevalue\tbit\tpoltype\tpolstart\tpolend\tqseq\tsseq\n";
while(<$FILEA>) {
    chomp;
    @fields = split('\t', $_);
    if ($fields[1] =~ m/VP1_PV1/) {
        $SabinStart = $fields[9]+2480;
        $SabinEnd = $fields[10]+2480;
        $Sabin = PV1;
  } elsif ($fields[1] =~ m/VP1_PV2/) {
        $SabinStart = $fields[9]+2482;			
        $SabinEnd = $fields[10]+2482; 
        $Sabin = PV2;
  } elsif ($fields[1] =~ m/VP1_PV3/) {
        $SabinStart = $fields[9]+2328;
        $SabinEnd = $fields[10]+2328; 
        $Sabin = PV3;
  } elsif ($fields[1] =~ m/VP2_PV1/) {
        $SabinStart = $fields[9]+950;
        $SabinEnd = $fields[10]+950; 
        $Sabin = PV1;
  } elsif ($fields[1] =~ m/VP2_PV2/) {
        $SabinStart = $fields[9]+955;
        $SabinEnd = $fields[10]+955; 
        $Sabin = PV2;
  } elsif ($fields[1] =~ m/VP2_PV3/) {
        $SabinStart = $fields[9]+834;
        $SabinEnd = $fields[10]+834; 
        $Sabin = PV3;
  } elsif ($fields[1] =~ m/VP3_PV1/) {
        $SabinStart = $fields[9]+1766;
        $SabinEnd = $fields[10]+1766; 
        $Sabin = PV1;
  } elsif ($fields[1] =~ m/VP3_PV2/) {
        $SabinStart = $fields[9]+1768;
        $SabinEnd = $fields[10]+1768; 
        $Sabin = PV2;
  } elsif ($fields[1] =~ m/VP3_PV3/) {
        $SabinStart = $fields[9]+1620;
        $SabinEnd = $fields[10]+1620; 
        $Sabin = PV3;
  } elsif ($fields[1] =~ m/VP4_PV1/) {
        $SabinStart = $fields[9]+743;
        $SabinEnd = $fields[10]+743; 
        $Sabin = PV1;
  } elsif ($fields[1] =~ m/VP4_PV2/) {
        $SabinStart = $fields[9]+748;
        $SabinEnd = $fields[10]+748; 
        $Sabin = PV2;
  } elsif ($fields[1] =~ m/VP4_PV3/) {
        $SabinStart = $fields[9]+627;
        $SabinEnd = $fields[10]+627; 
        $Sabin = PV3;
  } elsif ($fields[1] =~ m/5UTR_PV1/) {
        $SabinStart = $fields[9];
        $SabinEnd = $fields[10]; 
        $Sabin = PV1;
  } elsif ($fields[1] =~ m/5UTR_PV2/) {
        $SabinStart = $fields[9];
        $SabinEnd = $fields[10]; 
        $Sabin = PV2;
  } elsif ($fields[1] =~ m/5UTR_PV3/) {
        $SabinStart = $fields[9];
        $SabinEnd = $fields[10]; 
        $Sabin = PV3;
  } elsif ($fields[1] =~ m/2A_PV1/) {
        $SabinStart = $fields[9]+3386;
        $SabinEnd = $fields[10]+3386; 
        $Sabin = PV1;
  } elsif ($fields[1] =~ m/2A_PV2/) {
        $SabinStart = $fields[9]+3385;
        $SabinEnd = $fields[10]+3385; 
        $Sabin = PV2;
  } elsif ($fields[1] =~ m/2A_PV3/) {
        $SabinStart = $fields[9]+3198;
        $SabinEnd = $fields[10]+3198; 
        $Sabin = PV3;
  } elsif ($fields[1] =~ m/2B_PV1/) {
        $SabinStart = $fields[9]+3833;
        $SabinEnd = $fields[10]+3833; 
        $Sabin = PV1;
  } elsif ($fields[1] =~ m/2B_PV2/) {
        $SabinStart = $fields[9]+3832;
        $SabinEnd = $fields[10]+3832; 
        $Sabin = PV2;
  } elsif ($fields[1] =~ m/2B_PV3/) {
        $SabinStart = $fields[9]+3630;
        $SabinEnd = $fields[10]+3630; 
        $Sabin = PV3;
  } elsif ($fields[1] =~ m/2C_PV1/) {
        $SabinStart = $fields[9]+4124;
        $SabinEnd = $fields[10]+4124; 
        $Sabin = PV1;
  } elsif ($fields[1] =~ m/2C_PV2/) {
        $SabinStart = $fields[9]+4123;
        $SabinEnd = $fields[10]+4123; 
        $Sabin = PV2;
  } elsif ($fields[1] =~ m/2C_PV3/) {
        $SabinStart = $fields[9]+3921;
        $SabinEnd = $fields[10]+3921; 
        $Sabin = PV3;
  } elsif ($fields[1] =~ m/3A_PV1/) {
        $SabinStart = $fields[9]+5111;
        $SabinEnd = $fields[10]+5111; 
        $Sabin = PV1;
  } elsif ($fields[1] =~ m/3A_PV2/) {
        $SabinStart = $fields[9]+5110;
        $SabinEnd = $fields[10]+5110; 
        $Sabin = PV2;
  } elsif ($fields[1] =~ m/3A_PV3/) {
        $SabinStart = $fields[9]+4911;
        $SabinEnd = $fields[10]+4911; 
        $Sabin = PV3;
  } elsif ($fields[1] =~ m/3B_PV1/) {
        $SabinStart = $fields[9]+5372;
        $SabinEnd = $fields[10]+5372; 
        $Sabin = PV1;
  } elsif ($fields[1] =~ m/3B_PV2/) {
        $SabinStart = $fields[9]+5371;
        $SabinEnd = $fields[10]+5371; 
        $Sabin = PV2;
  } elsif ($fields[1] =~ m/3B_PV3/) {
        $SabinStart = $fields[9]+5166;
        $SabinEnd = $fields[10]+5166; 
        $Sabin = PV3;
  } elsif ($fields[1] =~ m/3C_PV1/) {
        $SabinStart = $fields[9]+5438;
        $SabinEnd = $fields[10]+5438; 
        $Sabin = PV1;
  } elsif ($fields[1] =~ m/3C_PV2/) {
        $SabinStart = $fields[9]+5437;
        $SabinEnd = $fields[10]+5437; 
        $Sabin = PV2;
  } elsif ($fields[1] =~ m/3C_PV3/) {
        $SabinStart = $fields[9]+5235;
        $SabinEnd = $fields[10]+5235; 
        $Sabin = PV3;
  } elsif ($fields[1] =~ m/3D_PV1/) {
        $SabinStart = $fields[9]+5987;
        $SabinEnd = $fields[10]+5987; 
        $Sabin = PV1;
  } elsif ($fields[1] =~ m/3D_PV2/) {
        $SabinStart = $fields[9]+5986;
        $SabinEnd = $fields[10]+5986; 
        $Sabin = PV2;
  } elsif ($fields[1] =~ m/3D_PV3/) {
        $SabinStart = $fields[9]+5781;
        $SabinEnd = $fields[10]+5781; 
        $Sabin = PV3;
  } elsif ($fields[1] =~ m/3UTR_PV1/) {
        $SabinStart = $fields[9]+7370;
        $SabinEnd = $fields[10]+7370; 
        $Sabin = PV1;
  } elsif ($fields[1] =~ m/3UTR_PV2/) {
        $SabinStart = $fields[9]+7369;
        $SabinEnd = $fields[10]+7369;
        $Sabin = PV2; 
  } elsif ($fields[1] =~ m/3UTR_PV3/) {
        $SabinStart = $fields[9]+7161;
        $SabinEnd = $fields[10]+7161; 
        $Sabin = PV3;
  }    


    print "$fields[0]\t$fields[1]\t$fields[2]\t$fields[3]\t$fields[4]\t$fields[5]\t$fields[6]\t$fields[7]\t$fields[8]\t$fields[9]\t$fields[10]\t$fields[11]\t$fields[12]\t$Sabin\t$SabinStart\t$SabinEnd\t$fields[13]\t$fields[14]\n";
}

=pod
close FILE
        print $OUTFILE $_;
        $_ = <$FILEA>;
        print $OUTFILE $_; 
        $_ = <$FILEA>;
        print $OUTFILE $_; 
        $_ = <$FILEA>;
        print $OUTFILE $_; 

        $_ = <$FILEB>;
        print $OUTFILE $_; 
        $_ = <$FILEB>;
        print $OUTFILE $_;
        $_ = <$FILEB>;
        print $OUTFILE $_;
        $_ = <$FILEB>;
        print $OUTFILE $_;
}
=cut
 


