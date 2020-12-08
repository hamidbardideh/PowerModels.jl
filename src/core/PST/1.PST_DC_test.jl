using PowerModels
using Ipopt
using Memento
# using CPLEX
using SCS
using Mosek
using MosekTools
using JuMP
using Gurobi  # needs startvalues for all variables!
using InfrastructureModels

file = "C:/Users/hbardide/.julia/dev/PowerModels/test/data/matpower/PST Files/0.case5_base.m"
file_pst = "C:/Users/hbardide/.julia/dev/PowerModels/test/data/matpower/PST Files/0.case5_pst.m"
file_2pst = "C:/Users/hbardide/.julia/dev/PowerModels/test/data/matpower/PST Files/0.case5_2pst.m"
file_2pst_imp = "C:/Users/hbardide/.julia/dev/PowerModels/test/data/matpower/PST Files/0.case5_2pst_imp.m"
include("C:/Users/hbardide/.julia/dev/PowerModels/src/core/PST/1.opst_DC.jl")

ipopt = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=0)
mosek = JuMP.with_optimizer(Mosek.Optimizer)
scs = JuMP.with_optimizer(SCS.Optimizer)
gurobi = JuMP.with_optimizer(Gurobi.Optimizer, Presolve=0)
# cplex = JuMP.with_optimizer(CPLEX.Optimizer)

s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)
result = run_opf(file, DCPPowerModel, gurobi; setting = s)
PowerModels.print_summary(result["solution"])
data = parse_file(file_pst)
result_pst = run_opst_DC(file_pst, DCPPowerModel, ipopt; setting = s)
PowerModels.print_summary(result_pst["solution"])
result_2pst = run_opst_DC(file_2pst, DCMPPowerModel, ipopt; setting = s)
PowerModels.print_summary(result_2pst["solution"])
result_2pst_imp = run_opst_DC(file_2pst_imp, DCPPowerModel, ipopt; setting = s)
PowerModels.print_summary(result_2pst_imp["solution"])

result = run_opf(file, ACPPowerModel, ipopt; setting = s)
