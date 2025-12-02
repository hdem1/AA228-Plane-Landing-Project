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
    q_learning_model = QLearningModel()

    # Outer loop
    iter = 0
    while iter < model_config.max_iter

        # Loop through a single simulation:
        run_config = generate_run_config(sim_config)
        terminate = false
        curr_obs = run_config.init_state
        action = Action(0.0, 0.0)
        t = 0.0
        while !terminate
            # Get new action:
            if (rand() < model_config.epsilon) #Explore!
                
            else #Take best action!

            end

            # Propagate Sim:
            new_obs, reward, terminate = step(curr_obs, action, sim_config, run_config)

            # Update Q Table:
            update_q_table(q_learning_model, curr_obs, action, new_obs, reward, model_config.discount_factor, model_config.learning_rate)
            
            # Update variables:
            t += sim_config.dt
            curr_obs = new_obs
        end

        iter+=1
    end

    #
end