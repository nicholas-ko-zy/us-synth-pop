funName <- function(arg1, arg2, arg3 = 3, arg4 = T){
    y <- (arg1 - arg2) ^ arg3
    if(arg4) {
      plot(arg1, y)
    }
    return(y)
}

out <- funName(-10:10,2)
out