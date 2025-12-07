#########################################################
# random_policy.jl – random action baseline
#########################################################

using POMDPs           
using Random
using CSV, DataFrames

# Pull in State, Action, SimConfig, RunConfig, step, generate_run_config, etc.
include(joinpath(@__DIR__, "..", "includes.jl"))


# Action space: match the POMDP action grid (3x3 throttle/pitch)
function random_action_space(sim_config::SimConfig)
    ab = sim_config.action_bounds_config
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

# Run a single random-policy episode using step(...)
function run_random_episode(
    sim_config::SimConfig;
    ep::Int,
    max_steps::Int = 1500,
    rng::AbstractRNG = Random.default_rng(),
)
    # New run config each episode
    run_config = generate_run_config(sim_config)

    # Initial state from run_config
    s = run_config.init_state

    # Discrete action set (same grid as PlanePOMDP)
    acts = random_action_space(sim_config)

    # Trajectory buffers
    xs     = Float64[]
    ys     = Float64[]
    vxs    = Float64[]
    vys    = Float64[]
    thetas = Float64[]
    thrs   = Float64[]
    wvxs   = Float64[]
    wvys   = Float64[]
    rs     = Float64[]
    ts     = Int[]

    t = 0
    terminated = false

    while !terminated && t < max_steps
        # Log current state at time t
        push!(xs, s.x)
        push!(ys, s.y)
        push!(vxs, s.vx)
        push!(vys, s.vy)
        push!(thetas, s.theta)
        push!(thrs, s.throttle)
        push!(wvxs, s.wind_vx)
        push!(wvys, s.wind_vy)
        push!(ts, t)

        # Random action from the discrete action grid
        a = rand(rng, acts)

        # Step environment (uses your dynamics, wind, and reward)
        s_next, r, terminated = step(s, a, sim_config, run_config; log = false)

        # Log reward for this step
        push!(rs, r)

        # Advance
        s = s_next
        t += 1
    end

    n = length(ts)
    return DataFrame(
        episode = fill(ep, n),
        t       = ts,
        x       = xs,
        y       = ys,
        vx      = vxs,
        vy      = vys,
        theta   = thetas,
        thr     = thrs,
        wind_vx = wvxs,
        wind_vy = wvys,
        r       = rs,
    )
end

# Main: run episodes + write CSV
function main()
    sim_config = load_sim_config()

    n_episodes = 10
    max_steps  = 1500
    rng        = MersenneTwister(42)

    all_df = DataFrame()

    for ep in 1:n_episodes
        df_ep = run_random_episode(sim_config; ep = ep, max_steps = max_steps, rng = rng)
        append!(all_df, df_ep)
    end

    CSV.write("random_policy_trajectories.csv", all_df)

    println("Wrote random_policy_trajectories.csv with ", nrow(all_df), " rows.")
    println("Total reward per episode:")
    println(combine(groupby(all_df, :episode), :r => sum => :total_R))
end

main()
