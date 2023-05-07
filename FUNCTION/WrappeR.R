#######################################################################################
#######################################################################################
#LS-factor::Dealing with R and SAGA-GIS
#######################################################################################
#######################################################################################
DATA.DIR = "d:/Dropbox/GIT/ABAG/DATA/"
FUNC.DIR = "d:/Dropbox/GIT/ABAG/FUNCTION/"
OUT.DIR = "d:/Dropbox/GIT/ABAG/DATA/DGM20/"
EPSG = 31468
DEM.FILE = "DGM20_EPSG31468"
VECTOR.FILE = "Koennern_Feldblock_EPSG31468.shp"
## LS factor calculation
source(file.path(FUNC.DIR,"fLSrsagacmd.R"))
fLSrsagacmd(DATA.DIR,
         DEM.FILE,
         DEM.FRM = ".asc",
         EPSG,
         PARCEL=VECTOR.FILE,
         ASC.EXPORT=TRUE)

#######################################################################################
#######################################################################################
#K-factor::rasterization of polygons
#######################################################################################
#######################################################################################
# Generate empty raster file
r <- raster::raster(paste(DATA.DIR,DEM.FILE,".asc",sep=""))
r
crs(r) <- CRS(paste("+init=EPSG:",EPSG,sep=""))
r
plot(r)
r <- r*0+1

# Import soil taxation
k <- sf::read_sf(paste(DATA.DIR,"Koennern_BS_EPSG31468.shp",sep="")) 
names(k)
plot(density(k$KBxKH_BSGB,na.rm=TRUE))

# Rasterize
extent(r) <- extent(k)
kbs <- raster::rasterize(k, r, 'KBxKH_BSGB')
plot(kbs)
# Export
writeRaster(kbs,paste(DATA.DIR,DEM.FILE,"_KBS.asc",sep=""),overwrite=TRUE)

# Import soil map 1:50000 (VBK 50) 
k <- sf::read_sf(paste(DATA.DIR,"Koennern_VBK_EPSG31468.shp",sep="")) 
names(k)
plot(density(k$K_Faktor,na.rm=TRUE))

# Rasterize
extent(r) <- extent(k)
kbk <- raster::rasterize(k, r, 'K_Faktor')
plot(kbk)
writeRaster(kbk,paste(DATA.DIR,DEM.FILE,"_KBK.asc",sep=""),overwrite=TRUE)

#######################################################################################
#######################################################################################
#R-factor::resample raster data
#######################################################################################
#######################################################################################
rf <- raster::raster(paste(DATA.DIR,"R-Faktor_EPSG31468.tif",sep=""))
rf

plot(rf)
cuts=seq(0,1000,20) #set breaks
pal <- colorRampPalette(c("green","blue"))
plot(rf, 
     breaks=cuts, 
     col = pal(20),
     legend=FALSE) #plot with defined breaks


rf <- raster::resample(rf, r, method='bilinear')
plot(rf)
writeRaster(rf,paste(DATA.DIR,DEM.FILE,"_R.asc",sep=""), overwrite=TRUE)


#######################################################################################
#######################################################################################
#Zonal statistics
#######################################################################################
#######################################################################################
#Raster to polygones
names(r) <- c("ID")
pr <- raster::rasterToPolygons(r)
pr$ID <- 1:nrow(pr@data)

#Export as shapefile
write_sf(st_as_sf(pr),paste(OUT.DIR,DEM.FILE,"_ABAG.shp",sep=""), delete_layer = TRUE)

#List asc-files, which should be coupled 
setwd(file.path(OUT.DIR))
l.g <- mixedsort(list.files(pattern=paste("^(",DEM.FILE,").*\\.asc$",sep="")),decreasing=TRUE)
print(l.g)

source("d:/Dropbox/GIT/ABAG/FUNCTION/fZonalStatistics.R")
NAMESLIST <- c("LSwb","R","LSnB","KBS","KBK")
for (i in 1:length(l.g)) {
  fZonalStatistics(DATA.DIR=OUT.DIR,
                   RASTER.FILE=l.g[i],
                   RU.SHP=paste(DEM.FILE,"_ABAG.shp",sep=""),
                   COL.NAME=NAMESLIST[i]) 
}

#######################################################################################
#######################################################################################
#Plotting of raster files
#######################################################################################
#######################################################################################
source(file.path(FUNC.DIR,"fRasterMap.R"))
fRasterMap(DATA.DIR,
           RASTER.FILE="DGM20_EPSG31468_wB-LS",
           RASTER.FRM=".sdat",
           VECTOR.FILE="Koennern_Feldblock_EPSG31468",
           VECTOR.FRM = ".shp",
           N=9,#Number of classes
           D=2,#Number of decimal places
           REVERS=FALSE,#revers colore order 
           REPROJECT=FALSE,#desired projection
           AXES=TRUE,#Axes and frame box with geographical tics
           EPSG=31468,#EPSG code (http://spatialreference.org)
           TITLE="LS (wB)"
)

