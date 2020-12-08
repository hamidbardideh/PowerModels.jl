using JuMP
using PowerModels
using JSON

case5_tnep= "./test/data/matpower/case5_tnep.m"
network_data = PowerModels.parse_file(case5_tnep)
pm = PowerModels.instantiate_model(network_data, ACPPowerModel, PowerModels.build_opf)
networks=nws(pm)


a=ref(pm)[:bus][4]
for (n,nw_ref) in nws(pm)
    print(n,nw_ref)
end
b=ref(pm, :bus_gens)
c=get(var(pm) ,:vm, 3)
de=ref(pm)
q_load= ref(pm, :load, 1 )
display(var(pm))
a=var(pm)
b=var(pm)[:p][(4,4,5)]
bb=var(pm, :p),(4,4,5)
c=ref(pm)
#cc=nw_ref(pm)
d=var(pm)[:q]
pg   = get(var(pm),   :pg, Dict())
bus_pd = Dict(k => ref(pm,:load, k, "pd") for k in bus_loads)

I1 = [x[1] for x in A]
# nws is a dictionary which its keyword is network num and we give all the info to new_ref

L_sh=0.2
m=nws(pm)
for (n, nw_ref) in nws(pm)
    for (i,load_data) in nw_ref[:load]

        0<L_sh<load_data["pd"]
        println(load_data["pd"])
        load_data["pd"]=load_data["pd"]-L_sh
        println(load_data["pd"])

        #0<= a <=load["pd"]
        #load["pd"]=load["pd"]-variable_load_shedding(pm)
    end
end



d=pm.ref[:nw][0][:load]












display(ref(pm))
a=ids(pm,:load)

display(var(pm))
p = get(var(pm), :p , 3 )


keys(p, bus_arcs, "active power", "branch")
#why nws not defined? why it does not know ref
#nws(pm::AbstractPowerModel) = pm.ref[:nw]
#a=PowerModels.nws()
#println(a)
display(nws(pm))
gen_cost = Dict()
dcline_cost = Dict()

for (n, nw_ref) in nws(pm)
    # display(nw_ref)
    # display(nw_ref[:gen][1]["cost"])
    for (i,gen) in nw_ref[:gen]
        pg = sum( var(pm, n, :pg, i)[c] for c in conductor_ids(pm, n) )

        if length(gen["cost"]) == 1
            gen_cost[(n,i)] = gen["cost"][1]
        elseif length(gen["cost"]) == 2
            gen_cost[(n,i)] = gen["cost"][1]*pg + gen["cost"][2]
        elseif length(gen["cost"]) == 3
            gen_cost[(n,i)] = gen["cost"][1]*pg^2 + gen["cost"][2]*pg + gen["cost"][3]
        else
            gen_cost[(n,i)] = 0.0
        end
    end

    from_idx = Dict(arc[1] => arc for arc in nw_ref[:arcs_from_dc])
    for (i,dcline) in nw_ref[:dcline]
        p_dc = sum( var(pm, n, :p_dc, from_idx[i])[c] for c in conductor_ids(pm, n) )

        if length(dcline["cost"]) == 1
            dcline_cost[(n,i)] = dcline["cost"][1]
        elseif length(dcline["cost"]) == 2
            dcline_cost[(n,i)] = dcline["cost"][1]*p_dc + dcline["cost"][2]
        elseif length(dcline["cost"]) == 3
            dcline_cost[(n,i)] = dcline["cost"][1]*p_dc^2 + dcline["cost"][2]*p_dc + dcline["cost"][3]
        else
            dcline_cost[(n,i)] = 0.0
        end
    end
end
