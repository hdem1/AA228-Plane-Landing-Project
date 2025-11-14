struct RunConfig
    init_state::State
    wind_alt_bins::Vector{Float64}
    wind_v_x::Vector{Float64}
    wind_v_y::Vector{Float64}
end

function generate_run_config() 

end

function set_airspeeds(s::State, run_config::RunConfig)
    i = 1
    while i < length(wind_alt_bins) && s.y > run_config.wind_alt_bins[i+1]
        i++
    end

    return State(s.x, s.y, s.theta, s.vx, s.vy, s.throttle, run_config.wind_v_x[i], run_config.wind_v_y[i])
end