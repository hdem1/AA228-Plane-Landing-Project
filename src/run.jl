include("includes.jl")

if ARGS[1] == "--test-run"
    run_basic()
elseif ARGS[1] == "--q-learning"
    run_q_learning()
else
    error("Incorrect usage - see README for details on how to run the code.")
end