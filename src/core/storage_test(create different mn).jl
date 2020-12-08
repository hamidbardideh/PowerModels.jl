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
using Juniper

file = "/Users/hergun/.julia/dev/PowerModels/test/data/matpower/case5_strg_own.m"

ipopt = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=0)
mosek = JuMP.with_optimizer(Mosek.Optimizer)
scs = JuMP.with_optimizer(SCS.Optimizer)
gurobi = JuMP.with_optimizer(Gurobi.Optimizer, Presolve=0)
juniper = JuMP.with_optimizer(Juniper.Optimizer, nl_solver = ipopt, mip_solver= gurobi, time_limit= 7200)
# cplex = JuMP.with_optimizer(CPLEX.Optimizer)

s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)

load_profile = [0.5 0.45 0.4 0.38 0.42 0.45 0.52 0.6 0.68 0.7 0.65 0.62 0.57 0.54 0.49 0.51 0.67 0.8 0.91 1.0 0.92 0.85 0.8 0.63];
price_profile = [0.6 0.62 0.55 0.52 0.68 0.75 0.86 0.9 0.77 0.55 0.42 0.3 0.25 0.3 0.35 0.51 0.88 0.96 1.1 1.3 1.15 0.9 0.72 0.62];

data = parse_file(file);
mn_data = InfrastructureModels.replicate(data, 24, Set{String}(["source_type", "name", "source_version", "per_unit"]))

for (n,nw) in mn_data["nw"]
    for (g,gen) in nw["gen"]
        gen["cost"][2] = gen["cost"][2] * price_profile[parse(Int64, n)]
    end
    for (l,load) in nw["load"]
        load["pd"] = load["pd"] * load_profile[parse(Int64, n)];
        load["qd"] = load["qd"] * load_profile[parse(Int64, n)];
    end
end


result = run_mn_opf_strg(mn_data, ACPPowerModel, juniper; setting = s)
print("hour",",","E",",","P","\n")
for (n, nw) in result["solution"]["nw"]
    print(n,",", nw["storage"]["2"]["se"],"," ,nw["storage"]["2"]["ps"],"\n")
end
#PowerModels.print_summary(result["solution"])
# data = parse_file(file_oltc)
# result_oltc = run_oltc(file_oltc, ACPPowerModel, ipopt; setting = s)
