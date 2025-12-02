struct State
    x::Float64
    y::Float64
    theta::Float64
    vx::Float64
    vy::Float64
    throttle::Float64
    wind_vx::Float64
    wind_vy::Float64
end

function State()
    return State(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
end

struct Observation
    x::Float64
    y::Float64
    theta::Float64
    vx_air::Float64
    vy_air::Float64
end

struct ObsUncertaintyConfig
    x_err_mag::Float64
    y_err_mag::Float64
    theta_err_mag::Float64
    vx_air_err_mag::Float64
    vy_air_err_mag::Float64
end

function get_airspeed_x(s::State)
    return s.vx - s.wind_vx
end

function get_airspeed_y(s::State)
    return s.vy - s.wind_vy
end

function get_observation(s::State, uncConfig::ObsUncertaintyConfig)
    x_obs = s.x + rand() * uncConfig.x_err_mag
    y_obs = s.y + rand() * uncConfig.y_err_mag
    theta_obs = s.theta + rand() * uncConfig.theta_err_mag
    vx_air_obs = get_airspeed_x(s) + rand() * uncConfig.vx_air_err_mag
    vy_air_obs = get_airspeed_y(s) + rand() * uncConfig.vy_air_err_mag
    return Observation(x_obs, y_obs, theta_obs, vx_air_obs, vy_air_obs)
end

function get_alpha(s::State)
    theta_airspeed = atan( get_airspeed_y(s) / get_airspeed_x(s) )
    return s.theta - theta_airspeed
end

function State(state::State, action::Action, action_config::ActionBoundsConfig)
    new_throttle = clamp(action.new_throttle, action_config.throttle_limits[1], action_config.throttle_limits[2])
    new_theta = clamp(state.theta + action.dPitch, action_config.pitch_limits[1], action_config.pitch_limits[2])
    return State(state.x, state.y, new_theta, state.vx, state.vy, new_throttle, state.wind_vx, state.wind_vy)
end

function ObsUncertaintyConfig(uncertainty_config::Dict{String,Any})
    return ObsUncertaintyConfig(
        uncertainty_config["x"], 
        uncertainty_config["y"], 
        uncertainty_config["vx_airspeed"], 
        uncertainty_config["vy_airspeed"], 
        uncertainty_config["theta"]
    )
end