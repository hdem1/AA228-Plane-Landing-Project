struct State
    x::Float64
    y::Float64
    theta::Float64
    vx::Float64
    vy::Float64
    throttle::Float64
    wind_v_x::Float64
    wind_v_y::Float64
end

struct Observation
    x::Float64
    y::Float64
    theta::Float64
    v_x_air::Float64
    v_y_air::Float64
end

struct ObsUncertaintyConfig
    x_err_mag::Float64
    y_err_mag::Float64
    theta_err_mag::Float64
    v_x_air_err_mag::Float64
    v_y_air_err_mag::Float64
end

struct StateDiscretizationConfig
    x_bins::Vector{Float64}
    y_bins::Vector{Float64}
    theta_bins::Vector{Float64}
    v_x_air_bins::Vector{Float64}
    v_y_air_bins::Vector{Float64}
end

function get_airspeed_x(s::State)
    return s.v_x - s.wind_v_x
end

function get_airspeed_y(s::State)
    return s.v_y - s.wind_v_y
end

function get_observation(s::State, uncConfig::ObsUncertaintyConfig)
    x_obs = s.x + rand() * uncConfig.x_err_mag
    y_obs = s.y + rand() * uncConfig.y_err_mag
    theta_obs = s.theta + rand() * uncConfig.theta_err_mag
    v_x_air_obs = get_airspeed_x(s) + rand() * uncConfig.v_x_air_err_mag
    v_y_air_obs = get_airspeed_y(s) + rand() * uncConfig.v_y_air_err_mag
    return Observation(x_obs, y_obs, theta_obs, v_x_air_obs, v_y_air_obs)
end

function get_alpha(s::State)
    theta_airspeed = atan( get_airspeed_y(s) / get_airspeed_x(s) )
    return s.theta - theta_airspeed
end

function State(state::State, action::Action, action_config::ActionConfig)
    dT, dTheta = get_action_results(action, action_config)
    new_throttle = clamp(state.throttle + dT, action_config.action_result_limits["throttle"][0], action_config.action_result_limits["throttle"][1])
    new_theta = clamp(state.theta + dTheta, action_config.action_result_limits["theta"][0], action_config.action_result_limits["theta"][1])
    return State(state.x, state.y, new_theta, state.vx, state.vy, new_throttle, wind_v_x, wind_v_y)
end

function