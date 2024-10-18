include("parser.jl")

function find_greedy_solution(filename)

    r, c, b, m, t = readfile(filename, 0);
    Ratio = c./r;
    current_ressources = zeros(m)
    task_assignation = zeros(t)

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

T = find_greedy_solution("Instances/gap1.txt")
print(T)