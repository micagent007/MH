using DataFrames
using CSV
include("Gap_struc.jl")

function create_csv(folder="Instances/")

    files = readdir(folder)
    df = DataFrame(id = Int[], file = String[], instance = Int[], greedy_solution = Int[], find_least_ressources = Int[], find_least_ressources_bis = []) # Ajouter les heuristiques à comparer
    id = 0

    for file in files
        path = folder*file # Ajuster le path
        nb_instances = parse(Int, readline(path))
        for instance in 0:nb_instances-1

            gap = GAP(path, instance)

            # Ajouter les heuristiques à comparer

            # Greedy solution
            find_greedy_solution!(gap)
            greedy_cost = is_feasible(gap) ? cost(gap) : 0

            # Least ressources (task)
            find_least_ressources!(gap)
            lr_cost = is_feasible(gap) ? cost(gap) : 0

            # Least ressources (worker)
            find_least_ressources_bis!(gap)
            lr_bis_cost = is_feasible(gap) ? cost(gap) : 0



            push!(df, (id, path, instance, greedy_cost, lr_cost, lr_bis_cost)) # Ajouter les heuristiques à comparer
            println(id)
            id += 1
        end
    end
    CSV.write("output_csv_heuristique", df)
end