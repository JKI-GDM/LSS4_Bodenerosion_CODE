print("Function to crop one- or multi-dimensional raster files")
#########################################################################################################
##Libraries
#########################################################################################################
loadandinstall <- function(mypkg) {
  for(i in seq(along=mypkg)){
    if (!is.element(mypkg[i],installed.packages()[,1])){install.packages(mypkg[i])}
    library(mypkg[i], character.only=TRUE)
  }
}
packages <- sort(c("raster"))
loadandinstall(packages)
#########################################################################################################
##Function
#########################################################################################################
fCropRaster <- function(RU.DIR,
                        RU.SHP,
                        RASTER.DIR,
                        RASTER.FILE,
                        RASTER.FRM,
                        INPUT.EPSG,
                        MULTI=TRUE,
                        EXTENT=TRUE,
                        REPROJECT=TRUE,
                        OUTPUT.EPSG,
                        OUTPUT.RES){
s <- shapefile(file.path(RU.DIR,RU.SHP),verbose=TRUE)

if(MULTI==TRUE){
r <- stack(paste(RASTER.DIR,RASTER.FILE,RASTER.FRM,sep=""))}
if(MULTI==FALSE){
r <- raster(paste(RASTER.DIR,RASTER.FILE,RASTER.FRM,sep=""))}
crs(r) <- CRS(paste("+init=epsg:",INPUT.EPSG,sep=""))
#reproject raster file
if(REPROJECT==TRUE){
  r = projectRaster(r, crs = paste("+init=epsg:",OUTPUT.EPSG,sep=""), 
                    method = "bilinear",
                    res = OUTPUT.RES)
}
if(RASTER.FRM==".tif"){
  writeRaster(r, filename=paste(RASTER.DIR,RASTER.FILE,"_",OUTPUT.EPSG,RASTER.FRM,sep=""), format="GTiff", overwrite=TRUE)}
if(RASTER.FRM==".asc"){
  writeRaster(r, filename=paste(RASTER.DIR,RASTER.FILE,"_",OUTPUT.EPSG,RASTER.FRM,sep=""), format="ascii", overwrite=TRUE)}
if(RASTER.FRM==".sdat"){
  writeRaster(r, filename=paste(RASTER.DIR,RASTER.FILE,"_",OUTPUT.EPSG,RASTER.FRM,sep=""), format="SAGA", overwrite=TRUE)}

#reproject shape file
s <- spTransform(s, r@crs)
if(EXTENT==FALSE){
r.crop <- crop(r, s)}
if(EXTENT==TRUE){
r.crop <- crop(r, extent(s))}
if(RASTER.FRM==".tif"){
writeRaster(r.crop, filename=paste(RASTER.DIR,RASTER.FILE,"_","_CROP",RASTER.FRM,sep=""), format="GTiff", overwrite=TRUE)}
if(RASTER.FRM==".asc"){
  writeRaster(r.crop, filename=paste(RASTER.DIR,RASTER.FILE,"_","_CROP",RASTER.FRM,sep=""), format="ascii", overwrite=TRUE)}
if(RASTER.FRM==".sdat"){
  writeRaster(r.crop, filename=paste(RASTER.DIR,RASTER.FILE,"_","_CROP",RASTER.FRM,sep=""), format="SAGA", overwrite=TRUE)}
}

     