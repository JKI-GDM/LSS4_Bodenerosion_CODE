#######################################################################################
#######################################################################################
print("Derivation coupling of ABAG factors (variants) LS, R and by using R and SAGA-GIS")
#######################################################################################
#Land System Science 4 course, University of Halle-Wittenberg, Germany
#Markus Möller, markus.moeller@julius-kuehn.de  
#######################################################################################


#######################################################################################
#Settings
#######################################################################################
#Directories and input data
DATA.DIR = paste0(getwd(),"/INPUT/")
FUNC.DIR = paste0(getwd(),"/FUNCTION/")
SAGA.DIR = "c:/_saga_791_x64/saga_cmd.exe"
EPSG = 31468
RESOLUTION = 90
DEM.FILE = "DGM90_EPSG31468"
VECTOR.FILE = "Koennern_Feldblock_EPSG31468.shp"
#Create output directory
setwd(getwd())
dir.create("OUTPUT")
OUT.DIR = paste0(getwd(),"/OUTPUT/")

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
                   "corrplot",
                   "ranger"))
loadandinstall(packages)

#Package information
packageDescription("caret")
??caret::caret

#######################################################################################
#LS factor derivation with SAGA-GIS
#######################################################################################
#Plot DEM
source(file.path(FUNC.DIR,"fRasterMap.R"))
fRasterMap(DATA.DIR,
           RASTER.FILE =DEM.FILE,
           RASTER.FRM =".asc",
           OUT.DIR = OUT.DIR,
           VECTOR.FILE="Koennern_Feldblock_EPSG31468",
           VECTOR.FRM = ".shp",
           N=9,#Number of classes
           D=2,#Number of decimal places
           REVERS=FALSE,#revers color order 
           AXES=TRUE,#Axes and frame box with geographical tics
           TITLE="DEM"
)


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
r <- projectRaster(r, crs = crs(r), res = RESOLUTION)
res(r)
plot(r)
r <- r*0+1
plot(r)

# Import soil taxation
k <- sf::read_sf(paste(DATA.DIR,"Koennern_BS_EPSG31468.shp",sep="")) 
names(k)
plot(density(k$KBxKH_BSGB,na.rm=TRUE))

#Rasterize
extent(r) <- extent(k)
kbs <- raster::rasterize(k, r, 'KBxKH_BSGB')
res(kbs)
kbs <- projectRaster(kbs, crs = crs(r), res = RESOLUTION)
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
res(kbk)
kbk <- projectRaster(kbk, crs = crs(r), res = RESOLUTION)
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
     legend=TRUE) #plot with defined breaks

#plot R factor
source(file.path(FUNC.DIR,"fRasterMap.R"))
fRasterMap(DATA.DIR,
           RASTER.FILE ="R-Faktor_EPSG31468",
           RASTER.FRM =".tif",
           OUT.DIR = OUT.DIR,
           VECTOR.FILE="Koennern_Feldblock_EPSG31468",
           VECTOR.FRM = ".shp",
           N=9,#Number of classes
           D=2,#Number of decimal places
           REVERS=FALSE,#revers color order 
           AXES=TRUE,#Axes and frame box with geographical tics
           TITLE="R factor"
)

#Resampling
rf <- raster::resample(rf, r, method='bilinear')
res(rf)
rf <- projectRaster(rf, crs = crs(r), res = RESOLUTION)
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
l.g <- gtools::mixedsort(list.files(pattern=paste0("^(",DEM.FILE,").*\\.asc$")),decreasing=TRUE)
print(l.g)

source(file.path(FUNC.DIR,"fZonalStatistics.R"))
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
A <- sf::read_sf(paste0(OUT.DIR,DEM.FILE,"_ABAG.shp"))
#Remove geometry information
sf::st_geometry(A) <- NULL

#create a data frame of ABAG factors
head(A)
df.A <- data.frame(A[2:6])

#Remove NA
nrow(df.A)
df.A[df.A == 0] <- NA
df.A <- na.omit(df.A)
nrow(df.A)


#Correlation matrix
cor(df.A)

#Correlation plot
?corrplot
corrplot::corrplot(cor(df.A),
                   method = c("number"),
                   bg = "lightgrey",
                   outline = TRUE)

#######################################################################################
#Calculation of Soil Loss and analyzing  ABAG factors 
#######################################################################################
#Selecting factors
df.A <- df.A[c(1,2,4)]
head(df.A)

#Factor multiplication
df.A$A =  Reduce(`*`, df.A)#Product calculation
head(df.A)

#Derive training data set
set.seed(123)
indxTrain <- caret::createDataPartition(y = df.A$A, p = 0.75,list = FALSE)
df.A.train <- df.A[indxTrain,]
df.A.test <- df.A[-indxTrain,]
nrow(df.A)
nrow(df.A.train)
nrow(df.A.test)

#KS test of training and total data set
#KS test, checks whether data in two data sets are distributed identically.

o.KS.train.test <- ks.test(df.A.train$A,df.A.test$A)
o.KS.train.all <- ks.test(df.A.train$A,df.A$A)

summary(o.KS.train.test)
o.KS.train.test$statistic
o.KS.train.test$p.value
o.KS.train.all$statistic
o.KS.train.all$p.value
o.KS.train.test$method

par(mfrow=c(1,2))
plot(ecdf(df.A$A),
     main="ECDF plots")
plot(ecdf(df.A.train$A),
     add=TRUE,
     col="blue")
plot(ecdf(df.A.test$A),
     add=TRUE,
     col="red")
legend("bottomright",
       title="KS-Test (Train/Test)",
       c(paste("D =",round(ks.test(df.A.train$A,df.A.test$A)$statistic,2)),
         paste("p = ",round(ks.test(df.A.train$A,df.A.test$A)$p.value,2))),
       bty="n",
       cex=1)
legend("right",
       title="KS-Test (Train/All)",
       c(paste("D =",round(ks.test(df.A.train$A,df.A$A)$statistic,2)),
         paste("p = ",round(ks.test(df.A.train$A,df.A$A)$p.value,2))),
       bty="n",
       cex=1)
plot(density(df.A$A),
     main="Density plots")
lines(density(df.A.train$A),
      col="blue")
lines(density(df.A.test$A),
      col="red")



#Model
set.seed(123)
ctrl <- caret::trainControl(method="cv",
                            number=5)

tuneGrid <- expand.grid(
  mtry = c(2, 3),        # Variables sampled per split
  splitrule = "variance",     # Regression splitting rule
  min.node.size = 3           # Node size
)
??ranger::ranger

head(df.A.train)
m.Fit <-   caret::train(A ~ .,
                        data = df.A.train,
                        method = "ranger",
                        trControl = ctrl,
                        tuneGrid = tuneGrid,
                        quantreg = TRUE,# Enable quantile regression
                        importance = "impurity",
                        verbose = TRUE)
m.Fit$results

#Variable importance
as.data.frame(varImp(m.Fit)$importance)
plot(varImp(m.Fit))

#Validation
df.A.train$A.pre <- predict(m.Fit,newdata = df.A.train)
df.A.test$A.pre <- predict(m.Fit,newdata = df.A.test)
head(df.A.train)
head(df.A.test)

# Predict quantiles (5% and 95%)
pred_quantiles <- predict(
  m.Fit$finalModel,       # Access ranger object
  data = df.A.test,
  type = "quantiles",
  quantiles = c(0.05, 0.95)
)

df.A.test$A.q05 <- pred_quantiles$predictions[, 1]
df.A.test$A.q95 <- pred_quantiles$predictions[, 2]
df.A.test$A.uct <- df.A.test$A.q95 - df.A.test$A.q05
head(df.A.test)


#linear models of predicted and test/train data set 
lm.test <-    train(A ~ A.pre,data=df.A.test,method = "lm")
lm.test$results
lm.test.R2 <- round(lm.test$results$Rsquared,3)
lm.test.RMSE <- round(lm.test$results$RMSE,3)

lm.train <-    train(A ~ A.pre,data=df.A.train,method = "lm")
lm.train$results
lm.train.R2 <- round(lm.train$results$Rsquared,3)
lm.train.RMSE <- round(lm.train$results$RMSE,3)

#plot biplot
par(mfrow=c(1,2))
plot(df.A.train$A,df.A.train$A.pre,
     ylab="Prediction",
     xlab="Train",
     xlim=range(df.A.train$A,df.A.train$A.pre),
     ylim=range(df.A.train$A,df.A.train$A.pre),
     main="Training data set")
legend("bottomright",   legend= c(as.expression(bquote({italic(R)^{2}} == .(lm.train.R2))), 
                                  as.expression(bquote({italic(RMSE)} == .(lm.train.RMSE)))), bty="n",cex=1)
abline(lm(df.A.test$A.pre~df.A.test$A),col="red",lwd=2)

plot(df.A.test$A,df.A.test$A.q05,
     ylab="Prediction",
     xlab="Test",
     xlim=range(df.A.train$A,df.A.train$A.pre),
     ylim=range(df.A.train$A,df.A.train$A.pre),
     main="Test data set"
)
points(df.A.test$A,df.A.test$A.q95,
     col="black")
points(df.A.test$A,df.A.test$A.pre,
       col="blue")


legend("bottomright",   legend= c(as.expression(bquote({italic(R)^{2}} == .(lm.test.R2))), 
                                  as.expression(bquote({italic(RMSE)} == .(lm.test.RMSE)))), bty="n",cex=1)
abline(lm(df.A.test$A.pre~df.A.test$A),col="red",lwd=2)
