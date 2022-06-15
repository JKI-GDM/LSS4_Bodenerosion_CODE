print("fLSrsaga: Calculation of LS factor using SAGA GIS and RSAGA")
#########################################################################################################
##Libraries and functions
#########################################################################################################
loadandinstall <- function(mypkg) {
  for(i in seq(along=mypkg)){
    if (!is.element(mypkg[i],installed.packages()[,1])){install.packages(mypkg[i])}
    library(mypkg[i], character.only=TRUE)
  }
}
packages <- sort(c("RSAGA",
                   "gtools"))
loadandinstall(packages)

##Setting RSAGA environment
myenv <- rsaga.env()

##Alternative 
#myenv <- rsaga.env(workspace="c:/Users/.../_temp/", 
#                   path="c:/...",
#                   modules = "c:/.../modules")

print("RSAGA modules")
print(rsaga.get.libraries(path= myenv$modules))


#########################################################################################################
##Function
#########################################################################################################
fLSrsaga <- function(IN.DIR,
                DEM,
                DEM.FRM,
                OUT.DIR,
                EPSG,
                PARCEL,
                M.CA=4,
                M.LS1,
                M.LS2){
  #------------------------------------------------------------------------------- 
  print("Import DEM")
  #------------------------------------------------------------------------------- 
  rsaga.geoprocessor(
    lib="io_grid",
    module=1,
    param=list(FILE=paste(IN.DIR,DEM,DEM.FRM,sep=""),
               GRID=paste(OUT.DIR,DEM,".sgrd",sep="")),
    env=myenv)

  
  #------------------------------------------------------------------------------- 
  print("Filling sinks")
  #-------------------------------------------------------------------------------   
  rsaga.geoprocessor(
    lib="ta_preprocessor",
    module=3,
    param=list(DEM=paste(OUT.DIR,DEM,".sgrd",sep=""),
               RESULT=paste(OUT.DIR,DEM,"_FILL.sgrd",sep="")),
    env=myenv)
  
  
  
  #------------------------------------------------------------------------------- 
  print("Slope calculation (degrees)")
  #-------------------------------------------------------------------------------
  rsaga.geoprocessor(lib="ta_morphometry",
                     module=0,
                     param=list(ELEVATION=paste(OUT.DIR,DEM,"_FILL.sgrd",sep=""),
                                SLOPE=paste(OUT.DIR,DEM,"_SLP.sgrd",sep=""),
                                METHOD=6,
                                UNIT_SLOPE=1),
                     env=myenv) 
  
  #------------------------------------------------------------------------------- 
  print("Catchment area")
  #-------------------------------------------------------------------------------
  rsaga.geoprocessor(lib="ta_hydrology",
                     module=0, 
                     param=list(ELEVATION=paste(OUT.DIR,DEM,"_FILL.sgrd",sep=""),
                                FLOW=paste(OUT.DIR,DEM,"_CA.sgrd",sep=""),
                                METHOD=M.CA),
                     env=myenv)
  
  
  #------------------------------------------------------------------------------- 
  print("LS factor")
  #-------------------------------------------------------------------------------
  rsaga.geoprocessor(
    lib="ta_hydrology",
    module=22, 
    param=list(SLOPE=paste(OUT.DIR,DEM,"_SLP.sgrd",sep=""),
               AREA=paste(OUT.DIR,DEM,"_CA.sgrd",sep=""),
               LS=paste(OUT.DIR,DEM,"_LS1.sgrd",sep=""),
               METHOD=M.LS1),
    env=myenv)
  
  #------------------------------------------------------------------------------- 
  print("Field-based LS factor")
  #-------------------------------------------------------------------------------
  rsaga.geoprocessor(
    lib="ta_hydrology",
    module=25, 
    param=list(DEM=paste(OUT.DIR,DEM,"_FILL.sgrd",sep=""),
             FIELDS=paste(IN.DIR,PARCEL,sep=""),
             UPSLOPE_AREA=paste(paste(OUT.DIR,DEM,"_FB-UA.sgrd",sep="")),
             UPSLOPE_LENGTH=paste(paste(OUT.DIR,DEM,"_FB-UL.sgrd",sep="")),
             UPSLOPE_SLOPE=paste(paste(OUT.DIR,DEM,"_FB-US.sgrd",sep="")),
             LS_FACTOR=paste(OUT.DIR,DEM,"_LS2.sgrd",sep=""),
             BALANCE=paste(OUT.DIR,DEM,"_BLC.sgrd",sep=""),
             METHOD=M.LS2,
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
