using Pkg
using Ipopt
using PowerModels
import PowerModels

"to controll OPF time and obj for simple OPF @ Relaxations"
#1. OPF
Matpower_add= "test/copy_case5.m"
Intitial_result_OPF = run_ac_opf("test/copy_case5.m", with_optimizer(Ipopt.Optimizer))
Intitial_result_OPF
Intitial_result_OPF["solve_time"]
Intitial_result_OPF["objective"]


#2. ACPPowerModel(??????? what is the difference with run_ac_opf)
Intitial_result_ACP = run_opf("test/copy_case5.m", ACPPowerModel, Ipopt.Optimizer)
Intitial_result_ACP
Intitial_result_ACP["solve_time"]
Intitial_result_ACP["objective"]

#3. DCPPowerModel
Intitial_result_DC = run_opf("test/copy_case5.m", DCMPPowerModel, Ipopt.Optimizer)
Intitial_result_DC
Intitial_result_DC["solve_time"]
Intitial_result_DC["objective"]

#4. SOCWRPowerModel (why not SOCWRConicPowerModel? Because IPOPT can not solve SOCWRConicPowerModel, it is npt quadratic)
Intitial_result_SOC = run_opf("test/copy_case5.m", SOCWRPowerModel, Ipopt.Optimizer)
Intitial_result_SOC
Intitial_result_SOC["solve_time"]
Intitial_result_SOC["objective"]


data = PowerModels.parse_file(Matpower_add) # all data are in pu

"to convert the results from pu to real unit"
PowerModels.make_mixed_units!(data) #change the data from pu to real values
data
PowerModels.print_summary(data) # mixed units form

"Here instead of Load and Gen with indexes, I replaced them with Bus Numbers"
println("For LOADS")
New_data_Load = Dict{String, Any}()
for (i,k) in data["load"]
    print("\n $i => INDEX VALUES            ")
    Bus_Num=data["load"][i]["load_bus"]
    print(" $Bus_Num => bus number values")
    New_data_Load["$Bus_Num"]=k
end
data["load"]=New_data_Load

#"Gens"
println("For GENS")
New_data_Gen = Dict{String, Any}()
for (i,k) in data["gen"]
    print("\n $i => INDEX VALUES            ")
    Bus_Num=data["gen"][i]["gen_bus"]
    print(" $Bus_Num => bus number values")
    New_data_Gen["$Bus_Num"]=k
end
data["load"]=New_data_Gen

"I know the load busses are 2,3,4 with 300,300,400 respectively and want to change some infos regarding their load"
PL2_Old =New_data_Load["2"]["pd"]
QL2_Old =New_data_Load["2"]["qd"]

PL3_Old =New_data_Load["3"]["pd"]
QL3_Old =New_data_Load["3"]["qd"]

PL4_Old =New_data_Load["4"]["pd"]
QL4 =New_data_Load["4"]["qd"]

"I know the load busses are 1,3,4,10 respectively and want to change some infos regarding their load"
PG1_Old =New_data_Gen["1"]["pg"]
QG1_Old =New_data_Gen["1"]["qg"]

PG3_Old =New_data_Gen["3"]["pg"]
QG3_Old =New_data_Gen["3"]["qg"]

PG4_Old =New_data_Gen["4"]["pg"]
QG4_Old =New_data_Gen["4"]["qg"]

PG4_Old =New_data_Gen["10"]["pg"]
QG4_Old =New_data_Gen["10"]["qg"]


#"Branch Power Flow"
#??????????????????????????????? HOW CAN i WRITE Intitial_result_OPF["solution"]["branch"]["Any"]["PT"]
Intitial_result_OPF["solution"]["branch"]
Intitial_result_OPF["solution"]["branch"]["Any"]["pt"]


"Change the Active Power of The Loads"
New_data_Load["2"]["pd"]=New_data_Load["2"]["pd"] + 1
New_data_Load["3"]["pd"]=New_data_Load["3"]["pd"] + 1
New_data_Load["4"]["pd"]=New_data_Load["4"]["pd"] - 1
data["load"]=New_data_Load


# implement a small load_shedding
##function variable_load_shedding(pm::AbstractPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
#    if bounded
        #PowerModels.var(pm, nw, cnd)[:pd_shed ] = @variable(pm.model,
        #[i in PowerModels.ids(pm, nw, :load)], base_name="$(nw)_$(cnd)_pd_shed",
        #lower_bound = 0,
        #upper_bound = PowerModels.ref(pm, nw, :load, i, "pd", cnd),
        #start = PowerModels.comp_start_value(ref(pm, nw, :load, i), "pd", cnd, 0.0)
        #)
   #end
#end



Final_result = run_ac_opf(data, with_optimizer(Ipopt.Optimizer))
