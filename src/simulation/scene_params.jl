struct SceneParams
   name::String
   width::Float64
   height::Float64
   starting_x_bounds::Vector{Float64}
   starting_y_bounds::Vector{Float64}
   starting_theta_bounds::Vector{Float64}
   starting_alpha_bounds::Vector{Float64}
   starting_vel_bounds::Vector{Float64}
   avg_wind_speed_x_sigma::Float64
   avg_wind_speed_y_sigma::Float64
   wind_speed_x_var_sigma::Float64
   wind_speed_y_var_sigma::Float64
   num_wind_layers::Int64
end

function SceneParams(scene_params_name::String)
   filepath = "configs/scene_params/"*scene_params_name*".yaml"
   config = YAML.load_file(filepath, dicttype=Dict{String, Any})
   return SceneParams(
      config["name"], 
      config["width"], 
      config["height"], 
      config["starting_x_bounds"], 
      config["starting_y_bounds"], 
      config["starting_theta_bounds"], 
      config["starting_alpha_bounds"], 
      config["starting_vel_bounds"], 
      config["avg_wind_speed_x_sigma"], 
      config["avg_wind_speed_y_sigma"], 
      config["wind_speed_x_var_sigma"], 
      config["wind_speed_y_var_sigma"],
      config["num_wind_layers"])
end

