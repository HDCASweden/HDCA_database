#!/bin/bash
source /home/ubuntu/HDD/opt/miniforge3/etc/profile.d/conda.sh
source ~/.bash_profile
wait
conda activate dotfiles
git pull

cd ~/repos/HDCA_database/code

mkdir -p data/publications
mkdir -p compiled/publications

echo 'Joakim Lundeberg'
# esearch -db pubmed -query 'Joakim Lundeberg' | efetch -format native -mode xml > ../data/publications/JL.xml
esearch -db pubmed -query 'Joakim Lundeberg' | efetch -format abstract > ../data/publications/JL.txt

echo 'Emma Lundberg'
# esearch -db pubmed -query 'Emma Lundberg' | efetch -format native -mode xml > ../data/publications/EM.xml
esearch -db pubmed -query 'Emma Lundberg' | efetch -format abstract > ../data/publications/EM.txt

echo 'Mats Nilsson'
# esearch -db pubmed -query 'Mats Nilsson' | efetch -format native -mode xml > ../data/publications/MN.xml
esearch -db pubmed -query 'Mats Nilsson' | efetch -format abstract > ../data/publications/MN.txt

echo 'Sten Linnarsson'
# esearch -db pubmed -query 'Sten Linnarsson' | efetch -format native -mode xml > ../data/publications/SL.xml
esearch -db pubmed -query 'Sten Linnarsson' | efetch -format abstract > ../data/publications/SL.txt

echo 'Christos Samakovlis'
# esearch -db pubmed -query 'Christos Samakovlis' | efetch -format native -mode xml > ../data/publications/CS.xml
esearch -db pubmed -query 'Christos Samakovlis' | efetch -format abstract > ../data/publications/CS.txt

echo 'Erik Sundstrom'
# esearch -db pubmed -query 'Erik Sundstrom' | efetch -format native -mode xml > ../data/publications/ES.xml
esearch -db pubmed -query 'Erik Sundstrom' | efetch -format abstract > ../data/publications/ES.txt

Rscript ./get_pubmed_info.R

git add .
git commit -m "$(echo 'updates citations ('`date +"%m-%d-%y-%T"`')')"
git push


