## Smaple code to parse .raw files and run AC & DC power flow and optimal power flow using PowerModels.jl
## Author: Hakan Ergun
## Date: 18.09.2020

using PowerModels
using JuMP
using Ipopt
using JSON

# Read - data (Flexplan vs recent French data)
file = "C:/Users/hbardide/Desktop/KU LEUVEN/Projects/2. FlexPlan/Main Process/Flexplan/WP5/missing French 90-63 kV network/1. Flexplan grid data/Fr.raw"   # path and name of your .raw file

file_json_OHL = "C:/Users/hbardide/Desktop/KU LEUVEN/Projects/2. FlexPlan/Main Process/Flexplan/WP5/missing French 90-63 kV network/2. Recent French grid data/lignes-aeriennes-rte.json" #overheadline
file_json_UGC = "C:/Users/hbardide/Desktop/KU LEUVEN/Projects/2. FlexPlan/Main Process/Flexplan/WP5/missing French 90-63 kV network/2. Recent French grid data/lignes-souterraines-rte.json" #underground cables
file_json_Sub = "C:/Users/hbardide/Desktop/KU LEUVEN/Projects/2. FlexPlan/Main Process/Flexplan/WP5/missing French 90-63 kV network/2. Recent French grid data/enceintes-de-poste-rte.json" #substations


# parsing raw and Jsons
data_raw = PowerModels.parse_file(file)  # parse .raw file


rte_ohl_data = Dict()
open(file_json_OHL,) do f
    global rte_ohl_data
    dicttxt = read(f, String)  # file information to string
    rte_ohl_data = JSON.parse(dicttxt)  # parse and transform data
end


rte_ugc_data = Dict()
open(file_json_UGC,) do f
    global rte_ohl_data
    dicttxt = read(f, String)  # file information to string
    rte_ugc_data = JSON.parse(dicttxt)  # parse and transform data
end


rte_substation_data = Dict()
open(file_json_Sub,) do f
    global rte_substation_data
    dicttxt = read(f, String)  # file information to string
    rte_substation_data = JSON.parse(dicttxt)  # parse and transform data
end



# Main code
# I changed this but github desktop did not recored

#just to check RTE data
rte_ohl_data
first_data=rte_ohl_data[1]
Length=length(rte_ohl_data)
a=Dict()
a[1]=Dict()
#just to check flexplan data
data_raw
data_raw["bus"]["2243"]["name"]


#dictionary list of all OHL 63 kv missing
ohl_list_63kv = Dict()
ohl_list_90kv = Dict()

for i in 1:length(rte_ohl_data)
    ohl = rte_ohl_data[i]["fields"]
    if ohl["tension"] == "63kV"
        ohl_63kv_name = ohl["code_ligne"]
        if !haskey(ohl_list_63kv, ohl_63kv_name)
            ohl_list_63kv[ohl_63kv_name] = Dict()
        end
    end
    if ohl["tension"]=="90kV"
        ohl_90kv_name = ohl["code_ligne"]
        if !haskey(ohl_list_90kv, ohl_90kv_name)
            ohl_list_90kv[ohl_90kv_name] = Dict()
        end
    end
end

##############################################################
ohl_list_63kv
ohl_list_90kv

#from dictionary to array
ohl_63kv = [k for (k,v) in ohl_list_63kv]
ohl_90kv = [k for (k,v) in ohl_list_90kv]


#####PLAY##########
ohl_63kv[1]
first=ohl_63kv[1][1:5]
b=[5,4,3,2,1]
deleteat!(b,1)
b
length(ohl_63kv)

n=5
string(n)
a="efgghhr"
a[1]
###############################################
ohl_63kv_sort=sort(ohl_63kv)

a=ohl_63kv_sort[2]
a[1:5]
ohl_63kv_sort[1]
A = ["1", "2", "3"]
(A, "2")
ohl_63kv_new=[]
length(ohl_63kv_new)

# 1. there are many repetative component, that I removed them 2.one of ABCDE123VWXYZ VWXYZ123ABCDE were removed 3.one of ABCDE123VWXYZ VWXYZ456ABCDE were removed
for i=1:length(ohl_63kv_sort)
    if i==1
        a=ohl_63kv_sort[i]
        a1=a[1:5]
        a2=a[end-4:end]
        result_a=string(a1,a2)
        push!(ohl_63kv_new, result_a)
        display(ohl_63kv_new)
    else
        a=ohl_63kv_sort[i-1]
        b=ohl_63kv_sort[i]

        if (a[1:5]==b[1:5] && a[end-4:end]==b[end-4:end])
            a1=a[1:5]
            a2=a[end-4:end]
            result_ab=string(a1,a2)
            t=0
            for j=1:length(ohl_63kv_new)
                if ohl_63kv_new[j]!=result_ab
                    t=t+1
                    if t==length(ohl_63kv_new)
                        push!(ohl_63kv_new, result_ab)
                    end
                end
            end

        else
            a1=a[1:5]
            a2=a[end-4:end]
            result_a=string(a1,a2)
            b1=b[1:5]
            b2=b[end-4:end]
            result_b=string(b1,b2)

            t=0
            for j=1:length(ohl_63kv_new)
                if ohl_63kv_new[j]!=result_a
                    t=t+1
                    if t==length(ohl_63kv_new)
                        push!(ohl_63kv_new, result_a)
                    end
                end
            end

            u=0
            for j=1:length(ohl_63kv_new)
                if ohl_63kv_new[j]!=result_b
                    u=u+1
                    if u==length(ohl_63kv_new)
                        push!(ohl_63kv_new, result_b)
                    end
                end
            end
        end
    end
end

ohl_63kv_new
#254 elements were removed
###############################################
#count the repetition number of each line's ending,
ohl_63kv_new_con=[]
for i=1:length(ohl_63kv_new)
    a=ohl_63kv_new[i]
    global r=0
    global l=0
    for j=1:length(ohl_63kv_new)
        b=ohl_63kv_new[j]

        if (a[1:5]== b[1:5]      ||   a[1:5]==b[end-4:end] )
            l=l+1
        end

        if (a[end-4:end]== b[end-4:end]      ||   a[end-4:end]==b[1:5]  )
            r=r+1
        end
    end
        reslt=string(l,a)
        result=string(reslt,r)
        push!(ohl_63kv_new_con, result )

    end


ohl_63kv_new_con
if ohl_63kv_new_con[1][1]=='2'
    display("yes")
else
    display("no")
end

# deleteat!(ohl_63kv_new_con,3)
ohl_63kv_new_con[2]
#######################################################
#create a new matrix
a=[4,5,6]
a[2]=7
a
ohl_63kv_final=[]
for i=1:length(ohl_63kv_new_con)
    a=ohl_63kv_new_con[i]

    for j=1:length(ohl_63kv_new_con)
        if j!=i
            b=ohl_63kv_new_con[j]
            if a[1]=='2' && a[1:6]==b[1:6]
                    r1=a[end-6:end-1]
                    r2=b[end-6:end-1]
                    result=string(r1,r2)
                    ohl_63kv_new_con[j]=0
                    # deleteat!(ohl_63kv_new_con, j)
                    ohl_63kv_new_con[i]=result
            elseif a[1]=='2' && a[1:6]==b[end-6:end]
                    r1=a[end-6:end-1]
                    r2=b[2:6]
                    result=string(r1,r2)
                    ohl_63kv_new_con[j]=0
                    # deleteat!(ohl_63kv_new_con, j)
                    ohl_63kv_new_con[i]=result
            elseif a[end]=='2' && a[end-6:end]==b[1:6]
                    r1=a[2:6]
                    r2=b[end-6:end-1]
                    result=string(r1,r2)
                    ohl_63kv_new_con[j]=0
                    # deleteat!(ohl_63kv_new_con, j)
                    ohl_63kv_new_con[i]=result
            elseif  a[end]=='2' && a[end-6:end]==b[end-6:end]
                    r1=a[2:6]
                    r2=b[2:6]
                    result=string(r1,r2)
                    ohl_63kv_new_con[j]=0
                    # deleteat!(ohl_63kv_new_con, j)
                    ohl_63kv_new_con[i]=result
                end

            end

        end
    end













#         if ohl_list_63kv[i][1:5]== ohl_list_63kv[j][1:5] && if ohl_list_63kv[i][end-4:end] != ohl_list_63kv[j][end-4:end]
#             deleteat!(ohl_list_63kv,i)
#             deleteat(ohl_list_63kv,j)
#             keep1=ohl_list_63kv[i][end-4:end]
#             keep2=ohl_list_63kv[j][end-4:end]
#             mix=string(keep1,keep2)
#
#         end
#
#         if ohl_list_63kv[i][1:5]==ohl_list_63kv[j][end-4:end] && if ohl_list_63kv[i][end-4:end] != ohl_list_63kv[j][1:5]
#         end
#
#         if ohl_list_63kv[i][end-4:end]== ohl_list_63kv[j][1:5] && if ohl_list_63kv[i][1:5] != ohl_list_63kv[j][end-4:end]
#         end
#
#         if ohl_list_63kv[i][end-4:end]== ohl_list_63kva[j][end-4:end] && if ohl_list_63kv[i][1:5] != ohl_list_63kv[j][1:5]
#         end
#     end
# end





for i in 1:length(ohl_list_63kv)
    for j in 1:length(ohl_list_63kv)
        ohl_list_63kv[i]

















# line_code_list = Dict()
#
# for i in 1:length(rte_ohl_data)
#     ohl = rte_ohl_data[i]["fields"]
#     if ohl["tension"] == "63kV"
#         ohl_name = ohl["code_ligne"]
#         f_bus_code = ohl_name[1:5]
#         t_bus_code = ohl_name[end-4:end]
#
#         if !haskey(line_code_list, ohl_name)
#             line_code_list[ohl_name] = Dict()
#             for (b, bus) in data_raw["bus"]
#                 #if bus["base_kv"] = 380
#                     raw_name = bus["name"]
#                     if raw_name[1:5] == f_bus_code
#                         print("f_bus = ",f_bus_code, ", bus_no =", b,"\n")
#                     end
#                     if raw_name[1:5] == t_bus_code
#                         print("t_bus = ",t_bus_code, ", bus_no =", b,"\n")
#                     end
#                 #end
#             end
#         end
#     end
# end




# for i in 1:length(rte_substation_data)
#     rte_code = rte_substation_data[i]["fields"]["code_poste"]
#     rte_name = rte_substation_data[i]["fields"]["nom_poste"]
#     if rte_name == "ALBERT"
#         print(rte_name,"\n")
#         print(i,"\n")
#     end
#     # for (b, bus) in data_raw["bus"]
#     #     raw_name = bus["name"]
#     #     if raw_name[1:5] == rte_name
#     #         print(rte_name,"\n")
#     #     end
#     # end
# end

# # Specify solver and PowerModels settings
# ipopt = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=1)
# s = Dict("output" => Dict("branch_flows" => true))

# resultDCOPF = PowerModels.run_opf(data, DCPPowerModel, ipopt; setting = s)
# resultDCPF = PowerModels.run_pf(data, DCPPowerModel, ipopt; setting = s)
# resultACPF = PowerModels.run_pf(data, ACPPowerModel, ipopt; setting = s)
# resultACOPF = PowerModels.run_opf(data, ACPPowerModel, ipopt; setting = s)

# # Write out JSON files
# data_output = JSON.json(data)
# open(file_json, "w") do g
#         write(g, data_output)
# end
