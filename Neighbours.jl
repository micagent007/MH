function is_feasible(task_assignation, filename, id)
    r, c, b, m, t = readfile(filename, id);

    ressources_used = zeros(Int, m)

    for task in 1:t
        worker = task_assignation[task]
        if worker < 1 || worker > m
            return false
        end
        ressources_used[worker] += r[worker, task]
    end

    for worker in 1:m
        if ressources_used[worker] > b[worker]
            return false
        end
    end

    return true
end

function shift_workers(task_assignation, task_index, new_worker_index)
    temp_task = copy(task_assignation)
    temp_task[task_index] = new_worker_index
    return temp_task
end

function swap_tasks(task_assignation, first_task_index, second_task_index)
    temp_task = copy(task_assignation)
    first_worker = temp_task[first_task_index]
    temp_task[first_task_index] = temp_task[second_task_index]
    temp_task[second_task_index] = first_worker
    return temp_task
end

function Neighbours_search()
    
end