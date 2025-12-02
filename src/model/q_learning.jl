struct QLearningModel
    q_table::Vector{Vector{Float64}}
end

function QLearningModel(state_space::Int64, action_space::Int64, init_value::Float64 = 0.0)
    
end