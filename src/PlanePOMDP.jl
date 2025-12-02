module PlanePOMDP

# using POMDPs: POMDP
using Random


export PlanePOMDPProblem, PlaneStateWrapper, PlaneAction, PlaneObs
export initalstate, generate, discount

# -------------------------
# Import dependencies
# -------------------------
# include("plant/planet.jl")
# include("simulation/action.jl")
# include("simulation/state.jl")
# include("plant/plane.jl")
# include("simulation/scene_params.jl")
# include("simulation/sim_config.jl")
include(joinpath(@__DIR__, "plant/planet.jl"))
include(joinpath(@__DIR__, "simulation/action.jl"))
include(joinpath(@__DIR__, "simulation/state.jl"))
include(joinpath(@__DIR__, "plant/plane.jl"))
include(joinpath(@__DIR__, "simulation/scene_params.jl"))
include(joinpath(@__DIR__, "simulation/sim_config.jl"))

# -------------------------
# Basic types (light wrappers)
# -------------------------
struct PlaneStateWrapper
    s::State   # will store your simulator State instance
end

struct PlaneAction
    dThrottle::Float64
    dPitch::Float64
end

struct PlaneObs
    z::Vector{Float64}
end

# -------------------------
# The POMDP problem struct
# -------------------------
# const BasePOMDP = POMDP{PlaneStateWrapper, PlaneAction}

# struct PlanePOMDPProblem <: BasePOMDP
#     sim_config::Any
#     action_config::Any
#     obs_uncertainty::ObsUncertaintyConfig
#     crash_penalty::Float64
#     touchdown_reward::Float64
# end
struct PlanePOMDPProblem
    sim_config::Any
    action_config::Any
    obs_uncertainty::ObsUncertaintyConfig
    crash_penalty::Float64
    touchdown_reward::Float64
end

# -------------------------
# Initial state 
# -------------------------
function initialstate(p::PlanePOMDPProblem)
    if hasfield(typeof(p.sim_config), :init_state)
        return PlaneStateWrapper(p.sim_config.init_state)
    else
        return PlaneStateWrapper(State())
    end
end

# -------------------------
# Helper: apply action increments to state with new throttle/theta
# -------------------------

function _apply_action(state::State, action::PlaneAction, action_config)
    sim_action = Action(action.dThrottle, action.dPitch)
    return State(state, sim_action, action_config)
end

# -------------------------
# Helper: gen obs
# -------------------------
function _get_observation(state::State, obs_uncertainty::ObsUncertaintyConfig)
    obs = get_observation(state, obs_uncertainty)
    # Flatten into vector for POMDPs
    return PlaneObs([obs.x, obs.y, obs.theta, obs.vx_air, obs.vy_air])
end

# -------------------------
# Reward and terminal helpers
# -------------------------
function reward(state::State, p::PlanePOMDPProblem)
    r = 0.0
    y_pos = state.y
    r -= abs(y_pos) * 0.01
    if abs(y_pos) < 0.5
        r += p.touchdown_reward
    elseif y_pos < 0.0
        r += p.crash_penalty
    end
    return r
end

function terminal(state::State)
    y_pos = state.y
    return abs(y_pos) < 0.5 || y_pos < 0.0
end


# -------------------------
# Generative model: single simulate step
# -------------------------
function generate(p::PlanePOMDPProblem, wrapped::PlaneStateWrapper, a::PlaneAction)
    # unwrap state
    sim_state = wrapped.s

    # apply action increments
    new_state = _apply_action(sim_state, a, p.action_config)

    # step dynamics
    next_state = dynamics(new_state, p.sim_config)

    # generate obs
    obs = _get_observation(next_state, p.obs_uncertainty)

    # simple reward: encourage lower altitude to touchdown
    r = reward(next_state, p)
    term = terminal(next_state)
    return (PlaneStateWrapper(next_state), obs, r, term)
end

# -------------------------
# Discount
# -------------------------
discount(::PlanePOMDPProblem) = 0.9

end # module


