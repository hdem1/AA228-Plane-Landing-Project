struct SimConfig
   dt::Float64
   planet::Planet
   plane::Plane
   scene_params::SceneParams
   action_config::ActionConfig
   obs_uncertainty_config::ObsUncertaintyConfig
end

function load_sim_config()
   filepath = "configs/simulation_config.yaml"
   config = YAML.load_file(filepath, dicttype=Dict{String, Any})
   
   # dt:
   dt = config["dt"]

   # Planet:
   planet = Planet(config["planet"])
   
   # Plane:
   plane = Plane(config["plane"])

   # Scene Params:
   scene_params = SceneParams(config["scene_params"])

   # Action config:

   return SimConfig(dt, planet, plane, scene_params, action_config, obs_uncertainty_config)
end