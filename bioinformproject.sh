#Run this script from a directory which includes subdirectories proteomes/ and ref_sequences/ (where ref_sequences includes the reference gene sequences and proteomes includes the proteome files) 
#usage: bash bioinformproject.sh

# changes directory to reference sequence folder
cd ./ref_sequences

#compile mcrAgene reference sequences in one .fasta file
for file in mcrAgene_??.fasta 
do 
cat $file >> mcrAgene_refseqs.fasta
done

#compile hsp70 gene reference sequences in one .fasta file
for file in hsp70gene_??.fasta
do
cat $file >> hsp70_refseqs.fasta
done

#run muscle sequence alignment on the output fasta files for both genes, creating an MSA file 
muscle -in mcrAgene_refseqs.fasta -out mcrAgene_MSA.fasta
muscle -in hsp70_refseqs.fasta -out hsp70gene_MSA.fasta

#run hmmer build to build the hidden Markov model for both genes
hmmbuild ../proteomes/mcrA_hmmbuild mcrAgene_MSA.fasta
hmmbuild ../proteomes/hsp70_hmmbuild hsp70gene_MSA.fasta

#change directory to proteome folder
cd ../proteomes

#combine hmm builds for the mcrA gene and hsp70 gene into one build
cat mcrA_hmmbuild > combined_hmmbuild
cat hsp70_hmmbuild >> combined_hmmbuild

#hmmer search for each proteome .fasta file, searching for the presence of the mrcA gene and hsp70 gene; generates a text file with the results for each proteome
for proteome in *.fasta
do
hmmsearch --tblout $(echo $proteome | sed 's/.fasta/.txt/') combined_hmmbuild $proteome
done

#making an output file with the hmm search results for each proteome with columns for proteome, number of mcrA gene copies (0 or 1), and number of hsp70 gene copies (variable)
echo "#[Proteome] [Number_of_mcrAgene_copies] [Number_of_hsp70_gene_copies]" > search_output.txt

# for loop which examines each proteome and writes the name of the proteome, the number of mcrAgene copies, and the number of hsp70gene copies to the search_output.txt file created in the previous step
for proteome in proteome_??.txt
do
echo "$(echo $proteome | sed 's/.txt//') $(cat $proteome | grep -v "#" | grep -c mcrAgene_MSA) $(cat $proteome | grep -v "#" | grep -c hsp70gene_MSA)" >> search_output.txt
done

# moves hmm search output file to the bioinformatics directory (parent directory)
mv search_output.txt ..

#changes working directory to the bioinformatics directory (parent directory of the proteomes directory that we're currently in)
cd ..

# makes file for pH resistant methanogen proteomes with description of file contents
echo "# candidate proteomes for pH resistant methanogens in order of likeliness based on number of hsp70 genes" > pH_resistant_methanogens.txt

# greps out the proteomes which have 1 or more mcrA gene and 1 or more hsp70 gene copy; then sorts list in order of most hsp70 copies (highest hsp70 count listed first) and writes this to a text file
cat search_output.txt | grep -v "#" | grep -e "^proteome_..\s[^0]\s[^0]" | sort -nr -k 3 | cut -d " " -f 1 >> pH_resistant_methanogens.txt


