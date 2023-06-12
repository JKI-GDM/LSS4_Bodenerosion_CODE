print("fLSrsagacmd: Calculation of LS factor using SAGA GIS and Rsagacmd")
#########################################################################################################
##Initiating saga object
#########################################################################################################

print("[1] Initiating saga object")
saga <- saga_gis(raster_backend = "terra",
                 saga_bin = "c:/_saga_830_x64/saga_cmd.exe")

#########################################################################################################
##Function
#########################################################################################################
fLSrsagacmd <- function(DATA.DIR,
                DEM.FILE,
                DEM.FRM,
                EPSG,
                PARCEL,
                ASC.DIR,
                ASC.EXPORT=TRUE){

#------------------------------------------------------------------------------- 
print("[2] Import DEM")
#------------------------------------------------------------------------------- 
saga$io_grid$import_esri_arc_info_grid(grid = paste(DATA.DIR,DEM.FILE,".sgrd",sep=""), 
                                         file = paste(DATA.DIR,DEM.FILE,DEM.FRM,sep=""))

#------------------------------------------------------------------------------- 
print("[3] Filling sinks")
#-------------------------------------------------------------------------------   
saga$ta_preprocessor$fill_sinks_planchon_darboux_2001(dem=paste(DATA.DIR,DEM.FILE,".sgrd",sep=""),
                                                      result=paste(DATA.DIR,DEM.FILE,"_FILL.sgrd",sep=""))
  
#------------------------------------------------------------------------------- 
print("[4] LS factor without boundaries")
#-------------------------------------------------------------------------------
saga$ta_hydrology$ls_factor_field_based(dem=paste(DATA.DIR,DEM.FILE,"_FILL.sgrd",sep=""),
                                          ls_factor=paste(ASC.DIR,DEM.FILE,"_LSnB.sgrd",sep=""),
                                          method=0)
  
  
#------------------------------------------------------------------------------- 
print("[5] Field-based LS factor")
#-------------------------------------------------------------------------------
saga$ta_hydrology$ls_factor_field_based(dem=paste(DATA.DIR,DEM.FILE,"_FILL.sgrd",sep=""),
                                          fields = paste(DATA.DIR,PARCEL,sep=""),
                                          ls_factor=paste(ASC.DIR,DEM.FILE,"_LSwB.sgrd",sep=""),
                                          method=0)

if(ASC.EXPORT==TRUE){
#------------------------------------------------------------------------------- 
print("[6] asc export")
#-------------------------------------------------------------------------------
setwd(file.path(ASC.DIR))
l.g <- mixedsort(list.files(pattern=paste("^(",DEM.FILE,").*\\.sdat$",sep="")),decreasing=TRUE)
print(l.g)
pb <- txtProgressBar(min=1, max=length(l.g), style=3)
for(i in 1:length(l.g)){
  r <- raster(paste(ASC.DIR,l.g[i],sep=""))
  writeRaster(r,paste(ASC.DIR,substr(l.g[i],1,nchar(l.g[i])-5),".asc",sep=""),overwrite=TRUE)
setTxtProgressBar(pb, i)
}
}
}
