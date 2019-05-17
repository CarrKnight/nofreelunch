library(tidyverse)




path<-"/home/carrknight/code/oxfish/docs/indirect_inference/commondata/errors/"

#get all the files
error_table<-list.files(path, ".csv")  %>% 
  #turn the vector into a data.frame (name-value)
  enframe() %>%
  #read each file
  mutate( observations = map(file.path(path,value),~read_csv(.))) %>%
  #clean up names
  select(-name) %>% rename(experiment=value) %>% 
  mutate(experiment=gsub(".csv","",experiment)) %>%
  #unnest results and you are done
  unnest(observations) 
  

# which is the better group?
error_table %>% 
  mutate(supervised = method %in% c("lm","rf","loess")) %>% 
  group_by(experiment,parameter,supervised) %>% 
  summarise(best=min(value)) %>%
  spread(supervised,best) %>%
  mutate(supervised_is_better = `TRUE`<`FALSE`) %>%
  ungroup() %>%
  summarise(sum(supervised_is_better)/length(supervised_is_better))

# 57% of the time, supervised is better


#best methods
error_table %>%
  group_by(experiment,parameter) %>%
  filter(value==min(value)) %>%
  group_by(method) %>%
  summarise(time_best=n()) %>%
  arrange(desc(time_best))
#random forest uber alles





#let's compare everything to LM
comparator<-
  error_table %>%
   filter(method=="lm")  %>%
  rename(comparison=value) %>% select(-method)

better_table<-
  left_join(error_table,comparator)

# how many times is LM better?
better_table %>%
  mutate(normalized = value/comparison) %>%
  group_by(method) %>%
  summarise(better=sum(normalized>1) / length(normalized)) 


#let's compare everything to RF
comparator<-
  error_table %>%
  filter(method=="rf")  %>%
  rename(comparison=value) %>% select(-method)

better_table<-
  left_join(error_table,comparator)

# how many times is RF better?
better_table %>%
  mutate(normalized = value/comparison) %>%
  group_by(method) %>%
  summarise(better=sum(normalized>1) / length(normalized)) 


#let's compare everything to loess
comparator<-# how many times is loess better?
  better_table %>%
  mutate(normalized = value/comparison) %>%
  group_by(method) %>%
  
  error_table %>%
  filter(method=="loess")  %>%
  rename(comparison=value) %>% select(-method)

better_table<-
  left_join(error_table,comparator)

# how many times is loess better?
better_table %>%
  mutate(normalized = value/comparison) %>%
  group_by(method) %>%
  summarise(better=sum(normalized>1) / length(normalized)) 

