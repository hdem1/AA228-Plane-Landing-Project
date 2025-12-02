struct ActionDiscretizationConfig
    throttle_bins::Vector{Float64}
    num_throttle_actions::Int64
    pitch_bins::Vector{Float64}
    num_pitch_actions::Int64
    tot_action_space::Int64
end

struct ObsDiscretizationConfig
    x_bins::Vector{Float64}
    num_x_bins::Int64
    y_bins::Vector{Float64}
    num_y_bins::Int64
    theta_bins::Vector{Float64}
    num_theta_bins::Int64
    vx_air_bins::Vector{Float64}
    num_vx_bins::Int64
    vy_air_bins::Vector{Float64}
    num_vy_bins::Int64
    tot_obs_space::Int64
end

struct DiscretizedAction
    throttleAction::Int64
    pitchAction::Int64
end

struct DiscretizedObservation
    x::Int64
    y::Int64
    theta::Int64
    vx_air::Int64
    vy_air::Int64
end

function get_action_results(dAction::DiscretizedAction, actionConfig::ActionDiscretizationConfig)
    return Action(actionConfig.throttleChanges[dAction.throttleAction], actionConfig.pitchChanges[dAction.pitchAction])
end

function DiscretizedObservation(obs::Observation, config::ObsDiscretizationConfig)
    x_bin = 1
    while (x_bin <= config.num_x_bins && obs.x > config.x_bins[x_bin])
        x_bin += 1
    end
    y_bin = 1
    while (y_bin <= config.num_y_bins && obs.y > config.y_bins[y_bin])
        y_bin += 1
    end
    theta_bin = 1
    while (theta_bin <= config.num_theta_bins && obs.theta > config.theta_bins[theta_bin])
        theta_bin += 1
    end
    vx_bin = 1
    while (vx_bin <= config.num_vx_bins && obs.vx_air > config.vx_air_bins[vx_bin])
        vx_bin += 1
    end
    vy_bin = 1
    while (vy_bin <= config.num_vy_bins && obs.vy_air > config.vy_air_bins[vy_bin])
        vy_bin += 1
    end
    return DiscretizedObservation(x_bin, y_bin, theta_bin, vx_bin, vy_bin)
end

function DiscretizedAction(action::Action, config::ActionDiscretizationConfig)
    throttle_bin = 1
    while (throttle_bin <= config.num_throttle_actions && action.new_throttle > config.throttle_bins[throttle_bin])
        throttle_bin += 1
    end
    dpitch_bin = 1
    while (dpitch_bin <= config.num_pitch_actions && action.dPitch > config.pitch_bins[dpitch_bin])
        dpitch_bin += 1
    end
    return DiscretizedAction(throttle_bins, dpitch_bin)
end

function ActionDiscretizationConfig(config::Dict{String, Any})
    num_throttle_actions = length(config["throttle"]) + 1
    num_pitch_actions = length(config["pitch"]) + 1
    return ActionDiscretizationConfig(
        config["throttle"],
        num_throttle_actions,
        config["pitch"],
        num_pitch_actions,
        num_throttle_actions * num_pitch_actions
    )
end

function ObsDiscretizationConfig(config::Dict{String, Any})
    num_x_bins = length(config["x"]) + 1
    num_y_bins = length(config["y"]) + 1
    num_theta_bins = length(config["theta"]) + 1
    num_vx_bins = length(config["vx_air"]) + 1
    num_vy_bins = length(config["vy_air"]) + 1
    return ObsDiscretizationConfig(
        config["x"],
        num_x_bins,
        config["y"],
        num_y_bins,
        config["theta"],
        num_theta_bins,
        config["vx_air"],
        num_vx_bins,
        config["vy_air"],
        num_vy_bins,
        num_x_bins * num_y_bins * num_theta_bins * num_vx_bins * num_vy_bins
    )
end

function obsToIndex(obs::DiscretizedObservation, obs_config::ObsDiscretizationConfig)
    index = (obs.x - 1)
    index *= config.num_x_bins
    index += (obs.y - 1)
    index *= config.num_y_bins
    index += (obs.theta - 1)
    index *= config.num_theta_bins
    index += (obs.vx_air - 1)
    index *= config.num_vx_bins
    index += (obs.vy_air - 1)
    return index + 1
end

function indexToObs(index::Int64, obs_config::ObsDiscretizationConfig)
    index -= 1
    vy_air = (index % config.num_vx_bins) + 1
    index = index / config.num_vx_bins
    vx_air = (index % config.num_theta_bins) + 1
    index = index / config.num_theta_bins
    theta = (index % config.num_y_bins) + 1
    index = index / config.num_y_bins
    y = (index % config.num_x_bins) + 1
    index = index / config.num_x_bins
    x = index + 1
    return DiscretizedObservation(x, y, theta, vx_air, vy_air)
end

function actionToIndex(action::DiscretizedAction, config::ActionDiscretizationConfig)
    index = (action.throttleAction - 1)
    index *= config.num_throttle_actions
    index += (action.pitchAction - 1)
    return index + 1
end

function indexToAction(index::Int64, config::ActionDiscretizationConfig)
    index -= 1
    pitchAction = (index % config.num_throttle_actions) + 1
    index = index / config.num_throttle_actions
    throttleAction = index + 1
    return DiscretizedAction(throttleAction, pitchAction)
end

function Action(disc_action::DiscretizedAction, config::ActionDiscretizationConfig, action_bounds_config::ActionBoundsConfig)
    # Get new throttle:
    if disc_action.throttleAction == 1
        low_throttle = action_bounds_config.throttle_limits[1]
    else
        low_throttle = config.throttle_bins[disc_action.throttleAction - 1]
    end

    if disc_action.throttleAction == config.num_throttle_actions + 1
        high_throttle = action_bounds_config.throttle_limits[2]
    else
        high_throttle = config.throttle_bins[disc_action.throttleAction]
    end
    throttle = (low_throttle + high_throttle) / 2

    # Get new pitch change:
    if disc_action.pitchAction == 1
        low_pitch = action_bounds_config.pitch_limits[1]
    else
        low_pitch = config.pitch_bins[disc_action.pitchAction - 1]
    end

    if disc_action.pitchAction == config.num_pitch_actions + 1
        high_pitch = action_bounds_config.pitch_limits[2]
    else
        high_pitch = config.pitch_bins[disc_action.pitchAction]
    end
    dPitch = (low_pitch + high_pitch) / 2

    return Action(throttle, dPitch)
end