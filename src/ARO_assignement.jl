module ARO_assignement

using Gurobi
using JuMP
using DataFrames
# the instance data
products_lengths = [28, 4, 5, 9, 7, 1]
products_demands = [7, 5, 8, 9, 1, 1]

nbr_products = length(products_lengths)
steel_bar_length = maximum(products_lengths) + 30

#= products_lengths = [3, 4, 5, 7, 9, 11]
products_demands = [25, 40, 20, 30, 15, 20]

nbr_products = length(products_lengths)
steel_bar_length = 30 =#

# the first constraints
patterns = [2 0 0 0 0 1 ; 0 5 4 1 1 0]
#= patterns = [10 0 0 0 0 0; 
             8 1 0 0 0 0;
             8 0 1 0 0 0;
             7 2 0 0 0 0;
             7 1 1 0 0 0;
             1 0 0 1 1 1 ] =#
reduced_cost = -Inf
results_df = DataFrame(iteration = Int[], obj_value = Float64[], product1 = Int[], product2 = Int[], product3 = Int[], product4 = Int[], product5 = Int[], product6 = Int[])
iter = 1
#loop until we get no more improvement
while reduced_cost <= -0.00001
    #create the master problem
    model = Model(Gurobi.Optimizer)
    #the master variables
    @variable(model, x[1:size(patterns)[1]] >= 0)

    #the master constraints
    @constraint(model, constraint[j = 1:nbr_products], sum(patterns[i,j] * x[i] for i in 1:size(patterns)[1]) >= products_demands[j])

    #the master objective function
    @objective(model, Min, sum(x[i] for i in 1:size(patterns)[1]))
    #solve the master problem
    optimize!(model)

    # get the objective function and the value variables
    x_values = value.(x)
    obj_value = objective_value(model)
    
    # get te dual prices
    consts = all_constraints(model, include_variable_in_set_constraints = true)
    duals_prices = dual.(consts)[1:nbr_products]
    
    #create the pricing problem
    price_model = Model(Gurobi.Optimizer)
    #the pricing variables
    @variable(price_model, y[1:nbr_products] >= 0, Int)
    #the pricing constraints
    @constraint(price_model, sum(products_lengths[j] * y[j] for j in 1:nbr_products) <= steel_bar_length)
    #the pricing objective function
    @objective(price_model, Min, sum(-1 * duals_prices[j] * y[j] for j in 1:nbr_products))
    
    #solve the pricing problem
    optimize!(price_model)

    #get the price y_values
    y_values = value.(y)
    price_objective = objective_value(price_model)

    # add the pattern to the master problem
    patterns = [patterns ; y_values']

    reduced_cost = 1 + price_objective

    #push the results
    push!(results_df, [iter, obj_value, y_values[1], y_values[2], y_values[3], y_values[4], y_values[5], y_values[6]])
    iter += 1
end

#convert the results 
for row in eachrow(results_df)
    println(row.iteration, " & ", round(row.obj_value,digits=2), " & ", row.product1, " & ", row.product2, " & ", row.product3, " & ", row.product4, " & ", row.product5, " & ", row.product6, " \\\ ")
end

for i in 1:length(x_values)
    println("x$i & $(x_values[i])")
end


end # module ARO_assignement
