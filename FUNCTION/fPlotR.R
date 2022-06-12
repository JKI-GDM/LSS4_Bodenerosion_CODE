print("fPlotR: Scatter plots and accuracy metrics")
#########################################################################################################
##Libraries and functions
#########################################################################################################
loadandinstall <- function(mypkg) {
  for(i in seq(along=mypkg)){
    if (!is.element(mypkg[i],installed.packages()[,1])){install.packages(mypkg[i])}
    library(mypkg[i], character.only=TRUE)
  }
}
packages <- sort(c("caret"))
loadandinstall(packages)


#########################################################################################################
##Function
#########################################################################################################
fPlotR <- function(RU.DIR,
                   RU.SHP,
                   OUT.DIR,
                   PM1,
                   PM2){
#------------------------------------------------------------------------------- 
print("Import DEM")
#------------------------------------------------------------------------------- 
p <- st_read(paste(RU.DIR,RU.SHP,sep=""))

# Create new columns
p[[c(paste("PM1"))]] <- p[[c(c(match(paste(PM1,sep=""),names(p))))]] 
p[[c(paste("PM2"))]] <- p[[c(c(match(paste(PM2,sep=""),names(p))))]] 


#------------------------------------------------------------------------------- 
print("calculating accuracy metrics")
#------------------------------------------------------------------------------- 
# Linear model
set.seed(123)
lm <-    train(PM1 ~ PM2,data=p,method = "lm",na.action = na.pass)

# Export accuarcy metrics
setwd(file.path(OUT.DIR))
write.csv2(as.data.frame(lm$results), 
           file=paste(PM1,"__",PM2,c(".csv"),sep=""))


# Scatter plot and accuarcy metrics
lm.R2 <- round(lm$results$Rsquared,3)
lm.RMSE <- round(lm$results$RMSE,3)

setwd(file.path(OUT.DIR))
pdf(paste(PM1,"__",PM2,c(".pdf"),sep=""), height=4.5,width=4)
plot(p$PM1,p$PM2,
     xlab=paste(PM1),
     ylab=paste(PM2),
     xlim=range(p$PM1,p$PM2,na.rm = TRUE),
     ylim=range(p$PM1,p$PM2,na.rm = TRUE)
)
legend("topleft",   legend= c(as.expression(bquote({italic(R)^{2}} == .(lm.R2))), 
                                  as.expression(bquote({italic(RMSE)} == .(lm.RMSE)))), bty="n",cex=1)
abline(lm(p$PM2~p$PM1),col="red")
dev.off()
}
