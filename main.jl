include("Gap_struc.jl")

filename = "Instances/gap5.txt"
id = 0
gap = GAP(filename, id, true, true)

# calcul d'une solution gloutonne
find_greedy_solution!(gap)
println("Solution gloutonne par tâche: ", gap.task_assignation)
println("Coût solution gloutonne par tâche : ", cost(gap))

println("////////////////////////////////////////////////////////////////////////////////////////////////////////////////////")

# Exécuter l'algorithme de montée
best_solution_climb, best_cost_climb = hill_climbing!(gap)
println("Meilleure solution trouvée avec la montée de voisinage : ", best_solution_climb)
println("Coût de la meilleure solution trouvée avec la montée de voisinage : ", best_cost_climb)

println("////////////////////////////////////////////////////////////////////////////////////////////////////////////////////")

#génétique initialisé par la montée de voisinage variable
population_size = 40
num_generations = 50
mutation_rate = 0.3

best_solution, best_cost = genetic_algorithm(gap, population_size, num_generations, mutation_rate)
println("Meilleure solution trouvée par un algorithme génétique : ", best_solution)
println("Coût de la meilleure solution : ", best_cost)

println("////////////////////////////////////////////////////////////////////////////////////////////////////////////////////")

#tabou initialisé par la montée de voisinage variable
gap.task_assignation .= best_solution_climb
tabu_search!(gap, 20, 5)
println("Recherche Tabou - Meilleure solution : ", gap.task_assignation, " avec coût : ", cost(gap))

println("////////////////////////////////////////////////////////////////////////////////////////////////////////////////////")

#recuit initialisé par la montée de voisinage variable
gap.task_assignation .= best_solution_climb

mu = 0.95
T0 = 100
iter_max = 1000

recuit(gap, mu, T0, iter_max)
println("Recuit simulé - Meilleure solution : ", gap.task_assignation, " avec coût : ", cost(gap))