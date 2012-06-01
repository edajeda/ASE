#! /bin/bash -l
# download the software and DB
wget 'http://research-pub.gene.com/gmap/src/gmap-gsnap-2012-05-15.tar.gz'
wget 'http://research-pub.gene.com/gmap/genomes/hg19.tar'
wget 'ftp://hgdownload.cse.ucsc.edu/goldenPath/hg19/database/snp135.txt.gz'


#set vars
annotdir='/bubo/home/h24/alvaj/glob/annotation/gsnap'
splicefile=${annotdir}/'splicesitesfilechr'
refdir=${annotdir}/gmapdb
ref=hg19
snpdir=${annotdir}/dbsnp
snpfile=dbsnp135


### 
#SNPs
###
# downloaded the needed file snp134,snp135common, 
cd $snpdir
wget 'ftp://hgdownload.cse.ucsc.edu/goldenPath/hg19/database/snp135Common.txt.gz'

#reformat
gunzip -c snp135Common.txt.gz | /bubo/home/h24/alvaj/opt/gmap-2012-05-15/util/dbsnp_iit  -w 3  > ${snpfile}.txt &

(cat ${snpfile}.txt | /bubo/home/h24/alvaj/opt/gmap-2012-05-15/src/iit_store -o $snpfile >${snpfile}.iitstore.out) >& ${snpfile}.iitstore.err &

(snpindex -D $refdir -d $ref -V $snpdir -v $snpfile ${snpfile}.iit >snpindex.out) >& snpindex.err &


###
# Splice sites , to generate a splice site index---***splicesite***
###
cat Homo_sapiens.GRCh37.59.gtf |/bubo/home/h24/alvaj/glob/annotation/gsnap/gmap-2012-05-15/util/gtf_splicesites > snp.splicesiteschr
#TBD: awk thingy...
## processing it to map file (changing to .iit file)---done for snp.splicesitechr
cat snp.splicesitechr |/bubo/home/h24/alvaj/glob/annotation/gsnap/gmap-2012-05-15/src/iit_store -o splicesitesfilechr


###
## Fastq files
###
scriptdir='/proj/b2012046/rani/scripts/gsnap'
fastqdir='/proj/b2012046/edsgard/ase/sim/data/synt/fastqfilt'
projid='b2012046'
email='alva.rani@scilifelab.se'
outdir='/proj/b2012046/rani/analysis/gsnap'

# all files apart from those with '.S' extension
cd $scriptdir
find $fastqdir -maxdepth 1 -name '*fastq' | grep -v '\.S\.' >fastq.files

#Create sbatch scripts
cat fastq.files | sed 's/1.filter.fastq//' | grep -v '2.filter.fastq' >fastqfiles.prefix

(cat <<EOF
#!/bin/bash -l
#SBATCH -A $projid
#SBATCH -t 35:00:00
#SBATCH -J gsnap
#SBATCH -p core -n 1
#SBATCH -e $outdir/log/gsnap.samplejid_%j.stderr
#SBATCH -o $outdir/log/gsnap.samplejid_%j.stdout
#SBATCH --mail-type=All
#SBATCH --mail-user=$email
export PATH=$PATH:/bubo/home/h24/alvaj/opt/gmap-2012-05-15/bin
cd ${fastqdir}
gsnap -D $refdir -d $ref -A sam -s $splicefile -V $snpdir -v $snpfile --quality-protocol=illumina sample1.filter.fastq sample2.filter.fastq >${outdir}/samplesam
EOF
) >sbatch.template
cat fastqfiles.prefix | xargs -I% basename % | xargs -I% echo cat sbatch.template "| sed 's/sample/"%"/g' >" %gsnap.sbatch >cmds.sh
sh cmds.sh
find . -name '*.gsnap.sbatch' | xargs -I% sbatch %
#status: submitted




