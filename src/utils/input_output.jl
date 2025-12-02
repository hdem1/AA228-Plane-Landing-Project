LOGGING_FILEPATH = ""
RUN_NUMBER = -1
TRAINING_LOG_FILENAME="outputs/training_runs/training_runs.csv"

# Get Next filename:
function get_next_training_log_filename()
    training_log = CSV.read(TRAINING_LOG_FILENAME, DataFrame)
    if isempty(training_log.run_number)
        max_number = 0
    else
        max_number = maximum(training_log.run_number)
    end
    new_number = max_number+1
    new_dir = "outputs/training_runs/run$new_number"
    return new_number, new_dir
end

# Set up training run folder:
function set_up_log_folder(max_iter::Int64, state_space::Int64, action_space::Int64, discount_factor::Float64, epsilon::Float64)
    print("Setting Up New Log Folder....")
    run_number, new_log_folder = get_next_training_log_filename()
    global LOGGING_FILEPATH, RUN_NUMBER
    LOGGING_FILEPATH = new_log_folder
    RUN_NUMBER = run_number
    mkdir(new_log_folder)
    mkdir(new_log_folder*"/trajectories")
    mkdir(new_log_folder*"/intermediate_models")

    # Make log csv:
    open(LOGGING_FILEPATH*"/training_log.csv", "w") do f
        println(f, "iteration,simulation_duration,total_reward")  # CSV header
    end

    # Log hyperparameters:
    open("outputs/training_runs/training_runs.csv", "a") do f
        println(f, "$RUN_NUMBER,$max_iter,$state_space,$action_space,$discount_factor,$epsilon")
    end

    println("Success")
end

function log_iteration(iter::Int64, duration::Float64, tot_reward::Float64)
    if LOGGING_FILEPATH == ""
        error("you must set up the save folder by calling set_up_log_folder() first")
    end
    open(LOGGING_FILEPATH*"/training_log.csv", "a") do f
        println(f, "$iter,$duration,$tot_reward")
    end
end

function delete_run(run_num::Int64)
    println("Are you sure you want to delete run #$run_num? [y/n]")
    answer = readline()
    if answer == "y" || answer == "Y"
        print("Deleting run #$run_num.....")

        # Delete folder:
        rm("outputs/training_runs/run$run_num"; recursive=true, force=true)

        # Delete line in CSV:
        training_log = CSV.read(TRAINING_LOG_FILENAME, DataFrame)
        filter!(row -> row.run_number != run_num, training_log)
        CSV.write(TRAINING_LOG_FILENAME, training_log)

        println("Success")
    end
end