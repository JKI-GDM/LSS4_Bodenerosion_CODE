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
fZonalStatistics <- function(RASTER.DIR,
                             RASTER.FILE,
                             RU.DIR,
                             RU.SHP,
                             #EPSG,
                             OUT.DIR,
                             COL.NAME){
  
  #Import reference units and raster file
  p <- st_read(paste(RU.DIR,RU.SHP,sep=""))
  plot(p)
  head(p)
  r <- raster(paste(RASTER.DIR,RASTER.FILE,sep=""))
  plot(r)
  #crs(r) <- CRS(paste("+init=EPSG:",EPSG,sep=""))
  
  #Generate data frame of zonal statistcis results
  print("Zonal statistics")
  o <- exact_extract(r,p,'median')
  o <- data.frame(o)
  #Rename data frame
  colnames(o) <- c(paste(COL.NAME))

  #Combine shape file and data frame  
  p <- bind_cols(p, o)
  #Remove rows wit NA values
  #p <- na.omit(p)
  plot(p)
  #Export shape file
  write_sf(p,paste(OUT.DIR,RU.SHP,sep=""), delete_layer = TRUE)
}
