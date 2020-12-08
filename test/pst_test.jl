using Pkg
using PowerModelsACDC
using PowerModels
using Ipopt
using Memento
using InfrastructureModels
# using CPLEX
using SCS
using Mosek
using MosekTools
using JuMP
using Gurobi  # needs startvalues for all variables!
using InfrastructureModels

export(run_opst)
include("C:/Users/hbardide/.julia/dev/PowerModels/src/core/opst.jl")

file = "./test/data/matpower/PST Files/case5_base.m"
file_pst = "./test/data/matpower/PST Files/case5_pst.m"
file_2pst = "./test/data/matpower/PST Files/case5_2pst.m"
file_2pst_imp = "./test/data/matpower/PST Files/case5_2pst_imp.m"
include("C:/Users/hbardide/.julia/dev/PowerModels/src/core/0.opst.jl")


ipopt = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=0)
mosek = JuMP.with_optimizer(Mosek.Optimizer)
scs = JuMP.with_optimizer(SCS.Optimizer)
gurobi = JuMP.with_optimizer(Gurobi.Optimizer, Presolve=0)
# cplex = JuMP.with_optimizer(CPLEX.Optimizer)

s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)
result = run_opf(file, ACPPowerModel, ipopt; setting = s)
print_summary(result["solution"])
data = parse_file(file_pst)
result_pst = run_opst(file_pst, ACPPowerModel, ipopt; setting = s)
print_summary(result_pst["solution"])
result_2pst = run_opst(file_2pst, ACPPowerModel, ipopt; setting = s)
print_summary(result_2pst["solution"])
result_2pst_imp = run_opst(file_2pst_imp, ACPPowerModel, ipopt; setting = s)
print_summary(result_2pst_imp["solution"])
