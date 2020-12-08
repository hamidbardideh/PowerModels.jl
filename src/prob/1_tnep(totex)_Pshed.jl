#### General Assumptions of these TNEP Models ####
export run_tnep_Pshed



function run_tnep_Pshed(file, model_type::Type, optimizer; kwargs...)
    return run_model(file, model_type, optimizer, build_tnep_Pshed; ref_extensions=[ref_add_on_off_va_bounds!,ref_add_ne_branch!], kwargs...)
end

"the general form of the tnep optimization model"
function build_tnep_Pshed(pm::AbstractPowerModel)
    variable_branch_ne(pm)
    variable_voltage(pm)
    variable_voltage_ne(pm)
    variable_generation(pm)
    variable_branch_flow(pm)
    variable_dcline_flow(pm)
    variable_branch_flow_ne(pm)
# are added for flexibility
    variable_pflex(pm)
    variable_pflex_minus(pm)
    variable_pflex_plus(pm)
###########################################################

    constraint_model_voltage(pm)
    constraint_model_voltage_ne(pm)

    for i in ids(pm, :ref_buses)
        constraint_theta_ref(pm, i)
    end



    for i in ids(pm, :branch)
        constraint_ohms_yt_from(pm, i)
        constraint_ohms_yt_to(pm, i)

        constraint_voltage_angle_difference(pm, i)

        constraint_thermal_limit_from(pm, i)
        constraint_thermal_limit_to(pm, i)
    end

    for i in ids(pm, :ne_branch)
        constraint_ohms_yt_from_ne(pm, i)
        constraint_ohms_yt_to_ne(pm, i)

        constraint_voltage_angle_difference_ne(pm, i)

        constraint_thermal_limit_from_ne(pm, i)
        constraint_thermal_limit_to_ne(pm, i)
    end

    for i in ids(pm, :dcline)
        constraint_dcline(pm, i)
    end

# the below constraints are built and modified respectively
    for i in ids(pm,:load)
        constraint_flexible_active_Power_flow(pm,i)
    end


    for i in ids(pm, :bus)
        constraint_P_power_balance_ne_ls(pm, i)
    end
#########################################
    #print(pshh)
    #for i in ids(pm, :load)
    #    constraint_flexible_active_Power_flow(pm)
    #end
    objective_tnep_gen_sh_cost(pm)

end



function objective_tnep_gen_sh_cost(pm::AbstractPowerModel; report::Bool=true)
    gen_cost = Dict()
    dcline_cost = Dict()
    l_sh_cost= Dict()
    #sh_cost= price * baseMVA
    sh_cost=10000 * 100
    flex_time_per_year=5*365 # it needs to be in function if you want to use it

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

        for (i,load) in nw_ref[:load]
            ls = sum( var(pm, n, :pflex_minus, i)[c] for c in conductor_ids(pm, n) )
            l_sh_cost[(n,i)] = sh_cost * ls
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

    return JuMP.@objective(pm.model, Min,
        sum(
           #  sum(  gen_cost[(n,i)] for (i,gen) in nw_ref[:gen] ) for (n, nw_ref) in nws(pm)+
           #  sum( dcline_cost[(n,i)] for (i,dcline) in nw_ref[:dcline]) for (n, nw_ref) in nws(pm)+
           # sum( l_sh_cost[(n,i)] for (i,load) in nw_ref[:load]) for (n, nw_ref) in nws(pm)+
           sum( branch["construction_cost"]*var(pm, n, :branch_ne, i) for (i,branch) in nw_ref[:ne_branch] )
           for (n, nw_ref) in nws(pm)) +
        8760*sum(
            sum(  gen_cost[(n,i)] for (i,gen) in nw_ref[:gen] )
            for (n, nw_ref) in nws(pm)
                ) +
        flex_time_per_year*sum(
            sum( l_sh_cost[(n,i)] for (i,load) in nw_ref[:load])
            for (n, nw_ref) in nws(pm)
            ))
end
