setwd("U:/r_map") # set working directory

#install.packages("rgdal")
library(rgdal)
# read in eGRID subregion shapefile 
# The original eGRID shapefile can be found here: https://www.epa.gov/energy/download-egrid2014-shapefiles
# Those shapefiles are problematic for plotting the contiguous US for a few reasons: 
# 1. parts of Alaska are on the Eastern Hemisphere, so 2-D maps show the entire world
# 2. the maps are incredibly large, leading to slow plot times and large file sizes
# In egrid_shpfiles_edit I have removed the parts of the shapefile in the eastern Hemisphere using ArcGIS (ArcMap I think)
# In the egrid_shpfiles_edit_simple, I have simplified the shapefile on the website mapshaper.org 
# Typically I simplify to about 10%, using default settings and checking "prevent shape removal"
# Each simple folder is a simplification of the previous simple folder. 
# i.e. simple2 is the simplified file from simple
# Therefore, simple 3 has been simplified 3 times. 
# I find this leads to fast plotting times (around 3 seconds) without losing too much resolution on the map
egrid_subrgn <- readOGR('egrid_shpfiles_edit_simple3','eGRID2014_subregions')
# remove AK and HI from subregions
egrid_subrgn <- egrid_subrgn[!egrid_subrgn$zips_for_G %in% 
                    c("AKGD", "AKMS", "HIOA", "HIMS"), ] 

trace_elem = 'Cl' # select trace element 

#install.packages("readxl")
library(readxl)
# define filenames 
# first file contains emission factors (mg/MWh) by eGRID subregion
# second file contains mass loadins (kg/yr) and emission factors (mg/MWh)
# for each power plant 
filename1 = paste('data_egrid_emf_', trace_elem, '.xlsx', sep='')
filename2 = paste('data_boot_cq_remov_', trace_elem, '.xlsx', sep='')
# input data
df <- read_excel(filename1)
df2 <- read_excel(filename2)
# some formatting of data
df$liq_mg_mwh <- round(df$liq_mg_mwh, digits = 1) # I don't think this works
df2$liq_kg <- df2$liq_mg/1e6 # converts mg to kg 

# rename column headers - this formats the legend down the line 
#install.packages("dplyr")
library(dplyr)
df2 <- rename(df2, "Plant level emissions (kg)" = liq_kg,
         "Plant level waste stream factor (mg/MWh)" = liq_emf_mg_mwh) 

# joins coordinate data to plant source data: 
pt <- SpatialPointsDataFrame(coords = df2[,c("Longitude","Latitude")], data = df2,
                             proj4string = CRS("+proj=longlat +datum=WGS84"))
# joins spatial geometry to regional level emissions: 
egrid_subrgn@data <- left_join(egrid_subrgn@data, df, by=c("zips_for_G" = "eGRID"))

#install.packages("tmap")
library(tmap)

start_time <- Sys.time() # keep track of time 

# plotting 
tm_shape(egrid_subrgn) + # plots US plot 
  # colors eGRID subregions by emission factors
  tm_fill("liq_mg_mwh", style="quantile", palette="Blues",
          title="Liquid waste stream factors (mg/MWh)") +
  # writes labels on top of eGRID subregions 
  #tm_text("zips_for_G", scale= 0.7, col = "black", 
   #       bg.color="white", bg.alpha = .66) +
  tm_borders("black") +
  tm_legend(outside = TRUE, text.size = 2) + 
  tm_layout(frame = FALSE, 
            legend.outside.position = "bottom", 
            legend.text.size = 0.5, 
            legend.hist.size = 0.5,
            legend.stack = "horizontal") + 
tm_shape(pt) + # plots individual data points 
  tm_bubbles(size="Plant level emissions (kg)", 
             col="Plant level waste stream factor (mg/MWh)", 
             border.col="black", border.lwd = 1, scale = 1.2) 
save_tmap(filename = paste('output_maps/',trace_elem,'_map.pdf',sep=''), 
          width = 4, height = 4, units = "in", useDingbats=FALSE)

Sys.time() - start_time # report time elapsed 

