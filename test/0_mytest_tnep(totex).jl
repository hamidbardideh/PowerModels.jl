using PowerModels
using Gurobi
using Ipopt
using JuMP
using InfrastructureModels
using JSON

# include("C:/Users/hbardide/.julia/dev/PowerModels/src/prob/tnep_gen.jl");
file_case5="C:/Users/hbardide/.julia/dev/PowerModels/test/data/matpower/case5_tnep_edited.m"
# pm = instantiate_model(file_case5, DCPPowerModel, PowerModels.build_opf)
# r=ref(pm)
# var(pm)

result_case5 = run_tnep_gen(file_case5, DCPPowerModel, JuMP.with_optimizer(Gurobi.Optimizer))

pm = PowerModels.instantiate_model(file_case5, DCPPowerModel, PowerModels.build_opf)

a=ref(pm)

ref
