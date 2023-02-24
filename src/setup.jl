import YAML

include("exodus.jl")
include("interpolation.jl")
include("model.jl")
include("time.jl")
include("solver.jl")


Exodus = exodus_module()

function setup(input_file::String)
    params = YAML.load_file(input_file)
    sim_type = params["type"]
    if sim_type == "single"
        setup_single(params)
    elseif sim_type == "multi"
        setup_multi(params)
    else
        error("Unknown type of simulation: ", sim_type)
    end
    return params
end

function setup_single(params::Dict{Any,Any})
    input_mesh_file = params["input mesh file"]
    output_mesh_file = params["output mesh file"]
    rm(output_mesh_file, force=true)
    output_mesh = Exodus.copy_mesh(input_mesh_file, output_mesh_file)
    params["output_mesh"] = output_mesh
    input_mesh = Exodus.exodus(input_mesh_file)
    params["input_mesh"] = input_mesh
    model = create_model(params)
    params["model_struct"] = model
    solver = create_solver(params)
    params["solver_struct"] = solver
    time_integrator = create_time_integrator(params)
    params["time_integrator_struct"] = time_integrator
end

function setup_multi(params::Dict{Any,Any})
    domain_files = params["domains"]
    for domain_file ∈ domain_files
        println("domain file: ", domain_file)
        domain_params = setup(domain_file)
        params[domain_file] = domain_params
        domain_params["global_params"] = params
    end
end