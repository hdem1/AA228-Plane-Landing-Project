

function dynamics(state::State, sim_config::SimConfig)
    # Get forces:
    F_x, F_y = collectForces(state, sim_config)
    
    # Get new velocity:
    new_vx = state.vx + (F_x/sim_config.plane.mass) * sim_config.dt
    new_vy = state.vy + (F_y/sim_config.plane.mass) * sim_config.dt

    # Get new position
    new_x = state.x + sim_config.dt * (new_vx + state.vx) / 2
    new_y = state.y + sim_config.dt * (new_vy + state.vy) / 2

    # Return new state:
    return State(new_x, new_y, state.theta, new_vx, new_vy, state.throttle, state.wind_vx, state.wind_vy)
end

function collectForces(state::State, sim_config::SimConfig)
    # Sum forces:
    F_x = 0.0
    F_y = 0.0

    # Gravity:
    F_y -= sim_config.plane.mass * sim_config.planet.gravity
    # println("Gravity: 0, $(F_y)")

    # Lift/Drag:
    F_lift, F_drag = getAeroForces(sim_config, state)
    # println("Aero Forces: $(F_lift), $(F_drag)")
    F_x += -1 * sin(state.theta) * F_lift - cos(state.theta) * F_drag
    F_y += cos(state.theta) * F_lift - sin(state.theta) * F_drag
    # println("Aero in x,y: $(F_x), $(cos(state.theta) * F_lift - sin(state.theta) * F_drag)")

    # Engine
    F_engine = sim_config.plane.F_engine * state.throttle
    F_x += cos(state.theta) * F_engine
    F_y += sin(state.theta) * F_engine
    # println("Engine Forces: $(cos(state.theta) * F_engine), $(sin(state.theta) * F_engine)")

    return F_x, F_y
end

function getAeroForces(sim_config::SimConfig, state::State)
    alpha = get_alpha(state)
    # println("ALPHA = $alpha")
    C_L = sim_config.plane.m_lift * alpha + sim_config.plane.b_lift
    C_drag = sim_config.plane.a_drag * C_L*C_L + sim_config.plane.c_drag
    
    v_sq = get_airspeed_x(state)^2 + get_airspeed_y(state)^2
    airflow = 0.5 * sim_config.planet.air_density * sim_config.plane.A_wing * v_sq
    
    # println("C_L = $C_L, C_D = $C_drag")

    return C_L * airflow, C_drag * airflow
end