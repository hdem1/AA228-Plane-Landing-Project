struct Plane
    name::String
    mass::Float64
    m_lift::Float64
    b_lift::Float64
    a_drag::Float64
    c_drag::Float64
    A_wing::Float64
    F_engine::Float64
    max_landing_vx::Float64
    max_landing_vy::Float64
end

function Plane(plane_name::String)
    filepath = "configs/vehicles/"*plane_name*".yaml"
    config = YAML.load_file(filepath, dicttype=Dict{String, Any})
    return Plane(plane_name, config["mass"], config["m_lift"], config["b_lift"], config["a_drag"],  config["c_drag"], config["A_wing"], config["F_engine"], config["max_landing_vx"], config["max_landing_vy"])
end