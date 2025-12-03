function run_basic()
    # Load config:
    sim_config = load_sim_config()

    # initilize a simulation:
    run_config = generate_run_config(sim_config)

    # Iterate through a simulation
    terminate = false
    curr_state = run_config.init_state
    action = Action(0.5, 0.0)
    t = 0.0
    tot_reward = 0.0
    while !terminate
        new_state, reward, terminate = step(curr_state, action, sim_config, run_config)
        t += sim_config.dt
        println("At Time $t, the plane is at position $(new_state.x), $(new_state.y) and angle $(new_state.theta), moving with speed $(new_state.vx), $(new_state.vy)")
        curr_state = new_state
        tot_reward += reward
        println("New reward = $reward --> tot reward = $tot_reward")
    end
end

function run_q_learning()
    # Load configs:
    sim_config = load_sim_config()
    model_config = load_model_config()
    save_config = load_save_config()

    # Setting up saving infrastructure:
    if save_config.saving
        set_up_log_folder(
            model_config.max_iter,
            model_config.obs_discretization_config.tot_obs_space, 
            model_config.action_discretization_config.tot_action_space, 
            model_config.discount_factor,
            model_config.epsilon
        )
    end

    # Set up q-learning:
    q_learning_model = QLearningModel(model_config.obs_discretization_config, model_config.action_discretization_config)

    # Training loop
    iter = 0
    println("Training:")
    p = Progress(model_config.max_iter)
    while iter < model_config.max_iter

        # Loop through a single simulation:
        run_config = generate_run_config(sim_config)
        terminate = false
        curr_state = run_config.init_state
        curr_obs = DiscretizedObservation(curr_state, sim_config.obs_uncertainty_config, model_config.obs_discretization_config)
        t = 0.0
        tot_reward = 0.0
        if should_save_training_traj(save_config, iter, false)
            states = Vector{String}()
            push!(states, "t,reward,"*get_state_print_format())
            push!(states, "0.0,0.0,"*get_state_string(curr_state))
        end

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
            if should_save_training_traj(save_config, iter, false)
                push!(states,"$t,$reward,"*get_state_string(curr_state))
            end
            curr_obs = new_obs
            curr_state = new_state
            tot_reward += reward
        end

        if should_save_training_traj(save_config, iter, true)
            log_iteration(iter, t, tot_reward)
            log_trajectory("training$iter", states)
        end
        if should_save_intermediate_model(save_config, iter, true)
            model_dataframe = model2DataFrame(q_learning_model)
            log_intermediate_model(iter, model_dataframe)
        end
        iter+=1
        next!(p)
    end
    println("Training concluded.")

    # Test final Model:# Training loop
    iter = 0
    println("Testing:")
    p2 = Progress(model_config.test_iter)
    avg_reward = 0.0
    while iter < model_config.test_iter

        # Loop through a single simulation:
        run_config = generate_run_config(sim_config)
        terminate = false
        curr_state = run_config.init_state
        curr_obs = DiscretizedObservation(curr_state, sim_config.obs_uncertainty_config, model_config.obs_discretization_config)
        t = 0.0
        tot_reward = 0.0
        if should_save_testing_traj(save_config, iter, false)
            states = Vector{String}()
            push!(states,"t,reward,"*get_state_print_format())
            push!(states,"0.0,0.0,"*get_state_string(curr_state))
        end
        while !terminate
            # Get new action:
            discretized_action = get_best_action(q_learning_model, curr_obs)
            action = Action(discretized_action, model_config.action_discretization_config, sim_config.action_bounds_config)

            # Propagate Sim:
            new_state, reward, terminate = step(curr_state, action, sim_config, run_config)
            new_obs = DiscretizedObservation(new_state, sim_config.obs_uncertainty_config, model_config.obs_discretization_config)
            
            # Update variables:
            t += sim_config.dt
            if should_save_testing_traj(save_config, iter, false)
                push!(states,"$t,$reward,"*get_state_string(curr_state))
            end
            curr_obs = new_obs
            curr_state = new_state
            tot_reward += reward
        end

        avg_reward += (tot_reward / model_config.test_iter)
        if should_save_testing_traj(save_config, iter, true)
            log_trajectory("testing$iter", states)
        end
        next!(p2)
        iter+=1
    end
    println("Finished Testing with Average Reward $avg_reward")

    # Save final model:
    if save_config.saving
        print("Saving final model.......")
        model_dataframe = model2DataFrame(q_learning_model)
        log_model(model_dataframe, avg_reward)
        println("Success")
    end
end