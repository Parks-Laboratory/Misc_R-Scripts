library(RODBC)
library(dplyr)
library(Matrix)
library(qvalue)
library(fdrtool)

db <- odbcDriverConnect('SERVER=PARKSLAB;DATABASE=Epistasis;Trusted_Connection=Yes;DRIVER={SQL Server}')

#------------------------------------------------------
#     INPUT TRAIT WE ARE INTERESTED IN              ###
#------------------------------------------------------
trait = 'MALE_HDL_LOG'
#------------------------------------------------------

## Query for p value dataset from SQL database
Trait_query <- paste("select Pvalue from dbo.HMDP_OBESITY where Trait LIKE '", trait, "'", sep="")
traitTable = sqlQuery(db, Trait_query)
odbcClose(db)

#Generate random samples from the population and look at the top rows
#sampleTable = sample_n(traitTable, 100000)
#head(sampleTable, n = 10)

## Make a pretty QQ plot of p-values ### Add ymax.soft
qq = function(pvector,gridlines=F,gridlines.col='gray83',gridlines.lwd=1,gridlines.lty=1,confidence=T,confidence.col='gray81',
              pt.cex=0.5,pt.col='black',pt.bg='black',pch=21,abline.col='red',abline.lwd=1.8,abline.lty=1,ymax=8,ymax.soft=T,
              highlight=NULL,highlight.col=c('green3','magenta'),highlight.bg=c('green3','magenta'),
              annotate=NULL,annotate.cex=0.7,annotate.font=3,cex.axis=0.95,...) {
  #======================================================================================================
  ######## Check data and arguments; create observed and expected distributions
  d = suppressWarnings(as.numeric(pvector))
  names(d) = names(pvector)
  d = d[!is.na(d)] # remove NA, and non-numeric [which were converted to NA during as.numeric()]
  d = d[d>0 & d<1] # only Ps between 0 and 1
  
  
  if (!is.null(highlight) | !is.null(annotate)){
    if (is.null(names(d))) stop("P-value vector must have names to use highlight or annotate features.")
    d = d[!is.na(names(d))]
    if (!is.null(highlight) & FALSE %in% (highlight %in% names(d))) stop ("D'oh! Highlight vector must be a subset of names(pvector).")
    if (!is.null(annotate) & FALSE %in% (annotate %in% names(d))) stop ("D'oh! Annotate vector must be a subset of names(pvector).")
  }
  
  d = d[order(d,decreasing=F)] # sort
  o = -log10(d)
  e = -log10( ppoints(length(d) ))
  if (!is.null(highlight) | !is.null(annotate)) names(e) = names(o) = names(d)
  
  if (!is.numeric(ymax) | ymax<max(o)) ymax <- max(o) 
  
  if (!is.numeric(pt.cex) | pt.cex<0) pt.cex=0.5
  if (!is.numeric(annotate.cex) | annotate.cex<0) annotate.cex=0.7
  if (!is.numeric(annotate.font)) annotate.font=3
  
  if (is.character(gridlines.col[1]) & !(gridlines.col[1] %in% colors())) gridlines.col = 'gray83'
  if (is.character(confidence.col[1]) & !(confidence.col[1] %in% colors())) confidence.col = 'gray81'
  if (is.character(abline.col[1]) & !(abline.col[1] %in% colors())) abline.col = 'red'
  
  if (FALSE %in% (pt.col %in% colors() | !is.na(suppressWarnings(as.numeric(pt.col))) )){
    pt.col = 'black'; warning("pt.col argument(s) not recognized. Setting to default: 'black'.")
  }
  
  if (FALSE %in% (pt.bg %in% colors() | !is.na(suppressWarnings(as.numeric(pt.bg))) )){
    pt.bg = 'black'; warning("pt.bg argument(s) not recognized. Setting to default: 'black'.")
  }
  
  if (FALSE %in% (highlight.col %in% colors() | !is.na(suppressWarnings(as.numeric(highlight.col))) )){
    highlight.col = 'blue'; warning("highlight.col argument(s) not recognized. Setting to default: 'blue'.")
  }
  
  if (FALSE %in% (highlight.bg %in% colors() | !is.na(suppressWarnings(as.numeric(highlight.bg))) )){
    highlight.bg = 'blue'; warning("highlight.bg argument(s) not recognized. Setting to default: 'blue'.")
  }
  
  # Ymax
  if(is.na(suppressWarnings(as.numeric(ymax)))){  # not numeric
    ymax = ceiling(max(o))
    warning('non-numeric ymax argument.')
  } else if (as.numeric(ymax) < 0){ 			# negative
    ymax = ceiling(max(o))
    warning('negative ymax argument.')
  }
  if (ymax.soft==T){ #if soft, ymax is just the lower limit for ymax
    ymax = max(ymax, ceiling(max(o)))
  } #else, ymax = ymax
  
  
  ################################
  
  # Initialize plot
  #print('Setting up plot.')
  #print(ymax)
  xspace = 0.078
  xmax = max(e) * 1.019
  xmin = max(e) * -0.035
  #ymax = ceiling(ymax * 1.03)
  ymin = -ymax*0.03
  plot(0,xlab=expression(Expected~~-log[10](italic(p))),ylab=expression(Observed~~-log[10](italic(p))),
       col=F,las=1,xaxt='n',xlim=c(xmin,xmax),ylim=c(ymin,ymax),bty='n',xaxs='i',yaxs='i',cex.axis=cex.axis)
  axis(side=1,labels=seq(0,max(e),1),at=seq(0,max(e),1),cex.axis=cex.axis,lwd=0,lwd.ticks=1)
  
  # Grid lines
  if (isTRUE(gridlines)){
    yvals = par('yaxp')
    yticks = seq(yvals[1],yvals[2],yvals[2]/yvals[3])
    abline(v=seq(0,max(e),1),col=gridlines.col[1],lwd=gridlines.lwd,lty=gridlines.lty)
    abline(h=yticks,col=gridlines.col[1],lwd=gridlines.lwd,lty=gridlines.lty)
  }
  
  #Confidence intervals
  find_conf_intervals = function(row){
    i = row[1]
    len = row[2]
    if (i < 10000 | i %% 100 == 0){
      return(c(-log10(qbeta(0.95,i,len-i+1)), -log10(qbeta(0.05,i,len-i+1))))
    } else { # Speed up
      return(c(NA,NA))
    }
  }
  
  # Find approximate confidence intervals
  if (isTRUE(confidence)){
    #print('Plotting confidence intervals.')
    ci = apply(cbind( 1:length(e), rep(length(e),length(e))), MARGIN=1, FUN=find_conf_intervals)
    bks = append(seq(10000,length(e),100),length(e)+1)
    for (i in 1:(length(bks)-1)){
      ci[1, bks[i]:(bks[i+1]-1)] = ci[1, bks[i]]
      ci[2, bks[i]:(bks[i+1]-1)] = ci[2, bks[i]]
    }
    colnames(ci) = names(e)
    # Extrapolate to make plotting prettier (doesn't affect intepretation at data points)
    slopes = c((ci[1,1] - ci[1,2]) / (e[1] - e[2]), (ci[2,1] - ci[2,2]) / (e[1] - e[2]))
    extrap_x = append(e[1]+xspace,e) #extrapolate slightly for plotting purposes only
    extrap_y = cbind( c(ci[1,1] + slopes[1]*xspace, ci[2,1] + slopes[2]*xspace), ci)
    
    polygon(c(extrap_x, rev(extrap_x)), c(extrap_y[1,], rev(extrap_y[2,])),col = confidence.col[1], border = confidence.col[1])	
  }
  
  # Points (with optional highlighting)
  #print('Plotting data points.')
  fills = rep(pt.bg,length(o))
  borders = rep(pt.col,length(o))
  names(fills) = names(borders) = names(o)
  if (!is.null(highlight)){	
    borders[highlight] = rep(NA,length(highlight))
    fills[highlight] = rep(NA,length(highlight))
  }
  points(e,o,pch=pch,cex=pt.cex,col=borders,bg=fills)
  
  if (!is.null(highlight)){
    points(e[highlight],o[highlight],pch=pch,cex=pt.cex,col=highlight.col,bg=highlight.bg)
  }
  
  #Abline
  abline(0,1,col=abline.col,lwd=abline.lwd,lty=abline.lty)
  
  # Annotate SNPs
  if (!is.null(annotate)){
    x = e[annotate] # x will definitely be the same
    y = -0.1 + apply(rbind(o[annotate],ci[1,annotate]),2,min)
    text(x,y,labels=annotate,srt=90,cex=annotate.cex,adj=c(1,0.48),font=annotate.font)		
  }
  # Box
  box()
}

###########################################################################################################
#############################################################################################################
###################################################################################################
#################################################################################################
#############################################################################################
###################################################################################

## prepare data format to fit the package requirements
unListed <- as.double(unlist(traitTable$Pvalue))
sampleTable <- as.data.frame(unListed)

## Save figure in a tiff image
# tiff(filename= "PvaluesFULL_qqplot.tiff", width = 600, height = 600)
# qq(unListed)
# dev.off()

## Population of the random data dataset p > 0.0005 
desc <- as.data.frame(seq(from = 0.0005, to = 1, by = 0.0000000031))

#------------------------------------------------------
#     INPUT NUMBER OF TIMES WE WANT TO SAMPLE      ###
#------------------------------------------------------
N = 10
#------------------------------------------------------

## Computes the aggregate of the Bonferroni cutoff based on number of samples
aggBF_0.01 = 0
aggBF_0.05 = 0
aggBF_0.1 = 0
aggBF_0.25 = 0 
for (i in 1:N)
{
  sampleDesc = sample_n(desc, 10000000)
  sampleList = sample_n(sampleTable, 10000000)
  appended <- as.double(unlist(append(sampleList, sampleDesc)))
  fdrBF <- p.adjust(appended, method = "bonferroni")
  aggBF_0.01 = aggBF_0.01 + max(fdrBF[fdrBF <= 0.01])
  aggBF_0.05 = aggBF_0.05 + max(fdrBF[fdrBF <= 0.05])
  aggBF_0.1 = aggBF_0.1 + max(fdrBF[fdrBF <= 0.1])
  aggBF_0.25 = aggBF_0.25 + max(fdrBF[fdrBF <= 0.25])
}

## Average out the cutoff values
(BF_0.01 = aggBF_0.01/N)
(BF_0.05 = aggBF_0.05/N)
(BF_0.1 = aggBF_0.1/N)
(BF_0.25 = aggBF_0.25/N)

## Use qvalue package to calculate the adjusted q values
# HMDP_q <- qvalue(appended, pi0.method="bootstrap")
# plot(HMDP_q)

## Use fdrtool package to calculate adjusted q values
fdrStats <- fdrtool(appended, statistic = "pvalue", plot = TRUE, color.figure = TRUE)

## Checks return values
# attributes(fdrStats)
# fdrStats$pval
# fdrStats$qval
# fdrStats$lfdr
# fdrStats$statistic
# fdrStats$param

## Find the cutoff q values for each q value cutoff threshold
max(fdrStats$pval[fdrStats$qval <= 0.01])
max(fdrStats$pval[fdrStats$qval <= 0.05])
max(fdrStats$pval[fdrStats$qval <= 0.10])
max(fdrStats$pval[fdrStats$qval <= 0.25])

## Code to try to simulate actual dataset by creating a uniform distribution for p values
sampleDesc = sample_n(desc, 100000000 - 160000)
sampleList = sample_n(sampleTable, 1000000)
appended <- as.double(unlist(sampleList))
appended <- as.double(unlist(append(sampleList, sampleDesc)))
hist(appended)
fdrStats <- fdrtool(appended, statistic = "pvalue", plot = TRUE, color.figure = TRUE)
# fdrBF <- p.adjust(appended, method = "bonferroni")
