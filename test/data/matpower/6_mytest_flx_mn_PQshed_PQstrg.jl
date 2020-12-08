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



export(run_opf_mn_flex)

#1. first take the single_network_data (including tnep_snep_shedding), and then parse its data to Julia
"1.  matpower file case5_tnep_strg_flexplan.m was completely prepared and ne_storage and new parameters for storage were added"
case_tnep_flx_sn= "./test/data/matpower/case5_tnep_strg_flexplan.m"
network_data = PowerModels.parse_file(case_tnep_flx_sn)
# pm = PowerModels.instantiate_model(network_data, ACPPowerModel, build_mn_opf_strg)    #later when I fix the build I shoud change the build model
# networks=nws(pm)
# re=ref(pm)

#2. change parameter's data based on flexplan project
    #2.1    for pre_exisiting storages
# a=network_data["storage"]
for (i, storage_data) in network_data["storage"]
    storage_data["energy_min"]=            0   *  storage_data["energy_rating"]
    storage_data["energy"]=                1   *  storage_data["energy_rating"]     # full energy of  battery's initial status
    # storage_data["ext_inj_energy"]=        0
    # storage_data["lost_wasted_energy"]=    0
    storage_data["min_charge_rating"]=     0
    storage_data["min_discharge_rating"]=  0
    storage_data["discharge_rating_min"]=  0   *  storage_data["discharge_rating"]
    storage_data["charge_rating_min"]=     0   *  storage_data["charge_rating"]
end

    #2.2    for pre_exisiting storages
# b=network_data["ne_storage"]
for (i, storage_data) in network_data["ne_storage"]
    storage_data["energy_min"]=            0   *  storage_data["energy_rating"]
    storage_data["energy"]=                1   *  storage_data["energy_rating"]    # full energy of  battery's initial status
    storage_data["ext_inj_energy"]=        0
    storage_data["lost_wasted_energy"]=    0
    storage_data["min_charge_rating"]=     0
    storage_data["min_discharge_rating"]=  0
    storage_data["discharge_rating_min"]=  0   *  storage_data["discharge_rating"]
    storage_data["charge_rating_min"]=     0   *  storage_data["charge_rating"]
end




#3. build multi period netwrork data
function build_mn_data_24(base_data; replicates::Int=24)
    mp_data = PowerModels.parse_file(base_data)
    return PowerModels.replicate(mp_data, replicates)
end

case_tnep_flx_mn=build_mn_data_24(case_tnep_flx_sn)


#. Run Multi_period
result_case5 = run_opf_mn_flx(case_tnep_flx_mn, ACPPowerModel, juniper;  multinetwork=true )

# pm = PowerModels.instantiate_model(case_tnep_flx_mn, ACPPowerModel, PowerModels.build_mn_opf_flx; multinetwork=true)
# a=ref(pm)
