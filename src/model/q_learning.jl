struct QLearningModel
    q_table::Matrix{Float64}
    obs_discretization_config::ObsDiscretizationConfig
    action_discretization_config::ActionDiscretizationConfig
end

function QLearningModel(obs_discretization_config::ObsDiscretizationConfig, action_discretization_config::ActionDiscretizationConfig,init_value::Float64 = 0.0)
    print("Initializing Q-Learning Model.........")
    obs_space = obs_discretization_config.tot_obs_space
    action_space = action_discretization_config.tot_action_space
    q_table = fill(init_value, obs_space, action_space)
    model = QLearningModel(q_table, obs_discretization_config, action_discretization_config)
    println("Success")
    return model
end

function update_q_table(model::QLearningModel, obs::DiscretizedObservation, action::DiscretizedAction, new_obs::DiscretizedObservation, reward::Float64, discount_factor::Float64, learning_rate::Float64)

    # Get indices:
    obsIndex = obsToIndex(obs, model.obs_discretization_config)
    actionIndex = actionToIndex(action, model.action_discretization_config)
    newObsIndex = obsToIndex(new_obs, model.obs_discretization_config)

    # Update q_table:
    model.q_table[obsIndex, actionIndex] += learning_rate * (reward + discount_factor * maximum(model.q_table[newObsIndex, :]) - model.q_table[obsIndex, actionIndex])
end

function get_best_action(model::QLearningModel, obs::DiscretizedObservation)
    obsIndex = obsToIndex(obs, model.obs_discretization_config)
    _, best_action = findmax(obsIndex)
    return indexToAction(best_action, model.action_discretization_config)
end

# function save_model(model::QLearningModel)