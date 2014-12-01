macro dprint(s)
    :(verbose && println($s))
end

function parsefromargs()
  s = ArgParseSettings("Process DCE-MRI data. "*
                       "Optional arguments can be used to override any "*
                       "values found in input files. "*
                       "For questions, contact David Smith <david.smith@gmail.com>. "*
                       "For bug reports and feature requests, file an issue at "*
                       "http://github.com/davidssmith/DCEMRI.jl"
                       )
  @add_arg_table s begin
    "datafile"
    help = "path to MAT file containing DCE and T1 data"
    arg_type = ByteString
    #required = true
    default = "input.mat"
    "--outfile", "-O"
    help = "path to MAT file to contain the ouput"
    arg_type = ByteString
    default = "results.mat"
    "--relaxivity", "-R"
    help = "contrast agent relaxivity (1/s)"
    arg_type = Float64
    "--TR", "-r"
    help = "repetition time (ms)"
    arg_type = Float64
    "--DCEflip", "-d"
    help = "flip angle of DCE data"
    arg_type = Float64
    "--SERcutoff", "-c"
    help = "minimum SER to include in processing mask"
    arg_type = Float64
    "--T1flip", "-t"
    help = "list of flip angle(s) of T1 data"
    arg_type = Float64
    nargs = '+'
    "--models", "-m"
    help = "list of models: 1=plasma only, 2=Standard, 3=Extended"
    arg_type = Int64
    nargs = '+'
    "--plotting", "-p"
    help = "plot intermediate results"
    action = :store_true
    "--workers", "-w"
    help = "number of parallel workers to use (one per CPU core is good)"
    arg_type = Int64
    default = 4
    "--verbose", "-v"
    help = "show verbose output"
    action = :store_true
  end

  parsed_args = parse_args(ARGS, s)

  if parsed_args["verbose"]
    println("Parsed args:")
    for (key,val) in parsed_args
      println("  $key  =>  $(repr(val))")
    end
  end
  parsed_args
end

function defaultparams()
  # defaults to use if not specified
  opts = Dict()
  opts["datafile"] = "input.mat"
  opts["outfile"] = "output.mat"
  opts["relaxivity"] = 4.5
  opts["SERcutoff"] = 2.0
  opts["models"] = [2]
  opts["plotting"] = false
  opts["verbose"] = true
  opts["workers"] = 4
  opts
end

function validate(d::Dict)
  if !(haskey(d, "Cp") && haskey(d, "DCEdata") && haskey(d, "t") &&
       haskey(d, "DCEflip") && haskey(d, "TR") &&
       ((haskey(d, "R10") && haskey(d, "S0")) ||
        (haskey(d,"T1data") && haskey(d,"T1flip"))))
     error("Input must contain Cp, DCEdata, t, DCEflip, TR, and either R10 and S0 or T1data and T1flip.")
  end
end

function ccc{T,N}(x::Array{T,N}, y::Array{T,N})
  # concordance correlation coefficient
  m1 = mean(x)
  m2 = mean(y)
  s1 = var(x)*(length(x) - 1.0) / length(x)
  s2 = var(y)*(length(y) - 1.0) / length(y)
  s12 = sum((x - m1).*(y - m2)) / length(x)
  2s12 / (s1 + s2 + (m1 - m2).^2)
end

# converts keyword argument to a dictionary
function kwargs2dict(kwargs)
    d = Dict{ASCIIString,Any}()
    for (k, v) in kwargs
        d[string(k)] = v
    end
    d
end
