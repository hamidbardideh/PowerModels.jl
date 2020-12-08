using Pkg
using PowerModels
using Gurobi
using Ipopt
using JuMP
using InfrastructureModels
using JSON



case_storage_sn= "./test/data/matpower/case5_strg.m"

function build_mn_data_24(base_data; replicates::Int=24)
    mp_data = PowerModels.parse_file(base_data)
    return PowerModels.replicate(mp_data, replicates)
end

case_storage_mn=build_mn_data_24(case_storage_sn)

function run_opf_mn_strg(file, model_type::Type, optimizer; kwargs...)
    return run_model(file, model_type, optimizer,  build_mn_Strg; ref_extensions=[ref_add_on_off_va_bounds!], multinetwork=true, kwargs...)
end


result_case5 = run_opf_mn_strg(case_storage_mn, DCPPowerModel, JuMP.with_optimizer(Gurobi.Optimizer); multinetwork=true)
