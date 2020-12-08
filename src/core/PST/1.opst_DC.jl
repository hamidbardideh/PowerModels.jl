function run_opst_DC(file, model_type::Type, optimizer; kwargs...)
    data = PowerModels.parse_file(file)
    process_pst_data!(data)
    return run_model(data, model_type, optimizer, build_opst_DC; ref_extensions = [ref_add_pst!], kwargs...)
end

""
function build_opst_DC(pm::AbstractPowerModel)
    variable_bus_voltage(pm)
    variable_gen_power(pm)
    variable_branch_power(pm)
    variable_dcline_power(pm)
    variable_pst_DC(pm)

    objective_min_fuel_and_flow_cost(pm)

    constraint_model_voltage(pm)

    for i in ids(pm, :ref_buses)
        constraint_theta_ref(pm, i)
    end

    for i in ids(pm, :bus)
        constraint_power_balance_pst_DC(pm, i)
    end

    for i in ids(pm, :branch)
        constraint_ohms_yt_from(pm, i)
        constraint_ohms_yt_to(pm, i)

        constraint_voltage_angle_difference(pm, i)

        constraint_thermal_limit_from(pm, i)
        constraint_thermal_limit_to(pm, i)
    end
    for i in ids(pm, :pst)
        constraint_ohms_y_from_pst_DC(pm, i)
        constraint_ohms_y_to_pst_DC(pm, i)
        constraint_limits_pst_DC(pm, i)
    end

    for i in ids(pm, :dcline)
        constraint_dcline(pm, i)
    end
end

###############################################
# PST variables
function variable_pst_DC(pm; kwargs...)
    variable_active_pst_flow_DC(pm, kwargs...)
    variable_reactive_pst_flow_DC(pm, kwargs...)
    variable_pst_angle(pm, kwargs...)
end

"variable: `p[l,i,j]` for `(l,i,j)` in `arcs`"
function variable_active_pst_flow_DC(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool=true, report::Bool=true)
    p = var(pm, nw)[:ppst] = JuMP.@variable(pm.model,
        [(l,i,j) in ref(pm, nw, :arcs_pst)], base_name="$(nw)_ppst",
        start = 0
    )

    if bounded
        for arc in ref(pm, nw, :arcs_pst)
            l,i,j = arc
                JuMP.set_lower_bound(p[arc], -ref(pm, nw, :pst, l)["rateA"])
                JuMP.set_upper_bound(p[arc], ref(pm, nw, :pst, l)["rateA"])
        end
    end

    report && InfrastructureModels.sol_component_value_edge(pm, nw, :pst, :pf, :pt, ref(pm, nw, :arcs_from_pst), ref(pm, nw, :arcs_to_pst), p)
end



"variable: `q[l,i,j]` for `(l,i,j)` in `arcs`"
function variable_reactive_pst_flow_DC(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool=true, report::Bool=true)
    q = var(pm, nw)[:qpst] = JuMP.@variable(pm.model,
        [(l,i,j) in ref(pm, nw, :arcs_pst)], base_name="$(nw)_qpst",
        start = 0
    )

    if bounded
        for arc in ref(pm, nw, :arcs_pst)
            l,i,j = arc
                JuMP.set_lower_bound(q[arc], -ref(pm, nw, :pst, l)["rateA"])
                JuMP.set_upper_bound(q[arc], ref(pm, nw, :pst, l)["rateA"])
        end
    end

    report && InfrastructureModels.sol_component_value_edge(pm, nw, :pst, :qf, :qt, ref(pm, nw, :arcs_from_pst), ref(pm, nw, :arcs_to_pst), q)
end

"variable: `t[i]` for `i` in `bus`es"
function variable_pst_angle(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool=true, report::Bool=true)
    alpha = var(pm, nw)[:psta] = JuMP.@variable(pm.model,
        [i in ids(pm, nw, :pst)], base_name="$(nw)_psta",
        start = 0
    )
    if bounded
        for (i, pst) in ref(pm, nw, :pst)
            JuMP.set_lower_bound(alpha[i], pst["angmin"])
            JuMP.set_upper_bound(alpha[i], pst["angmax"])
            print(pst["angmin"],"\n")
            print(pst["angmax"],"\n")
        end
    end
    report && InfrastructureModels.sol_component_value(pm, nw, :pst, :alpha, ids(pm, nw, :pst), alpha)
end

###############################################
# Constraint templates
function constraint_ohms_y_from_pst_DC(pm::AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    pst = ref(pm, nw, :pst, i)
    f_bus = pst["fbus"]
    t_bus = pst["tbus"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    g, b = calc_branch_y(pst)
    g_fr = pst["g_fr"]
    b_fr = pst["b_fr"]

    constraint_ohms_y_from_pst_DC(pm, nw, i, f_bus, t_bus, f_idx, t_idx, g, b, g_fr, b_fr)
end





function constraint_ohms_y_to_pst_DC(pm::AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    pst = ref(pm, nw, :pst, i)
    f_bus = pst["fbus"]
    t_bus = pst["tbus"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    g, b = calc_branch_y(pst)
    g_to = pst["g_to"]
    b_to = pst["b_to"]

    constraint_ohms_y_to_pst_DC(pm, nw, i, f_bus, t_bus, f_idx, t_idx, g, b, g_to, b_to)
end

function constraint_power_balance_pst_DC(pm::AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    bus = ref(pm, nw, :bus, i)
    bus_arcs = ref(pm, nw, :bus_arcs, i)
    bus_arcs_pst = ref(pm, nw, :bus_arcs_pst, i)
    bus_arcs_dc = ref(pm, nw, :bus_arcs_dc, i)
    bus_arcs_sw = ref(pm, nw, :bus_arcs_sw, i)
    bus_gens = ref(pm, nw, :bus_gens, i)
    bus_loads = ref(pm, nw, :bus_loads, i)
    # bus_shunts = ref(pm, nw, :bus_shunts, i)
    bus_storage = ref(pm, nw, :bus_storage, i)

    bus_pd = Dict(k => ref(pm, nw, :load, k, "pd") for k in bus_loads)
    # bus_qd = Dict(k => ref(pm, nw, :load, k, "qd") for k in bus_loads)

    # bus_gs = Dict(k => ref(pm, nw, :shunt, k, "gs") for k in bus_shunts)
    # bus_bs = Dict(k => ref(pm, nw, :shunt, k, "bs") for k in bus_shunts)

    constraint_power_balance_pst_DC(pm, nw, i, bus_arcs, bus_arcs_pst, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd)
end

###############################################
# PST Constraints
function constraint_ohms_y_from_pst_DC(pm::AbstractPowerModel, n::Int, i::Int, f_bus, t_bus, f_idx, t_idx, g, b, g_fr, b_fr)
    alpha = var(pm, n,  :psta, i)
    p_fr  = var(pm, n,  :ppst, f_idx)
    q_fr  = var(pm, n,  :qpst, f_idx)
    # vm_fr = var(pm, n, :vm, f_bus)
    # vm_to = var(pm, n, :vm, t_bus)
    va_fr = var(pm, n, :va, f_bus)
    va_to = var(pm, n, :va, t_bus)

    # JuMP.@NLconstraint(pm.model, p_fr ==  (g+g_fr)*(vm_fr)^2 - g*vm_fr*vm_to*cos(va_fr-va_to-alpha) + -b*vm_fr*vm_to*sin(va_fr-va_to-alpha) )
    # JuMP.@NLconstraint(pm.model, q_fr == -(b+b_fr)*(vm_fr)^2 + b*vm_fr*vm_to*cos(va_fr-va_to-alpha) + -g*vm_fr*vm_to*sin(va_fr-va_to-alpha) )


end

function constraint_ohms_y_to_pst_DC(pm::AbstractPowerModel, n::Int, i::Int, f_bus, t_bus, f_idx, t_idx, g, b, g_to, b_to)
    alpha = var(pm, n,  :psta, i)
    p_to  = var(pm, n,  :ppst, t_idx)
    q_to  = var(pm, n,  :qpst    , t_idx)
    # vm_fr = var(pm, n, :vm, f_bus)
    # vm_to = var(pm, n, :vm, t_bus)

    va_fr = var(pm, n, :va, f_bus)
    va_to = var(pm, n, :va, t_bus)

    # JuMP.@NLconstraint(pm.model, p_to ==  (g+g_to)*vm_to^2 - g*vm_to*vm_fr*cos(va_to-va_fr+alpha) + -b*vm_to*vm_fr*sin(va_to-va_fr+alpha) )
    # JuMP.@NLconstraint(pm.model, q_to == -(b+b_to)*vm_to^2 + b*vm_to*vm_fr*cos(va_to-va_fr+alpha) + -g*vm_to*vm_fr*sin(va_to-va_fr+alpha) )
    JuMP.@constraint(pm.model, p_to == -b*(va_to-va_fr+alpha) )
    end

function constraint_limits_pst_DC(pm::AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    pst = ref(pm, nw, :pst, i)
    srated = pst["rateA"]
    angmin = pst["angmin"]
    angmax = pst["angmax"]

    f_bus = pst["fbus"]
    t_bus = pst["tbus"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    alpha = var(pm, nw,  :psta, i)
    p_fr  = var(pm, nw,  :ppst, f_idx)
    q_fr  = var(pm, nw,  :qpst, f_idx)
    p_to  = var(pm, nw,  :ppst, t_idx)
    q_to  = var(pm, nw,  :qpst, t_idx)

    # JuMP.@NLconstraint(pm.model, p_fr^2 + q_fr^2 <= srated^2)
    # JuMP.@NLconstraint(pm.model, p_to^2 + q_to^2 <= srated^2)
    JuMP.@constraint(pm.model, p_fr<= srated)
    JuMP.@constraint(pm.model, -srated <= p_fr)
    JuMP.@constraint(pm.model, p_to <= srated)
    JuMP.@constraint(pm.model, -srated <= p_to)



    JuMP.@constraint(pm.model, alpha <= angmax)
    JuMP.@constraint(pm.model, alpha >= angmin)
end


function constraint_power_balance_pst_DC(pm::AbstractPowerModel, n::Int, i::Int, bus_arcs, bus_arcs_pst, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd)
    # vm   = var(pm, n, :vm, i)
    vm=1
    p    = get(var(pm, n),    :p, Dict()); PowerModels._check_var_keys(p, bus_arcs, "active power", "branch")
    # q    = get(var(pm, n),    :q, Dict()); PowerModels._check_var_keys(q, bus_arcs, "reactive power", "branch")
    ppst    = get(var(pm, n),    :ppst, Dict()); PowerModels._check_var_keys(p, bus_arcs_pst, "active power", "pst")
    # qpst    = get(var(pm, n),    :qpst, Dict()); PowerModels._check_var_keys(q, bus_arcs_pst, "reactive power", "pst")
    pg   = get(var(pm, n),   :pg, Dict()); PowerModels._check_var_keys(pg, bus_gens, "active power", "generator")
    # qg   = get(var(pm, n),   :qg, Dict()); PowerModels._check_var_keys(qg, bus_gens, "reactive power", "generator")
    ps   = get(var(pm, n),   :ps, Dict()); PowerModels._check_var_keys(ps, bus_storage, "active power", "storage")
    # qs   = get(var(pm, n),   :qs, Dict()); PowerModels._check_var_keys(qs, bus_storage, "reactive power", "storage")
    psw  = get(var(pm, n),  :psw, Dict()); PowerModels._check_var_keys(psw, bus_arcs_sw, "active power", "switch")
    # qsw  = get(var(pm, n),  :qsw, Dict()); PowerModels._check_var_keys(qsw, bus_arcs_sw, "reactive power", "switch")
    p_dc = get(var(pm, n), :p_dc, Dict()); PowerModels._check_var_keys(p_dc, bus_arcs_dc, "active power", "dcline")
    # q_dc = get(var(pm, n), :q_dc, Dict()); PowerModels._check_var_keys(q_dc, bus_arcs_dc, "reactive power", "dcline")

    cstr_p = JuMP.@constraint(pm.model,
        sum(p[a] for a in bus_arcs)
        + sum(ppst[a] for a in bus_arcs_pst)
        + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
        + sum(psw[a_sw] for a_sw in bus_arcs_sw)
        ==
        sum(pg[g] for g in bus_gens)
        - sum(ps[s] for s in bus_storage)
        - sum(pd for (i,pd) in bus_pd)
        # - sum(gs for (i,gs) in bus_gs)*vm^2
    )
    # cstr_q = JuMP.@constraint(pm.model,
    #     sum(q[a] for a in bus_arcs)
    #     + sum(qpst[a] for a in bus_arcs_pst)
    #     + sum(q_dc[a_dc] for a_dc in bus_arcs_dc)
    #     + sum(qsw[a_sw] for a_sw in bus_arcs_sw)
    #     ==
    #     sum(qg[g] for g in bus_gens)
    #     - sum(qs[s] for s in bus_storage)
    #     - sum(qd for (i,qd) in bus_qd)
    #     + sum(bs for (i,bs) in bus_bs)*vm^2
    # )

    if InfrastructureModels.report_duals(pm)
        sol(pm, n, :bus, i)[:lam_kcl_r] = cstr_p
        # sol(pm, n, :bus, i)[:lam_kcl_i] = cstr_q
    end
end

###############################################
# ADD REF MODEL
function ref_add_pst!(ref::Dict{Symbol,<:Any}, data::Dict{String,<:Any})
    for (nw, nw_ref) in ref[:nw]
        if !haskey(nw_ref, :pst)
            error(_LOGGER, "required pst data not found")
        end

        nw_ref[:pst] = Dict(x for x in nw_ref[:pst] if (x.second["status"] == 1 && x.second["fbus"] in keys(nw_ref[:bus]) && x.second["tbus"] in keys(nw_ref[:bus])))

        nw_ref[:arcs_from_pst] = [(i,pst["fbus"],pst["tbus"]) for (i,pst) in nw_ref[:pst]]
        nw_ref[:arcs_to_pst]   = [(i,pst["tbus"],pst["fbus"]) for (i,pst) in nw_ref[:pst]]
        nw_ref[:arcs_pst] = [nw_ref[:arcs_from_pst]; nw_ref[:arcs_to_pst]]

        bus_arcs_pst = Dict((i, []) for (i,bus) in nw_ref[:bus])
        for (l,i,j) in nw_ref[:arcs_pst]
            push!(bus_arcs_pst[i], (l,i,j))
        end
        nw_ref[:bus_arcs_pst] = bus_arcs_pst
        # if !haskey(nw_ref, :buspairs_pst)
        #     nw_ref[:buspairs_pst] = calc_buspair_parameters(nw_ref[:bus], nw_ref[:pst], conductor_ids(pm, nw), ismulticonductor(pm, nw))
        # end
    end
end

###############################################
# DATA SCALINNG PST
function process_pst_data!(data)
    if !haskey(data, "multinetwork") || data["multinetwork"] == false
        to_pu_single_network_pst!(data)
        fix_data_single_network_pst!(data)
    else
        to_pu_multi_network_pst!(data)
        fix_data_multi_network_pst!(data)
    end
end

function to_pu_single_network_pst!(data)
    MVAbase = data["baseMVA"]
    for (i, pst) in data["pst"]
        scale_pst_data!(pst, MVAbase)
    end
end

function fix_data_single_network_pst!(data)
    for (i, pst) in data["pst"]
        pst["g_fr"] = 0
        pst["b_fr"] = 0
        pst["g_to"] = 0
        pst["b_to"] = 0
    end
end
function to_pu_multi_network_pst!(data)
    MVAbase = data["baseMVA"]
    for (n, network) in data["nw"]
        MVAbase = network["baseMVA"]
        for (i, pst) in network[n]["pst"]
            scale_pst_data!(pst, MVAbase)
        end
    end
end

function fix_data_multi_network_pst!(data)
    for (n, network) in data["nw"]
        for (i, pst) in network[n]data["pst"]
            pst["g_fr"] = 0
            pst["b_fr"] = 0
            pst["g_to"] = 0
            pst["b_to"] = 0
        end
    end
end

function scale_pst_data!(pst, MVAbase)
    rescale_power = x -> x/MVAbase
    PowerModels._apply_func!(pst, "rateA", rescale_power)
    PowerModels._apply_func!(pst, "rateB", rescale_power)
    PowerModels._apply_func!(pst, "rateC", rescale_power)
    PowerModels._apply_func!(pst, "angle", deg2rad)
    PowerModels._apply_func!(pst, "angmin", deg2rad)
    PowerModels._apply_func!(pst, "angmax", deg2rad)
end
