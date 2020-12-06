using Pkg
using PowerModels
using Gurobi
using Ipopt
using JuMP
using InfrastructureModels
using JSON
include("../src/prob/tnep.jl")

# file_case3="C:/Users/hbardide/.julia/dev/PowerModels/test/data/matpower/case3_tnep.m"
# result_case3 = run_tnep(file_case3, DCPPowerModel, JuMP.with_optimizer(Gurobi.Optimizer))
file_case5="C:/Users/hbardide/.julia/dev/PowerModels/test/data/matpower/case5_tnep_edited.m"

# pm = PowerModels.instantiate_model(file_case5, DCPPowerModel, PowerModels.build_opf)
# a=var(pm)
# c=ref(pm)

result_case5 = PowerModels.run_tnep(file_case5, DCPPowerModel, JuMP.with_optimizer(Gurobi.Optimizer))
