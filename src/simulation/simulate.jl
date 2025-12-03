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

    # Got to ground:
    if state.y <= 0
        if state.vy <= sim_config.plane.max_landing_vy #Crashed
            reward -= 10000
        else #Successful landing
            reward += 5000
            reward -= abs(state.vy) * 100 # Reward less landing impact
            reward -= max(0, state.vx - sim_config.plane.max_landing_vx) * 20 # Punish landing with too much horizontal speed
        end
        return reward, true
    end

    # Small punishment for going around (x > width)
    if state.y > 0 && state.x >= sim_config.scene_params.width
        reward -= 1000
        return reward, true
    end 

    # Reward going downhill by the slope required to hit the runway 100 meters before the end
    target_landing_dist = 100
    if state.x < sim_config.scene_params.width - 5 * target_landing_dist
        target_angle = atan(-1 * state.y, ((sim_config.scene_params.width - target_landing_dist) - state.x ))
        curr_angle = atan(state.vy, state.vx)
        reward -= abs(target_angle - curr_angle) * 20
    end

    # Punish significant action changes?

    return reward, false
end