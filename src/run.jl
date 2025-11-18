include("includes.jl")

function run_basic()
    # Load config:
    sim_config = load_sim_config()

    # initilize a simulation:
    run_config = generate_run_config(sim_config)

    # Iterate through a simulation
    terminate = false
    while !terminate

    end
end

if ARGS[1] == "--test-run"
    run_basic()
else
    error("Incorrect usage - see README for details on how to run the code.")
end