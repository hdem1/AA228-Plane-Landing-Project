function run_basic()
    # Load config:
    sim_config = load_sim_config()

    # initilize a simulation:
    run_config = generate_run_config(sim_config)

    # Iterate through a simulation
    terminate = false
    curr_state = run_config.init_state
    action = Action(0.0, 0.0)
    t = 0.0
    while t < 40 && !terminate
        new_state, reward, terminate = step(curr_state, action, sim_config, run_config)
        t += sim_config.dt
        println("At Time $t, the plane is at position $(new_state.x), $(new_state.y) and angle $(new_state.theta), moving with speed $(new_state.vx), $(new_state.vy)")
        curr_state = new_state
    end
end

function run_q_learning()
    # Load configs:
    sim_config = load_sim_config()
    model_config = load_model_config()

    # Set up q-learning:
    q_learning_model = QLearningModel(model_config.obs_discretization_config, model_config.action_discretization_config)

    # Setting up saving infrastructure:
    list_of_rewards = zeros(model_config.max_iter)

    # Outer loop
    iter = 0
    while iter < model_config.max_iter

        # Loop through a single simulation:
        run_config = generate_run_config(sim_config)
        terminate = false
        curr_state = run_config.init_state
        curr_obs = DiscretizedObservation(curr_state, sim_config.obs_uncertainty_config, model_config.obs_discretization_config)
        t = 0.0
        tot_reward = 0.0
        while !terminate
            # Get new action:
            if (rand() < model_config.epsilon) #Explore!
                discretized_action = indexToAction(rand(1:model_config.action_discretization_config.tot_action_space), model_config.action_discretization_config)
            else #Take best action!
                discretized_action = get_best_action(q_learning_model, curr_obs)
            end
            action = Action(discretized_action, model_config.action_discretization_config, sim_config.action_bounds_config)

            # Propagate Sim:
            new_state, reward, terminate = step(curr_state, action, sim_config, run_config)
            new_obs = DiscretizedObservation(new_state, sim_config.obs_uncertainty_config, model_config.obs_discretization_config)

            # Update Q Table:
            update_q_table(q_learning_model, curr_obs, discretized_action, new_obs, reward, model_config.discount_factor, model_config.learning_rate)
            
            # Update variables:
            t += sim_config.dt
            curr_obs = new_obs
            curr_state = new_state
            #println("Time = ", t)
            tot_reward += reward
        end

        iter+=1
        list_of_rewards[iter] = tot_reward
        println("Iteration #", iter, " had total reward ", tot_reward, " and lasted ", t, " seconds.")
    end

    # Save CSV:

end