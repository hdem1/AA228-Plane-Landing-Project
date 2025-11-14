struct Planet
    name::String
    air_density::Float64
    gravity::Float64
    avg_wind_v_x::Float64
    wind_noise_v_x::Float64
    avg_wind_v_y::Float64
    wind_noise_v_y::Float64
end

function Planet(planet_name::String)
    filepath = "configs/planets/"*planet_name*".yaml"
    config = YAML.load_file(filepath, dicttype=Dict{String, Any})
    return Planet(planet_name, config["air_density"], config["gravity"], config["avg_wind_v_x"], config["wind_noise_v_x"], config["avg_wind_v_y"], config["wind_noise_v_y"])
end