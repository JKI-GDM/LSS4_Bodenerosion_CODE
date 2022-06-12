#######################################################################################
#######################################################################################
#LS-factor::Dealing with R and SAGA-GIS (https://saga-gis.sourceforge.io/)
#######################################################################################
#######################################################################################
IN.DIR = "/media/data_storage/markus/ABAG/INPUT/"
OUT.DIR = "/media/data_storage/markus/ABAG/OUTPUT/"
EPSG = 31468

## Using RSAGA package 
source("/media/data_storage/markus/ABAG/FUNCTION/fLSrsaga.R")
# Information about SAGA-GIS modules and functions
rsaga.get.lib.modules("io_gdal", env =  myenv, interactive = FALSE)
rsaga.get.usage("io_gdal",1,env =  myenv)


fLSrsaga(IN.DIR = "/media/data_storage/markus/ABAG/INPUT/",
    DEM = "DGM10_EPSG31468",
    DEM.FRM = ".asc",
    OUT.DIR = "/media/data_storage/markus/ABAG/OUTPUT/",
    EPSG,
    PARCEL="Koennern_Feldblock_EPSG31468.shp",
    M.CA,
    M.LS1=1,
    M.LS2=1)


## Using Rsagacmd package
#source("/media/data_storage/markus/ABAG/FUNCTION/fLSrsagacmd.R")
#fLSrsagacmd(IN.DIR,
#         DEM = "DGM10_EPSG31468",
#         DEM.FRM = ".asc",
#         OUT.DIR,
#         EPSG,
#         PARCEL="Koennern_Feldblock_EPSG31468.shp",
#         M.CA,
#         M.LS1=1,
#         M.LS2=1)


#######################################################################################
#######################################################################################
#K-factor::rasterization of polygons
#######################################################################################
#######################################################################################
library("raster")

# Generate empty raster file
r <- raster(paste(IN.DIR,"DGM10_EPSG31468.asc",sep=""))
r <- r*0+1

# Import soil taxation
k <- shapefile(paste(IN.DIR,"Koennern_BS_EPSG31468.shp",sep="")) 
extent(r) <- extent(k)

# Rasterize
rk <- rasterize(k, r, 'KBxKH_BSGB')
plot(rk)
# Export
writeRaster(rk,paste(OUT.DIR,"K-Faktor_BS_EPSG31468.asc",sep=""),overwrite=TRUE)

# Import soil map 1:50000 (VBK 50) 
k <- shapefile("/media/data_storage/markus/ABAG/INPUT/Koennern_VBK_EPSG31468.shp") 
extent(r) <- extent(k)
rk <- rasterize(k, r, 'K_Faktor')
plot(rk)
writeRaster(rk,paste(OUT.DIR,"K-Faktor_VBK_EPSG31468.asc",sep=""))


#######################################################################################
#######################################################################################
#Zonal statistics
#######################################################################################
#######################################################################################
source("/media/data_storage/markus/ABAG/FUNCTION/fZonalStatistics.R")
fZonalStatistics(RASTER.DIR=OUT.DIR,
                 RASTER.FILE="K-Faktor_VBK_EPSG31468.asc",
                 RU.DIR=IN.DIR,
                 RU.SHP="Koennern_Feldblock_EPSG31468.shp",
                 OUT.DIR,
                 COL.NAME="K_VBK")


fZonalStatistics(RASTER.DIR=OUT.DIR,
                 RASTER.FILE="K-Faktor_BS_EPSG31468.asc",
                 RU.DIR=OUT.DIR,
                 RU.SHP="Koennern_Feldblock_EPSG31468.shp",
                 OUT.DIR,
                 COL.NAME="K_BS")


fZonalStatistics(RASTER.DIR=IN.DIR,
                 RASTER.FILE="R-Faktor_EPSG31468.tif",
                 RU.DIR=OUT.DIR,
                 RU.SHP="Koennern_Feldblock_EPSG31468.shp",
                 OUT.DIR,
                 COL.NAME="R")

fZonalStatistics(RASTER.DIR=OUT.DIR,
                 RASTER.FILE="DGM10_EPSG31468_LS1.sdat",
                 RU.DIR=OUT.DIR,
                 RU.SHP="Koennern_Feldblock_EPSG31468.shp",
                 OUT.DIR,
                 COL.NAME="LS1")

fZonalStatistics(RASTER.DIR=OUT.DIR,
                 RASTER.FILE="DGM10_EPSG31468_LS2.sdat",
                 RU.DIR=OUT.DIR,
                 RU.SHP="Koennern_Feldblock_EPSG31468.shp",
                 OUT.DIR,
                 COL.NAME="LS2")

#######################################################################################
#######################################################################################
#ABAG calculation and statistical comparison
#######################################################################################
#######################################################################################
RU.SHP="Koennern_Feldblock_EPSG31468.shp"
#Import
p <- st_read(paste(OUT.DIR,RU.SHP,sep=""))
head(p)
#ABAG variants
p$K_VBK_LS1 <- p$R*p$K_VBK*p$LS1
p$K_VBK_LS2 <- p$R*p$K_VBK*p$LS2
p$K_BS_LS1 <- p$R*p$K_BS*p$LS1
p$K_BS_LS2 <- p$R*p$K_BS*p$LS2
#Export
write_sf(p,paste(OUT.DIR,RU.SHP,sep=""), delete_layer = TRUE)

source("/media/data_storage/markus/ABAG/FUNCTION/fPlotR.R")

fPlotR(RU.DIR=OUT.DIR,
       RU.SHP="Koennern_Feldblock_EPSG31468.shp",
       PM1 = "K_VBK_LS1",
       PM2 = "K_VBK_LS2",
       OUT.DIR)

fPlotR(RU.DIR=OUT.DIR,
       RU.SHP="Koennern_Feldblock_EPSG31468.shp",
       PM1 = "K_VBK_LS1",
       PM2 = "K_BS_LS1",
       OUT.DIR)

fPlotR(RU.DIR=OUT.DIR,
       RU.SHP="Koennern_Feldblock_EPSG31468.shp",
       PM1 = "K_VBK_LS2",
       PM2 = "K_BS_LS2",
       OUT.DIR)
