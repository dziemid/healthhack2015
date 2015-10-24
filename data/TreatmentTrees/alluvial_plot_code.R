rm(list=ls()) 
gc()

library(plyr)
require(rCharts)
require(rjson)

path_len_lim <- Inf
min_age <- 0
max_age <- Inf
sex_filter <- 1
path_size_cutoff <- 20
path_match <- '[]' # [] for all paths (everyone starts here)

data <- read.table("/Users/amydonaldson/Documents/Habib/dev/health_hack/TreatmentTrees/TreatmentTree_MockData_RealTreat.txt",sep=',',header=TRUE)
str(data)
data <- data[data$age>=min_age&data$age<=max_age,]

history_data <- read.table("/Users/amydonaldson/Documents/Habib/dev/health_hack/healthhack2015/data/TreatmentTrees/periods_with_history.txt",sep=';',header=TRUE)
id_list <- unique(history_data[history_data$history==path_match,"id"])
history_data <- history_data[history_data$id%in%id_list,]
data <- merge(data,history_data[,c("period","id","history")],by=c("period","id"))

data <- data[data$period <= path_len_lim,]

# n_treats <- length(unique(data$treatment))
# treatment_lookup <- data.frame(treatment=seq(1,n_treats),treatment_class=LETTERS[seq(from = 1, to = n_treats)])
# data <- merge(data,treatment_lookup,by="treatment")
# data$treatment <- data$treatment_class

# count_data <- count(data,c("period","history"))
# ggplot(count_data,aes(period,freq,fill=factor(history))) +
#   geom_bar(stat="identity")


data_prev <- data
data_prev$period <- data_prev$period + 1

data_merge <- merge(data,data_prev[,c("id","period","history")],by=c("id","period"),all.x=TRUE)


head(data_merge)
names(data_merge)[names(data_merge)=="history.y"] <- "source"
names(data_merge)[names(data_merge)=="history.x"] <- "target"



plot_data <- count(data_merge[!is.na(data_merge$source),],c("period","source","target"))
names(plot_data)[names(plot_data)=="freq"] <- "value"

# plot_data$source <- as.character(paste0(plot_data$source,plot_data$period))
# plot_data$target <- as.character(paste0(plot_data$target,plot_data$period+1))
plot_data <- plot_data[,c("source","target","value")]

# plot_data$value <- plot_data$value/max(plot_data$value)

str(plot_data)

#verify that no source = target
#or will get stuck in infinite loop
plot_data[which(plot_data[,1]==plot_data[,2]),]

#implement path volume cutoff
plot_data <- plot_data[plot_data$value>=path_size_cutoff,]


sankeyPlot3 <- rCharts$new()
sankeyPlot3$setLib('http://timelyportfolio.github.io/rCharts_d3_sankey/')
sankeyPlot3$set(
  data = plot_data,
  nodeWidth = 10,
  nodePadding = 1,
  layout = 32,
  width = 2000,
  height = 1500
)


sankeyPlot3$setTemplate(
  afterScript = "
  <script>
  // to be specific in case you have more than one chart
  d3.selectAll('#{{ chartId }} svg path.link')
  .style('stroke', function(d){
  //here we will use the source color
  //if you want target then sub target for source
  //or if you want something other than gray
  //supply a constant
  //or use a categorical scale or gradient
  return d.source.color;
  })
  //note no changes were made to opacity
  //to do uncomment below but will affect mouseover
  //so will need to define mouseover and mouseout
  //happy to show how to do this also
  // .style('stroke-opacity', .7) 
  </script>
  ")

sankeyPlot3
