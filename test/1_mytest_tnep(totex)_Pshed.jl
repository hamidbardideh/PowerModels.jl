using PowerModels
using Pkg
using Gurobi
using Ipopt
using JuMP
using InfrastructureModels
using JSON


file_case5="C:/Users/hbardide/.julia/dev/PowerModels/test/data/matpower/case5_tnep_edited.m"
# pm = PowerModels.instantiate_model(file_case5, DCPPowerModel, PowerModels.build_opf)
# r=ref(pm)
# v=var(pm)

result_case5 = run_tnep_Pshed(file_case5, DCPPowerModel, JuMP.with_optimizer(Gurobi.Optimizer))
