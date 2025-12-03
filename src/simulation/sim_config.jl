struct SimConfig
   dt::Float64
   planet::Planet
   plane::Plane
   scene_params::SceneParams
   action_bounds_config::ActionBoundsConfig
   obs_uncertainty_config::ObsUncertaintyConfig
end

function load_sim_config()
   filepath = "configs/simulation_config.yaml"
   print("Loading Simulation Configuration from $filepath........")
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
   action_config = ActionBoundsConfig(config["action_limits"])

   # Observation Uncertainty:
   obs_uncertainty_config = ObsUncertaintyConfig(config["uncertainty_magnitude"])

   config = SimConfig(dt, planet, plane, scene_params, action_config, obs_uncertainty_config)
   println("Success")
   return config
end