include("includes.jl")

if ARGS[1] == "--test-run"
    run_basic()
elseif ARGS[1] == "--q-learning"
    run_q_learning()
elseif ARGS[1] == "--delete-run"
    if length(ARGS) >= 2
        for i in 2:length(ARGS)
            delete_run(parse(Int64, ARGS[i]))
        end
    else
        error("Incorrect usage - Please list the run numbers you want deleted after --delete-run")
    end
else
    error("Incorrect usage - see README for details on how to run the code.")
end