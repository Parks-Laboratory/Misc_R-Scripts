library(RODBC)
library(beeswarm)
setwd("E:/EPISTASIS/DO_EPISTASIS/INS_PER_ISLET_LOG/BOXPLOTS/")


#------------------------------------------------------
#     INPUT PHENOTYPE FILE DATA AND 2 SNP rsIDS      ###
#------------------------------------------------------
filename = 'INSULIN_PER_ISLET_ORIGINAL_DATA.txt'
snpID <- 'UNC481045'
snpID_2 <- 'UNC15549297'
#------------------------------------------------------


#*----------------------------------------------------
#   GET SNP1 GENOTYPES AND ORGANIZE IN DATAFRAME   ###
#----------------------------------------------------
db <- odbcDriverConnect('SERVER=PARKSLAB;DATABASE=DO;Trusted_Connection=Yes;DRIVER={SQL Server}')
SNP1_query <- paste("select * from dbo.Genotype_Calls_Plink_Format where snp_id='", snpID, "'", sep="")
SNP1 = sqlQuery(db, SNP1_query)
odbcClose(db) 

SNP1 = t(SNP1)
SNP1 = data.frame(SNP1)
SNP1$Strain = rownames(SNP1)
rownames(SNP1) = NULL
SNP1$SNP1 = SNP1[,1]
SNP1 = SNP1[,-1]
SNP1 = SNP1[5:nrow(SNP1), ]
SNP1 = SNP1[order(SNP1[,2]), ]
SNP1 = na.omit(SNP1)
#*----------------------------------------------------
#   GET SNP2 GENOTYPES AND ORGANIZE IN DATAFRAME   ###
#----------------------------------------------------
db <- odbcDriverConnect('SERVER=PARKSLAB;DATABASE=DO;Trusted_Connection=Yes;DRIVER={SQL Server}')
SNP2_query <- paste("select * from dbo.Genotype_Calls_Plink_Format where snp_id='", snpID_2, "'", sep="")
SNP2 = sqlQuery(db, SNP2_query)
odbcClose(db) 

SNP2 = t(SNP2)
SNP2 = data.frame(SNP2)
SNP2$Strain = rownames(SNP2)
rownames(SNP2) = NULL
SNP2$SNP2 = SNP2[,1]
SNP2 = SNP2[,-1]
SNP2 = SNP2[5:nrow(SNP2), ]
SNP2 = SNP2[order(SNP2[,2]), ]
SNP2 = na.omit(SNP2)
#*----------------------------------------------------
#   MERGE SNPS and INPUT PHENOTYPE DATA and COMBINE  ###
#----------------------------------------------------
SNP1_SNP2 = merge(SNP1, SNP2, by="Strain")
TRAIT = read.table(filename, header=T, sep="\t")
#TRAIT = TRAIT[ ,-c(1,3)] 
#TRAIT = na.omit(TRAIT)
SNP_TRAIT = merge(SNP1_SNP2, TRAIT, by = "Strain")
SNP_TRAIT$SNP1_SNP2 = paste(SNP_TRAIT$SNP1, SNP_TRAIT$SNP2)
SNP_TRAIT = SNP_TRAIT[SNP_TRAIT$SNP1 != '0 0', ]
SNP_TRAIT = SNP_TRAIT[SNP_TRAIT$SNP2 != '0 0', ]

write.table(SNP_TRAIT, file=paste('Epistasis_DO_INSULIN_PER_ISLET_',snpID,'_', snpID_2,'.txt', sep=''), sep="\t", row.names=F)

#-----------------------------------------------------
#         OUTPUT EPISTASIS PLOT                     #
#-----------------------------------------------------
tiff(filename=paste('Epistasis_DO_INSULIN_PER_ISLET',snpID,'_',snpID_2,'.tiff', sep=''), width = 1200, height = 800)
par(mar=c(12, 6, 2, 4.1))
beeswarm(SNP_TRAIT$INSULIN_PER_ISLET ~SNP_TRAIT$SNP1_SNP2, pch=19, method=c('swarm'), 
         spacing=1, col=c('black','red', 'blue', 'green'), ylab='INSULIN PER ISLET',
         xlab = '', cex.lab=1.5, cex.axis=1.5, las=2, main = paste(snpID,"/", snpID_2))
boxplot(SNP_TRAIT$INSULIN_PER_ISLET ~SNP_TRAIT$SNP1_SNP2, add=T, names=c('',''), axes=F, outline=F, col='#9E9E9E33')
dev.off()

SNP_TRAIT$SNP1 = as.character(SNP_TRAIT$SNP1)
SNP_TRAIT$SNP2 = as.character(SNP_TRAIT$SNP2)



### allele 1 plot
tiff(filename=paste('Epistasis_DO_INSULIN_PER_ISLET',snpID,'.tiff', sep=''), width = 600, height = 600)
par(mar=c(5.1, 5.1, 2, 4.1))
beeswarm(SNP_TRAIT$INSULIN_PER_ISLET ~ SNP_TRAIT$SNP1, pch=19, method=c('swarm'), spacing=1, 
         col=c('red', 'blue'),xlab=paste(snpID), ylab='INSULIN PER ISLET', cex.lab=2, cex.axis=2)
boxplot(SNP_TRAIT$INSULIN_PER_ISLET ~ SNP_TRAIT$SNP1, add=T, names=c('', ''), axes=F, outline=F, col='#9E9E9E33')
dev.off()

### allele 2 plot
tiff(filename=paste('Epistasis_DO_INSULIN_PER_ISLET',snpID_2,'.tiff', sep=''), width = 600, height = 600)
par(mar=c(5.1, 5.1, 2, 4.1))
beeswarm(SNP_TRAIT$INSULIN_PER_ISLET ~ SNP_TRAIT$SNP2, pch=19, method=c('swarm'), spacing=1, 
         col=c('red', 'blue'),xlab=paste(snpID_2), ylab='INSULIN PER ISLET', cex.lab=2, cex.axis=2)
boxplot(SNP_TRAIT$INSULIN_PER_ISLET ~ SNP_TRAIT$SNP2, add=T, names=c('', ''), axes=F, outline=F, col='#9E9E9E33')
dev.off()


