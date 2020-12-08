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


file = "C:/Users/hbardide/.julia/dev/PowerModels/test/data/matpower/PST Files/1.case5_base_NE.m"
file_pst = "C:/Users/hbardide/.julia/dev/PowerModels/test/data/matpower/PST Files/1.case5_pst_NE.m"
file_2pst = "C:/Users/hbardide/.julia/dev/PowerModels/test/data/matpower/PST Files/1.case5_2pst_NE.m"
file_2pst_imp = "C:/Users/hbardide/.julia/dev/PowerModels/test/data/matpower/PST Files/1.case5_2pst_NE_imp.m"

include("C:/Users/hbardide/.julia/dev/PowerModels/src/core/PST/1.opst_DC.jl")
include("C:/Users/hbardide/.julia/dev/PowerModels/src/core/PST/2.opst_DC_investment.jl")

ipopt = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=0)
mosek = JuMP.with_optimizer(Mosek.Optimizer)
scs = JuMP.with_optimizer(SCS.Optimizer)
gurobi = JuMP.with_optimizer(Gurobi.Optimizer, Presolve=0)
# cplex = JuMP.with_optimizer(CPLEX.Optimizer)

s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)
result = run_opf(file, ACPPowerModel, ipopt; setting = s)
result_DC = run_opf(file, DCPPowerModel, gurobi; setting = s)
PowerModels.print_summary(result["solution"])

result_pst = run_opf(file_pst, DCPPowerModel, gurobi; setting = s)
result_DCOPF_pst = run_opst_DC(file_pst, DCPPowerModel, gurobi; setting = s)
result_DCOPF_pst_inv = run_opst_DC_investment(file_pst, DCPPowerModel, gurobi; setting = s)
PowerModels.print_summary(result_DCOPF_pst_inv["solution"])


result_DCOPF_2pst = run_opf(file_2pst, DCPPowerModel, gurobi; setting = s)
result_DCOPF_2pst_inv = run_opst_DC(file_2pst, DCMPPowerModel, gurobi; setting = s)
result_DCOPF_2pst_inv = run_opst_DC_investment(file_2pst, DCMPPowerModel, gurobi; setting = s)
PowerModels.print_summary(result_DCOPF_2pst_inv["solution"])

result_DCOPF_2ps_imp = run_opf(file_2pst, DCPPowerModel, gurobi; setting = s)
result_DCOPF_2pst_imp_inv = run_opst_DC_investment(file_2pst_imp, DCPPowerModel, gurobi; setting = s)
PowerModels.print_summary(result_DCOPF_2pst_imp_inv["solution"])
