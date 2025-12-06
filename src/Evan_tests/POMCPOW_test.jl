#########################################################
# POMCPOW_test.jl – run POMCPOW on your plane POMDP
#########################################################

using POMDPs
using POMDPTools              # HistoryRecorder, etc.
using POMCPOW
using Random
using CSV, DataFrames
using Distributions


# Load your existing project code (states, actions, dynamics, configs, etc.)
include(joinpath(@__DIR__, "..", "includes.jl"))

#########################################################
# POMDP wrapper around your existing simulator
#########################################################

# We'll use Observation = State (with noise added).
const Obs = Observation

struct PlaneLandingPOMDP <: POMDP{State, Action, Obs}
    sim_config::SimConfig
    run_config::RunConfig
end

# ----- Discount factor -----
POMDPs.discount(::PlaneLandingPOMDP) = 0.99

using POMDPTools: Deterministic   # you already have this above, so make sure it's there once

# ----- Initial state -----
function POMDPs.initialstate(p::PlaneLandingPOMDP)
    # Return a *distribution* instead of a raw State.
    # HistoryRecorder will then sample with rand(rng, ...)
    return Deterministic(p.run_config.init_state)
end

function POMDPs.initialstate(p::PlaneLandingPOMDP, rng::AbstractRNG)
    # If anything calls the RNG version, just give the actual state back.
    # (This version is mostly here for compatibility.)
    return p.run_config.init_state
end



# Action space

function POMDPs.actions(p::PlaneLandingPOMDP)
    ab = p.sim_config.action_bounds_config

    # (min, max) for throttle and pitch
    t_min, t_max = ab.throttle_limits
    p_min, p_max = ab.pitch_limits

    # Simple discretization; adjust counts as you like
    throttle_vals = collect(range(t_min, t_max; length = 5))
    pitch_vals    = collect(range(p_min, p_max; length = 5))

    acts = Action[]
    for th in throttle_vals, ph in pitch_vals
        push!(acts, Action(th, ph))
    end
    return acts
end

POMDPs.actions(p::PlaneLandingPOMDP, s::State) = POMDPs.actions(p)

# Observation model (explicit interface, with noise)
struct ObsDist
    mu::Observation
    oc::ObsUncertaintyConfig
end

# How likely is it to see observation o under this distribution?
function Distributions.pdf(d::ObsDist, o::Observation)
    oc = d.oc

    # Treat_uncertainty magnitudes as std devs
    px = pdf(Normal(d.mu.x,      oc.x_err_mag),      o.x)
    py = pdf(Normal(d.mu.y,      oc.y_err_mag),      o.y)
    pθ = pdf(Normal(d.mu.theta,  oc.theta_err_mag),  o.theta)
    pvx = pdf(Normal(d.mu.vx_air, oc.vx_air_err_mag), o.vx_air)
    pvy = pdf(Normal(d.mu.vy_air, oc.vy_air_err_mag), o.vy_air)

    return px * py * pθ * pvx * pvy
end

# How to sample a noisy observation from this distribution
function Base.rand(rng::AbstractRNG, d::ObsDist)
    oc = d.oc
    return Observation(
        d.mu.x      + randn(rng) * oc.x_err_mag,
        d.mu.y      + randn(rng) * oc.y_err_mag,
        d.mu.theta  + randn(rng) * oc.theta_err_mag,
        d.mu.vx_air + randn(rng) * oc.vx_air_err_mag,
        d.mu.vy_air + randn(rng) * oc.vy_air_err_mag,
    )
end


using POMDPTools: Deterministic

function POMDPs.observation(p::PlaneLandingPOMDP,
                            s::State,
                            a::Action,
                            sp::State)
    oc = p.sim_config.obs_uncertainty_config

    # "True" observation mean (noise-free) based on the next state
    mu = Observation(
        sp.x,
        sp.y,
        sp.theta,
        get_airspeed_x(sp),
        get_airspeed_y(sp),
    )
    return ObsDist(mu, oc)
end



# Transition and reward (explicit interface)

# Transition: step your simulator once, wrap next_state in Deterministic
function POMDPs.transition(p::PlaneLandingPOMDP,
                           s::State,
                           a::Action)
    # Your step(s, a, sim_config, run_config) -> (sp, r, done)
    sp, r, done = step(s, a, p.sim_config, p.run_config)

    # ---- OPTIONAL: add extra wind uncertainty here ----
    # If your step() already includes random wind, you can skip this.
    # If you want extra gusts, uncomment and set sigmas:
    #
    # wind_σx = 0.0
    # wind_σy = 0.0
    # sp = State(
    #     sp.x,
    #     sp.y,
    #     sp.theta,
    #     sp.vx,
    #     sp.vy,
    #     sp.throttle,
    #     sp.wind_vx + wind_σx*randn(),
    #     sp.wind_vy + wind_σy*randn(),
    # )

    return Deterministic(sp)
end

# Reward: reuse your existing reward logic
function POMDPs.reward(p::PlaneLandingPOMDP,
                       s::State,
                       a::Action,
                       sp::State)
    # Use your existing reward logic
    reward, terminate = get_reward_and_terminate(s, a, p.sim_config)

    if !isfinite(reward)
        @warn "Non-finite reward in POMDPs.reward" reward state=s action=a
        # Band-aid: treat this as a big crash and terminate
        reward = -1e6
    end

    return reward
end

function POMDPs.isterminal(p::PlaneLandingPOMDP, s::State)
    # Same conditions as get_reward_and_terminate
    if s.y <= 0
        return true
    end
    if s.y > 0 && s.x >= p.sim_config.scene_params.width
        return true
    end
    return false
end


# Main driver: build POMDP, solve with POMCPOW, export CSV

function main()
    # 1. Load configs using your existing code
    sim_config = load_sim_config()
    run_config = generate_run_config(sim_config)

    pomdp = PlaneLandingPOMDP(sim_config, run_config)

    # 2. Set up POMCPOW solver
solver = POMCPOWSolver(
    tree_queries = 600,
    max_depth    = 30,
    eps          = 0.001,      # default UCT exploration; tune if you like
    # you can also set other options here if needed, e.g.:
    # enable_action_pw = true,
    # alpha_action     = 0.5,
    # k_action         = 1.0,
)


    policy = solve(solver, pomdp)

    # 3. Simulate one episode, using the POMCPOW policy
    sim = HistoryRecorder(max_steps = 1500)
    hist = simulate(sim, pomdp, policy)

    # 4. Extract states from history
states  = hist[:s]                      # this is already a vector of State
rewards = [step.r for step in hist]     # turn generator into Vector{Float64}


    # 5. Export trajectory to CSV
    df = DataFrame(
        t       = 0:length(states)-1,
        x       = [s.x      for s in states],
        y       = [s.y      for s in states],
        vx      = [s.vx     for s in states],
        vy      = [s.vy     for s in states],
        theta   = [s.theta  for s in states],
        thr     = [s.throttle for s in states],
        wind_vx = [s.wind_vx for s in states],
        wind_vy = [s.wind_vy for s in states],
        r       = rewards,
    )
@show size(df)
@show names(df)
@show eltype.(eachcol(df))
println(first(df, 1))

CSV.write("POMCPOW_trajectory7.csv", df; bufsize=10_000_000)  # 10 MB buffer

    println("POMCPOW episode finished.")
    println("Total reward = ", sum(rewards))
    println("Trajectory written to POMCPOW_trajectory7.csv")
end

main()
