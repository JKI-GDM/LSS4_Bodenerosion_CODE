print("fLSrsagacmd: Calculation of LS factor using SAGA GIS and Rsagacmd")
#########################################################################################################
##Libraries and functions
#########################################################################################################
loadandinstall <- function(mypkg) {
  for(i in seq(along=mypkg)){
    if (!is.element(mypkg[i],installed.packages()[,1])){install.packages(mypkg[i])}
    library(mypkg[i], character.only=TRUE)
  }
}
packages <- sort(c("Rsagacmd",
                   "gtools"))
loadandinstall(packages)


# Initiate a saga object
saga <- saga_gis(raster_backend = "terra")

##Setting RSAGA environment
myenv <- rsaga.env()

#########################################################################################################
##Function
#########################################################################################################
fLSrsagacmd <- function(IN.DIR,
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
  saga$io_grid$import_esri_arc_info_grid(grid = paste(OUT.DIR,DEM,".sgrd",sep=""), 
                                         file = paste(IN.DIR,DEM,DEM.FRM,sep=""))
  
  
  #------------------------------------------------------------------------------- 
  print("Filling sinks")
  #-------------------------------------------------------------------------------   
  saga$ta_preprocessor$fill_sinks_planchon_darboux_2001(dem=paste(OUT.DIR,DEM,".sgrd",sep=""),
                                                        result=paste(OUT.DIR,DEM,"_FILL.sgrd",sep=""))
  
  #------------------------------------------------------------------------------- 
  print("Slope calculation (degrees)")
  #-------------------------------------------------------------------------------
  saga$ta_morphometry$slope_aspect_curvature(elevation=paste(OUT.DIR,DEM,"_FILL.sgrd",sep=""),
                                             slope=paste(OUT.DIR,DEM,"_SLP.sgrd",sep=""),
                                             method=6,
                                             unit_slope=1)
  
  #------------------------------------------------------------------------------- 
  print("Catchment area")
  #-------------------------------------------------------------------------------
  saga$ta_hydrology$flow_accumulation_top_down(elevation=paste(OUT.DIR,DEM,"_FILL.sgrd",sep=""),
                                               flow=paste(OUT.DIR,DEM,"_CA.sgrd",sep=""),
                                               method=M.CA)
  
  #------------------------------------------------------------------------------- 
  print("LS factor")
  #-------------------------------------------------------------------------------
  saga$ta_hydrology$ls_factor(slope=paste(OUT.DIR,DEM,"_SLP.sgrd",sep=""),
                              area=paste(OUT.DIR,DEM,"_CA.sgrd",sep=""),
                              ls=paste(OUT.DIR,DEM,"_LS1.sgrd",sep=""),
                              method=M.LS1)

  #------------------------------------------------------------------------------- 
  print("Field-based LS factor")
  #-------------------------------------------------------------------------------
  saga$ta_hydrology$ls_factor_field_based(dem=paste(OUT.DIR,DEM,"_FILL.sgrd",sep=""),
                                          fields = paste(IN.DIR,PARCEL,sep=""),
                                          upslope_area=paste(paste(OUT.DIR,DEM,"_FB-UA.sgrd",sep="")),
                                          upslope_length=paste(paste(OUT.DIR,DEM,"_FB-UL.sgrd",sep="")),
                                          upslope_slope=paste(paste(OUT.DIR,DEM,"_FB-US.sgrd",sep="")),
                                          ls_factor=paste(OUT.DIR,DEM,"_LS2.sgrd",sep=""),
                                          balance=paste(OUT.DIR,DEM,"_BLC.sgrd",sep=""),
                                          method=M.LS2,
                                          method_area=3,
                                          method_slope=1)

#------------------------------------------------------------------------------- 
print("asc export")
#-------------------------------------------------------------------------------
setwd(file.path(OUT.DIR))
l.g <- mixedsort(list.files(pattern=paste("^(",DEM,").*\\.sdat$",sep="")),decreasing=TRUE)
print(l.g)
pb <- txtProgressBar(min=1, max=length(l.g), style=3)
for(i in 1:length(l.g)){
  r <- raster(paste(OUT.DIR,l.g[i],sep=""))
  writeRaster(r,paste(OUT.DIR,substr(l.g[i],1,nchar(l.g[i])-5),".asc",sep=""),overwrite=TRUE)
setTxtProgressBar(pb, i)
}
}
