struct ActionDiscretizationConfig
    throttle_changes::Vector{Float64}
    num_throttle_actions::Int64
    pitch_changes::Vector{Float64}
    num_pitch_actions::Int64
    tot_action_space::Int64
end

struct StateDiscretizationConfig
    x_bins::Vector{Float64}
    y_bins::Vector{Float64}
    theta_bins::Vector{Float64}
    vx_air_bins::Vector{Float64}
    vy_air_bins::Vector{Float64}
end

struct DiscretizedAction
    throttleAction::Int64
    pitchAction::Int64
end


function get_action_results(dAction::DiscretizedAction, actionConfig::ActionDiscretizationConfig)
    return Action(actionConfig.throttleChanges[dAction.throttleAction], actionConfig.pitchChanges[dAction.pitchAction])
end

function ActionDiscretizationConfig(config::Dict{String, Any})
    num_throttle_actions = length(config["throttle_changes"])
    num_pitch_actions = length(config["pitch_changes"])
    return ActionDiscretizationConfig(
        config["throttle_changes"],
        num_throttle_actions,
        config["pitch_changes"],
        num_pitch_actions,
        num_throttle_actions + num_pitch_actions
    )
end