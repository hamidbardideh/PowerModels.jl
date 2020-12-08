#
# export build_mn_opf_flx

"a toy example of how to model with multi-networks and storage"


function run_opf_mn_flx_Pshed_Pstrg(data, model_type::Type, optimizer; kwargs...)
    return run_model(data, model_type, optimizer, build_mn_opf_flx_Pshed_Pstrg; ref_extensions= [ref_add_on_off_va_bounds!,ref_add_ne_branch!,ref_add_ne_storage!], kwargs...)
end



function build_mn_opf_flx_Pshed_Pstrg(pm::AbstractPowerModel)
    for (n, network) in nws(pm)

####################"@ VARIABLES @ ##########################################################################################################################################################################
        variable_voltage(pm, nw=n)              # Magnitude and angle
        variable_generation(pm, nw=n)           # Pg and Qg
        variable_branch_flow(pm, nw=n)          # P and Q
        variable_dcline_flow(pm, nw=n)          # Pdc and Qdc
        variable_branch_ne(pm, nw=n)            # binary decision variable for the line
        variable_branch_flow_ne(pm, nw=n)       # Pne and Qne
        variable_voltage_ne(pm, nw=n)           # new voltage definition when branch_ne is added

# variables added for shedding_gen cost (only DC solution)
        variable_pflex(pm, nw=n)
        variable_pflex_minus(pm, nw=n)
        variable_pflex_plus(pm, nw=n)

# variables added to this problem file to be extended not only DC calculation that neglects active power but also for bringing reacive flexibility
        # variable_qflex(pm, nw=n)
        # variable_qflex_minus(pm, nw=n)
        # variable_qflex_plus(pm, nw=n)
#variables in already existing storages
        variable_strg(pm, nw=n)           # Includes all variables that need to be defined for storages

# other variables for new storage multinetwork problem
        variable_storage_ne(pm, nw=n)           # binary decision variable for storage_ne
        variable_ne_storage_P(pm, nw=n)           # Includes all variables need to be defined for variable_storage_ne
    end


    for (n, network) in nws(pm)
####################"@ CONSTRAINTS @ ###########################################################################
# Power Flow constraints

        for i in ids(pm, :ref_buses, nw=n)      # refrence angle constraint
            constraint_theta_ref(pm, i, nw=n)
        end

        constraint_model_voltage(pm, nw=n)      # all voltage constraints

        for i in ids(pm, :branch, nw=n)         # branch constraints
            constraint_ohms_yt_from(pm, i, nw=n)
            constraint_ohms_yt_to(pm, i, nw=n)
            constraint_voltage_angle_difference(pm, i, nw=n)
            constraint_thermal_limit_from(pm, i, nw=n)
            constraint_thermal_limit_to(pm, i, nw=n)
        end

        for i in ids(pm, :dcline, nw=n)         # dc_branch constraint
            network_ids = sort(collect(nw_ids(pm)))
            constraint_dcline(pm, i, nw=n)
        end


        for i in ids(pm, :bus, nw=n)            # Nodal balance equation (the equations is modifed with respect to tnep_gen_sh.jl , in addition to the flexible load,   1.new storage modify the power balance equation 2. reactive power is added into the equations)
            constraint_power_balance_flx_ne_Pshed_Pstrg(pm, i, nw=n)
        end


# TNEP constraints
            constraint_model_voltage_ne(pm, nw=n) # branch_ne voltage constraints
        #
        for i in ids(pm, :ne_branch, nw=n)        # branch_ne constraints
            constraint_ohms_yt_from_ne(pm, i, nw=n)
            constraint_ohms_yt_to_ne(pm, i, nw=n)
            constraint_voltage_angle_difference_ne(pm, i, nw=n)
            constraint_thermal_limit_from_ne(pm, i, nw=n)
            constraint_thermal_limit_to_ne(pm, i, nw=n)
        end


# flexible load constraints
        for i in ids(pm,:load, nw=n)                # flexible_active_power_flow in load for load shedding ( already created from)
            constraint_flexible_active_Power_floww(pm, i, nw=n)
            constraint_limited_active_Power_flow(pm, i, nw=n)
        end

        # for i in ids(pm,:load, nw=n)                # flexible_reactive_power_flow in load for load shedding ( created in this problem file)
        #     constraint_flexible_reactive_Power_flow(pm ,i, nw=n)
        #     constraint_limited_reactive_Power_flow(pm, i, nw=n)
        # end

# already_exisiting storage constraints
        for i in ids(pm, :storage, nw=n)
            constraint_storage_complementarity_mi(pm, i, nw=n)
                    #constraint_storage_loss(pm, i, nw=n)
                    #constraint_storage_thermal_limit(pm, i, nw=n)
        end

#new storage_ne constraints



         for i in ids(pm, :ne_storage, nw=n)
             constraint_Pstrg_new_chr_dischr_exclusivity(pm, i, nw=n)
             constraint_storage_new_energy_limit(pm, i, nw=n)
             constraint_storage_new_chrg_limit(pm, i, nw=n)
             constraint_storage_new_dischrg_limit(pm, i, nw=n)
             constraint_storage_new_sc_ps_and_sd_pd(pm, i, nw=n)
             same_strg_decision_variable(pm, i; nw=n)
             # constraint_storage_new_investment_status(pm, i, nw=n)
         end
    end

        #
        network_ids = sort(collect(nw_ids(pm)))
        n_1 = network_ids[1]
        display("this is n_1 $n_1")
        for i in ids(pm, :storage, nw=n_1)
            constraint_strg_state(pm, i, nw=n_1)
        end

        for n_2 in network_ids[2:end]
            for i in ids(pm, :storage, nw=n_2)
                constraint_strg_state(pm, i, n_1, n_2)
            end
            n_1 = n_2
        end


        n_1 = network_ids[1]
        for i in ids(pm, :ne_storage, nw=n_1)
            constraint_storage_new_state(pm, i, nw=n_1)
        end
        for n_2 in network_ids[2:end]
            for i in ids(pm, :ne_storage, nw=n_2)
                constraint_storage_new_state(pm, i, n_1, n_2)
            end
        n_1 = n_2
        end


###################"@ OBJECTIVE_FUNCTION @ ####################################################################
        objective_mn_flx(pm)



end

####################################################################################################################################################################################################################################



function objective_mn_flx(pm::AbstractPowerModel; report::Bool=true)
    gen_cost = Dict()
    l_sh_cost= Dict()
# shedding cost is the cost per MW, therefore should be multiplied by base MW
    sh_cost=10000 * 100



    for (n, nw_ref) in nws(pm)
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

        for (i,load) in nw_ref[:load]                                                                               # load shedding cost definition ( operational)
            ls = sum( var(pm, n, :pflex_minus, i)[c] for c in conductor_ids(pm, n) )
            l_sh_cost[(n,i)] = sh_cost * ls

        end

    end

    return JuMP.@objective(pm.model, Min,
        sum(

           sum( branch["construction_cost"]*var(pm, n, :branch_ne, i) for (i,branch) in nw_ref[:ne_branch] )        # branch_ne investment cost
           for (n, nw_ref) in nws(pm)) +


        sum(
           sum( storage["construction_cost"]*var(pm,  n, :storage_ne, i) for (i,storage) in nw_ref[:ne_storage] )
            for (n, nw_ref) in nws(pm)) +

         sum(
            sum(  gen_cost[(n,i)] for (i,gen) in nw_ref[:gen] )
            for (n, nw_ref) in nws(pm)
                ) +
         sum(
            sum( l_sh_cost[(n,i)] for (i,load) in nw_ref[:load])
            for (n, nw_ref) in nws(pm)
            ))
end


function ref_add_ne_storage!(pm::AbstractPowerModel)
    for (nw, nw_ref) in pm.ref[:nw]
        if !haskey(nw_ref, :ne_storage)
            error(_LOGGER, "required ne_storage data not found")
        end

        nw_ref[:ne_storage] = Dict(x for x in nw_ref[:ne_storage] if (x.second["status"] == 1  && x.second["storage_bus"] in keys(nw_ref[:bus])))

        bus_ne_storage = Dict((i, Int[]) for (i,bus) in nw_ref[:bus])
        for (k,strg) in nw_ref[:ne_storage]
            push!(bus_ne_storage[strg["storage_bus"]],  k)
        end
        nw_ref[:bus_ne_storage] = bus_ne_storage
    end
end


# function ref_add_extra_strg!(pm::AbstractPowerModel)
#     for (nw, nw_ref) in pm.ref[:nw]
#         if !haskey(nw_ref, :extra_strg)
#             error(_LOGGER, "required storage_extra info for flexplan project is not found")
#         end
#         nw_ref[:extra_strg] = Dict(x for x in nw_ref[:extra_strg] if (x.second["status"] == 1  && x.second["storage_bus"] in keys(nw_ref[:bus])))
#     end
# end
