#######################################################################################
#######################################################################################
#Derivation coupling of ABAG factors (variants) LS, R and by using R and SAGA-GIS
#######################################################################################
#Land System Science 4 course, University of Halle-Wittenberg, Germany
#Markus Möller, markus.moeller@julius-kuehn.de  
#######################################################################################


#######################################################################################
#Settings
#######################################################################################
#Directories and input data
DATA.DIR = ".../INPUT/"
FUNC.DIR = ".../FUNCTION/"
EPSG = 31468
DEM.FILE = "DEM name"#e.g. "DGM90_EPSG31468"
VECTOR.FILE = "Koennern_Feldblock_EPSG31468.shp"

#Create directory
OUT.DIR = paste(DATA.DIR,DEM.FILE,"/",sep="")
dir.create(OUT.DIR)

#Load and install packages
loadandinstall <- function(mypkg) {
  for(i in seq(along=mypkg)){
    if (!is.element(mypkg[i],installed.packages()[,1])){install.packages(mypkg[i])}
    library(mypkg[i], character.only=TRUE)
  }
}
packages <- sort(c("Rsagacmd",
                   "gtools",
                   "terra",
                   "raster",
                   "sf",
                   "randomForest",
                   "caret",
                   "utils",
                   "Hmisc",
                   "corrplot"))
loadandinstall(packages)

#Package information
packageDescription("caret")
??caret::caret

#######################################################################################
#LS factor derivation with SAGA-GIS
#######################################################################################
source(file.path(FUNC.DIR,"fLSrsagacmd.R"))
fLSrsagacmd(DATA.DIR,
         DEM.FILE,
         DEM.FRM = ".asc",
         EPSG,
         PARCEL=VECTOR.FILE,
         ASC.DIR=OUT.DIR,
         ASC.EXPORT=TRUE)

#######################################################################################
#K factor (Rasterization of polygons)
#######################################################################################
#Generate empty raster file
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

#Rasterize
extent(r) <- extent(k)
kbs <- raster::rasterize(k, r, 'KBxKH_BSGB')
plot(kbs)
# Export
raster::writeRaster(kbs,paste(OUT.DIR,DEM.FILE,"_KBS.asc",sep=""),overwrite=TRUE)

#Import soil map 1:50000 (VBK 50) 
k <- sf::read_sf(paste(DATA.DIR,"Koennern_VBK_EPSG31468.shp",sep="")) 
names(k)
plot(density(k$K_Faktor,na.rm=TRUE))

#Rasterize
extent(r) <- extent(k)
kbk <- raster::rasterize(k, r, 'K_Faktor')
plot(kbk)
#Export
raster::writeRaster(kbk,paste(OUT.DIR,DEM.FILE,"_KBK.asc",sep=""),overwrite=TRUE)

#######################################################################################
#R factor (Resampling and cropping of existing of raster data set)
#######################################################################################
#Import
rf <- raster::raster(paste(DATA.DIR,"R-Faktor_EPSG31468.tif",sep=""))

cuts=seq(0,1000,20) #set breaks
pal <- colorRampPalette(c("green","blue"))
plot(rf, 
     breaks=cuts, 
     col = pal(20),
     legend=FALSE) #plot with defined breaks

#Resampling
rf <- raster::resample(rf, r, method='bilinear')
plot(rf)
#Export
raster::writeRaster(rf,paste(OUT.DIR,DEM.FILE,"_R.asc",sep=""), overwrite=TRUE)


#######################################################################################
#Zonal statistics
#######################################################################################
#Raster to polygones
names(r) <- c("ID")
pr <- raster::rasterToPolygons(r)
pr$ID <- 1:nrow(pr@data)

#Export as shapefile
sf::write_sf(st_as_sf(pr),paste(OUT.DIR,DEM.FILE,"_ABAG.shp",sep=""), delete_layer = TRUE)

#List asc-files, which should be coupled 
setwd(file.path(OUT.DIR))
l.g <- gtools::mixedsort(list.files(pattern=paste("^(",DEM.FILE,").*\\.asc$",sep="")),decreasing=TRUE)
print(l.g)

source("d:/Dropbox/GIT/ABAG/FUNCTION/fZonalStatistics.R")
for (i in 1:length(l.g)){
  fZonalStatistics(DATA.DIR=OUT.DIR,
                   RASTER.FILE=l.g[i],
                   RU.SHP=paste(DEM.FILE,"_ABAG.shp",sep=""),
                   COL.NAME=substr(l.g[i],17,nchar(l.g[i])-4)) 
}

#######################################################################################
#Calculating a correlation matrix of ABAG factors
#######################################################################################
#Import
A <- sf::read_sf(paste(OUT.DIR,DEM.FILE,"_ABAG.shp",sep=""))
#Remove geometry information
sf::st_geometry(A) <- NULL

#create a data frame of ABAG factors
df.A <- data.frame(A[2:6])

#Remove NA
df.A[df.A == 0] <- NA
df.A <- na.omit(df.A)


#Correlation matrix
cor(df.A)
Hmisc::rcorr(as.matrix(df.A))

#Correlation plot
?corrplot
corrplot::corrplot(cor(df.A),
                   method = c("number"),
                   bg = "lightgrey",
                   outline = TRUE)

#######################################################################################
#Calculation of Soil Loss and analyzing  ABAG factors 
#######################################################################################
#Selecting factos
df.A <- df.A[c(1,2,4)]
head(df.A)

#Factor multiplication
df.A$A =  Reduce(`*`, df.A)#Product calculation
head(df.A)

#Derive training data set
set.seed(123)
indxTrain <- caret::createDataPartition(y = df.A$A, p = 0.25,list = FALSE)
df.A.train <- df.A[indxTrain,]
df.A.test <- df.A[-indxTrain,]
nrow(df.A)
nrow(df.A.train)
nrow(df.A.test)

#KS test of training and total data set
ks.test(df.A.train$A,df.A$A)

#Model
set.seed(123)
ctrl <- caret::trainControl(method="repeatedcv",
                            number=5)

head(df.A.train)
m.Fit <-   caret::train(A ~ .,
                        data = df.A.train,
                        method = "rf",
                        trControl = ctrl,
                        preProc = c("center", "scale"),
                        importance = TRUE,
                        verbose = TRUE)
m.Fit$results

#Variable importance
as.data.frame(varImp(m.Fit)$importance)
plot(varImp(m.Fit))


#######################################################################################
#Plot raster files
#######################################################################################
source(file.path(FUNC.DIR,"fRasterMap.R"))
fRasterMap(DATA.DIR,
           RASTER.FILE="DGM90_EPSG31468",
           RASTER.FRM=".asc",
           VECTOR.FILE="Koennern_Feldblock_EPSG31468",
           VECTOR.FRM = ".shp",
           N=9,#Number of classes
           D=2,#Number of decimal places
           REVERS=FALSE,#revers colore order 
           REPROJECT=FALSE,#desired projection
           AXES=TRUE,#Axes and frame box with geographical tics
           EPSG=31468,#EPSG code (http://spatialreference.org)
           TITLE="DEM"
)

