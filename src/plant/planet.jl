struct Planet
    name::String
    air_density::Float64
    gravity::Float64
    avg_wind_vx::Float64
    wind_noise_vx::Float64
    avg_wind_vy::Float64
    wind_noise_vy::Float64
end

function Planet(planet_name::String)
    filepath = "configs/planets/"*planet_name*".yaml"
    config = YAML.load_file(filepath, dicttype=Dict{String, Any})
    return Planet(planet_name, config["air_density"], config["gravity"], config["avg_wind_vx"], config["wind_noise_vx"], config["avg_wind_vy"], config["wind_noise_vy"])
end