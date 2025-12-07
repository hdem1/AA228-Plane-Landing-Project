# POMCPOW_test.jl – FINAL
using POMDPs
using POMDPTools # HistoryRecorder, etc.
using POMCPOW
using Random
using CSV, DataFrames
using Distributions
using POMDPTools: Deterministic

# Load existing project code (states, actions, dynamics, configs, etc.)
include(joinpath(@__DIR__, "..", "includes.jl"))

# POMDP wrapper around your existing simulator

# use Observation = State (with noise added).
const Obs = Observation

struct PlaneLandingPOMDP <: POMDP{State, Action, Obs}
    sim_config::SimConfig
    run_config::RunConfig
end

# Discount factor 
POMDPs.discount(::PlaneLandingPOMDP) = 0.99

# Initial state
function POMDPs.initialstate(p::PlaneLandingPOMDP)
    # Return a *distribution* instead of a raw State.
    # HistoryRecorder will then sample with rand(rng, ...)
    return Deterministic(p.run_config.init_state)
end

function POMDPs.initialstate(p::PlaneLandingPOMDP, rng::AbstractRNG)
    # If anything calls the RNG version, just give the actual state back.
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

# Sample a noisy observation from this distribution
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
function POMDPs.transition(p::PlaneLandingPOMDP, s::State, a::Action)
    sp, _, _ = step(s, a, p.sim_config, p.run_config; log=false)

    return Deterministic(sp)
end

function POMDPs.reward(p::PlaneLandingPOMDP, s::State, a::Action, sp::State)
    r, _ = get_reward_and_terminate(sp, a, p.sim_config; log=false)
    if !isfinite(r)
        @warn "Non-finite reward in POMDPs.reward" r state=s action=a
        r = -1e6
    end
    return r
end

function environment_step(p::PlaneLandingPOMDP, s::State, a::Action)
    sp, _, _ = step(s, a, p.sim_config, p.run_config)

    r, done = get_reward_and_terminate(sp, a, p.sim_config; log=true)
    return sp, r, done
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

function main()
    # 1. Load configs
    sim_config = load_sim_config()

    # 2. Set up POMCPOW solver and planner
    solver = POMCPOWSolver(
        tree_queries = 1800,
        max_depth    = 75,
        eps          = 0.001,
    )

    # 3. Run multiple episodes and collect all trajectories
    n_episodes = 10
    all_df = DataFrame()

    for ep in 1:n_episodes
        run_config = generate_run_config(sim_config)

        pomdp = PlaneLandingPOMDP(sim_config, run_config)
        policy = solve(solver, pomdp)
        sim = HistoryRecorder(max_steps = 1500)

        # This uses your POMDP definitions: initialstate, transition, reward, etc.
        hist = simulate(sim, pomdp, policy)

        states  = hist[:s]
        rewards = [step.r for step in hist]

        df_ep = DataFrame(
            episode = fill(ep, length(states)),
            t       = 0:length(states)-1,
            x       = [s.x for s in states],
            y       = [s.y for s in states],
            vx      = [s.vx for s in states],
            vy      = [s.vy for s in states],
            theta   = [s.theta for s in states],
            thr     = [s.throttle for s in states],
            wind_vx = [s.wind_vx for s in states],
            wind_vy = [s.wind_vy for s in states],
            r       = rewards,
        )

        append!(all_df, df_ep)
    end

    @show size(all_df)
    CSV.write("POMCPOW_many_trajectories4.csv", all_df)

    println("Finished $n_episodes episodes.")
    println("Total rewards per episode = ",
        combine(groupby(all_df, :episode), :r => sum => :total_R))
end

main()
