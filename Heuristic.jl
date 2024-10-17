include("parser.jl")

function find_greedy_solution(filename)

    r, c, b, m, t = readfile(filename, 0);
    Ratio = r;
    temp = minimum(Ratio)
    current_ressources = zeros(m)
    task_assignation = zeros(t)

    while maximum(Ratio .!= 0.0)
        #Find the maximum Ratio and the task/workers that maximizes it
        max = maximum(Ratio)
        indexes = argmax(Ratio)
        m_index = indexes[1]
        t_index = indexes[2]

        #If the worker can take the task we assign it else we block this task for this worker
        if current_ressources[m_index] + r[m_index, t_index] <= b[m_index]
            current_ressources .+= r[m_index, t_index]
            task_assignation[t_index] = m_index
            Ratio[:, t_index] .= 0
        elseif current_ressources[m_index] + r[m_index, t_index] > b[m_index]
            Ratio[indexes] = 0
        end
        print
        println(Ratio[:, 1])

    end

    return task_assignation;
end

T = find_greedy_solution("Instances/gap1.txt")
print(T)