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

            gap = GAP(path, instance, true)

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

function create_csv_recuit(folder="Instances/")
    files = readdir(folder)
    df = DataFrame(id = Int[], file = String[], instance = Int[], greedy_solution = Int[], recuit_solution = []) # Ajouter les heuristiques à comparer
    id = 0

    for file in files
        path = folder*file # Ajuster le path
        nb_instances = parse(Int, readline(path))
        for instance in 0:nb_instances-1

            gap = GAP(path, instance, true)

            # Greedy solution
            find_greedy_solution!(gap)
            greedy_cost = is_feasible(gap) ? cost(gap) : 0

            # Recuit
            x = recuit(gap, 0.95, 100, 1000)
            recuit_cost = cost(x)

            push!(df, (id, path, instance, greedy_cost, recuit_cost)) # Ajouter les heuristiques à comparer
            println(id)
            id += 1
        end
    end
    CSV.write("output_csv_recuit", df)
end

function create_csv_tabu(folder="Instances/")
    files = readdir(folder)
    df = DataFrame(id = Int[], file = String[], instance = Int[], tabu_20_3_solution = [], tabu_20_5_solution = [], tabu_20_10_solution = [], tabu_50_3_solution = [], tabu_50_5_solution = [], tabu_50_10_solution = []) # Ajouter les heuristiques à comparer
    id = 0

    for file in files
        path = folder*file # Ajuster le path
        nb_instances = parse(Int, readline(path))
        for instance in 0:nb_instances-1

            gap = GAP(path, instance, true)
            best_solution_20_3, tabu_20_3 = tabu_search!(gap, 20, 3)
            best_solution_20_5, tabu__20_5 = tabu_search!(gap, 20, 5)
            best_solution_20_10, tabu_20_10 = tabu_search!(gap, 20, 10)
            best_solution_50_3, tabu_50_3 = tabu_search!(gap, 50, 3)
            best_solution_50_5, tabu_50_5 = tabu_search!(gap, 50, 5)
            best_solution_50_10, tabu_50_10 = tabu_search!(gap, 50, 10)

            push!(df, (id, path, instance, tabu_20_3, tabu__20_5, tabu_20_10, tabu_50_3, tabu_50_5, tabu_50_10)) # Ajouter les heuristiques à comparer
            println(id)
            id += 1
        end
    end
    CSV.write("output_csv_tabu", df)
end

function create_csv_genetic(folder="Instances/")
    files = readdir(folder)
    df = DataFrame(id = Int[], file = String[], instance = Int[], genetic_solution = []) # Ajouter les heuristiques à comparer
    id = 0

    for file in files
        path = folder*file # Ajuster le path
        nb_instances = parse(Int, readline(path))
        for instance in 0:nb_instances-1

            gap = GAP(path, instance, true)
            population_size = 20
            num_generations = 50
            mutation_rate = 0.1
            
            best_solution, best_cost = genetic_algorithm(gap, population_size, num_generations, mutation_rate)

            push!(df, (id, path, instance, best_cost)) # Ajouter les heuristiques à comparer
            println(id)
            id += 1
        end
    end
    CSV.write("output_csv_genetic", df)
end