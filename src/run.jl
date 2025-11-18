include("includes.jl")

if ARGS[1] == "--test-run"
    run_basic()
else
    error("Incorrect usage - see README for details on how to run the code.")
end