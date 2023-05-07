print("Zonal statistics of raster files")
#########################################################################################################
##Libraries and functions
#########################################################################################################
loadandinstall <- function(mypkg) {
  for(i in seq(along=mypkg)){
    if (!is.element(mypkg[i],installed.packages()[,1])){install.packages(mypkg[i])}
    library(mypkg[i], character.only=TRUE)
  }
}
packages <- sort(c("dplyr",
                   "exactextractr",
                   "gtools",
                   "raster",
                   "rgdal",
                   "sf"))
loadandinstall(packages)


#########################################################################################################
##Function
#########################################################################################################
fZonalStatistics <- function(DATA.DIR,
                             RASTER.FILE,
                             RU.SHP,
                             #EPSG,
                             COL.NAME){
  
  #Import reference units and raster file
  p <- st_read(paste(DATA.DIR,RU.SHP,sep=""))
  r <- raster(paste(DATA.DIR,RASTER.FILE,sep=""))
  #crs(r) <- CRS(paste("+init=EPSG:",EPSG,sep=""))
  
  #Generate data frame of zonal statistcis results
  print("Zonal statistics")
  o <- exact_extract(r,p,'median')
  o <- data.frame(o)
  #Rename data frame
  colnames(o) <- c(paste(COL.NAME))

  #Combine shape file and data frame  
  p <- bind_cols(p, o)
  #Remove rows with NA values
  #p <- na.omit(p)
  #Export shape file
  write_sf(p,paste(DATA.DIR,RU.SHP,sep=""), delete_layer = TRUE)
}
