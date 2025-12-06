#!/usr/bin/env julia

# -------------------------
# Load your module
# -------------------------
include("../src/PlanePOMDP.jl")
using .PlanePOMDP
using POMDPs
using POMDPModels   # for POMCP
using Random

# -------------------------
# Create sim/run configs
# -------------------------
sim_config = SimConfig()  # adjust if needed
run_config = RunConfig(init_state = sim_config.init_state)

# -------------------------
# Create the POMDP
# -------------------------
pomdp = PlaneLandingPOMDP.PlaneLandingPOMDP(sim_config, run_config)

# -------------------------
# Create solver
# -------------------------
solver = POMCP(max_depth=10, n_sims=50, rng=Random.GLOBAL_RNG)

# -------------------------
# Initial belief
# -------------------------
b0 = POMDPs.initialstate(pomdp)

# -------------------------
# Run a few steps
# -------------------------
num_steps = 5
s = b0.value

println("Starting simulation...")

for t in 1:num_steps
    # choose action
    a = solve(solver, pomdp, b0)
    println("Step $t: chosen action = ", a)

    # simulate one step
    sp, o, r, term = PlanePOMDP.POMDPs.gen(pomdp, s, a, Random.GLOBAL_RNG)
    println("Step $t: next state = ", sp, ", reward = ", r, ", terminal = ", term)

    # update current state
    s = sp
    if term
        println("Terminal state reached at step $t")
        break
    end
end
