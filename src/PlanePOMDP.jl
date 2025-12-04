#module PlanePOMDP

# include simulator
#include(joinpath(@__DIR__, "includes.jl"))
include("includes.jl")

# dependencies
using POMDPs
using POMDPTools

struct PlaneLandingPOMDP <: POMDP{State, Action, Observation}
    sim_config::SimConfig
    run_config::RunConfig
end

# -------------------------
# Make State work with POMCPOW
# -------------------------
import Random
# Random sampling for particle generation
function Random.rand(rng::AbstractRNG, ::Type{State})
    s0 = State(
        rand(rng, 0:1000.0:10000.0),  # x
        rand(rng, 0.0:1000.0:3000.0),      # y
        rand(rng, -0.3:0.3),               # theta
        rand(rng, -50.0:25.0:50.0),        # vx
        rand(rng, -50.0:25.0:50.0),        # vy
        0.5,                               # throttle
        0.0,                               # wind_vx
        0.0                                # wind_vy
    )
    return s0
end

# Needed by POMCPOW to copy states
Base.copy(s::State) = State(s.x, s.y, s.theta, s.vx, s.vy, s.throttle, s.wind_vx, s.wind_vy)

# -------------------------
# POMDP interface
# -------------------------
function POMDPs.initialstate(p::PlaneLandingPOMDP)
    return Deterministic(p.run_config.init_state)
end

# -------------------------
# Action space
# -------------------------
function POMDPs.actions(p::PlaneLandingPOMDP)
    ab = p.sim_config.action_bounds_config
    t_min, t_max = ab.throttle_limits
    p_min, p_max = ab.pitch_limits
    throttle_vals = collect(range(t_min, t_max; length = 3))
    pitch_vals    = collect(range(p_min, p_max; length = 3))
    acts = Action[]
    for th in throttle_vals, ph in pitch_vals
        push!(acts, Action(th, ph))
    end
    return acts
end

POMDPs.actionindex(p::PlaneLandingPOMDP, a::Action) = findfirst(==(a), actions(p))
# POMDPs.actions(p::PlaneLandingPOMDP) = all_actions(p.sim_config)
# POMDPs.actionindex(::PlaneLandingPOMDP, a) = a.action_index
# -------------------------
# Transition & Reward
# -------------------------
function POMDPs.gen(p::PlaneLandingPOMDP, s::State, a::Action)
    # Use your simulator to generate next state, reward, done
    next_state, reward, done = step(s, a, p.sim_config, p.run_config)

    # Observation: can be full state, or noisy version
    obs = observation(next_state, p.sim_config, p.run_config)

    return (next_state, obs, reward, done)
end

POMDPs.reward(p::PlaneLandingPOMDP, s::State, a::Action, sp::State) = begin
    _, r, _ = step(s, a, p.sim_config, p.run_config)
    return r
end

POMDPs.discount(::PlaneLandingPOMDP) = 0.9

function POMDPs.transition(p::PlaneLandingPOMDP, s::State, a::Action)
    next_state, reward, done = step(s, a, p.sim_config, p.run_config)
    return Deterministic(next_state)
end

# -------------------------
# Observation function
# -------------------------
function POMDPs.observation(p::PlaneLandingPOMDP, s::State, a::Action, sp::State)
    # Here you can return full continuous state or add noise
    return sp
end

#end # module
