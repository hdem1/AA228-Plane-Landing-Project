function step(state::State, action::Action, sim_config::SimConfig)
    # Update throttle and theta with action:
    state1 = State(state, action, sim_config.action_config)

    # Get dynamics:
    state2 = dynamics(state1, sim_config)
    
    # Update airspeed:
    new_state = set_airspeeds(state2, run_config)

    # Check for hitting ground:

    # Get reward
    # reward = 

    # Return
    return new_state #, reward, terminate
end