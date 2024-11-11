include("parser.jl")

# Définition de la structure GAP pour le problème d'affectation généralisé
mutable struct GAP
    r::Matrix{Int}  # Ressources consommées
    c::Matrix{Int}  # Profits associés
    b::Vector{Int}  # Capacités des agents
    m::Int          # Nombre d'agents
    t::Int          # Nombre de tâches
    task_assignation::Vector{Int}  # Assignation des tâches (solution courante)

    # Constructeur personnalisé pour charger les données à partir d'un fichier
    function GAP(filename::String, id::Int)
        r, c, b, m, t = readfile(filename, id)
        task_assignation = zeros(Int, t)
        new(r, c, b, m, t, task_assignation)
    end
end

# Méthode pour calculer le coût total d'une assignation
function cost(gap::GAP)
    total_cost = 0
    for task in 1:gap.t
        total_cost += gap.c[gap.task_assignation[task], task]
    end
    return total_cost
end

# # Méthode pour vérifier si une solution est faisable
# function is_feasible(gap::GAP, task_assignation = gap.task_assignation)
#     ressources_used = zeros(Int, gap.m)

#     for task in 1:gap.t
#         worker = task_assignation[task]
#         # Vérifie si l'assignation est complète
#         if worker < 1 || worker > gap.m
#             return false
#         end
#         ressources_used[worker] += gap.r[worker, task]
#     end

#     for worker in 1:gap.m
#         # Vérifie si l'assignation respecte les contraintes de ressources
#         if ressources_used[worker] > gap.b[worker]
#             return false
#         end
#     end

#     return true
# end

# Méthode pour vérifier si une solution est faisable
function is_feasible(gap::GAP, task_assignation = gap.task_assignation)
    ressources_used = zeros(Int, gap.m)

    for task in 1:gap.t
        worker = task_assignation[task]
        # Vérifie si l'assignation est complète
        if worker < 1 || worker > gap.m
            println("worker :", worker)
            return false
        end
        ressources_used[worker] += gap.r[worker, task]
    end

    for worker in 1:gap.m
        # Vérifie si l'assignation respecte les contraintes de ressources
        if ressources_used[worker] > gap.b[worker]
            println("worker :", worker, "max :", gap.b[worker], "valeur :", ressources_used[worker])
            return false
        end
    end

    return true
end

# Heuristique de solution gloutonne
function find_greedy_solution!(gap::GAP)
    Ratio = gap.c ./ gap.r
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
    Ratio = gap.r
    current_ressources = zeros(gap.m)
    gap.task_assignation .= zeros(Int, gap.t)

    for task in 1:gap.t
        max_val = maximum(Ratio)

        while gap.task_assignation[task] == 0
            indexes = argmin(Ratio[:, task])
            m_index = indexes[1]

            if current_ressources[m_index] + gap.r[m_index, task] <= gap.b[m_index]
                gap.task_assignation[task] = m_index
                current_ressources[m_index] += gap.r[m_index, task]
            else
                Ratio[m_index, task] = 100 #max_val
            end
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
            break
        end

    end
end

# Opérations sur les voisinages
function shift_worker!(gap::GAP, task_index::Int, new_worker_index::Int)
    temp_task_assignation = copy(gap.task_assignation)
    temp_task_assignation[task_index] = new_worker_index
    return temp_task_assignation
end

function swap_tasks!(gap::GAP, first_task_index::Int, second_task_index::Int)
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
                neighbour = shift_worker!(gap, task, new_worker)
                if is_feasible(gap, neighbour)
                    push!(neighbours, neighbour)
                end
            end
        end
    end

    # Optionnel : ajouter des voisins avec des échanges de tâches
    for task1 in 1:gap.t
        for task2 in task1+1:gap.t
            neighbour = swap_tasks!(gap, task1, task2)
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
            if neighbour_cost > best_cost
                best_solution = copy(neighbour)
                best_cost = neighbour_cost
                improved = true
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

function recuit(gap, mu, T0, iter_max)

    count = 0

    x_max = deepcopy(gap)
    x = deepcopy(gap)
    T = T0

    while T > 1
        for iter in 1:iter_max
            i = rand(1:gap.m)
            j = rand(1:gap.m)
            while j == i
                j = rand(1:gap.m)
            end
            x_p = deepcopy(x)
            x_p.task_assignation = swap_tasks!(x, i, j)
            
            if is_feasible(x_p)
                delta = cost(x_p) - cost(x)
                if delta > 0 # Maximisation (< 0 pour une minimisation)
                    println("better")
                    x = deepcopy(x_p)
                    if cost(x) > cost(x_max)
                        print("better")
                        x_max = deepcopy(x)
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

#=
filename = "Instances/gap1.txt"
id = 3
gap = GAP(filename, id)


# Initialiser avec une solution gloutonne
find_greedy_solution!(gap)
println("Solution initiale : ", gap.task_assignation)
println("Coût initial : ", cost(gap))

# Exécuter l'algorithme de montée
best_solution, best_cost = hill_climbing!(gap)
println("Meilleure solution trouvée : ", best_solution)
println("Coût de la meilleure solution : ", best_cost)

# Calcul d'une solution gloutonne
find_greedy_solution!(gap)
println("Solution gloutonne : ", gap.task_assignation)
println("Faisabilité : ", is_feasible(gap))
println("Coût total : ", cost(gap))

# Calcul d'une solution avec minimisation des ressources
find_least_ressources!(gap)
println("Solution minimisant les ressources : ", gap.task_assignation)
println("Faisabilité : ", is_feasible(gap))
println("Coût total : ", cost(gap))
=#