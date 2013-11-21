# by family
for (byfun,calfun) = ((:byyear,:year), 
                      (:bymonth,:month), 
                      (:byday,:day),
                      (:bydow,:dayofweek), 
                      (:bydoy,:dayofyear))
                      # (:byhour,:hour), 
                      # (:byminute,:minute), 
                      # (:bysecond,:second),
    @eval begin
        function ($byfun)(df::DataFrame, t::Int)
            df[([$calfun(d) for d in df["Date"]]) .== t, :]
        end
    end
end


# from, to, between and only 

for(nam, func) = ((:from, :>=), 
                  (:to, :<=))
  @eval begin
   function ($nam)(df::DataFrame, y::Int, m::Int, d::Int)
      p = Int[]
      for i in 1:nrow(df)
        if ($func)(df[i, "Date"], date(y, m, d))
        push!(p, i)
        end
      end
    df[p,:]
    end
  end
end

function between(df::DataFrame, fy::Int, fm::Int, fd::Int,
                               ty::Int, tm::Int, td::Int)
  d = from(df, fy, fm, fd)
  return to(d, ty, tm, td)
end

function only(df::DataFrame, f::Function)
  foo = df[1,1]:f:df[nrow(df),1] 
  bar = DataFrame(Date = [foo])
  return join(bar, df)
end


function OHLC(df::DataFrame)
  w =  [week(df[i, "Date"]) for i = 1:nrow(df)]   # needs regex to get other names for Date
  z = Int[] 
  j = 1
  for i=1:nrow(df) - 1 # create unique week ID array
    if w[i] < w[i+1]
      push!(z, j)
      j = j+1
    else
      push!(z,j)
    end         
  end

  # account for last row
  w[nrow(df)]  ==  w[nrow(df)-1] ? # is the last row the same week as 2nd to last row?
  push!(z, z[size(z)[1]]) :  
  push!(z, z[size(z)[1]] + 1)  

  within!(df, quote w = $z end) # attach unique week ID to each weekday

  newdf = df[1,["Date", "Open", "High", "Low", "Close"]] # init new df

  for i = 1:z[size(z)[1]]  # iterate over week ID groupings
    temp = select(:(w .== $i), df)
    nextrow = DataFrame(Date  = temp[nrow(temp), "Date"],
                        Open  = temp[1, "Open"], 
                        High  = maximum(temp["High"]), 
                        Low   = minimum(temp["Low"]), 
                        Close = temp[nrow(temp), "Close"])
    newdf = rbind(newdf, nextrow) 
  end
  return newdf
end

function toweekly()
  println("Generalized version of OHLC that takes varargs")
end
