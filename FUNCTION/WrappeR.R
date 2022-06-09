source("d:/Dropbox/GIT/LV_SS22/FUNCTION/fCropRaster.R")

fCropRaster(RU.DIR="d:/Dropbox/GIT/LV_SS22/FUNCTION/",
            RU.SHP = "Koennern_Testsite_EPSG31468.shp",
            RASTER.DIR = "d:/Dropbox/DATA/DEM_GERMANY/SRTM/",
            RASTER.FILE = "SRTM_DSM_EPSG31468",
            RASTER.FRM = ".tif",
            INPUT.EPSG = 31468,
            MULTI=FALSE,
            EXTENT=TRUE,
            REPROJECT=FALSE,
            OUTPUT.EPSG = 31468,
            OUTPUT.RES=90)

source("d:/Dropbox/GIT/LV_SS22/FUNCTION/fMosaicBKG.R")
fMosaicBKG(RASTER.DIR="d:/Dropbox/DATA/DEM_GERMANY/DHM10BKG/",
           VECTOR.FILE="d:/Dropbox/GIT/LV_SS22/INPUT/Koennern_Testsite_EPSG25832.shp",
           VECTOR.GRID="d:/Dropbox/DATA/DEM_GERMANY/DHM10BKG/dgm10_k20_utm32s.shp",
           MOSAIC.DIR="d:/Dropbox/DATA/DEM_GERMANY/DHM10BKG/",
           MOSAIC.NAME="DGM10BKG_EPSG25832",
           AGGREGATE=1,
           RASTER.FRM="asc",
           EXTENT=TRUE,
           EXTENT.NAME="KOENNERN_EXTENT")

source("d:/Dropbox/GIT/LV_SS22/FUNCTION/fIntersecteR.R")
IntersecteR(OUT.DIR="d:/Dropbox/GIT/LV_SS22/INPUT/",
            FB="d:/Dropbox/DATA/LPIS/Sachsen-Anhalt/FB_LSA_EPSG31468.shp",
            TS="d:/Dropbox/GIT/LV_SS22/INPUT/Koennern_Testsite_EPSG31468.shp")


