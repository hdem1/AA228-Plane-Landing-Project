struct SceneGeometry
   width::Float64
   height::Float64
   height::Float64
end

struct SimConfig
   dt::Float64
   planet::Planet
   scene_geometry::SceneGeometry
   plane::Plane
   action_config::ActionConfig
   obs_uncertainty_config::ObsUncertaintyConfig
   state_discretization_config::StateDiscretizationConfig
end

function load_sim_config()
   filepath = "configs/simulation_config.yaml"
   config = YAML.load_file(filepath, dicttype=Dict{String, Any})
   
   # dt:
   dt = config["dt"]

   # Planet and plane:
   planet = Planet(config["planet"])
   plane = Plane(config["plane"])

   # Action config:

   # 

   return SimConfig(planet, )
end