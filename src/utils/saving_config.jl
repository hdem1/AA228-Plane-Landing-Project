mutable struct SavingConfig
   saving::Bool
   save_training_trajs::Bool
   training_traj_save_freq::Int64
   last_training_traj_save_iter::Int64
   save_testing_traj::Bool
   testing_traj_save_freq::Int64
   last_testing_traj_save_iter::Int64
   saving_intermediate_models::Bool
   intermediate_model_save_freq::Int64
   last_intermediate_model_save_iter::Int64
end

function load_save_config()
   filepath = "configs/saving_config.yaml"
   print("Loading Saving Configuration from $filepath........")
   config = YAML.load_file(filepath, dicttype=Dict{String, Any})
   
   save_config = SavingConfig(
        config["saving"],
        config["save_training_trajs"],
        config["training_traj_frequency"],
        0,
        config["save_testing_trajs"],
        config["testing_traj_frequency"],
        0,
        config["save_intermediate_models"],
        config["intermediate_model_save_frequency"],
        0
   )
   println("Success")
   return save_config
end

function should_save_training_traj(config::SavingConfig, iter::Int64, increment::Bool)
    if (config.saving && config.save_training_trajs && iter - config.last_training_traj_save_iter >= config.training_traj_save_freq)
        if increment
            config.last_training_traj_save_iter = iter
        end
        return true
    end
    return false
end

function should_save_testing_traj(config::SavingConfig, iter::Int64, increment::Bool)
    if (config.saving && config.save_testing_traj && iter - config.last_testing_traj_save_iter >= config.testing_traj_save_freq)
        if increment
            config.last_testing_traj_save_iter = iter
        end
        return true
    end
    return false
end

function should_save_intermediate_model(config::SavingConfig, iter::Int64, increment::Bool)
    if (config.saving && config.saving_intermediate_models && iter - config.last_intermediate_model_save_iter >= config.intermediate_model_save_freq)
        if increment
            config.last_intermediate_model_save_iter = iter
        end
        return true
    end
    return false
end