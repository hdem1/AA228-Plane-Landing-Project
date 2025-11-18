struct RunConfig
    init_state::State
    wind_alt_bins::Vector{Float64}
    wind_vx::Vector{Float64}
    wind_vy::Vector{Float64}
end

function generate_run_config(sim_config::SimConfig)
    # generate avg airspeed 
    avg_wind_vx = rand(Normal(0, sim_config.scene_params.avg_wind_speed_x_sigma))
    avg_wind_vy = rand(Normal(0, sim_config.scene_params.avg_wind_speed_y_sigma))

    # Generate individual windspeeds
    num_wind_layers =  sim_config.scene_params.num_wind_layers
    wind_alt_bins = zeros(Float64,num_wind_layers)
    wind_vx = zeros(Float64,num_wind_layers)
    wind_vy = zeros(Float64,num_wind_layers)
    for i in 1:num_wind_layers
        wind_alt_bins[i] = (i-1.0) / num_wind_layers * sim_config.scene_params.height
        wind_vx[i] = rand(Normal(avg_wind_vx, sim_config.scene_params.wind_speed_x_var_sigma))
        wind_vy[i] = rand(Normal(avg_wind_vy, sim_config.scene_params.wind_speed_y_var_sigma))
    end

    # Generate the initial state:
    intermediate_config = RunConfig(State(), wind_alt_bins, wind_vx, wind_vy)
    init_state = generate_init_state(sim_config.scene_params, intermediate_config)

    return RunConfig(init_state, wind_alt_bins, wind_vx, wind_vy)
end

function generate_init_state(scene::SceneParams, run_config::RunConfig)
   init_x = rand() * (scene.starting_x_bounds[2] - scene.starting_x_bounds[1]) + scene.starting_x_bounds[1]
   init_y = rand() * (scene.starting_y_bounds[2] - scene.starting_y_bounds[1]) + scene.starting_y_bounds[1]
   init_theta = rand() * (scene.starting_theta_bounds[2] - scene.starting_theta_bounds[1]) + scene.starting_theta_bounds[1]
   init_vel = rand() * (scene.starting_vel_bounds[2] - scene.starting_vel_bounds[1]) + scene.starting_vel_bounds[1]
   init_alpha = rand() * (scene.starting_alpha_bounds[2] - scene.starting_alpha_bounds[1]) + scene.starting_alpha_bounds[1] 

   init_wind_vx, init_wind_vy = get_wind_speeds(init_y, run_config)

   init_vx = init_vel * cos(init_theta + init_alpha) + init_wind_vx
   init_vy = init_vel * sin(init_theta + init_alpha) + init_wind_vy

   new_state = State(init_x, init_y, init_theta, init_vx, init_vy, 0.5, init_wind_vx, init_wind_vy)
end

function get_wind_speeds(alt::Float64, run_config::RunConfig)
    i = 1
    while i < length(run_config.wind_alt_bins) && alt > run_config.wind_alt_bins[i+1]
        i+=1
    end
    return run_config.wind_vx[i], run_config.wind_vy[i]
end

function set_airspeeds(s::State, run_config::RunConfig)
    wind_vx, wind_vy = get_wind_speeds(s.y, run_config)
    return State(s.x, s.y, s.theta, s.vx, s.vy, s.throttle, wind_vx, wind_vy)
end