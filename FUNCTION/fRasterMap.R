#######################################################################################
#######################################################################################
print("Automatic creation of maps")
#######################################################################################
#Land System Science 4 course, University of Halle-Wittenberg, Germany
#Markus Möller, markus.moeller@julius-kuehn.de  
#######################################################################################


#######################################################################################################
#packages
#######################################################################################################
loadandinstall <- function(mypkg) {if (!is.element(mypkg,
                                                   installed.packages()[,1])){install.packages(mypkg)};
  library(mypkg, character.only=TRUE)  }

pk <- c("raster",
        "sp",
        "RColorBrewer",
        "classInt")
for(i in pk){loadandinstall(i)}

fRasterMap <- function(DATA.DIR,
                     RASTER.FILE,
                     RASTER.FRM,
                     OUT.DIR,
                     VECTOR.FILE,
                     VECTOR.FRM,
                     N,
                     D,
                     REVERS=FALSE,
                     AXES=TRUE,
                     TITLE){
#######################################################################################################
#####directories
#######################################################################################################
#------------------------------------------------------------------------------------------------------
print("Import raster file")
#------------------------------------------------------------------------------------------------------
r <- raster(paste0(DATA.DIR,RASTER.FILE,RASTER.FRM))
crs(r) <- CRS(paste("+init=EPSG:",EPSG,sep=""))

#------------------------------------------------------------------------------------------------------
print("Plot raster map")
#------------------------------------------------------------------------------------------------------
setwd(file.path(DATA.DIR))
my.palette <- brewer.pal(n = N, name = "Spectral")
if(REVERS==TRUE){
  my.palette <- rev(my.palette)}
  
breaks.qt <- classIntervals(values(r), n = (N-1), style = "kmeans")

setwd(OUT.DIR)
png(paste("MAP_",RASTER.FILE,c(".png"),sep=""),width=2200,height=2100,res=300)
  plot(r,
       breaks = breaks.qt$brks,
       col=my.palette,
       legend=FALSE,
       axes = AXES,
       box = FALSE)
  s <- shapefile(paste0(DATA.DIR,VECTOR.FILE,VECTOR.FRM))
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
