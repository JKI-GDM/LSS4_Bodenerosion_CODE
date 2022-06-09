print("fLS: Calculation of LS factor using SAGA GIS")
#########################################################################################################
##Libraries and functions
#########################################################################################################
loadandinstall <- function(mypkg) {
  for(i in seq(along=mypkg)){
    if (!is.element(mypkg[i],installed.packages()[,1])){install.packages(mypkg[i])}
    library(mypkg[i], character.only=TRUE)
  }
}
packages <- sort(c("caret",
                   "caretEnsemble",
                   "classInt",
                   "doParallel",
                   "EFS",
                   "foreign",
                   "fpc",
                   "gstat",
                   "gtools",
                   "lattice",
                   "maptools",
                   "raster",
                   "rgdal",
                   "radiant.data", 
                   "rgeos",
                   "RSAGA",
                   "sf",
                   "sp",
                   "stats",
                   "stringr",
                   "tidyr",
                   "utils"))
loadandinstall(packages)

##Setting RSAGA environment
myenv <- rsaga.env(workspace="c:/Users/scien/_temp/", 
                   path="c:/_saga_222_x64",
                   modules = "c:/_saga_222_x64/modules")
print("RSAGA modules")
print(rsaga.get.libraries(path= myenv$modules))
rsaga.get.lib.modules("ta_lighting", env =  myenv, interactive = FALSE)
rsaga.get.usage("ta_lighting",0,env =  myenv)


#########################################################################################################
##Function
#########################################################################################################
fLS <- function(IN.DIR,
                DEM,
                DEM.FRM,
                OUT.DIR,
                EPSG){
  #------------------------------------------------------------------------------- 
  print("1 | Import DEM")
  #------------------------------------------------------------------------------- 
  rsaga.geoprocessor(
    lib="io_grid",
    module=1,
    param=list(FILE=paste(IN.DIR,DEM,DEM.FRM,sep=""),
               GRID=paste(OUT.DIR,DEM,".sgrd",sep="")),
    env=myenv)
  
  #r <- raster(paste(DEM.DIR,DEM,DEM.FRM,sep=""))
  #r[r < 0] <- NA
  #plot(r)
  #r <- aggregate(r,fact=AGGREGATE, fun=mean)
  #crs(r) <- CRS(paste("+init=EPSG:",EPSG,sep=""))
  #writeRaster(r,paste(OUT.DIR,DEM,sep=""),format="SAGA",overwrite=TRUE)
  #------------------------------------------------------------------------------- 
  print("2 | Filling sinks")
  #-------------------------------------------------------------------------------   
  rsaga.geoprocessor(
    lib="ta_preprocessor",
    module=3,
    param=list(DEM=paste(OUT.DIR,DEM,".sgrd",sep=""),
               RESULT=paste(OUT.DIR,DEM,"_FILL.sgrd",sep="")),
    env=myenv)
  
  #------------------------------------------------------------------------------- 
  print("3 | Field-based LS factor")
  #-------------------------------------------------------------------------------
  rsaga.geoprocessor(
    lib="ta_hydrology",
    module=25, 
    param=list(DEM=paste(OUT.DIR,DEM,"_FILL.sgrd",sep=""),
             FIELDS=paste(IN.DIR,FB,sep=""),
             UPSLOPE_AREA=paste(paste(OUT.DIR,DEM,"_FB-UA.sgrd",sep="")),
             UPSLOPE_LENGTH=paste(paste(OUT.DIR,DEM,"_FB-UL.sgrd",sep="")),
             UPSLOPE_SLOPE=paste(paste(OUT.DIR,DEM,"_FB-US.sgrd",sep="")),
             LS_FACTOR=paste(OUT.DIR,DEM,"_FB-LS.sgrd",sep=""),
             BALANCE=paste(OUT.DIR,DEM,"_BLC.sgrd",sep=""),
             METHOD=1,
             METHOD_AREA=3,
             METHOD_SLOPE=1),
    env=myenv)
  
  
  #------------------------------------------------------------------------------- 
print("asc export")
#-------------------------------------------------------------------------------
setwd(file.path(OUT.DIR))
l.g <- mixedsort(list.files(pattern=paste("^(",DEM,").*\\.sgrd$",sep="")),decreasing=TRUE)
print(l.g)
pb <- txtProgressBar(min=1, max=length(l.g), style=3)
for(i in 1:length(l.g)){
  rsaga.sgrd.to.esri(in.sgrds=paste(OUT.DIR,l.g[i],sep=""), 
                   out.grids=paste(OUT.DIR,substr(l.g[i],1,nchar(l.g[i])-5),".asc",sep=""), 
                   prec=3,
                   env=myenv)
  setTxtProgressBar(pb, i)
}
}
