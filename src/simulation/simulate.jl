function step(state::State, action::Action, sim_config::SimConfig, run_config::RunConfig)
    # Update throttle and theta with action:
    state1 = State(state, action, sim_config.action_bounds_config)

    # Get dynamics:
    state2 = dynamics(state1, sim_config)
    
    # Update airspeed:
    new_state = set_airspeeds(state2, run_config)

    # Get reward
    reward, terminate = get_reward_and_terminate(state, action, sim_config)

    # Return
    return new_state, reward, terminate
end

function get_reward_and_terminate(state::State, action::Action, sim_config::SimConfig) 
    reward = 0.0
    terminate = false;

    # Got to ground:
    if state.y <= 0
        terminate = true;
        if state.vy <= sim_config.plane.max_landing_vy #Crashed
            reward -= 10000
        else #Successful landing
            reward += 5000
            reward -= abs(state.vy) * 100 # Reward less landing impact
            reward -= max(0, state.vx - sim_config.plane.max_landing_vx) * 20 # Punish landing with too much horizontal speed
        end
    end

    # Small punishment for going around (x > width)
    if state.y > 0 && state.x >= sim_config.scene_params.width
        terminate = true
        reward -= 1000
    end 

    # Punish significant state changes?

    return reward, terminate
end