include("parser.jl")

# Définition de la structure GAP pour le problème d'affectation généralisé
mutable struct GAP
    r::Matrix{Int}  # Ressources consommées
    c::Matrix{Int}  # Profits associés
    b::Vector{Int}  # Capacités des agents
    m::Int          # Nombre d'agents
    t::Int          # Nombre de tâches
    task_assignation::Vector{Int}  # Assignation des tâches (solution courante)
    is_maximisation::Bool

    # Constructeur personnalisé pour charger les données à partir d'un fichier
    function GAP(filename::String, id::Int, is_maximization::Bool)
        r, c, b, m, t = readfile(filename, id)
        task_assignation = zeros(Int, t)
        new(r, c, b, m, t, task_assignation, is_maximization)
    end
end

# Méthode pour calculer le coût total d'une assignation
function cost(gap::GAP)
    total_cost = 0
    for task in 1:gap.t
        if gap.task_assignation[task] == 0
            println("solution non admissible")
            return 0
        end
        total_cost += gap.c[gap.task_assignation[task], task]
    end
    return total_cost
end


# Méthode pour vérifier si une solution est faisable
function is_feasible(gap::GAP, task_assignation = gap.task_assignation)
    ressources_used = zeros(Int, gap.m)

    for task in 1:gap.t
        worker = task_assignation[task]
        # Vérifie si l'assignation est complète
        if worker < 1 || worker > gap.m
            return false
        end
        ressources_used[worker] += gap.r[worker, task]
    end

    for worker in 1:gap.m
        # Vérifie si l'assignation respecte les contraintes de ressources
        if ressources_used[worker] > gap.b[worker]
            return false
        end
    end

    return true
end

# Heuristique de solution gloutonne
function find_greedy_solution!(gap::GAP)
    Ratio = copy(gap.c) ./ copy(gap.r)
    current_ressources = zeros(gap.m)
    gap.task_assignation .= zeros(Int, gap.t)

    for task in 1:gap.t
        while gap.task_assignation[task] == 0
            indexes = argmax(Ratio[:, task])
            m_index = indexes[1]

            if current_ressources[m_index] + gap.r[m_index, task] <= gap.b[m_index]
                gap.task_assignation[task] = m_index
                current_ressources[m_index] += gap.r[m_index, task]
            else
                Ratio[m_index, task] = 0
            end
        end
    end
end

# Heuristique de solution avec minimisation des ressources (tâche)
function find_least_ressources!(gap::GAP)
    Ratio = copy(gap.r)
    current_ressources = zeros(gap.m)
    gap.task_assignation .= zeros(Int, gap.t)

    for task in 1:gap.t
        max_val = maximum(Ratio)
        worker_visited = 0

        while gap.task_assignation[task] == 0 && worker_visited <= gap.m
            indexes = argmin(Ratio[:, task])
            m_index = indexes[1]

            if current_ressources[m_index] + gap.r[m_index, task] <= gap.b[m_index]
                gap.task_assignation[task] = m_index
                current_ressources[m_index] += gap.r[m_index, task]
            else
                Ratio[m_index, task] = max_val + 1
            end
            worker_visited += 1
        end
    end
end

# Variante : Heuristique de solution avec minimisation des ressources (agent)
function find_least_ressources_bis!(gap::GAP)

    current_ressources = zeros(gap.m)

    r_copy = copy(gap.r)
    end_condition = fill(100, gap.m, gap.t)

    while gap.r != end_condition
        # Booléen pour sortir de la boucle si rien ne se passe
        feasibility = false
        for i in 1:gap.m
            # Si la tâche qui nécessite le moins de ressources satisfait la contrainte
            min = minimum(r_copy[i, :])
            amin = argmin(r_copy[i, :])
            if current_ressources[i] + min <= gap.b[i]
                feasibility = true
                # On assigne la nouvelle tâche à l'agent
                gap.task_assignation[amin] = i
                # On augmente sa charge
                current_ressources[i] += min
                # On ajoute le coût associée
                # On enlève la tâche des tâches à assigner
                r_copy[:, amin] .= 100
            end
        end
        if feasibility == false
            # Pas de solution, on sort de la boucle
            print("Pas de solution.")
            break
        end

    end
    gap.task_assignation .= assignment
end

# Opérations sur les voisinages
function shift_worker(gap::GAP, task_index::Int, new_worker_index::Int)
    temp_task_assignation = copy(gap.task_assignation)
    temp_task_assignation[task_index] = new_worker_index
    return temp_task_assignation
end

function swap_tasks(gap::GAP, first_task_index::Int, second_task_index::Int)
    temp_task_assignation = copy(gap.task_assignation)
    first_worker = temp_task_assignation[first_task_index]
    temp_task_assignation[first_task_index] = temp_task_assignation[second_task_index]
    temp_task_assignation[second_task_index] = first_worker
    return temp_task_assignation
end

# Méthode pour générer les voisins d'une solution actuelle
function generate_neighbours(gap::GAP)
    neighbours = []

    # Parcourir chaque tâche et essayer de l'affecter à un autre agent
    for task in 1:gap.t
        current_worker = gap.task_assignation[task]
        
        # Générer un voisin en déplaçant la tâche vers un autre agent
        for new_worker in 1:gap.m
            if new_worker != current_worker
                neighbour = shift_worker(gap, task, new_worker)
                if is_feasible(gap, neighbour)
                    push!(neighbours, neighbour)
                end
            end
        end
    end

    # Optionnel : ajouter des voisins avec des échanges de tâches
    for task1 in 1:gap.t
        for task2 in task1+1:gap.t
            neighbour = swap_tasks(gap, task1, task2)
            if is_feasible(gap, neighbour)
                push!(neighbours, neighbour)
            end
        end
    end

    return neighbours
end

# Méthode de montée (hill climbing) pour améliorer la solution
function hill_climbing!(gap::GAP)
    # Initialiser avec une solution faisable
    find_greedy_solution!(gap)
    best_solution = copy(gap.task_assignation)
    best_cost = cost(gap)

    # Itération tant qu'il y a des améliorations
    while true
        improved = false
        neighbours = generate_neighbours(gap)

        # Rechercher le meilleur voisin
        for neighbour in neighbours
            gap.task_assignation .= neighbour
            neighbour_cost = cost(gap)
            
            # Si le voisin est meilleur, on l'accepte
            if gap.is_maximisation
                if neighbour_cost > best_cost
                    best_solution = copy(neighbour)
                    best_cost = neighbour_cost
                    improved = true
                end
            else
                if neighbour_cost < best_cost
                    best_solution = copy(neighbour)
                    best_cost = neighbour_cost
                    improved = true
                end
            end
            
        end

        # Si aucune amélioration n'est trouvée, on arrête l'algorithme
        if !improved
            break
        end

        # Mise à jour de la meilleure solution courante
        gap.task_assignation .= best_solution
    end

    # Retourner la meilleure solution trouvée
    return best_solution, best_cost
end

# include("Neighbours.jl")
using Random

#Meta Génétique
# Fonction d'évaluation du coût pour un vecteur d'assignation
function evaluate(gap::GAP, task_assignation::Vector{Int})
    gap.task_assignation .= task_assignation  # Met à jour l'assignation dans gap pour calculer le coût
    return cost(gap)
end

# Fonction pour vérifier la faisabilité d'un vecteur d'assignation
function is_feasible_assignment(gap::GAP, task_assignation::Vector{Int})
    gap.task_assignation .= task_assignation  # Met à jour l'assignation dans gap pour vérifier la faisabilité
    return is_feasible(gap)
end

# Fonction de sélection (tournoi) pour choisir les meilleurs individus
function selection(population, gap::GAP, num_parents::Int)
    sorted_population = sort(population, by=x -> evaluate(gap, x), rev=true)
    return sorted_population[1:num_parents]
end

# Fonction de croisement (crossover) pour combiner deux solutions
function crossover(parent1::Vector{Int}, parent2::Vector{Int})
    crossover_point = rand(1:length(parent1))
    child1 = vcat(parent1[1:crossover_point], parent2[crossover_point+1:end])
    child2 = vcat(parent2[1:crossover_point], parent1[crossover_point+1:end])
    return child1, child2
end

# Fonction de mutation pour introduire des modifications aléatoires
function mutate!(task_assignation::Vector{Int}, gap::GAP, mutation_rate::Float64)
    for task in 1:length(task_assignation)
        if rand() < mutation_rate
            task_assignation[task] = rand(1:gap.m)  # Affecte la tâche à un agent aléatoire
        end
    end
end

# Fonction principale pour l'algorithme génétique
function genetic_algorithm(gap::GAP, population_size::Int, num_generations::Int, mutation_rate::Float64)
    # Initialiser la population avec des solutions gloutonnes faisables
    find_greedy_solution!(gap)
    population = [copy(gap.task_assignation) for _ in 1:population_size]
   
    best_solution = copy(population[1])
    best_cost = evaluate(gap, best_solution)

    for generation in 1:num_generations
        # Sélection des meilleurs individus pour reproduction
        parents = selection(population, gap, population_size ÷ 2)
        new_population = []

        # Appliquer le croisement sur les paires de parents
        for i in 1:2:length(parents)-1
            parent1 = parents[i]
            parent2 = parents[i+1]
            child1, child2 = crossover(parent1, parent2)
            
            # Mutation des enfants
            mutate!(child1, gap, mutation_rate)
            mutate!(child2, gap, mutation_rate)
            
            # Vérifier faisabilité des enfants et ajouter à la nouvelle population
            if is_feasible_assignment(gap, child1)
                push!(new_population, child1)
            end
            if is_feasible_assignment(gap, child2)
                push!(new_population, child2)
            end
        end

        # Remplir la population avec les parents et les enfants
        population = vcat(parents, new_population)

        # Mettre à jour la meilleure solution trouvée
        current_best = selection(population, gap, 1)[1]
        current_best_cost = evaluate(gap, current_best)
        if gap.is_maximisation
            if current_best_cost > best_cost
                best_solution = copy(current_best)
                best_cost = current_best_cost
            end
        else    
            if current_best_cost < best_cost
                best_solution = copy(current_best)
                best_cost = current_best_cost
            end
        end
        

        println("Génération $generation: Meilleur coût = $best_cost")
    end

    return best_solution, best_cost
end



#Méta Tabou
# Méthode simplifiée de recherche tabou
function tabu_search!(gap::GAP, max_iters::Int, tabu_tenure::Int)
    find_greedy_solution!(gap)
    # Initialisation de la meilleure solution et de son coût
    best_solution = copy(gap.task_assignation)
    best_cost = cost(gap)
    current_solution = copy(best_solution)
    
    # Liste tabou pour stocker les solutions entières
    tabu_list = []

    for iter in 1:max_iters
        neighbours = generate_neighbours(gap)
        if gap.is_maximisation
            best_neighbour_cost = -Inf
        else
            best_neighbour_cost = Inf
        end
        
        best_neighbour = copy(current_solution)

        # Parcourir chaque voisin
        for neighbour in neighbours
            # Vérifier si le voisin est dans la liste tabou
            if !(neighbour in tabu_list)
                gap.task_assignation .= neighbour
                neighbour_cost = cost(gap)

                # Si le voisin est meilleur, on l'enregistre
                if gap.is_maximisation
                    if neighbour_cost > best_neighbour_cost
                        best_neighbour_cost = neighbour_cost
                        best_neighbour = copy(neighbour)
                    end
                else 
                    if neighbour_cost < best_neighbour_cost
                        best_neighbour_cost = neighbour_cost
                        best_neighbour = copy(neighbour)
                    end   
                end
                
            end
        end

        # Mise à jour de la solution actuelle avec le meilleur voisin
        current_solution .= best_neighbour

        # Mettre à jour la meilleure solution si le coût s'améliore
        if gap.is_maximisation
            if best_neighbour_cost > best_cost
                best_cost = best_neighbour_cost
                best_solution .= best_neighbour
            end
        else
            if best_neighbour_cost < best_cost
                best_cost = best_neighbour_cost
                best_solution .= best_neighbour
            end
        end
        

        # Ajouter la solution actuelle à la liste tabou
        push!(tabu_list, copy(current_solution))

        # Garder seulement les éléments récents dans la liste tabou
        if length(tabu_list) > tabu_tenure
            popfirst!(tabu_list)  # Retire la solution la plus ancienne
        end

        # Affichage de l'état de chaque itération
        println("Itération $iter: Meilleur coût = $best_cost")
    end

    # Retourner la meilleure solution trouvée
    gap.task_assignation .= best_solution
    return best_solution, best_cost
end





function recuit(gap, mu, T0, iter_max)

    count = 0

    x_max = deepcopy(gap) # Meilleure solution
    x = deepcopy(gap) # Solution courante
    T = T0

    while T > 1
        for iter in 1:iter_max
            i = rand(1:gap.m)
            j = rand(1:gap.m)
            while j == i
                j = rand(1:gap.m)
            end
            x_p = deepcopy(x)
            x_p.task_assignation = swap_tasks(x, i, j)
            if is_feasible(x_p)
                delta = cost(x_p) - cost(x)
                if delta > 0 # Maximisation (< 0 pour une minimisation) -> améliore la solution courante
                    x = deepcopy(x_p)
                    if gap.is_maximisation
                        if cost(x) > cost(x_max) # Améliore la solution optimale
                            print("better")
                            x_max = deepcopy(x)
                        end
                    else
                        if cost(x) < cost(x_max) # Améliore la solution optimale
                            print("better")
                            x_max = deepcopy(x)
                        end 
                    end
                    
                else
                    q = rand()
                    if q <= exp(-delta/T)
                        x = deepcopy(x_p)
                    end
                end
            end
        end
        T = mu * T
        count += 1
        println(T)
    end
    return x_max
end


filename = "Instances/gap5.txt"
id = 1
gap = GAP(filename, id, true)


# calcul d'une solution gloutonne
find_greedy_solution!(gap)
println("Solution gloutonne par tâche: ", gap.task_assignation)
println("Coût solution gloutonne par tâche : ", cost(gap))

println("////////////////////////////////////////////////////////////////////////////////////////////////////////////////////")

# Exécuter l'algorithme de montée
best_solution, best_cost = hill_climbing!(gap)
println("Meilleure solution trouvée avec la montée de voisinage : ", best_solution)
println("Coût de la meilleure solution trouvée avec la montée de voisinage : ", best_cost)

println("////////////////////////////////////////////////////////////////////////////////////////////////////////////////////")

# Calcul d'une solution avec minimisation des ressources
find_least_ressources!(gap)
println("Solution minimisant les ressources : ", gap.task_assignation)
println("Faisabilité : ", is_feasible(gap))
println("Coût total de cette solution : ", cost(gap))

println("////////////////////////////////////////////////////////////////////////////////////////////////////////////////////")

population_size = 20
num_generations = 50
mutation_rate = 0.1

best_solution, best_cost = genetic_algorithm(gap, population_size, num_generations, mutation_rate)
println("Meilleure solution trouvée par un algorithme génétique : ", best_solution)
println("Coût de la meilleure solution : ", best_cost)

println("////////////////////////////////////////////////////////////////////////////////////////////////////////////////////")

# Exécuter la recherche tabou avec la version simplifiée
tabu_search!(gap, 20, 5)
println("Recherche Tabou - Meilleure solution : ", gap.task_assignation, " avec coût : ", cost(gap))

println("////////////////////////////////////////////////////////////////////////////////////////////////////////////////////")
