struct ModelConfig
   action_discretization_config::ActionDiscretizationConfig
   obs_discretization_config::ObsDiscretizationConfig
   max_iter::Int64
   discount_factor::Float64
   learning_rate::Float64
   epsilon::Float64
   test_iter::Int64
end

function load_model_config()
   filepath = "configs/model_config.yaml"
   print("Loading Model Configuration from $filepath.........")
   config = YAML.load_file(filepath, dicttype=Dict{String, Any})
   
   # Action discretization config
   action_config = ActionDiscretizationConfig(config["action_discretization"])

   # State discretization config
   obs_config = ObsDiscretizationConfig(config["obs_discretization"])

   # Max iteration:
   max_iter = config["max_num_iterations"]

   # Discount factor:
   discount_factor = config["discount_factor"]

   # Learning rate:
   learning_rate = config["learning_rate"]

   # Epsilon:
   epsilon = config["exploration_rate"]

   # Test Iterations:
   test_iter = config["test_iterations"]

   config = ModelConfig(action_config, obs_config, max_iter, discount_factor, learning_rate, epsilon, test_iter)
   println("Success")
   return config
end