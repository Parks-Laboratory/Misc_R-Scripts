#! /bin/sh
# Usage: $ chtcFastLMM trait_name (pulls fastlmm_*.sub, *.sh, .log and all .gwas files from fastlmm_results)
# Effect: Creates LOG_FILES folder with only .log files, RESULTS folder with all .gwas files, deletes all files except those needed in the directories
if [ -z "$1" ]
then
	echo Please enter a trait;
else
    if [ -z "$2" ]; then
		echo Please enter either "epistasis" or "fastlmm" to extract the required files;
    else
    	if [ "$2" == "fastlmm" ]; then
    		ssh $USER@submit-3.chtc.wisc.edu "
    			find ./fastlmm_condor_out/$1/ -type f ! -name '*.log' -delete
				find ./fastlmm_results/$1/ -type f ! -name '*.gwas' -delete
				echo Deleting non .log and .gwas files in fastlmm directories
				exit"
        	scp -r $USER@submit-3.chtc.wisc.edu:fastlmm_$1.sh .
        	scp -r $USER@submit-3.chtc.wisc.edu:fastlmm_$1.sub .
        	scp -r $USER@submit-3.chtc.wisc.edu:fastlmm_condor_out/$1/ ./LOG_FILES
        	scp -r $USER@submit-3.chtc.wisc.edu:fastlmm_results/$1/ ./RESULTS
    	elif [ "$2" == "epistasis" ]; then
        	ssh $USER@submit-3.chtc.wisc.edu "
        	find ./epistasis_condor_out/$1/ -type f ! -name '*.log' -delete;
        	find ./epistasis_results/$1/ -type f ! -name '*.gwas' -delete;
        	echo Deleting non .log and .gwas files in epistasis directories...;
        	exit;"
        	scp -r $USER@submit-3.chtc.wisc.edu:epistasis_$1.sh .
        	scp -r $USER@submit-3.chtc.wisc.edu:epistasis_$1.sub .
        	scp -r $USER@submit-3.chtc.wisc.edu:epistasis_condor_out/$1/ ./LOG_FILES
        	scp -r $USER@submit-3.chtc.wisc.edu:epistasis_results/$1/ ./RESULTS
        else
        	echo Enter either epistasis or fastlmm
    	fi
	fi
fi
