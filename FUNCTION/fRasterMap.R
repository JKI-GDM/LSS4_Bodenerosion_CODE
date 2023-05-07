#######################################################################################################
#######################################################################################################
#######################################################################################################
print("Automatic creation of maps")
#######################################################################################################
#######################################################################################################
#######################################################################################################
#packages
#######################################################################################################
loadandinstall <- function(mypkg) {if (!is.element(mypkg,
                                                   installed.packages()[,1])){install.packages(mypkg)};
  library(mypkg, character.only=TRUE)  }

pk <- c("raster",
        "rgdal",
        "maptools",
        "sp",
        "RColorBrewer",
        "classInt")
for(i in pk){loadandinstall(i)}

fRasterMap <- function(DATA.DIR,
                     RASTER.FILE,
                     RASTER.FRM,
                     VECTOR.FILE,
                     VECTOR.FRM,
                     N,
                     D,
                     REVERS=FALSE,
                     EPSG,
                     AXES=TRUE,
                     REPROJECT=TRUE,
                     TITLE){
#######################################################################################################
#####directories
#######################################################################################################
#------------------------------------------------------------------------------------------------------
print("Import raster file")
#------------------------------------------------------------------------------------------------------
r <- raster(paste(DATA.DIR,RASTER.FILE,RASTER.FRM,sep=""))
crs(r) <- CRS(paste("+init=EPSG:",EPSG,sep=""))

if(REPROJECT==TRUE){
print("Reproject raster file")
r <- projectRaster(r, crs=CRS(paste("+init=epsg:",EPSG,sep="")))
}
#------------------------------------------------------------------------------------------------------
print("Plot raster map")
#------------------------------------------------------------------------------------------------------
setwd(file.path(DATA.DIR))
my.palette <- brewer.pal(n = N, name = "Spectral")
if(REVERS==TRUE){
  my.palette <- rev(my.palette)}
  
breaks.qt <- classIntervals(values(r), n = (N-1), style = "kmeans")

png(paste("MAP_",RASTER.FILE,c(".png"),sep=""),width=2200,height=2100,res=300)
  plot(r,
       breaks = breaks.qt$brks,
       col=my.palette,
       legend=FALSE,
       axes = AXES,
       box = FALSE)
  s <- shapefile(paste(DATA.DIR,VECTOR.FILE,VECTOR.FRM,sep=""))
  s <- spTransform(s, r@crs)
  plot(s,
       add=TRUE,
       lwd=2)

  legend("bottomright",
         title=paste(TITLE), 
         legend = round(breaks.qt$brks,D), 
         fill = my.palette,
         bty="y",
         cex=1.15)
dev.off()
}
  