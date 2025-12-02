struct ModelConfig
   action_discretization_config::ActionDiscretizationConfig
   state_discretization_config::StateDiscretizationConfig
   max_iter::Int64
end

function load_model_config()
   filepath = "configs/model_config.yaml"
   config = YAML.load_file(filepath, dicttype=Dict{String, Any})
   
    # Action discretization config
    action_config = ActionDiscretizationConfig(config["action_discretization"])

    # State discretization config
    state_config = ActionDiscretizationConfig(config["state_discretization"])

    # Max iteration:
    max_iter = config["max_num_iterations"]

   return ModelConfig(action_config, state_config, max_iter)
end