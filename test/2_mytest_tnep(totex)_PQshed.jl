using Pkg
using PowerModels
import Gurobi
import Juniper
import Ipopt
using JuMP
using InfrastructureModels
using JSON
# import Cbc

# cbc = JuMP.with_optimizer(Cbc.Optimizer, tol=1e-4, print_level=0)

gurobi = JuMP.with_optimizer(Gurobi.Optimizer, TimeLimit = 7200)
ipopt = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-4, print_level=0)
juniper = JuMP.with_optimizer(Juniper.Optimizer, nl_solver = ipopt, mip_solver= gurobi)



file_case5="C:/Users/hbardide/.julia/dev/PowerModels/test/data/matpower/case5_tnep_edited.m"
# pm = PowerModels.instantiate_model(file_case5, DCPPowerModel, PowerModels.build_opf)
# r=ref(pm)
# v=var(pm)

#result_case5 = run_tnep_PQshed(file_case5, DCPPowerModel, JuMP.with_optimizer(Gurobi.Optimizer))
result_case5 = run_tnep_PQshed(file_case5, ACPPowerModel, juniper )
