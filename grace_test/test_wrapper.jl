using POMDPs
using POMDPTools: HistoryRecorder, state_hist
# using POMCPOW
# using ParticleFilters
using Random
using CSV, DataFrames

# Load your module
include("../src/PlanePOMDP.jl")
#using PlanePOMDP  # use the module defined in PlanePOMDP.jl

# Load simulator configs
sim_config = load_sim_config()
run_config = generate_run_config(sim_config)

# -------------------------
# Build POMDP
# -------------------------
pomdp = PlaneLandingPOMDP(sim_config, run_config)
println("POMDP built successfully")

# -------------------------
# Define RNG
# -------------------------
rng = MersenneTwister(1234)   # fixed RNG for reproducibility

# -------------------------
# Use a simple random policy
# -------------------------
policy = RandomPolicy(rng=rng, pomdp)

# -------------------------
# Solve using POMCPOW
# -------------------------
# solver = POMCPOWSolver(max_depth = 10, rng = MersenneTwister())
# planner = POMCPOWPlanner(solver, pomdp)

sim = HistoryRecorder(max_steps=200)

initial_state = Deterministic(pomdp.run_config.init_state)
hist = simulate(sim, pomdp, policy, initial_state; rng=rng)
# policy = RandomPolicy(pomdp)
# hist = simulate(sim, pomdp, policy)
# println("Simulation completed successfully")
# policy = solve(solver, pomdp)

# # -------------------------
# # Simulate a trajectory
# # -------------------------
# sim = HistoryRecorder(max_steps=200)
# hist = simulate(sim, pomdp, policy)

# # -------------------------
# # Export trajectory to CSV
# # -------------------------
# states = state_hist(hist)

# df = DataFrame(
#     t     = 0:length(states)-1,
#     x     = [s.x for s in states],
#     y     = [s.y for s in states],
#     vx    = [s.vx for s in states],
#     vy
