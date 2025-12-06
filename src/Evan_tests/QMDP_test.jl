include("../includes.jl")

using POMDPs
using QMDP
using POMDPTools  # for simulate, HistoryRecorder, etc.
using POMDPTools: Deterministic

using CSV, DataFrames


struct PlaneLandingPOMDP <: POMDP{State, Action, Observation}
    sim_config::SimConfig
    run_config::RunConfig
    state_space::Vector{State}

end 
const NX  = 15   # number of x points
const NY  = 10   # number of y (altitude) points
const NVX = 7    # tweak all of these as needed
const NVY = 7
const NTH = 5
const x_min = -2000.0
const x_max = 2000.0
const y_min = 0.0
const y_max = 2000.0
const vx_min = -50.0
const vx_max = 50.0
const vy_min = -50.0
const vy_max = 50.0
const theta_min = -0.3
const theta_max = 0.3

function make_state_grid(pomdp::PlaneLandingPOMDP)
    s0 = pomdp.run_config.init_state
    xs   = range(x_min, x_max; length=NX)
    ys   = range(y_min, y_max; length=NY)
    vxs  = range(vx_min, vx_max; length=NVX)
    vys  = range(vy_min, vy_max; length=NVY)
    thetas = range(theta_min, theta_max; length=NTH)

    states = State[]
    for x in xs, y in ys, vx in vxs, vy in vys, th in thetas
        push!(states, State(x, y, th, vx, vy, s0.throttle,  s0.wind_vx, s0.wind_vy,))
    end
    return states
end

function POMDPs.actions(p::PlaneLandingPOMDP)
    ab = p.sim_config.action_bounds_config

    # These are 2-element tuples or vectors: (min, max)
    t_min, t_max = ab.throttle_limits
    p_min, p_max = ab.pitch_limits

    # Simple 3-level discretization 
    throttle_vals = range(t_min, t_max; length = 3)
    pitch_vals    = range(p_min, p_max; length = 3)

    acts = Action[]
    for th in throttle_vals, ph in pitch_vals
        push!(acts, Action(th, ph))
    end
    return acts
end

POMDPs.actions(p::PlaneLandingPOMDP, s::State) = POMDPs.actions(p)

# 3. Hook up the POMDPs.jl interface by calling existing code
POMDPs.initialstate(p::PlaneLandingPOMDP) = p.run_config.init_state

POMDPs.transition(p::PlaneLandingPOMDP, s::State, a::Action) = begin
    next_state, reward, done = step(s, a, p.sim_config, p.run_config)
    return Deterministic(next_state)
end

POMDPs.reward(p::PlaneLandingPOMDP, s::State, a::Action, sp::State) = begin
    _, r = get_reward_and_terminate(s, a, p.sim_config)  
    return r
end

POMDPs.discount(::PlaneLandingPOMDP) = 0.99

sim_config = load_sim_config() # defined in sim_config.jl
run_config = generate_run_config(sim_config)

state_space = make_state_grid(PlaneLandingPOMDP(sim_config, run_config, state_space))

pomdp = PlaneLandingPOMDP(sim_config, run_config, state_space)

POMDPs.states(p::PlaneLandingPOMDP) = p.state_space

function POMDPs.stateindex(p::PlaneLandingPOMDP, s::State)
    return findfirst(==(s), p.state_space)
end

solver = QMDPSolver()
policy = solve(solver, pomdp)

sim = HistoryRecorder(max_steps=200)
hist = simulate(sim, pomdp, policy)

states = hist.state_hist

df = DataFrame(
    t = 0:length(states)-1,
    x = [s.x for s in states],
    y = [s.y for s in states],
    vx = [s.vx for s in states],
    vy = [s.vy for s in states],
    theta = [s.theta for s in states]
)

CSV.write("QMDP_certain_trajectory.csv", df)