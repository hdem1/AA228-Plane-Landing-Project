include("includes.jl")

if ARGS[1] == "--test-run"
    run_basic()
elseif ARGS[1] == "--q-learning"
    if "--no-save" in ARGS
        run_q_learning(false)
    else
        run_q_learning(true)
    end
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