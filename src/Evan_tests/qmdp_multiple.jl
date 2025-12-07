using POMDPs
using QMDP
using POMDPTools # HistoryRecorder, etc.
using POMDPTools: Deterministic
using POMDPTools: DiscreteBelief
using LinearAlgebra

using CSV, DataFrames

# Load your existing project code
include(joinpath(@__DIR__, "..", "includes.jl"))

# ================================
# POMDP definition
# ================================

struct PlaneLandingPOMDP <: POMDP{State, Action, State}
    sim_config::SimConfig
    run_config::RunConfig
    state_space::Vector{State}   # discrete grid for QMDP
end

# Coarse state grid sizes (tweak as needed)
const NX  = 5
const NY  = 5
const NVX = 3
const NVY = 3
const NTH = 3

const x_min    = -2000.0
const x_max    =  2000.0
const y_min    =     0.0
const y_max    =  2000.0
const vx_min   =   -50.0
const vx_max   =    50.0
const vy_min   =   -50.0
const vy_max   =    50.0
const theta_min = -0.3 # radians
const theta_max =  0.3

const XS     = collect(range(x_min, x_max; length = NX))
const YS     = collect(range(y_min, y_max; length = NY))
const THETAS = collect(range(theta_min, theta_max; length = NTH))
const VXS    = collect(range(vx_min, vx_max; length = NVX))
const VYS    = collect(range(vy_min, vy_max; length = NVY))

function make_state_grid(run_config::RunConfig)
    s0 = run_config.init_state

    states = State[]
    for x in XS, y in YS, th in THETAS, vx in VXS, vy in VYS
        push!(states, State(
            x,
            y,
            th,
            vx,
            vy,
            s0.throttle,
            s0.wind_vx,
            s0.wind_vy,
        ))
    end
    return states
end

# ================================
# Action space (discretized)
# ================================

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

POMDPs.actions(p::PlaneLandingPOMDP, s::State) = POMDPs.actions(p)

function POMDPs.actionindex(p::PlaneLandingPOMDP, a::Action)
    idx = findfirst(==(a), actions(p))
    if idx === nothing
        error("Action $a not found in actions(p).")
    end
    return idx
end

# ================================
# Initial state
# ================================

function POMDPs.initialstate(p::PlaneLandingPOMDP)
    s0_cont = p.run_config.init_state
    idx = stateindex(p, s0_cont)
    s0_grid = p.state_space[idx]
    return Deterministic(s0_grid)
end

# ================================
# Transition & reward (MDP for QMDP)
# ================================
# step(s, a, sim_config, run_config) returns (next_state, reward, done)

POMDPs.transition(p::PlaneLandingPOMDP, s::State, a::Action) = begin
    # Continuous next state from your simulator
    next_state_cont, reward, done = step(s, a, p.sim_config, p.run_config)

    # Snap to nearest grid state
    idx = stateindex(p, next_state_cont)
    next_state_grid = p.state_space[idx]

    return Deterministic(next_state_grid)
end

POMDPs.reward(p::PlaneLandingPOMDP, s::State, a::Action, sp::State) = begin
    _, r, _ = step(s, a, p.sim_config, p.run_config)
    return r
end

# Discount factor
POMDPs.discount(::PlaneLandingPOMDP) = 0.99

# ================================
# State grid hooks for QMDP
# ================================

POMDPs.states(p::PlaneLandingPOMDP) = p.state_space

function POMDPs.stateindex(p::PlaneLandingPOMDP, s::State)
    # Find nearest index in each dimension
    ix  = argmin(abs.(XS .- s.x))
    iy  = argmin(abs.(YS .- s.y))
    ith = argmin(abs.(THETAS .- s.theta))
    ivx = argmin(abs.(VXS .- s.vx))
    ivy = argmin(abs.(VYS .- s.vy))

    # Convert 5D indices (ix, iy, ith, ivx, ivy) into a single linear index.
    idx = 1 +
          (ix  - 1) * (NY * NTH * NVX * NVY) + (iy  - 1) * (NTH * NVX * NVY) +
          (ith - 1) * (NVX * NVY) + (ivx - 1) * (NVY) + (ivy - 1)
    return idx
end

function POMDPs.observation(p::PlaneLandingPOMDP,
                            s::State,
                            a::Action,
                            sp::State)
    idx = stateindex(p, sp)
    o = p.state_space[idx]
    return Deterministic(o)
end

# ================================
# QMDP policy helper
# ================================

# pick QMDP action for a single *grid* state
function qmdp_action_for_grid_state(pomdp::PlaneLandingPOMDP,
                                    policy::POMDPTools.Policies.AlphaVectorPolicy,
                                    s_grid::State)

    # 1. One-hot belief over grid states
    idx = stateindex(pomdp, s_grid)
    n   = length(pomdp.state_space)

    bvec = zeros(Float64, n)
    bvec[idx] = 1.0

    # 2. Alpha vectors and their associated actions
    alphas = policy.alphas
    amap   = policy.action_map  # vector of actions

    best_i   = 1
    best_val = -Inf

    for i in eachindex(alphas)
        v = dot(alphas[i], bvec)
        if v > best_val
            best_val = v
            best_i   = i
        end
    end

    return amap[best_i]
end

# Roll out continuous dynamics using QMDP policy.
# Returns (states, rewards) just like we used in random policy.
function rollout_qmdp_continuous(pomdp::PlaneLandingPOMDP,
                                 policy;
                                 max_steps::Int = 5000)

    s = pomdp.run_config.init_state

    states  = State[]
    rewards = Float64[]

    for t in 1:max_steps
        # Log current state
        push!(states, s)

        # 1. Map continuous state to nearest grid state
        idx    = stateindex(pomdp, s)
        s_grid = pomdp.state_space[idx]

        # 2. Use QMDP alpha vectors to choose an action
        a = qmdp_action_for_grid_state(pomdp, policy, s_grid)

        # 3. Evolve the real continuous dynamics
        s_next, r, done = step(s, a, pomdp.sim_config, pomdp.run_config)

        # Log reward for this step
        push!(rewards, r)

        s = s_next
        if done
            break
        end
    end

    return states, rewards
end

# ================================
# Main: run 10 trajectories and log like POMCPOW / random
# ================================

function main()
    sim_config = load_sim_config()

    n_episodes = 10
    max_steps  = 1500

    all_df = DataFrame()

    for ep in 1:n_episodes
        println("Solving QMDP and running episode $ep / $n_episodes")

        # Fresh run_config each episode (new initial state + wind)
        run_config  = generate_run_config(sim_config)
        state_space = make_state_grid(run_config)
        pomdp       = PlaneLandingPOMDP(sim_config, run_config, state_space)

        solver = QMDPSolver()
        policy = solve(solver, pomdp)

        states, rewards = rollout_qmdp_continuous(pomdp, policy; max_steps = max_steps)

        n = length(states)

        df_ep = DataFrame(
            episode = fill(ep, n),
            t       = 0:n-1,
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

    CSV.write("QMDP_trajectories.csv", all_df)
    println("Wrote QMDP trajectories to QMDP_trajectories.csv")

    println("Total rewards per episode =")
    println(combine(groupby(all_df, :episode), :r => sum => :total_R))
end

main()
