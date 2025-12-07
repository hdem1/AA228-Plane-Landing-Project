function step(state::State, action::Action,
              sim_config::SimConfig, run_config::RunConfig;
              log::Bool = false)

    # Update throttle and theta with action:
    state1 = State(state, action, sim_config.action_bounds_config)

    # Get dynamics:
    state2 = dynamics(state1, sim_config)
    
    # Update airspeed:
    new_state = set_airspeeds(state2, run_config)

    # Get reward based on the *new* state
    reward, terminate = get_reward_and_terminate(new_state, action, sim_config; log=log)

    return new_state, reward, terminate
end



function get_reward_and_terminate(state::State, action::Action, sim_config::SimConfig; log::Bool=true)
    reward = 0.0

    # Got to ground:
    if state.y <= 0
        if state.vy <= sim_config.plane.max_landing_vy # Crashed
            reward -= 10000
            if log
                @info "CRASH landing" y=state.y vy=state.vy vx=state.vx max_vy=sim_config.plane.max_landing_vy max_vx=sim_config.plane.max_landing_vx reward=reward
            end
        else # Successful landing
            reward += 10000
            reward -= abs(state.vy) * 100
            reward -= max(0, state.vx - sim_config.plane.max_landing_vx) * 20
            if log
                @info "SUCCESSFUL landing" y=state.y vy=state.vy vx=state.vx max_vy=sim_config.plane.max_landing_vy max_vx=sim_config.plane.max_landing_vx reward=reward
            end
        end
        return reward, true
    end

    # Small punishment for going around (x > width)
    if state.y > 0 && state.x >= sim_config.scene_params.width
        reward -= 1000
        return reward, true
    end

    # Reward going downhill by the slope required to hit the runway 100 m before the end
    target_landing_dist = 100
    if state.x < sim_config.scene_params.width - 5 * target_landing_dist
        target_angle = atan(-1 * state.y, ((sim_config.scene_params.width - target_landing_dist) - state.x))
        curr_angle   = atan(state.vy, state.vx)
        reward -= abs(target_angle - curr_angle) * 20
    end

    return reward, false
end



#=
EVAN OLD 
function get_reward_and_terminate(state::State, action::Action, sim_config::SimConfig) 
    reward = 0.0
    plane = sim_config.plane
    scene = sim_config.scene_params

    # --- Landing band (allow landing when y <= 1 m instead of exactly 0) ---
    if state.y <= 1.0
        # Crash if vertical speed is too high (too negative) or horizontal speed too large
        if state.vy <= plane.max_landing_vy || abs(state.vx) > plane.max_landing_vx
            reward -= 10_000
            @info "CRASH landing" y=state.y vy=state.vy vx=state.vx max_vy=plane.max_landing_vy max_vx=plane.max_landing_vx reward=reward
        else
            # Successful landing
            reward += 10_000
            reward -= abs(state.vy) * 100                              # reward softer vertical impact
            reward -= max(0.0, abs(state.vx) - plane.max_landing_vx) * 20  # punish excess horiz speed
            @info "SUCCESSFUL landing" y=state.y vy=state.vy vx=state.vx max_vy=plane.max_landing_vy max_vx=plane.max_landing_vx reward=reward
        end
        return reward, true   # terminate episode on landing
    end

    # --- Go-around / flew past runway ---
    if state.y > 0 && state.x >= scene.width
        reward -= 1000
        return reward, true
    end 

    # --- Shaping: reward following a good glide slope ---
    target_landing_dist = 100.0
    if state.x < scene.width - 5 * target_landing_dist
        # target point is (scene.width - target_landing_dist, 0)
        target_angle = atan(-state.y, (scene.width - target_landing_dist) - state.x)
        curr_angle   = atan(state.vy, state.vx)
        reward -= abs(target_angle - curr_angle) * 20
    end

    return reward, false
end


HENRY OLD

function get_reward_and_terminate(state::State, action::Action, sim_config::SimConfig) 
    reward = 0.0

    # Got to ground:
    if state.y <= 0
        if state.vy <= sim_config.plane.max_landing_vy #Crashed
            reward -= 10000
            @info "CRASH landing" y=state.y vy=state.vy vx=state.vx max_vy=max_vy max_vx=max_vx reward=reward
        else #Successful landing
            reward += 10000
            reward -= abs(state.vy) * 100 # Reward less landing impact
            reward -= max(0, state.vx - sim_config.plane.max_landing_vx) * 20 # Punish landing with too much horizontal speed
            @info "SUCCESSFUL landing" y=state.y vy=state.vy vx=state.vx max_vy=max_vy max_vx=max_vx reward=reward
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
=#