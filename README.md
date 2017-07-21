# Miscellaneous Scripts for Various Data Operations  
This repository contains sample scripts to perform certain functionalities. A table of contents will be listed to show the functionality of each project. Click on any of the selections in the table to go to the description of the item.

## Table of Contents
1. [DFShuffle](#dfshuffle)
2. [EPISTASIS BOX PLOT CODE WITH TWO SNPS](#epistasisboxplot)
3. [HMDP_OBESITY qqplot](#hmdpqqplot)
4. [Populate_HMDP](#databasepopulation)
5. [chtc_Test](#chtcTest)

### DFShuffle <a name="dfshuffle"></a>
This R script creates a sample data frame and shuffles one column while keeping all other columns intact. Solves the issue of the columns being tied together (i.e. break ties between columns to shuffle)

### Epistasis Box Plot code <a name="epistasisboxplot"></a> 
Merges three beeswarm plots (two individual snps and then the the outcome of the pair) into a figure and outputs it as a pretty tiff file.  
### HMDP Data qqplot <a name="hmdpqqplot"></a>
Contains a custom qqplot function which outputs a normal qqplot with respect to the expected values. A fdr cutoff is found by running it on several packages. Converted qvalues are inspected to find the cutoff point.

### SQL Database Population with huge schemas <a name="databasepopulation"></a>
Traditional SQL databases do not deal with large schemas (i.e. huge columns) and insertion into tables with large schemas are typically hard to do. This project is meant to be a one-off project for a dataset which large number of columns so the table schema is not specified during insertion. Concatenation logic is used instead of a static sql query. 

### Shell Script to Extract All Required Files from CHTC (CHTC is a type of cloud computing platform/grid) <a name="chtcTest"></a>
Genome SNPs are sent to CHTC to be computed pairwise, hence resulting in a large number of files being returned by the process. Traditional methods require users to scp each file from CHTC to the local server. This shell script helps users retrieve those files without having to ssh or scp at all. The .log and .gwas files will be stored in 2 separate folders. The files that we want are:
```bash
fastlmm_condor_out/(trait_name)/*.log
fastlmm_results/(trait_name)/*.gwas
fastlmm_(trait_name).sh
fastlmm_(trait_name).sub
``` 
The same string format applies for epistasis. We are mainly interested in the fastlmm and epistasis directories. 

#### Usage for Shell Script
```bash
./chtc_Test.sh (trait_name) (fastlmm/epistasis)
```
