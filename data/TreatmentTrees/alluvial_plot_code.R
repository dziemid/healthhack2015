rm(list=ls()) 
gc()

require(plyr)
require(rCharts)
require(rjson)
require(RCurl)

path_len_lim <- 5 #set to Inf to consider all paths
min_age <- 0
max_age <- Inf
sex_filter <- c(0,1) #set filter on which sex you want to consider c(0,1) for all
path_size_cutoff <- 20 #set minimum number of observations 
path_match <- c('[]') # [] for all paths (everyone starts here)

get_data <- getURL("https://raw.githubusercontent.com/dziemid/healthhack2015/master/data/TreatmentTrees/TreatmentTree_MockData_20151024.txt")
data <- read.table(text = get_data,sep=',',header=TRUE)
# data <- read.table("/Users/amydonaldson/Documents/Habib/dev/health_hack/TreatmentTrees/TreatmentTree_MockData_RealTreat.txt",sep=',',header=TRUE)
# str(data)
data <- data[data$age>=min_age&data$age<=max_age&data$sex%in%sex_filter,]

get_data <- getURL("https://raw.githubusercontent.com/dziemid/healthhack2015/master/data/TreatmentTrees/periods_with_history.txt")
history_data <- read.table(text = get_data,sep=';',header=TRUE)
# history_data <- read.table("/Users/amydonaldson/Documents/Habib/dev/health_hack/healthhack2015/data/TreatmentTrees/periods_with_history.txt",sep=';',header=TRUE)
names(history_data)[names(history_data)=="X.."] <- "history"
id_list <- unique(history_data[history_data$history%in%path_match,"id"])
history_data <- history_data[history_data$id%in%id_list,]

data <- merge(data,history_data[,c("period","id","history")],by=c("period","id"))


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


#create transitions for absorbing states
#dead states
data_deadstates <- data_merge[data_merge$dead==1,]
data_deadstates$period <- data_deadstates$period + 1
names(data_deadstates)[names(data_deadstates)=="history.x"] <- "source"
data_deadstates$target <- paste0(data_deadstates$source,",dead")
data_deadstates <- data_deadstates
data_deadstates <- count(data_deadstates,c("source","target"))
names(data_deadstates)[names(data_deadstates)=="freq"] <- "value"

#dead states
data_stopstates <- data_merge[data_merge$stop_treatment==1,]
data_stopstates$period <- data_stopstates$period + 1
names(data_stopstates)[names(data_stopstates)=="history.x"] <- "source"
data_stopstates$target <- paste0(data_stopstates$source,",stop")
data_stopstates <- data_stopstates
data_stopstates <- count(data_stopstates,c("source","target"))
names(data_stopstates)[names(data_stopstates)=="freq"] <- "value"


names(data_merge)[names(data_merge)=="history.y"] <- "source"
names(data_merge)[names(data_merge)=="history.x"] <- "target"


data_merge <- data_merge[data_merge$period <= path_len_lim + 1,]

plot_data <- count(data_merge[!is.na(data_merge$source),],c("period","source","target"))
names(plot_data)[names(plot_data)=="freq"] <- "value"


# plot_data$source <- as.character(paste0(plot_data$source,plot_data$period))
# plot_data$target <- as.character(paste0(plot_data$target,plot_data$period+1))
plot_data <- plot_data[,c("source","target","value")]

# plot_data$value <- plot_data$value/max(plot_data$value)

# str(plot_data)

#verify that no source = target
#or will get stuck in infinite loop
plot_data[which(plot_data[,1]==plot_data[,2]),]

#implement path volume cutoff
plot_data <- plot_data[plot_data$value>=path_size_cutoff,]
considered_paths <- unique(plot_data$source)
data_deadstates <- data_deadstates[data_deadstates$source%in%considered_paths,]
data_stopstates <- data_stopstates[data_stopstates$source%in%considered_paths,]
plot_data <- rbind(plot_data,data_deadstates,data_stopstates)

plot_data[order(plot_data$source),]
plot_data$colval <- 100

sankeyPlot3 <- rCharts$new()
sankeyPlot3$setLib('http://timelyportfolio.github.io/rCharts_d3_sankey/')
sankeyPlot3$set(
  data = plot_data,
  nodeWidth = 25,
  nodePadding = 10,
  layout = 32,
  width = 2000,
  height = 1000
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
  //return d.source.color;
  })
  //note no changes were made to opacity
  //to do uncomment below but will affect mouseover
  //so will need to define mouseover and mouseout
  //happy to show how to do this also
  // .style('stroke-opacity', .7) 
  </script>
  ")

sankeyPlot3
