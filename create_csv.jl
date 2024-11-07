using DataFrames
using CSV

function create_csv()

    df = DataFrame(id = Int[], file = String[], instance = Int[], greedy_worker = Int[]) # Ajouter les heuristiques à comparer
    id = 0

    for file in files
        path = "Instances/"*file # Ajuster le path
        nb_instances = parse(Int, readline(path))
        for instance in 0:nb_instances-1

            # Ajouter les heuristiques à comparer

            greedy_worker = greedy(path, instance)


            push!(df, (id, path, instance, greedy_worker)) # Ajouter les heuristiques à comparer
            id += 1
        end
    end
    CSV.write("output_csv", df)
end