
using PowerModels,InfrastructureModels,JSON,JuMP,Juno


function build_mn_data_24(base_data; replicates::Int=24)
    mp_data = PowerModels.parse_file(base_data)
    return PowerModels.replicate(mp_data, replicates)
end
file="./test/data/matpower/case3_tnep.m"

case3_tnep_mn=build_mn_data_24(file)
