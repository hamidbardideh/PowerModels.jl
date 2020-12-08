#### General Assumptions of these TNEP Models ####

""
function run_tnep_gen(file, model_type::Type, optimizer; kwargs...)
    return run_model(file, model_type, optimizer, build_tnep_gen; ref_extensions=[ref_add_on_off_va_bounds!,ref_add_ne_branch!], kwargs...)
end

"the general form of the tnep optimization model"
function build_tnep_gen(pm::AbstractPowerModel)
    variable_branch_ne(pm)
    variable_voltage(pm)
    variable_voltage_ne(pm)
    variable_generation(pm)
    variable_dcline_flow(pm)
    variable_branch_flow(pm)
    variable_branch_flow_ne(pm)

    objective_tnep_gen_cost(pm)

    constraint_model_voltage(pm)
    constraint_model_voltage_ne(pm)

    for i in ids(pm, :ref_buses)
        constraint_theta_ref(pm, i)
    end

    for i in ids(pm, :bus)
        constraint_power_balance_ne(pm, i)
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
end


"Cost of building branches + operational cost of generators"
function objective_tnep_gen_cost(pm::AbstractPowerModel; report::Bool=true)
    gen_cost = Dict()
    dcline_cost = Dict()

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

        from_idx = Dict(arc[1] => arc for arc in nw_ref[:arcs_from_dc])
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

    return display(JuMP.@objective(pm.model, Min,
        sum(
            24*365* sum( gen_cost[(n,i)] for (i,gen) in nw_ref[:gen] ) +
            sum( dcline_cost[(n,i)] for (i,dcline) in nw_ref[:dcline] )
         +

        sum(
            sum( branch["construction_cost"]*var(pm, n, :branch_ne, i) for (i,branch) in nw_ref[:ne_branch] ))

        for (n, nw_ref) in nws(pm))
        ))

end

# "Cost of building branches"
# function objective_tnep_gen_cost(pm::AbstractPowerModel)
#     return JuMP.@objective(pm.model, Min,
#         sum(
#             sum( branch["construction_cost"]*var(pm, n, :branch_ne, i) for (i,branch) in nw_ref[:ne_branch] )
#         for (n, nw_ref) in nws(pm))
#     )
# end

function ref_add_ne_branch!(pm::AbstractPowerModel)
    for (nw, nw_ref) in pm.ref[:nw]
        if !haskey(nw_ref, :ne_branch)
            error(_LOGGER, "required ne_branch data not found")
        end

        nw_ref[:ne_branch] = Dict(x for x in nw_ref[:ne_branch] if (x.second["br_status"] == 1 && x.second["f_bus"] in keys(nw_ref[:bus]) && x.second["t_bus"] in keys(nw_ref[:bus])))

        nw_ref[:ne_arcs_from] = [(i,branch["f_bus"],branch["t_bus"]) for (i,branch) in nw_ref[:ne_branch]]
        nw_ref[:ne_arcs_to]   = [(i,branch["t_bus"],branch["f_bus"]) for (i,branch) in nw_ref[:ne_branch]]
        nw_ref[:ne_arcs] = [nw_ref[:ne_arcs_from]; nw_ref[:ne_arcs_to]]

        ne_bus_arcs = Dict((i, []) for (i,bus) in nw_ref[:bus])
        for (l,i,j) in nw_ref[:ne_arcs]
            push!(ne_bus_arcs[i], (l,i,j))
        end
        nw_ref[:ne_bus_arcs] = ne_bus_arcs

        if !haskey(nw_ref, :ne_buspairs)
            nw_ref[:ne_buspairs] = calc_buspair_parameters(nw_ref[:bus], nw_ref[:ne_branch], conductor_ids(pm, nw), ismulticonductor(pm, nw))
        end
    end
end
