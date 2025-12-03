LOGGING_FILEPATH = ""
RUN_NUMBER = -1
TRAINING_LOG_FILENAME="outputs/training_runs/training_runs.csv"
MODEL_LOG_FILENAME="outputs/final_models/final_model_log.csv"

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
    mkdir(LOGGING_FILEPATH)
    mkdir(LOGGING_FILEPATH*"/trajectories")
    mkdir(LOGGING_FILEPATH*"/intermediate_models")
    mkdir(LOGGING_FILEPATH*"/configs")

    # Make log csv:
    open(LOGGING_FILEPATH*"/training_log.csv", "w") do f
        println(f, "iteration,simulation_duration,total_reward")  # CSV header
    end

    # Log hyperparameters:
    open("outputs/training_runs/training_runs.csv", "a") do f
        println(f, "$RUN_NUMBER,$max_iter,$state_space,$action_space,$discount_factor,$epsilon")
    end

    # Copy input configs:
    cp("configs/simulation_config.yaml", LOGGING_FILEPATH*"/configs/simulation_config.yaml")
    cp("configs/model_config.yaml", LOGGING_FILEPATH*"/configs/model_config.yaml")

    println("Success")
end

function log_iteration(iter::Int64, duration::Float64, tot_reward::Float64)
    if LOGGING_FILEPATH == ""
        error("you must set up the save folder by calling set_up_log_folder() before trying to log an iteration")
    end
    open(LOGGING_FILEPATH*"/training_log.csv", "a") do f
        println(f, "$iter,$duration,$tot_reward")
    end
end

function log_trajectory(run_name, states::Vector{String})
    if LOGGING_FILEPATH == ""
        error("you must set up the save folder by calling set_up_log_folder() before trying to log a trajectory")
    end
    open(LOGGING_FILEPATH*"/trajectories/$run_name.csv", "w") do f
        for i in states
            println(f, i)
        end
    end
end

function delete_run(run_num::Int64)
    println("Are you sure you want to delete all data (training log, final model, etc) for run #$run_num? [y/n]")
    answer = readline()
    if answer == "y" || answer == "Y"

        # Delete folder:
        print("Deleting training run folder outputs/training_runs/run$run_num.....")
        rm("outputs/training_runs/run$run_num"; recursive=true, force=true)
        println("Success")

        # Delete line in CSV:
        print("Deleting log in list of training runs at $TRAINING_LOG_FILENAME.....")
        training_log = CSV.read(TRAINING_LOG_FILENAME, DataFrame)
        filter!(row -> row.run_number != run_num, training_log)
        CSV.write(TRAINING_LOG_FILENAME, training_log)
        println("Success")

        # Delete final model
        print("Deleting final model at outputs/final_models/models/model$run_num.csv.....")
        rm("outputs/final_models/models/model$run_num.csv"; force=true)
        println("Success")

        # Delete line in ouput CSV
        print("Deleting log in list of final models at $MODEL_LOG_FILENAME........")
        model_log = CSV.read(MODEL_LOG_FILENAME, DataFrame)
        filter!(row -> row.model_num != run_num, model_log)
        CSV.write(MODEL_LOG_FILENAME, model_log)
        println("Success")

        println("Run #$run_num has been successfully deleted.")
    end
end

function log_model(model_dataframe::DataFrame, average_reward::Float64)
    if RUN_NUMBER == -1
        error("You cannot save the final model without saving the rest of the training data")
    end

    # Save model itself:
    new_file = "outputs/final_models/models/model$RUN_NUMBER.csv"
    CSV.write(new_file, model_dataframe)

    # Add model to log:
    open(MODEL_LOG_FILENAME, "a") do f
        println(f, "$RUN_NUMBER,$average_reward")
    end
end

function log_intermediate_model(iter::Int64, model_dataframe::DataFrame)
    if RUN_NUMBER == -1
        error("You cannot save the final model without saving the rest of the training data")
    end

    # Save model itself:
    new_file = "$LOGGING_FILEPATH/intermediate_models/iteration$iter.csv"
    CSV.write(new_file, model_dataframe)
end