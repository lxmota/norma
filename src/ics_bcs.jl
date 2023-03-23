@variables t, x, y, z
D = Differential(t)

function SMDirichletBC(input_mesh::PyObject, bc_params::Dict{Any,Any})
    node_set_name = bc_params["node set"]
    expression = bc_params["function"]
    offset = component_offset_from_string(bc_params["component"])
    node_set_id = node_set_id_from_name(node_set_name, input_mesh)
    node_set_node_indices = input_mesh.get_node_set_nodes(node_set_id)
    # expression is an arbitrary function of t, x, y, z in the input file
    disp_num = eval(Meta.parse(expression))
    velo_num = expand_derivatives(D(disp_num))
    acce_num = expand_derivatives(D(velo_num))
    SMDirichletBC(node_set_name, offset, node_set_id, node_set_node_indices,
        disp_num, velo_num, acce_num)
end

function SMNeumannBC(input_mesh::PyObject, bc_params::Dict{Any,Any})
    side_set_name = bc_params["side set"]
    expression = bc_params["function"]
    offset = component_offset_from_string(bc_params["component"])
    side_set_id = side_set_id_from_name(side_set_name, input_mesh)
    num_nodes_per_side, side_set_node_indices = input_mesh.get_side_set_node_list(side_set_id)
    # expression is an arbitrary function of t, x, y, z in the input file
    traction_num = eval(Meta.parse(expression))
    SMNeumannBC(side_set_name, offset, side_set_id, num_nodes_per_side, side_set_node_indices, traction_num)
end

function SMSchwarzContactBC(coupled_subsim::SingleDomainSimulation, input_mesh::PyObject, bc_params::Dict{Any,Any})
    side_set_name = bc_params["side set"]
    offset = component_offset_from_string(bc_params["component"])
    side_set_id = side_set_id_from_name(side_set_name, input_mesh)
    num_nodes_per_side, side_set_node_indices = input_mesh.get_side_set_node_list(side_set_id)
    coupled_block_name = bc_params["source block"]
    coupled_mesh = coupled_subsim.params["input_mesh"]
    coupled_block_id = block_id_from_name(coupled_block_name, coupled_mesh)
    coupled_side_set_name = bc_params["source side set"]
    coupled_side_set_id = side_set_id_from_name(coupled_side_set_name, coupled_mesh)
    is_dirichlet = true
    SMSchwarzContactBC(side_set_name, offset, side_set_id, num_nodes_per_side, 
        side_set_node_indices, coupled_subsim, coupled_block_id, coupled_side_set_id, is_dirichlet)
end

function apply_bc(model::SolidMechanics, bc::SMDirichletBC)
    for node_index ∈ bc.node_set_node_indices
        values = Dict(t=>model.time, x=>model.reference[1, node_index], y=>model.reference[2, node_index], z=>model.reference[3, node_index])
        disp_sym = substitute(bc.disp_num, values)
        velo_sym = substitute(bc.velo_num, values)
        acce_sym = substitute(bc.acce_num, values)
        disp_val = extract_value(disp_sym)
        velo_val = extract_value(velo_sym)
        acce_val = extract_value(acce_sym)
        dof_index = 3 * (node_index - 1) + bc.offset
        model.current[bc.offset, node_index] = model.reference[bc.offset, node_index] + disp_val
        model.velocity[bc.offset, node_index] = velo_val
        model.acceleration[bc.offset, node_index] = acce_val
        model.free_dofs[dof_index] = false
    end
end

function apply_bc(model::SolidMechanics, bc::SMNeumannBC)
    ss_node_index = 1
    for side ∈ bc.num_nodes_per_side
        side_nodes = bc.side_set_node_indices[ss_node_index:ss_node_index+side-1]
        side_coordinates = model.reference[:, side_nodes]
        nodal_force_component = get_side_set_nodal_forces(side_coordinates, bc.traction_num, model.time)
        ss_node_index += side
        side_node_index = 1
        for node_index ∈ side_nodes
            bc_val = nodal_force_component[side_node_index]
            side_node_index += 1
            dof_index = 3 * (node_index - 1) + bc.offset
            model.boundary_tractions_force[dof_index] += bc_val
        end
    end
end

function apply_bc(model::SolidMechanics, bc::SMSchwarzContactBC)
    if bc.is_dirichlet == true
        apply_sm_schwarz_contact_dirichlet(model, bc)
    else
        apply_sm_schwarz_contact_neumann(model, bc)
    end
end

function apply_sm_schwarz_contact_dirichlet(model::SolidMechanics, bc::SMSchwarzContactBC)
    ss_node_index = 1
    for side ∈ num_nodes_per_side
        side_nodes = bc.side_set_node_indices[ss_node_index:ss_node_index+side-1]
        ss_node_index += side
        for node_index ∈ side_nodes
            point = model.current[:, node_index]
            point_new, coupled_node_indices = find_and_project(point, bc.coupled_mesh, bc.coupled_block_id, bc.coupled_side_set_id, model)
            model.current[:, node_index] = point_new
            element_type = get_element_type(3, length(coupled_node_indices))
            coupled_vertices = bc.coupled_subsim.model.current[:, coupled_node_indices]
            ξ = map_to_parametric(element_type, coupled_vertices, point_new)
            N, _ = interpolate(element_type, ξ)
            model.velocity[:, node_index] = bc.coupled_subsim.model.velocity[:, coupled_vertices] * N
            model.acceleration[:, node_index] = bc.coupled_subsim.model.acceleration[:, coupled_vertices] * N
        end
    end  
end

function apply_sm_schwarz_contact_neumann(model::SolidMechanics, bc::SMSchwarzContactBC)
    ss_node_index = 1
    for side ∈ num_nodes_per_side
        side_nodes = bc.side_set_node_indices[ss_node_index:ss_node_index+side-1]
        ss_node_index += side
        side_node_index = 1
        for node_index ∈ side_nodes
            #get nodal forces
            side_node_index += 1
        end
    end  
end

function node_set_id_from_name(node_set_name::String, mesh::PyObject)
    node_set_names = mesh.get_node_set_names()
    num_names = length(node_set_names)
    node_set_index = 0
    for index ∈ 1:num_names
        if (node_set_name == node_set_names[index])
            node_set_index = index
            break
        end
    end
    if (node_set_index == 0)
        error("node set ", node_set_name, " cannot be found in mesh")
    end
    node_set_ids = mesh.get_node_set_ids()
    node_set_id = node_set_ids[node_set_index]
    return node_set_id
end

function side_set_id_from_name(side_set_name::String, mesh::PyObject)
    side_set_names = mesh.get_side_set_names()
    num_names = length(side_set_names)
    side_set_index = 0
    for index ∈ 1:num_names
        if (side_set_name == side_set_names[index])
            side_set_index = index
            break
        end
    end
    if (side_set_index == 0)
        error("side set ", side_set_name, " cannot be found in mesh")
    end
    side_set_ids = mesh.get_side_set_ids()
    side_set_id = side_set_ids[side_set_index]
    return side_set_id
end

function block_id_from_name(block_name::String, mesh::PyObject)
    block_names = mesh.get_elem_blk_names()
    num_names = length(block_names)
    block_index = 0
    for index ∈ 1:num_names
        if (block_name == block_names[index])
            block_index = index
            break
        end
    end
    if (block_index == 0)
        error("block ", block_name, " cannot be found in mesh")
    end
    block_ids = mesh.get_elem_blk_ids()
    block_id = block_ids[block_index]
    return block_id
end

function component_offset_from_string(name::String)
    offset = 0
    if name == "x"
        offset = 1
    elseif name == "y"
        offset = 2
    elseif name == "z"
        offset = 3
    else
        error("invalid component name ", name)
    end
    return offset
end

function extract_value(value::Real)
    return value
end

function extract_value(symbol::Num)
    return symbol.val
end

function create_bcs(params::Dict{Any,Any})
    boundary_conditions = Vector{BoundaryCondition}()
    if haskey(params, "boundary conditions") == false
        return boundary_conditions
    end
    input_mesh = params["input_mesh"]
    bc_params = params["boundary conditions"]
    for (bc_type, bc_type_params) ∈ bc_params
        for bc_setting_params ∈ bc_type_params
            if bc_type == "Dirichlet"
                boundary_condition = SMDirichletBC(input_mesh, bc_setting_params)
                push!(boundary_conditions, boundary_condition)
            elseif bc_type == "Neumann"
                boundary_condition = SMNeumannBC(input_mesh, bc_setting_params)
                push!(boundary_conditions, boundary_condition)
            elseif bc_type == "Schwarz contact"
                coupled_subsim_name = bc_setting_params["source"]
                sim = params["global_simulation"]
                coupled_subdomain_index = sim.subsim_name_index_map[coupled_cubsim_name]
                coupled_subsim = sim.subsims[coupled_subdomain_index]
                boundary_condition = SMSchwarzContactBC(coupled_subsim, input_mesh, bc_setting_params)
                push!(boundary_conditions, boundary_condition)                
            elseif bc_type == "Schwarz Dirichlet"
            elseif bc_type == "Schwarz Neumann"
            else
                error("Unknown boundary condition type : ", bc_type)
            end
        end
    end
    return boundary_conditions
end

function apply_bcs(model::SolidMechanics)
    _, num_nodes = size(model.reference)
    model.boundary_tractions_force = zeros(3*num_nodes)
    model.free_dofs = trues(3 * num_nodes)
    for boundary_condition ∈ model.boundary_conditions
        apply_bc(model, boundary_condition)
    end
end

function apply_ics(params::Dict{Any,Any}, model::SolidMechanics)
    if haskey(params, "initial conditions") == false
        return
    end
    input_mesh = params["input_mesh"]
    ic_params = params["initial conditions"]
    for (ic_type, ic_type_params) ∈ ic_params
        for ic ∈ ic_type_params
            node_set_name = ic["node set"]
            expr_str = ic["function"]
            component = ic["component"]
            offset = component_offset_from_string(component)
            node_set_id = node_set_id_from_name(node_set_name, input_mesh)
            node_set_node_indices = input_mesh.get_node_set_nodes(node_set_id)
            # expr_str is an arbitrary function of x, y, z in the input file
            ic_expr = Meta.parse(expr_str)
            ic_eval = eval(ic_expr)
            for node_index ∈ node_set_node_indices
                values = Dict(x=>model.reference[1, node_index], y=>model.reference[2, node_index], z=>model.reference[3, node_index])
                ic_sym = substitute(ic_eval, values)
                ic_val = extract_value(ic_sym)
                if ic_type == "displacement"
                    model.current[offset, node_index] = model.reference[offset, node_index] + ic_val
                elseif ic_type == "velocity"
                    model.velocity[offset, node_index] = ic_val
                end
            end
        end
    end
end