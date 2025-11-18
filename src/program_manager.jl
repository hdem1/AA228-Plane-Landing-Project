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
    while t < 40
        new_state, reward, terminate = step(curr_state, action, sim_config, run_config)
        t += sim_config.dt
        println("At Time $t, the plane is at position $(new_state.x), $(new_state.y) and angle $(new_state.theta), moving with speed $(new_state.vx), $(new_state.vy)")
        curr_state = new_state
    end
end