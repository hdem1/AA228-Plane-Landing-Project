struct ActionDiscretizationConfig
    throttle_changes::Vector{Float64}
    num_throttle_actions::Int64
    pitch_changes::Vector{Float64}
    num_pitch_actions::Int64
    tot_action_space::Int64
end

struct StateDiscretizationConfig
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
    tot_state_space::Int64
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

function DiscretizedObservation(obs:::Observation, config::StateDiscretizationConfig)
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

function StateDiscretizationConfig(config::Dict{String, Any})
    num_x_bins = length(config["x"]) + 1
    num_y_bins = length(config["y"]) + 1
    num_theta_bins = length(config["theta"]) + 1
    num_vx_bins = length(config["vx_air"]) + 1
    num_vy_bins = length(config["vy_air"]) + 1
    return ActionDiscretizationConfig(
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