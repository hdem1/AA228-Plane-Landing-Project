struct Action
    throttleAction::Int64
    pitchAction::Int64
end

struct ActionConfig
    throttleChanges::Vector{Float64}
    numThrottleActions::Int64
    pitchChanges::Vector{Float64}
    numPitchActions::Int64
    action_result_limits::Dict{String, Vector{Float64}}
    totActionSpace::Int64
end

function get_action_results(action::Action, actionConfig::ActionConfig)
    return actionConfig.throttleChanges[action.throttleAction], actionConfig.pitchChanges[action.pitchAction]
end