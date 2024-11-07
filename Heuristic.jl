include("parser.jl")
include("Neighbours.jl")

function cost(task_assignation, filename, id)
    r, c, b, m, t = readfile(filename, id);
    sum = 0
    for task in 1:t
        sum+=c[task_assignation[task], task]
    end
    return sum
end


function find_greedy_solution(filename, id)

    r, c, b, m, t = readfile(filename, id);
    Ratio = c./r;
    current_ressources = zeros(m)
    task_assignation = zeros(Int64, t)

    for task in 1:t

        while task_assignation[task] == 0
            #Find the maximum Ratio for this task (max over a column in Ratio)
            indexes = argmax(Ratio[:, task])
            m_index = indexes[1]
            t_index = task

            #If the max is on a worker that can take the task we assign it
            if current_ressources[m_index] + r[m_index, t_index] <= b[m_index]
                task_assignation[task] = m_index
                current_ressources[m_index] += r[m_index, t_index]
            else
                Ratio[m_index, task] = 0
            end
        end

    end

    return task_assignation;
end

function find_least_ressources(filename, id)

    r, c, b, m, t = readfile(filename, id);
    Ratio = r;
    current_ressources = zeros(m)
    task_assignation = zeros(Int64, t)

    for task in 1:t
        
        max = maximum(Ratio)

        while task_assignation[task] == 0
            #Find the maximum Ratio for this task (max over a column in Ratio)
            indexes = argmin(Ratio[:, task])
            m_index = indexes[1]
            t_index = task

            #If the max is on a worker that can take the task we assign it
            if current_ressources[m_index] + r[m_index, t_index] <= b[m_index]
                task_assignation[task] = m_index
                current_ressources[m_index] += r[m_index, t_index]
            else
                Ratio[m_index, task] = max
            end
        end

    end

    return task_assignation;
end

id = 1
filename = "Instances/gap1.txt"

T = find_least_ressources(filename, id)
println(T)
println(is_feasible(T, filename, id))
println(cost(T, filename, id))
#println(cost(T, filename, id))

T = find_greedy_solution(filename, id)
println(T)
println(is_feasible(T, filename, id))
println(cost(T, filename, id))
#println(cost(T, filename, id))