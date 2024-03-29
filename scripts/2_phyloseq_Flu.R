#########################################
#SRD129 16S - Creating phyloseq objects
#By Mou, KT

#Purpose: Create phyloseq objects to be used to calculate alpha and beta diversity measures for nasal samples in Flu and Control groups. This section will also use the adonis function to determine the effect of time and treatment on the community structure of nasal microbiota.

#Files needed:
#SRD129abundsingleton2000OTUtable.csv
#SRD129metadata.csv

#Load library packages
library(vegan)
library(ggplot2)
library(dplyr)
library(tidyr)
library(tidyverse)
library(phyloseq) #installed packages which need compilation

#R version 4.2.0 (2022-04-22)

#######################################################################

#Read files
otu <- read.csv("./data/SRD129abundsingleton2000OTUtable.csv", row.names=1) #Set column 1 as row names
meta <-read.csv("./data/SRD129metadata.csv")

dim(otu) #Check dimensions of 'otu'
head(otu[,1:5]) #Check the first part of 'otu' table
head(otu[,185:187]) #Check last part of 'otu' table
dim(meta) #Determine the dimensions of 'meta' dataframe. It has 186 rows and 5 columns
head(meta[,1:5]) #Check first part of 'meta' table

#Remove taxonomy from 'otu'
tax <- otu[,(186:187)] #Remove column 186 taxonomy and 187 to copy the row names from 'otu' to 'tax'
head(tax)
colnames(tax)[1] <- "delete" #Rename column 1 of 'tax' (formerly column 186) as "delete" which will be deleted later
head(tax)

#Modify 'otu' with only OTU count data
otu <- otu[,-187] #Remove column 187 taxonomy in 'otu' to have only OTU data
head(otu[,180:186])
dim(otu) #Dimensions of 'otu' show 1299 rows 186 columns

#Transpose 'otu' to match format of 'meta'
otu.trans <- t(otu)
#Now rownames in 'otu.trans' are sample names, columns are OTUs
head(otu.trans[,1:5])
head(meta) #Row names are numbered, but we want sample names as row names
rownames(meta) <- meta$Sample #Set names in "Sample" as rownames in 'meta'
head(meta)
class(meta) #The type of class that 'meta' is is dataframe
class(otu) #dataframe

#Merge 'otu' and 'meta' data frames
otu.meta <- merge(meta, otu.trans, by.x=0, by.y=0) #Merge by names of the columns that are common to both x and y (columns with common names between the two data sets)
#by.x=0 means match by rownames in 'meta'; y=0 means match by rownames in 'otu.trans'
head(otu.meta[,1:10])
class(otu.meta) #Check class type of 'otu.meta'. It should be a dataframe.

#Added an "All" column (combines 'Treatment' and 'Day' values) in new 'otu.meta2' dataframe
otu.meta2<- cbind(otu.meta) #Make second copy of 'otu.meta' to use to include an "All" column
otu.meta2$All <- with(otu.meta2, paste0(Day, sep=" ", Treatment)) #Combine "Day" and "Treatment" columns into an "All" column
head(otu.meta2) #Check first part of otu.meta2
dim(otu.meta2) #Check dimensions of 'otu.meta2' dataframe; 186 1306
head(otu.meta2[,1300:1306]) #Check the first part of the end of 'otu.meta2' dataframe
head(otu.meta2[,1:10])
rownames(otu.meta2) <- otu.meta2$Row.names #Set "Row.names" as rownames
otu.meta2 <- otu.meta2[,-1] #remove "Row.names" column
head(otu.meta2[,1:10])
otu.meta2 <- otu.meta2[,-1]
head(otu.meta2[,1:10])
dim(otu.meta2) #186 1304
head(otu.meta2[,1300:1304])
otu.meta2<- otu.meta2[,c(1:4,1304,5:1303)] #Reorder columns to have "All" column after "Treatment" column
head(otu.meta2[,1:10]) #Check the first part of the beginning of 'otu.meta2' dataframe
head(otu.meta2[,1300:1304])
write.csv(otu.meta2, file="SRD129abundsingleton2000.otu.meta.csv")

#Creating phyloseq objects for nasal samples

#Pull out metadata from 'otu.meta2' dataframe
head(otu.meta2[,1:10])
dim(otu.meta2) #186 1304
otu.meta3 <- otu.meta2[,1:5] #Take columns 1-5 to make 'otu.meta3'
head(otu.meta3)
dim(otu.meta3) #186 5

#Create SAM metadata table phyloseq object
SAM = sample_data(otu.meta3, errorIfNULL = TRUE)
head(SAM)
dim(SAM) #186 5

#Pull out OTU data from 'otu.meta2' dataframe
head(otu.meta2[,1:10])
dim(otu.meta2) #186 1304
head(otu.meta2[,1300:1304])
otu.meta4 <- otu.meta2[,c(6:1304)] #Select "OTU" columns to create 'otu.meta4' dataframe
head(otu.meta4[,1:10])
dim(otu.meta4) #186 1299
otu.meta4.trans <- t(otu.meta4) #Transpose 'otu.meta4' to have OTUs as rownames, sample names as column names
head(otu.meta4.trans[,1:10])
dim(otu.meta4.trans) #1299  186
head(otu.meta4.trans[,180:186])

#Merge 'tax' back into 'otu.meta4.trans' for correct format and taxons
head(tax)
otu.tax <- merge(otu.meta4.trans, tax, by=0) #Merge by rownames aka OTU rownames
dim(otu.tax) #1299  189
head(otu.tax[,185:189])
head(otu.tax[,1:5])
row.names(otu.tax) <- otu.tax[,1] #Set first row as rownames
head(otu.tax[,1:5])
otu.tax <- otu.tax[,-1] #Remove first row, extraneous OTU column
head(otu.tax[,1:5])
dim(otu.tax) #1299 188
head(otu.tax[185:188])

#Split 'otu.tax.nw2' again
dim(otu.tax) #1299 188
head(otu.tax[185:188])
otu.notax <- otu.tax[,1:186] #Take rows 1-186 to make new dataframe 'otu.notax' (187 is delete column, 188 is taxonomy column)
head(otu.notax[,1:5])
head(otu.notax[,184:186])
dim(otu.notax) #1299  186
class(otu.notax) #dataframe
otu.notax <- as.matrix(otu.notax) #Turn 'otu.notax' into a matrix class
class(otu.notax) #matrix

#Create OTU table phyloseq object
OTU = otu_table(otu.notax, taxa_are_rows = TRUE, errorIfNULL=TRUE)
head(OTU)
dim(OTU) #1299  186
class(OTU)
dim(otu.tax) #1299  188
head(otu.tax[,186:188])
tax.levels <- separate(data = otu.tax,
                       col = Taxonomy,
                       into=c("Kingdom", "Phylum", "Class", "Order", "Family", "Genus", "Species"), sep=";")
#Separate Taxonomy column into 7 separate columns labeled "Kingdom", "Phylum", "Class", etc.
head(tax.levels) #Notice that "Species" column is blank
dim(tax.levels) #1299  194
head(tax.levels[,186:194])
head(tax.levels[,188:193])
tax.only <- tax.levels[,188:193] #Keep only taxonomy columns from "Kingdom" up to "Genus"
head(tax.only)
dim(tax.only) #1299 6
class(tax.only) #data.frame
tax.m <- as.matrix(tax.only)
class(tax.m) #matrix
head(tax.m)

#Create TAX taxonomy table phyloseq object
TAX = tax_table(tax.m)
head(TAX)
dim(TAX) #1299 6
head(TAX)
class(TAX)

#Create phyloseq object 'phyloseqFlu' containing taxonomy, metadata, and OTU table
phyloseqFlu <- phyloseq(OTU, SAM, TAX)
phyloseqFlu #view phyloseq object
#phyloseq-class experiment-level object
#otu_table()   OTU Table:         [ 1299 taxa and 196 samples ]
#sample_data() Sample Data:       [ 196 samples by 5 sample variables ]
#tax_table()   Taxonomy Table:    [ 1299 taxa by 6 taxonomic ranks ]

save(phyloseqFlu, file="SRD129Flu.phyloseq.RData")


#Run adonis function to determine effect of time and treatment on structure of nasal microbiota

adonis.Flu <- as(sample_data(phyloseqFlu), "data.frame")
class(adonis.Flu) #data.frame

#distance function to run distance calculations
dist.Flu <- distance(phyloseqFlu, method="bray") #Distance calculation using Bray-Curtis
set.seed(1) #Use set.seed function when running simulations to ensure all results are reproducible
full.Flu <- adonis(dist.Flu~Day*Treatment, data=adonis.Flu, permutations=9999)
#output message: 'adonis' will be deprecated: use 'adonis2' instead
full.Flu #Display results
#Output:
#$aov.tab
#Permutation: free
#Number of permutations: 9999

#Terms added sequentially (first to last)

#               Df SumsOfSqs MeanSqs F.Model      R2 Pr(>F)    
#Day             9    8.2853 0.92059 12.8444 0.37628  1e-04 ***
#Treatment       1    0.3890 0.38903  5.4279 0.01767  1e-04 ***
#Day:Treatment   9    1.4470 0.16077  2.2432 0.06571  1e-04 ***
#Residuals     166   11.8977 0.07167         0.54034           
#Total         185   22.0190                 1.00000           
#---
#Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1

#$call
#adonis(formula = dist.Flu ~ Day * Treatment, data = adonis.Flu, 
#       permutations = 9999)

#$coefficients
#NULL

# output continues with coef.sites, f. perms, model.matrix, terms (too long to paste here)

###Day had largest effect on variation



#switched Treatment and Day order, obtained same conclusions: Day had the largest effect on variation
full.Flu_2 <- adonis(dist.Flu~Treatment*Day, data=adonis.Flu, permutations=9999)
#output message: 'adonis' will be deprecated: use 'adonis2' instead
full.Flu_2
#Output:
#$aov.tab
#Permutation: free
#Number of permutations: 9999

#Terms added sequentially (first to last)

#               Df SumsOfSqs MeanSqs F.Model      R2 Pr(>F)    
#Treatment       1    0.4068 0.40676  5.6752 0.01847  2e-04 ***
#Day             9    8.2676 0.91862 12.8169 0.37548  1e-04 ***
#Treatment:Day   9    1.4470 0.16077  2.2432 0.06571  1e-04 ***
#Residuals     166   11.8977 0.07167         0.54034           
#Total         185   22.0190                 1.00000           
#---
#Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1

#$call
#adonis(formula = dist.Flu ~ Treatment * Day, data = adonis.Flu, 
#       permutations = 9999)

#$coefficients
#NULL

# output continues with coef.sites, f. perms, model.matrix, terms (too long to paste here)

###Day had largest effect on variation



### TROUBLESHOOTING ###

#If distance function is giving an error message below:
#"Error: x should be a data.frame, data.table, tbl, tbl_df, array, or matrix."
#Use vegdist function from vegan package to run distance calculations instead of the distance function
#(original "distance" function that was used below is no longer available) and use those calculations to run through adonis test
#vegdist requires that phyloseq object's OTU table has OTUs listed in the columns and sample names listed in rows.
#Also, remove any OTUs with taxa_sums = 0 or non-numeric values. For example, this command can help remove OTUs with taxa_sums = 0:
#OTU <- prune_taxa(taxa_sums(<yourOTUtable>) > 0, <yourOTUtable>)
#If you create a separate phyloseq object with this specific OTU table setup,
#you should be able to run the vegdist function without any errors and use the output to run through adonis function

head(otu.meta4) #Sample names are listed in rows and OTUs are listed in columns in 'otu.meta4'
OTU.2 = otu_table(otu.meta4, taxa_are_rows = TRUE)
OTU.2.distance <- vegdist(OTU.2, method = "bray")
OTU.2.distance.full <- adonis(OTU.2.distance~Day*Treatment, data = adonis.Flu, permutations=9999)
OTU.2.distance.full
#Output is the same as full.Flu:
#Call:
#adonis(formula = OTU.2.distance ~ Day * Treatment, data = adonis.Flu,      permutations = 9999)

#Permutation: free
#Number of permutations: 9999

#Terms added sequentially (first to last)

#                   Df    SumsOfSqs MeanSqs   F.Model   R2        Pr(>F)
#  Day              9     8.2853    0.92059   12.8444   0.37628   1e-04 ***
#  Treatment        1     0.3890    0.38903   5.4279    0.01767   1e-04 ***
#  Day:Treatment    9     1.4470    0.16077   2.2432    0.06571   1e-04 ***
#  Residuals      166     11.8977   0.07167             0.54034
#  Total          185     22.0190                       1.00000
#---
#  Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1
