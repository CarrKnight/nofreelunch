# run abc examples
library(abc)
library(abctools)
library(R.utils)
library(quantregForest)
library(caret)
library(knitrProgressBar)
library(ranger)
library(e1071) #caret likes this for some unidentified reason!
library(rsample)




library(tidyverse)

DEGREE<-1 # regression degree
BOOTSTRAP_N = 200 # number of bootstraps
LOW_QUANTILE<-0.025
HIGH_QUANTILE<-0.975

# this is used in simulations where I am not wading through the full data-set
SMALL_DATA_SET_SIZE<-1250 # this should leave 1000 for training and 250 for testing
SMALL_DATA_RANDOM_SEED<-0 # the seed used when we are sampling at random from a big dataset to build a small one
MEDIUM_DATA_SET_SIZE<-5000 # this should leave 4000 for training and 1000 for testing




formula_maker<-function(yname,xnames,degree=DEGREE)
{
  formula(
    paste(
      yname,"~","(",
      paste(xnames,collapse = "+"),")",
      ifelse(degree>1,paste("^",degree),"")
      
    )
  )
  
  
}


DEFAULT_TOL<-.1


#library(gam)
# this is in-loop cv parameters for caret for RF; not the outer-loop CV parameters
control<-trainControl(method = "cv",
                      number = 5)



#   _____ ______ _____ _____ _____        _   _  ___   _     ___________  ___ _____ _____ _____ _   _ 
#  /  __ \| ___ \  _  /  ___/  ___|      | | | |/ _ \ | |   |_   _|  _  \/ _ \_   _|_   _|  _  | \ | |
#  | /  \/| |_/ / | | \ `--.\ `--. ______| | | / /_\ \| |     | | | | | / /_\ \| |   | | | | | |  \| |
#  | |    |    /| | | |`--. \`--. \______| | | |  _  || |     | | | | | |  _  || |   | | | | | | . ` |
#  | \__/\| |\ \\ \_/ /\__/ /\__/ /      \ \_/ / | | || |_____| |_| |/ /| | | || |  _| |_\ \_/ / |\  |
#   \____/\_| \_|\___/\____/\____/        \___/\_| |_/\_____/\___/|___/ \_| |_/\_/  \___/ \___/\_| \_/
#                                                                                                     
#    

# the cross validation function, all it does is take the real data; split it into training and testing and then call fitting method
# i made facades for each of the methods so that they call this automatically
cross_validate<-function(total_data,ngroup,fitting_method,cv_seed=0,...){
  n<-total_data %>% nrow()
  leave.out <- trunc(n/ngroup)
  o <- withSeed({
    sample(1:n)
  }, seed=cv_seed)
  groups <- vector("list", ngroup)
  for (j in 1:(ngroup - 1)) {
    jj <- (1 + (j - 1) * leave.out)
    groups[[j]] <- (o[jj:(jj + leave.out - 1)])
  }
  groups[[ngroup]] <- o[(1 + (ngroup - 1) * leave.out):n]
  results<-list()

  
  for(group in 1:ngroup){
    test_data<- total_data %>%
      ungroup() %>%
      filter(row_number() %in% groups[[group]] )
    training_data<-
      anti_join(total_data,test_data)
    
    results[[group]]<-
      fitting_method(training_set = training_data,testing_set = test_data,
                  ...)
  }
  
  return(
    list(
      results=results,
      errors= results %>% map_dfr(~bind_rows(.$errors)) %>% colMeans,
      contained =  results %>% map_dfr(~bind_rows(.$contained)) %>% colMeans,
      interval_size =  results %>% map_dfr(~bind_rows(.$interval_size)) %>% colMeans
    )
  )
  
}



print_table<-function(cross_validation_result){
  toprint<-rbind(cross_validation_result$errors,
                 scales::percent(cross_validation_result$contained),
                 cross_validation_result$interval_size) 
  toprint<-cbind(toprint,c("error","contained","interval"))
  colnames(toprint)<-c(param_names,"observation") 
  toprint %>% as_tibble() %>%
    dplyr::select(observation,everything()) %>%
    knitr::kable()
  
}



#   _     _                        ______                             _             
#  | |   (_)                       | ___ \                           (_)            
#  | |    _ _ __   ___  __ _ _ __  | |_/ /___  __ _ _ __ ___  ___ ___ _  ___  _ __  
#  | |   | | '_ \ / _ \/ _` | '__| |    // _ \/ _` | '__/ _ \/ __/ __| |/ _ \| '_ \ 
#  | |___| | | | |  __/ (_| | |    | |\ \  __/ (_| | | |  __/\__ \__ \ | (_) | | | |
#  \_____/_|_| |_|\___|\__,_|_|    \_| \_\___|\__, |_|  \___||___/___/_|\___/|_| |_|
#                                              __/ |                                
# 


linear_regression_fit<-function(
  training_set,testing_set,parameter_colnames, 
  x_names, # name of the X variables in the regression (summary statistics)
  degree,bootstrap_n = BOOTSTRAP_N){
  
  
  
  regressions<-list()
  errors<-rep.int(NA,length(parameter_colnames))
  interval_size<-rep.int(NA,length(parameter_colnames))
  contained<-rep.int(NA,length(parameter_colnames))
  predictions<-list()
  lows<-list()
  highs<-list()
  for(i in 1:length(parameter_colnames)){
    y<-parameter_colnames[i]
    formula1<-formula_maker(yname = y,
                            xnames = x_names,
                            degree = 1)
    
    regression<-lm(formula1,data=training_set)
    residuals<-residuals(regression)/sqrt(1-hatvalues(regression))
    
    current_prediction<-predict(regression,  newdata=testing_set)
    predictions[[y]]<-  current_prediction
    
    errors[i]<-  sqrt(mean((predictions[[y]]-testing_set[[y]])^2))
    progress_bar<- knitrProgressBar::progress_estimated(testing_set %>%nrow())
    
    #fit a regression function
    .boostrap_fit<-function(bootdata)
    {
      progress_bar$tick()
      return(
        lm(formula = formula1,data=analysis(bootdata))
      )
      
    }
    
    #fit many times
    booted<-rsample::bootstraps(training_set,times=BOOTSTRAP_N) %>%
      mutate(model = map(splits,.boostrap_fit)) %>%
      mutate(predictions = map(model,predict,newdata=testing_set,se=F)) %>%
      mutate(residuals = map(model,
                             function(x) sample(residuals(x)/sqrt(1-hatvalues(x)),
                                                size=length(current_prediction))
             
             )) %>%
      filter(!is.null(predictions))
    # 
    # residuals <-
    #   map(booted$residuals, ~ sample(.,size=10000/length(booted$residuals)))  %>% unlist()
    # 
    #observe prediction errors
    ses<-
      booted %>% mutate(original=list(current_prediction)) %>% 
      unnest(predictions,original,residuals) %>% ungroup() %>% 
      filter(is.finite(predictions)) %>% filter(!is.na(predictions)) %>%
      mutate(se = original-predictions) %>% 
      mutate(full = se + residuals) %>%
      group_by(id) %>% mutate(index=dplyr::row_number()) 
    # bootstrap a big list of them
    test<-ses  %>% group_by(index) %>% 
      summarise(error=list(sample(full,replace=TRUE,size = 10000)))

    # bootstrap also residuals
   # test$residuals<-list(residuals)
    #now combine these with resampled errors and grab quantiles
   
    #should be done!
    lows[[y]]<- predictions[[y]]  + (map(test$error,
                                        function(x) quantile(x,LOW_QUANTILE)) %>% unlist())
    highs[[y]]<- predictions[[y]] + (map(test$error,
                                        function(x) quantile(x,HIGH_QUANTILE)) %>% unlist())
    
    
    contained[i]<- sum( (testing_set[[y]]>=lows[[y]]) & (testing_set[[y]]<=highs[[y]]))/length(predictions[[y]])
    interval_size[i]<-mean(highs[[y]]-lows[[y]])
  }
  
  
  
  names(errors)<- names(contained) <- names(interval_size) <-parameter_colnames
  
  
  return(
    list(
      predictions= as_data_frame(predictions),
      lows = as_data_frame(lows),
      highs = as_data_frame(highs),
      errors = errors,
      contained = contained,
      interval_size = interval_size
    )
  )
  
  
  
  
}

  ### FACADE that calls cross_validate with linear_regression_fit
cross_validate_lm<-function(total_data,ngroup,
                             parameter_colnames,x_names,
                             degree=DEGREE,
                             cv_seed=0,...){
  cross_validate(total_data=total_data,cv_seed=cv_seed,
                 ngroup=ngroup,
                 fitting_method=linear_regression_fit,
                 degree=degree,
                 parameter_colnames=parameter_colnames,
                 x_names=x_names)
}


# does not store model to save on space                                          
biglm_regression_fit<-function(
  training_set,testing_set,parameter_colnames, 
  x_names, # name of the X variables in the regression (summary statistics)
  degree,bootstrap_n = BOOTSTRAP_N){
  # library(ff)
  # library(ffbase)
  # library(biglm)
  
  
  #abctools works on matrices, not data.frames so we need to convert
  regressions<-list()
  errors<-rep.int(NA,length(parameter_colnames))
  interval_size<-rep.int(NA,length(parameter_colnames))
  contained<-rep.int(NA,length(parameter_colnames))
  predictions<-list()
  lows<-list()
  highs<-list()
  for(i in 1:length(parameter_colnames)){
 #   print(parameter_colnames[i])
    y<-parameter_colnames[i]
    formula1<-formula_maker(yname = y,
                            xnames = x_names,
                            degree = 1)
    
    regression<- lm(formula = formula1, 
                    data = training_set, 
                    qr = TRUE,
                    x=FALSE,y=FALSE,
                    model = FALSE
    )
    
    current_prediction<-predict(regression,  newdata=testing_set)
    predictions[[y]]<-  current_prediction
    
    errors[i]<-  sqrt(mean((predictions[[y]]-testing_set[[y]])^2))
    progress_bar<- knitrProgressBar::progress_estimated(BOOTSTRAP_N)
    
    #adding s makes it non-parametric; caret does it for us when we call train
    #but in the bootstrap phase we just call gam directly
    #each time, redo the bootstrap using the same select and method
    .boostrap_fit<-function(bootdata)
    {
      progress_bar$tick()
      progress_bar$print()
      return(
        lm(formula = formula1, 
                    data = analysis(bootdata), 
                    qr = TRUE,
           x=FALSE,y=FALSE,
           model = FALSE)
      )
      
    }
    
    .one_sample<-function(){
      rsample::bootstraps(training_set,times=1) %>%
      mutate(model = map(splits,.boostrap_fit)) %>%
      mutate(predictions = map(model,predict,newdata=testing_set,se=F)) %>%
      mutate(residuals = map(model,
                             function(x) sample(residuals(x)/sqrt(1-hatvalues(x)),
                                                size=length(current_prediction),
                                                replace=TRUE)
                             
      )) %>%
      filter(!is.null(predictions)) %>% mutate(original=list(current_prediction)) %>% 
      unnest(predictions,original,residuals) %>% ungroup() %>% 
      filter(is.finite(predictions)) %>% filter(!is.na(predictions)) %>%
      mutate(se = sample(original-predictions,replace=TRUE)) %>% 
      mutate(full = se + residuals) %>%
      group_by(id) %>% mutate(index=dplyr::row_number()) 
    }
    
    booted<- .one_sample()
   
    test<-data.frame(full=booted$full,
                     index=booted$index)
    
    for(j in 1:(BOOTSTRAP_N-1))
    {
      booted<- .one_sample()
      
      test<-bind_rows(test,
                      data.frame(full=booted$full,
                                 index=booted$index))
    }
    
    test<- test %>% 
      group_by(index) %>% 
      summarise(up=quantile(full,HIGH_QUANTILE),
                low=quantile(full,LOW_QUANTILE))
    
    #should be done!
    lows[[y]]<- predictions[[y]]  + test$low
    highs[[y]]<- predictions[[y]] + test$up
    
    contained[i]<- sum( (testing_set[[y]]>=lows[[y]]) & (testing_set[[y]]<=highs[[y]]))/length(predictions[[y]])
#    print(contained)
    interval_size[i]<-mean(highs[[y]]-lows[[y]])
  }
  
  
  
  names(errors)<- names(contained) <- names(interval_size) <-parameter_colnames
  
  
  return(
    list(
      predictions= as_data_frame(predictions),
      lows = as_data_frame(lows),
      highs = as_data_frame(highs),
      errors = errors,
      contained = contained,
      interval_size = interval_size
    )
  )
  
  
  
  
}


cross_validate_biglm<-function(total_data,ngroup,
                            parameter_colnames,x_names,
                            degree=DEGREE,
                            cv_seed=0,...){
  cross_validate(total_data=total_data,cv_seed=cv_seed,
                 ngroup=ngroup,
                 fitting_method=biglm_regression_fit,
                 degree=degree,
                 parameter_colnames=parameter_colnames,
                 x_names=x_names)
}




#    ___  ______  _____ 
#   / _ \ | ___ \/  __ \
#  / /_\ \| |_/ /| /  \/
#  |  _  || ___ \| |    
#  | | | || |_/ /| \__/\
#  \_| |_/\____/  \____/
#                       
#   


# performs ABC on each single row of the training set independently.
# this to give the full benefit to ABC
abc_testing<-function(training_set,testing_set,tol=DEFAULT_TOL,parameter_colnames,
                      method="rejection",semiauto=FALSE,
                      #only used in semi-auto
                      satr=list(function(x){outer(x,Y=1:4,"^")}),# this comes from the COAL example; regress up to degree 4
                      ...)
{
  
  #abctools works on matrices, not data.frames so we need to convert
  obsparam = testing_set %>% 
    dplyr::select(parameter_colnames) %>% as.matrix()
  obs<- testing_set %>% dplyr::select(-parameter_colnames) %>%   
    data.matrix()
  progress_bar<- knitrProgressBar::progress_estimated(obs %>%nrow())
  
  
  #store results here
  results<-data.frame(
    matrix(ncol=length(parameter_colnames),nrow=0)
  )
  colnames(results)<-parameter_colnames
  
  #store intervals here
  highs<-data.frame(
    matrix(ncol=length(parameter_colnames),nrow=0)
  )
  lows<-data.frame(
    matrix(ncol=length(parameter_colnames),nrow=0)
  )
  colnames(highs)<-parameter_colnames
  colnames(lows)<-parameter_colnames
  
  # the x and the y of the training set
  param <-
    training_set %>% 
    dplyr::select(parameter_colnames) %>% data.matrix()
  sumstats<-
    training_set %>% dplyr::select(-parameter_colnames) %>%   
    data.matrix()
  for(i in 1:nrow(testing_set))
  {
    rezult<-NULL
    
    if(semiauto)
    {
      rezult<-
        semiauto.abc(obs = obs[i,], 
                     param = param ,
                     sumstats = sumstats,
                     method=method,
                     # this comes from the COAL example; regress up to degree 4
                     satr=satr,
                     verbose=FALSE,
                     plot=FALSE,
                     do.err=TRUE,
                     final.dens = TRUE,
                     tol=tol,
                     obspar = obsparam[i,],...)
      low<-rezult$post.sample %>% as.data.frame() %>% summarise_all(quantile,LOW_QUANTILE)
      medians<-rezult$post.sample %>% as.data.frame() %>% summarise_all(median)
      high<-rezult$post.sample %>% as.data.frame() %>% summarise_all(quantile,HIGH_QUANTILE)
      
    }
    else{
      rezult<-abc::abc(target = obs[i,], 
                  param = param,
                  sumstat = sumstats
                  ,tol=tol,method=method,...)
      low<- summary(rezult, print = F)[2, ]
      medians<-summary(rezult, print = F)[3, ] #grabbed from the ABC code (the cv method)
      high<-summary(rezult, print = F)[6,]
    }
    
    names(medians) <- names(low) <- names(high) <-parameter_colnames
    medians<-data.frame(
      as.list(medians)
    )
    # 3 is median; 4 is mean; 5 is mode.
    results<-bind_rows(results,
                       medians)
    
    highs<-bind_rows(highs,
                     data.frame(as.list(high)))
    lows<-bind_rows(lows,
                    data.frame(as.list(low)))
    
    progress_bar$tick()
    progress_bar$print()
    
  }
  
  #compute prediction errors
  errors<-vector(mode="numeric",length=length(parameter_colnames))
  contained<-vector(mode="numeric",length=length(parameter_colnames))
  interval_size<-vector(mode="numeric",length=length(parameter_colnames))
  
  for(i in 1:length(errors))
  {
    errors[i] <- sqrt(mean((obsparam[,i]-results[,i])^2))
    contained[i] <- sum( obsparam[,i] >= lows[,i] & obsparam[,i] <= highs[,i])/length(obsparam[,i])
    interval_size[i] <- mean(highs[,i]-lows[,i])
  }
  names(errors)<- names(contained) <- names(interval_size) <-parameter_colnames
  
  return(
    list(
      medians= results,
      lows = lows,
      highs = highs,
      errors = errors,
      contained = contained,
      interval_size = interval_size
    )
  )
  
}  



### FACADE that calls cross_validate with linear regression fit
cross_validate_abc<-function(total_data,ngroup,tol=DEFAULT_TOL,parameter_colnames,
                             method,semiauto=FALSE,cv_seed=0,
                             satr=list(function(x){outer(x,Y=1:4,"^")}),
                             ...){
  cross_validate(total_data=total_data,cv_seed=cv_seed,
                 ngroup=ngroup,
                 fitting_method=abc_testing,
                 tol=tol,
                 parameter_colnames=parameter_colnames,
                 method=method,
                 semiauto=semiauto,
                 satr=satr)
}

#   _____ _   _  ___   _   _ _____ _____ _      _____  ____________ 
#  |  _  | | | |/ _ \ | \ | |_   _|_   _| |    |  ___| | ___ \  ___|
#  | | | | | | / /_\ \|  \| | | |   | | | |    | |__   | |_/ / |_   
#  | | | | | | |  _  || . ` | | |   | | | |    |  __|  |    /|  _|  
#  \ \/' / |_| | | | || |\  | | |  _| |_| |____| |___  | |\ \| |    
#   \_/\_\\___/\_| |_/\_| \_/ \_/  \___/\_____/\____/  \_| \_\_|    
#                                                                   
# 




randomForest_fit<-function(
  training_set,testing_set,parameter_colnames, 
  x_names # name of the X variables in the regression (summary statistics)
      ){
  
  
  #abctools works on matrices, not data.frames so we need to convert
  regressions<-list()
  errors<-rep.int(NA,length(parameter_colnames))
  interval_size<-rep.int(NA,length(parameter_colnames))
  contained<-rep.int(NA,length(parameter_colnames))
  predictions<-list()
  lows<-list()
  highs<-list()
  for(i in 1:length(parameter_colnames)){
    y<-parameter_colnames[i]
    formula1<-formula_maker(yname = y,
                            xnames = x_names,
                            degree = 1)
    
    framed<-model.frame(formula1,data=training_set)
    test_frame<-model.frame(formula1,data=testing_set)
    
  #run the regressions
    train_X<-
      framed[,-1]
    train_Y<-
      framed[,1]
    
    if(is.null(ncol(train_X)))
      train_X <- train_X %>% as.data.frame()
    
    regression<- quantregForest(x =train_X,y=train_Y )
    
    test_X<-
      test_frame[,-1]
    test_Y<-
      test_frame[,1]
    
    if(is.null(ncol(test_X)))
      test_X <- test_X %>% as.data.frame()
    
    predictions[[y]]<- predict(regression,  test_X %>% as.data.frame(), what=0.5)
    errors[i]<-  sqrt(mean((predictions[[y]]-test_Y)^2))
    
    lows[[y]]<- predict(regression,  test_X, what=LOW_QUANTILE)
    highs[[y]]<- predict(regression,  test_X, what=HIGH_QUANTILE)

    
    contained[i]<- sum( (test_Y>=lows[[y]]) & (test_Y<=highs[[y]]))/length(predictions[[y]])
    interval_size[i]<-mean(highs[[y]]-lows[[y]])
  }
  
  
  
  names(errors)<- names(contained) <- names(interval_size) <-parameter_colnames
  
  
  return(
    list(
      predictions= as_data_frame(predictions),
      lows = as_data_frame(lows),
      highs = as_data_frame(highs),
      errors = errors,
      contained = contained,
      interval_size = interval_size
    )
  )
  
  
  
}
                                         
                                         
### FACADE that calls cross_validate with rf_testing
cross_validate_rf<-function(total_data,ngroup,
                            parameter_colnames,x_names,
                            cv_seed=0,...){
  cross_validate(total_data=total_data,cv_seed=cv_seed,
                 ngroup=ngroup,
                 fitting_method=randomForest_fit,
                 parameter_colnames=parameter_colnames,
                 x_names=x_names)
}
                                         
#  ______                _                  ______                  _   
#  | ___ \              | |                 |  ___|                | |  
#  | |_/ /__ _ _ __   __| | ___  _ __ ___   | |_ ___  _ __ ___  ___| |_ 
#  |    // _` | '_ \ / _` |/ _ \| '_ ` _ \  |  _/ _ \| '__/ _ \/ __| __|
#  | |\ \ (_| | | | | (_| | (_) | | | | | | | || (_) | | |  __/\__ \ |_ 
#  \_| \_\__,_|_| |_|\__,_|\___/|_| |_| |_| \_| \___/|_|  \___||___/\__|
#                                                                       
# 
                                         
randomForest_caretboot_fit<-function(
  training_set,testing_set,parameter_colnames, 
  x_names # name of the X variables in the regression (summary statistics)
){
  
  
  #abctools works on matrices, not data.frames so we need to convert
  regressions<-list()
  errors<-rep.int(NA,length(parameter_colnames))
  interval_size<-rep.int(NA,length(parameter_colnames))
  contained<-rep.int(NA,length(parameter_colnames))
  predictions<-list()
  lows<-list()
  highs<-list()
  
  if(length(parameter_colnames)>1)
  {      
    progress_bar<- knitrProgressBar::progress_estimated(length(parameter_colnames))
    progress_bar$print()
  }
  
  for(i in 1:length(parameter_colnames)){
    y<-parameter_colnames[i]
    formula1<-formula_maker(yname = y,
                            xnames = x_names,
                            degree = 1)
    
    
    if(length(x_names)>1)
    {
    regression<- train(formula1,data=training_set,method="ranger")
    
    #ugh, run it once more
    regression<- ranger(formula1,data=training_set,
                        keep.inbag = TRUE,
                        mtry = regression$bestTune$mtry,
                        splitrule = regression$bestTune$splitrule,
                        min.node.size = regression$bestTune$min.node.size)
    }
    else{
      regression<- ranger(formula1,data=training_set,
                          keep.inbag = TRUE)
    }
    
    #matrix with rows--> X and columns--> tree prediction at that X    
    best_prediction<-predict(regression,  data=testing_set,
                             type="se",se.method="infjack") 
    
    #if infinitesimal jacknife fails, we have to switch to plain jackkniffe (but pay the computational cost!)
    if(sum(is.na(best_prediction$se))>0)
      best_prediction<-predict(regression,  data=testing_set,
                               type="se",se.method="jack") 
    #get the residuals --> OUT OF BAG!
    residuals<-training_set[[y]]-regression$predictions
    

    test <- best_prediction$se %>% 
      as.list() %>% 
      map(~rnorm(mean=0,sd=.,n=1000)+ sample(residuals,size = 1000,replace=TRUE))
    
    low<- best_prediction$predictions +
      test %>% map_dbl(~quantile(.,probs=c(0.025)))
    high<- best_prediction$predictions +
      test %>% map_dbl(~quantile(.,probs=c(0.975)))
    
    
    test_Y<-
      testing_set[[y]]
    
    
    predictions[[y]]<- best_prediction$predictions
    errors[i]<-  sqrt(mean((predictions[[y]]-test_Y)^2))
    lows[[y]]<- low
    highs[[y]]<- high
    
    
    contained[i]<- sum( (test_Y>=lows[[y]]) & (test_Y<=highs[[y]]))/length(
      predictions[[y]])
    interval_size[i]<-mean(highs[[y]]-lows[[y]])
    
    if(length(parameter_colnames)>1)
    {
      progress_bar$tick()
      progress_bar$print()
    }
    
  }
  
  
  
  names(errors)<- names(contained) <- names(interval_size) <-parameter_colnames
  
  
  return(
    list(
      predictions= as_data_frame(predictions),
      lows = as_data_frame(lows),
      highs = as_data_frame(highs),
      errors = errors,
      contained = contained,
      interval_size = interval_size
    )
  )
  
  
  
}





### FACADE that calls cross_validate with randomForest_caretboot_fit
cross_validate_rfboot<-function(total_data,ngroup,
                            parameter_colnames,x_names,
                            cv_seed=0,...){
  cross_validate(total_data=total_data,cv_seed=cv_seed,
                 ngroup=ngroup,
                 fitting_method=randomForest_caretboot_fit,
                 parameter_colnames=parameter_colnames,
                 x_names=x_names)
}



                                         
#   _____    ___   ___  ___
#  |  __ \  / _ \  |  \/  |
#  | |  \/ / /_\ \ | .  . |
#  | | __  |  _  | | |\/| |
#  | |_\ \ | | | | | |  | |
#   \____/ \_| |_/ \_|  |_/
#                          
#                          
                                         
# I used to use gamLoess from caret package but it failed with some weird numerical error from time to time
# so I switched to mgcv. the name of the function however is stuck to "loess"                                         
                                         

loess_fit<-function(
  training_set,testing_set,parameter_colnames, 
  x_names, # name of the X variables in the regression (summary statistics)
  bam=FALSE, # should we use BAM instead of GAM? Useful for big data
  ...
){
 # print(bam)
  
  #abctools works on matrices, not data.frames so we need to convert
  regressions<-list()
  errors<-rep.int(NA,length(parameter_colnames))
  interval_size<-rep.int(NA,length(parameter_colnames))
  contained<-rep.int(NA,length(parameter_colnames))
  predictions<-list()
  lows<-list()
  highs<-list()
  if(length(parameter_colnames)>1)
  {      
    progress_bar<- knitrProgressBar::progress_estimated(length(parameter_colnames))
        progress_bar$print()
  }
  
  for(i in 1:length(parameter_colnames)){
    y<-parameter_colnames[i]
    #adding s makes it non-parametric; caret does it for us when we call train
    #but in the bootstrap phase we just call gam directly

    
    #we need to avoid putting too high k on variables whose unique values are only a few
    unique_values<-
      training_set %>% gather(variable,value) %>% group_by(variable) %>% 
      summarise(uniques=length(unique(value)))  %>% filter(uniques<10)
    
    #with more than 10 unique observations, they go in the formula directly
    valids<-setdiff(x_names,unique_values$variable)
    gam_formula<-
      paste(
        y,"~","s(",
        paste(valids,collapse = ")+s("),")"
        
      )
    #with 1 unique observation, they don't go in the formula at all
    unique_values<-unique_values %>% filter(uniques>1)
    if(nrow(unique_values)>0)
      gam_formula<-paste(gam_formula,"+",
                         paste("s(",unique_values$variable,",k=",pmin(10,unique_values$uniques),")",collapse = "+")
      )
      
    gam_formula<-formula(gam_formula)
    
    
    if(!bam)
    {
    regression<- mgcv::gam(gam_formula,data=training_set,select=TRUE)
    }
    else{
      regression<- mgcv::bam(gam_formula,data=training_set,select=TRUE,discrete = TRUE)
      
    }
    residuals<-residuals(regression)

    current_prediction<-predict(regression,  newdata=testing_set,se=T)
    predictions[[y]]<-  current_prediction$fit
    
    errors[i]<-  sqrt(mean((predictions[[y]]-testing_set[[y]])^2))

    residuals<-residuals(regression)

    test <- current_prediction$se %>% 
      as.list() %>% 
      map(~rnorm(mean=0,sd=.,n=10000)+ sample(residuals,size = 10000,replace=TRUE))
    
    low<- current_prediction$fit +
      test %>% map_dbl(~quantile(.,probs=c(0.025)))
    high<- current_prediction$fit +
      test %>% map_dbl(~quantile(.,probs=c(0.975)))
    
    
    #should be done!
    lows[[y]]<- low
    highs[[y]]<- high
    
    contained[i]<- sum( (testing_set[[y]]>=lows[[y]]) & (testing_set[[y]]<=highs[[y]]))/length(predictions[[y]])
    interval_size[i]<-mean(highs[[y]]-lows[[y]])
    
    if(length(parameter_colnames)>1)
    {
      progress_bar$tick()
      progress_bar$print()
    }
  }
  
  
  
  names(errors)<- names(contained) <- names(interval_size) <-parameter_colnames
  contained
  
  return(
    list(
      predictions= as_data_frame(predictions),
      lows = as_data_frame(lows),
      highs = as_data_frame(highs),
      errors = errors,
      contained = contained,
      interval_size = interval_size
    )
  )
  
  
  
}

cross_validate_loess<-function(total_data,ngroup,
                            parameter_colnames,x_names,
                            cv_seed=0,...){
  cross_validate(total_data=total_data,cv_seed=cv_seed,
                 ngroup=ngroup,
                 fitting_method=loess_fit,
                 parameter_colnames=parameter_colnames,
                 x_names=x_names,...)
}


#    ___                                 
#   / _ \                                
#  / /_\ \_   _____ _ __ __ _  __ _  ___ 
#  |  _  \ \ / / _ \ '__/ _` |/ _` |/ _ \
#  | | | |\ V /  __/ | | (_| | (_| |  __/
#  \_| |_/ \_/ \___|_|  \__,_|\__, |\___|
#                              __/ |     
#                             |___/                                               

cross_validate_average<-function(total_data,ngroup,
                               parameter_colnames,x_names,
                               cv_seed=0,...){
  cross_validate(total_data=total_data,cv_seed=cv_seed,
                 ngroup=ngroup,
                 fitting_method=average_fit,
                 parameter_colnames=parameter_colnames,
                 x_names=x_names)
}




average_fit<-function(
  training_set,testing_set,parameter_colnames, 
  x_names, # name of the X variables in the regression (summary statistics)
  ...
){
  
  
  #abctools works on matrices, not data.frames so we need to convert
  errors<-rep.int(NA,length(parameter_colnames))
  interval_size<-rep.int(NA,length(parameter_colnames))
  contained<-rep.int(NA,length(parameter_colnames))
  predictions<-list()
  lows<-list()
  highs<-list()
  for(i in 1:length(parameter_colnames)){
    y<-parameter_colnames[i]

    
    predictions[[y]]<-  mean(training_set[[y]])
    
    errors[i]<-  sqrt(mean((predictions[[y]]-testing_set[[y]])^2))
    

    
    #should be done!
    lows[[y]]<- predictions[[y]]  - 1.96 * sd(training_set[[y]])
    highs[[y]]<- predictions[[y]]  + 1.96 * sd(training_set[[y]])
    
    
    contained[i]<- sum( (testing_set[[y]]>=lows[[y]]) & (testing_set[[y]]<=highs[[y]]))/length(testing_set[[y]])
    interval_size[i]<-mean(highs[[y]]-lows[[y]])
  }
  
  
  
  names(errors)<- names(contained) <- names(interval_size) <-parameter_colnames
  
  
  return(
    list(
      predictions= as_data_frame(predictions),
      lows = as_data_frame(lows),
      highs = as_data_frame(highs),
      errors = errors,
      contained = contained,
      interval_size = interval_size
    )
  )
}



## todo: would like to add mxnet fits, but seems impossible to install
## would like to add BACCO fits, but no idea on how to choose GP hyper-pameters