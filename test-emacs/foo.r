#!/usr/bin/env Rscript

# Example usage:
# % egrep '(85.17.53.39|95.211.13.1)' http02_zalando-hip_access.log.5 \
#       | gawk -f image_filter.awk \
#       | awk '{print $1" "$2" "substr($0, index($0,$5))}' \
#       | ./analyze_responsiveness.r --ps bar.ps
# % gv bar.ps
# http://cran.r-project.org/web/packages/getopt/getopt.pdf
library('getopt');
spec <- c('file', 'f', "", "character",
          'ps', 'p', "xyz.ps", "character");
opt <- getopt(spec);
if ( is.null(opt$file)) {
  print("read from STDIN")
  con = file(description="stdin",open="r")
#  q(status=0)
} else {
  print("read from file")
  con <- file(opt$file,open="r")
}
postscript(opt$ps);
print( "read data" )
logtable <- read.table(con, header=FALSE);
print( "convert data")
logmatrix <-as.matrix(logtable);
resp_times <- logmatrix[,6];
resp_times_in_sec <- as.integer(resp_times) / 1000000 ;
print( "plot data")
qqplot(c(seq(0,1, by=0.001)), resp_times_in_sec,
       main="PageResponsiveness",xlab="Percentiles",
       ylab="Time inSeconds",type="p",tck=-0.01,col="blue",lab=c(20,20,20),
       sub="TEST");
#boxplot(c(seq(0,1, by=0.001)), resp_times_in_sec, main="Page Responsiveness",xlab="Percentiles", ylab="Time in Seconds",type="p",tck=-0.01,col="blue",lab=c(20,20,20), sub="TEST");
grid();
dev.off();
