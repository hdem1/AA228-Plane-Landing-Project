using POMDPs
using QMDP
using POMDPTools # HistoryRecorder, etc.
using POMDPTools: Deterministic
using POMDPTools: state_hist

using CSV, DataFrames

# Load your existing project code
include(joinpath(@__DIR__, "..", "includes.jl"))

#  POMDP definition 

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

const x_min = -2000.0
const x_max =  2000.0
const y_min =     0.0
const y_max =  2000.0
const vx_min =   -50.0
const vx_max =    50.0
const vy_min =   -50.0
const vy_max =    50.0
const theta_min = -0.3 # radians
const theta_max =  0.3

const XS     = collect(range(x_min,     x_max;     length = NX))
const YS     = collect(range(y_min,     y_max;     length = NY))
const THETAS = collect(range(theta_min, theta_max; length = NTH))
const VXS    = collect(range(vx_min,    vx_max;    length = NVX))
const VYS    = collect(range(vy_min,    vy_max;    length = NVY))

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

# Action space (discretized)
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
POMDPs.actionindex(p::PlaneLandingPOMDP, a::Action) = findfirst(==(a), actions(p))


# Initial state 

function POMDPs.initialstate(p::PlaneLandingPOMDP)
    s0_cont = p.run_config.init_state
    idx = stateindex(p, s0_cont)
    s0_grid = p.state_space[idx]
    return Deterministic(s0_grid)
end

function POMDPs.actionindex(p::PlaneLandingPOMDP, a::Action)
    idx = findfirst(==(a), actions(p))
    if idx === nothing
        error("Action $a not found in actions(p).")
    end
    return idx
end

# Transition & reward
# Assuming `step(s, a, sim_config, run_config)` exists and returns (next_state, reward, done)

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

# discount
POMDPs.discount(::PlaneLandingPOMDP) = 0.99

# State grid hooks for QMDP

POMDPs.states(p::PlaneLandingPOMDP) = p.state_space

function POMDPs.stateindex(p::PlaneLandingPOMDP, s::State)
    # Find nearest index in each dimension
    ix  = argmin(abs.(XS     .- s.x))
    iy  = argmin(abs.(YS     .- s.y))
    ith = argmin(abs.(THETAS .- s.theta))
    ivx = argmin(abs.(VXS    .- s.vx))
    ivy = argmin(abs.(VYS    .- s.vy))

    # Convert 5D indices (ix, iy, ith, ivx, ivy) into a single linear index.
    idx = 1 +
          (ix  - 1) * (NY * NTH * NVX * NVY) +
          (iy  - 1) * (     NTH * NVX * NVY) +
          (ith - 1) * (           NVX * NVY) +
          (ivx - 1) * (                 NVY) +
          (ivy - 1)

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

# Build POMDP, solve, simulate 

sim_config = load_sim_config()
run_config = generate_run_config(sim_config) 

state_space = make_state_grid(run_config)

pomdp = PlaneLandingPOMDP(sim_config, run_config, state_space)

solver = QMDPSolver()
policy = solve(solver, pomdp)

sim = HistoryRecorder(max_steps = 200)
hist = simulate(sim, pomdp, policy)

# Export trajectory 

states = state_hist(hist)   # vector of states at each step

df = DataFrame(
    t     = 0:length(states)-1,
    x     = [s.x for s in states],
    y     = [s.y for s in states],
    vx    = [s.vx for s in states],
    vy    = [s.vy for s in states],
    theta = [s.theta for s in states],
)

CSV.write("QMDP_certain_trajectory.csv", df)
println("Wrote trajectory to QMDP_certain_trajectory.csv")
