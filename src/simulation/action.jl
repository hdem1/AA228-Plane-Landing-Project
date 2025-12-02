struct Action
    new_throttle::Float64
    dPitch::Float64
end

struct ActionBoundsConfig
    throttle_limits::Vector{Float64}
    pitch_limits::Vector{Float64}
end 

function ActionBoundsConfig(action_limits::Dict{String,Any})
    throttle_limits = Vector{Float64}([action_limits["throttle"]["min"], action_limits["throttle"]["max"]])
    pitch_limits = Vector{Float64}([action_limits["pitch"]["min"], action_limits["pitch"]["max"]])
    return ActionBoundsConfig(throttle_limits, pitch_limits)
end