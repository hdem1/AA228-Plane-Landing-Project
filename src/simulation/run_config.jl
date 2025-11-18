struct RunConfig
    init_state::State
    wind_alt_bins::Vector{Float64}
    wind_v_x::Vector{Float64}
    wind_v_y::Vector{Float64}
end

function generate_run_config(sim_config::SimConfig)
    # generate avg airspeed 
    avg_wind_x = Normal(0, sim_config.scene_params.avg_wind_speed_x_sigma)
    avg_wind_y = Normal(0, sim_config.scene_params.avg_wind_speed_y_sigma)

    # Generate individual windspeeds
    num_wind_layers =  sim_config.scene_params.num_wind_layers
    wind_alt_bins = zeros(Float64,num_wind_layers)
    wind_v_x = zeros(Float64,num_wind_layers)
    wind_v_y = zeros(Float64,num_wind_layers)
    for i in 1:num_wind_layers
        wind_alt_bins[i] = (i-1.0) / num_wind_layers * sim_config.scene_params.height
        wind_v_x[i] = Normal(avg_wind_x, sim_config.scene_params.wind_speed_x_var_sigma)
        wind_v_y[i] = Normal(avg_wind_y, sim_config.scene_params.wind_speed_y_var_sigma)
    end

    # Generate the initial state:
    init_state = generate_init_state(sim_config.scene_geometry, wind_alt_bins, wind_v_x, wind_v_y)

    return RunConfig(init_state, wind_alt_bins, wind_v_x, wind_v_y)
end

function generate_init_state(scene::SceneGeometry, run_config::RunConfig)
   init_x = rand() * (scene.starting_x_bounds[1] - scene.starting_x_bounds[0]) + scene.starting_x_bounds[0]
   init_y = rand() * (scene.starting_y_bounds[1] - scene.starting_y_bounds[0]) + scene.starting_y_bounds[0]
   init_theta = rand() * (scene.starting_theta_bounds[1] - scene.starting_theta_bounds[0]) + scene.starting_theta_bounds[0]
   init_vel = rand() * (scene.starting_vel_bounds[1] - scene.starting_vel_bounds[0]) + scene.starting_vel_bounds[0]
   init_alpha = rand() * (scene.starting_alpha_bounds[1] - scene.starting_alpha_bounds[0]) + scene.starting_alpha_bounds[0] 

   init_vx = init_vel * cos(init_theta + init_alpha) + init_wind[0]
   init_vy = init_vel * sin(init_theta + init_alpha) + init_wind[1]

   get_wind_speeds()

   new_state = State(init_x, init_y, init_theta, init_vx, init_vy, 0.5, init_wind[0], init_wind[1])
end

function get_wind_speeds(alt::Float64, run_config::RunConfig)
    i = 1
    while i < length(wind_alt_bins) && s.y > run_config.wind_alt_bins[i+1]
        i++
    end
    return run_config.wind_v_x[i], run_config.wind_v_y[i]
end

function set_airspeeds(s::State, run_config::RunConfig)
    wind_v_x, wind_v_y = get_wind_speeds(s.y, run_config)
    return State(s.x, s.y, s.theta, s.vx, s.vy, s.throttle, wind_v_x, wind_v_y)
end