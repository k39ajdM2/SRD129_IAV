############################################################
#SRD129 16S - Nasal Microbiota: Genus Abundance
#By Mou, KT

#Purpose: Generate a list of percent total genera found in each treatment group per day for each tissue and creates a bar graph plot of the data

#Files needed:
#SRD129Flu.outsingletons.abund.opti_mcc.shared
#SRD129Flu.outsingletons.abund.opti_mcc.0.03.cons.taxonomy
#SRD129metadata.csv

#Load libraries
library(phyloseq)
library(tidyverse)
library(ggplot2)
library(dplyr)
library(cowplot)
library("ggsci")

#######################################################################

#Import files
otu <- import_mothur(mothur_shared_file = './data/SRD129Flu.outsingletons.abund.opti_mcc.shared')
taxo <- import_mothur(mothur_constaxonomy_file = './data/SRD129Flu.outsingletons.abund.opti_mcc.0.03.cons.taxonomy')
meta <- read.table('./data/SRD129metadata.csv', header = TRUE, sep = ",")
head(meta)
colnames(meta)[1] <- 'group' #Rename first column of "meta" as "group" temporarily. Will use "group" to set as rownames later and remove the "group" column
meta$Day<- gsub("D", "", meta$Day) #Remove "D"
meta$group <- as.character(meta$group)
head(meta)
phy_meta <- sample_data(meta)
rownames(phy_meta) <- phy_meta$group
head(phy_meta)
phy_meta <- phy_meta[,-1]
head(phy_meta)

#Create phyloseq-class objects with "otu" and "taxo"
IAV <- phyloseq(otu, taxo)
IAV <- merge_phyloseq(IAV, phy_meta)  #This combines the 'phy_meta' metadata with 'IAV' phyloseq object
colnames(tax_table(IAV)) <- c('Kingdom', 'Phylum', 'Class', 'Order', 'Family', 'Genus')
sample_sums(IAV) #Calculate the sum of all OTUs for each sample,
IAV <- prune_taxa(taxa_sums(IAV) > 2, IAV)  #Removes OTUs that occur less than 2 times globally
IAV.genus <- tax_glom(IAV, 'Genus')
phyla_tab <- as.data.frame(t(IAV.genus@otu_table)) #Transpose 'IAV.genus' by "otu_table"
head(phyla_tab)
IAV.genus@tax_table[,6]
colnames(phyla_tab) <- IAV.genus@tax_table[,6] #Replace column names in phyla_tab from Otuxxxx with Genus names
phyla_tab2 <- phyla_tab/rowSums(phyla_tab) #Calculate the proportion of specific phyla per phyla column in 'phyla_tab'
head(phyla_tab2)
phyla_tab2$group <- rownames(phyla_tab2) #Create new column called "group" in 'phyla_tab2' containing rownames
head(phyla_tab2)
fobar <- merge(meta, phyla_tab2, by = 'group') #Merge 'meta' with 'phyla_tab2' by "group"
head(fobar)
fobar.gather <- fobar %>% gather(Genus, value, -(group:Treatment))  #This converts 'fobar' to long-form dataframe.
#This also created new columns "Genus", "value"; it added columns "group" through "Treatment" before "Genus" and "value"
head(fobar.gather)

#Check to see where the extra "group" column is and remove the column
which(colnames(phyla_tab2)=="group") #Results say column 405 is "group" column
phyla_tab3 <- phyla_tab2[,-405] #Drop the 405th column
phyla_tab4 <- phyla_tab3[,colSums(phyla_tab3)>0.1] #Keep the columns that have greater than 0.1 value
phyla_tab4$group <- rownames(phyla_tab4) #Rename rownames as "group"
fobar2 <- merge(meta, phyla_tab4, by = 'group')
head(fobar2)
fobar2.gather <- fobar2 %>% gather(Genus, value, -(group:Treatment))
head(fobar2.gather)

#Create "All" column with "Day" and "Treatment" in 'fobar2.gather'
fobar2.gather$All <- paste(fobar2.gather$Day, fobar2.gather$Treatment, sep = '_')

#Count the number of unique items in 'fobar2.gather'. We're interested in the total unique number of genera
fobar2.gather %>% summarise_each(funs(n_distinct)) #86 total unique genera
fobar2.gather <- fobar2.gather %>% group_by(All) %>% mutate(value2=(value/(length(All)/86))*100) #86 refers to number of Genera

#Subset each "All" group from fobar2.gather and save as individual csv files.
#Two examples:
D0_Control.genus <- subset(fobar2.gather, All=="0_Control")
write.csv(D0_Control.genus, file="D0_Control.genus.csv")

D1_IAV.genus <- subset(fobar2.gather, All=="D1_IAV.genus")
write.csv(D1_IAV.genus, file="D4_IAV.genus")

#Calculate the total % percent abundance of each genera on each sample (I used JMP to do this)
#and save results in a spreadsheet editor such as Excel (see D0_Control.genus.xlsx for an example)
#Since we are only interested in genera that are above 2% abundance,
#calculate total percentage of all other genera that are less than 2% in the spreadsheet and label as "Other".
#Create a new spreadsheet and label as "Nasal genus.csv".
#Create the following columns: Day, Treatment group, Percent Abundance, and Genus.
#Copy the list of genera and their percent abundances from each of the individual Excel files to the respective "Nasal genus.csv" spreadsheet.
#Fill in the other columns manually (Day, Treatment Group).
#Save this as SRD129_Nasal_GenusPercentAbundance.csv. Continue to the next step.
nasalgen <- read.table('SRD129_Nasal_GenusPercentAbundance.csv', header = TRUE, sep = ",")
head(nasalgen)
unique(nasalgen.2$Day) #D0  D1  D3  D7  D10 D14 D21 D28 D36 D42
nasalgen.2$Day = factor(nasalgen.2$Day, levels = c("D0", "D1", "D3", "D7", "D10", "D14", "D21", "D28", "D36", "D42"))
nasalgen.2$More.than.2=as.character(nasalgen.2$Genus)
str(nasalgen.2$More.than.2) #Compactly display the internal structure of an R object,
nasalgen.2$More.than.2[nasalgen.2$Percent.abundance<1]<-"Other"
write.csv(nasalgen.2, file = "SRD129_Nasal_GenusPercentAbundanceAbove1percent.csv")

#To make sure the total percent abundance of all organisms for each day adds up to 100%,
#modify the percent abundance for "Other" for each day in "SRD129_Nasal_GenusPercentAbundanceAbove1percent.csv" in a spreadsheet editor
#and save as "SRD129_Nasal_GenusPercentAbundanceAbove1PercentAddTo100FINAL.csv"

#Create nasal genera plot
nasalgen.2 = read.csv("SRD129_Nasal_GenusPercentAbundanceAbove1PercentAddTo100FINAL.csv", header = TRUE)
levels(nasalgen.2$Day)  # "D0"  "D1"  "D10" "D14" "D21" "D28" "D3"  "D36" "D42" "D7"
nasalgen.2$Day = factor(nasalgen.2$Day, levels = c("D0", "D1", "D3", "D7", "D10", "D14", "D21", "D28", "D36", "D42"))

#Nasalgen.2 abundance plot for each day, more than 1% genera
(nasalgen.2plot <- ggplot(data=nasalgen.2, aes(x=Treatment, y=Percent.abundance, fill=Genus)) +
    geom_bar(stat = 'identity') +
    #geom_bar(stat= 'identity', colour='black') +
    #theme(legend.key = element_rect = element_rect(colour='black', size=1.5)) +
    facet_grid(~Day) + ylab('Relative abundance (%) at nasal site') +
    theme(plot.title = element_text(hjust = 0.5)) +
    theme(axis.text.x=element_text(angle=45, hjust=1),
          axis.title.x = element_blank()) +
    scale_fill_igv(name = "Genus") +
    theme(legend.direction = "vertical") +
    theme(legend.text = element_text(face = 'italic')))

ggsave("FluControl_NasalGenera.tiff", plot=nasalgen.2plot, width = 15, height = 7, dpi = 500, units =c("in"))
