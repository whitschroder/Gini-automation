### Load packages, use install.packages("") if not installed

library(EnvStats)
library(DescTools)
library(tidyverse)
library(ggplot2)
library(gglorenz)

### Import data (update your folder path between quotes, change backslashes to forward slashes)

df <- read.csv(file = "C:/SampleData.csv")

### Calculate Gini coefficients and related statistics from dataset

#filter data to include only sample sizes greater than or equal to 10

dffilter <- df %>% 
  group_by(Name) %>% 
  filter(n() >= 10) 

#define population functions

sd.p <- function(x){sd(x)*sqrt((length(x)-1)/length(x))}
cv.p <- function(x){sd.p(x)/mean(x)}

#calculate summary statistics

stats <- dffilter %>%
  group_by(Name) %>%
  summarize(across(Metric, c(Gini = ~Gini(.x, unbiased = FALSE, na.rm = TRUE),  
                             "Sample Size" = ~n(),
                             Mean = mean, Range = ~diff(range(.x)), 
                             "Std Deviation" = sd.p, 
                             "Co. of Variation" = cv.p, Min = min, 
                             "Lower Quantile" = ~quantile(.x, 0.25), 
                             "Median" = ~quantile(.x, 0.5), 
                             "Upper Quantile" = ~quantile(.x, 0.75),
                             Max = max), .names = "{fn}"))

#calculate corrected Gini and confidence intervals, mutate to columns, and format as single data frame

Ginistats <- do.call(data.frame, dffilter %>%
  group_by(Name) %>%
  summarize(across(Metric, ~as.data.frame(do.call(rbind, list(Gini(.x, conf.level = .95, R = 1000, 
                                              type = "bca", na.rm = TRUE)))), .names = "{fn}")))

#rename columns

Ginistats <- Ginistats %>%
  rename("Corrected Gini" = "X1.gini", "Lower Gini" = "X1.lwr.ci", "Higher Gini" = X1.upr.ci)

#merge summary and Gini statistics and relocate column

ginibyname <- merge(stats, Ginistats, by = "Name")

ginibyname <- ginitable %>% relocate("Corrected Gini", .after = Gini)

### Save summarized data as a csv to working directory and delete intermediate data (do not delete dffilter)

write.csv(ginibyname, file = 'ginibyname.csv', row.names=FALSE)

rm(stats, Ginistats) 

### Create plots

# create folders for plots in working directory

mainDir <- getwd()
uniDir <- "univariate"
fDir <- "fplot"
lDir <- "lorenz"
dir.create(file.path(mainDir, uniDir), showWarnings = TRUE)
dir.create(file.path(mainDir, fDir), showWarnings = TRUE)
dir.create(file.path(mainDir, lDir), showWarnings = TRUE)

### Loop to generate plots

for (i in unique(dffilter$Name)){
  dfsub <- dffilter %>%
    filter(Name == i)
  dfsub <- subset(dfsub, select=c(Name, Metric))
  dfsub <- dfsub[order(dfsub$`Metric`),]
  dfsub <- dfsub %>%
    mutate(fprimew = (`Metric` - lag(`Metric`, 2))/2)
  dfsub <- dfsub %>%
    mutate(fprimen = (`Metric` - lag(`Metric`, 1))/2)
  shift <- function(x, n){
    c(x[-(seq(1))], rep(NA, n))
  }
  dfsub$fprimew <- shift(dfsub$fprimew, 1)
  dfsub$fprimen <- shift(dfsub$fprimen, 1)
  dfsub <- dfsub %>%
    mutate(fdprimew = (fprimew - lag(fprimew, 2))/2)
  dfsub$fdprimew <- shift(dfsub$fdprimew, 1)
  dfsub <- dfsub %>%
    mutate(fdprimen = (fprimen - lag(fprimen, 1))/2)
  dfsub <- dfsub[, c(1, 2, 3, 5, 4, 6)]
  dfsub[,-1] <-round(dfsub[,-1],2)
  dfsub[is.na(dfsub)] <- 0
  p <- ggplot(data=dfsub, aes(x=as.numeric(row.names(dfsub)))) + geom_hline(yintercept=0, color="darkgray") + 
    geom_vline(xintercept=0, color="darkgray") + 
    geom_line(aes(y = `Metric`), color ="black", size = 1) + 
    geom_point(aes(y = `Metric`), color = "black") + ggtitle(paste("Univariate plot of", as.character(dfsub$Name[1]))) + theme(plot.title = element_text(color = "black", size = 14)) + xlab("Individual Datapoints")
  f <- paste0('univariate/', 'univariate', i, '.tiff')
  tiff(f, units="in", width=6.5, height=6.5, res=300)
  print(p)
  dev.off()
  p <- ggplot(data=dfsub, aes(x=as.numeric(row.names(dfsub)))) + geom_hline(yintercept=0, color="darkgray") + 
    geom_vline(xintercept=0, color="darkgray") + 
    geom_line(aes(y = `fdprimew`), color ="black", size = 1) + 
    geom_point(aes(y = `fdprimew`), color = "black") + ggtitle(paste('f" (wide method) of', as.character(dfsub$Name[1]))) + 
    theme(plot.title = element_text(color = "black", size = 14)) + xlab("Individual Datapoints") + 
    ylab("Acceleration of Metric")
  f <- paste0('fplot/', 'fwide', i, '.tiff')
  tiff(f, units="in", width=6.5, height=6.5, res=300)
  print(p)
  dev.off()
  p <- ggplot(data=dfsub, aes(x=as.numeric(row.names(dfsub)))) + geom_hline(yintercept=0, color="darkgray") + 
    geom_vline(xintercept=0, color="darkgray") + 
    geom_line(aes(y = `fdprimen`), color ="black", size = 1) + 
    geom_point(aes(y = `fdprimen`), color = "black") + ggtitle(paste('f" (narrow method) of', as.character(dfsub$Name[1]))) + 
    theme(plot.title = element_text(color = "black", size = 14)) + xlab("Individual Datapoints") + 
    ylab("Acceleration of Metric")
  f <- paste0('fplot/', 'fnarrow', i, '.tiff')
  tiff(f, units="in", width=6.5, height=6.5, res=300)
  print(p)
  dev.off()
  Distr <- dffilter[dffilter$Name == i,]
  Distr1 <- subset(Distr, select = c(Metric))
  ginifilter <- ginibyname %>%
    filter(Name == i)
  ginifilter[,-1] <-round(ginifilter[,-1],2)
  p <- ggplot(Distr1, aes(Metric)) + geom_hline(yintercept=0, color="darkgray") + 
    geom_vline(xintercept=0, color="darkgray") + 
    stat_lorenz() + ggtitle(paste('Lorenz Curve of', as.character(ginifilter$Name[1]))) + 
    theme(plot.title = element_text(size=16)) + geom_abline(color = "slategray") + 
    geom_text(x=.25, y=.75, label=paste('Gini:', as.character(ginifilter$Gini[1]), 
                                        '\n Corrected Gini:', as.character(ginifilter$`Corrected Gini`[1]), 
                                        '\n Confidence:', as.character(ginifilter$`Lower Gini`[1]),'-', 
                                        as.character(ginifilter$`Higher Gini`[1]), "\n n =", 
                                        as.character(ginifilter$`Sample Size`[1])), size=5) + 
    xlab("Cumulative Proportion of Population") + ylab("Cumulative Proportion of Wealth Metric")
  f <- paste0('lorenz/', 'lorenz', i, '.tiff')
  tiff(f, units="in", width=6.5, height=6.5, res=300)
  print(p)
  dev.off()
}
