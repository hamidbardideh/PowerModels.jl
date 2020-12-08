function run_oltc(file, model_type::Type, optimizer; kwargs...)
    data = PowerModels.parse_file(file)
    process_oltc_data!(data)
    return run_model(data, model_type, optimizer, build_oltc; ref_extensions = [ref_add_oltc!], kwargs...)
end

""
function build_oltc(pm::AbstractPowerModel)
    variable_voltage(pm)
    variable_generation(pm)
    variable_branch_flow(pm)
    variable_dcline_flow(pm)
    variable_oltc(pm)

    objective_min_fuel_and_flow_cost(pm)

    constraint_model_voltage(pm)

    for i in ids(pm, :ref_buses)
        constraint_theta_ref(pm, i)
    end

    for i in ids(pm, :bus)
        constraint_power_balance_oltc(pm, i)
    end

    for i in ids(pm, :branch)
        constraint_ohms_yt_from(pm, i)
        constraint_ohms_yt_to(pm, i)

        constraint_voltage_angle_difference(pm, i)

        constraint_thermal_limit_from(pm, i)
        constraint_thermal_limit_to(pm, i)
    end
    for i in ids(pm, :oltc)
        constraint_ohms_y_from_oltc(pm, i)
        constraint_ohms_y_to_oltc(pm, i)
        constraint_limits_oltc(pm, i)
    end

    for i in ids(pm, :dcline)
        constraint_dcline(pm, i)
    end
end

###############################################
# PST variables
function variable_oltc(pm; kwargs...)
    variable_active_oltc_flow(pm, kwargs...)
    variable_reactive_oltc_flow(pm, kwargs...)
    variable_oltc_tap(pm, kwargs...)
end

"variable: `p[l,i,j]` for `(l,i,j)` in `arcs`"
function variable_active_oltc_flow(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool=true, report::Bool=true)
    p = var(pm, nw)[:poltc] = JuMP.@variable(pm.model,
        [(l,i,j) in ref(pm, nw, :arcs_oltc)], base_name="$(nw)_poltc",
        start = 0
    )

    if bounded
        for arc in ref(pm, nw, :arcs_oltc)
            l,i,j = arc
                JuMP.set_lower_bound(p[arc], -ref(pm, nw, :oltc, l)["rateA"])
                JuMP.set_upper_bound(p[arc], ref(pm, nw, :oltc, l)["rateA"])
        end
    end

    report && sol_component_value_edge(pm, nw, :oltc, :pf, :pt, ref(pm, nw, :arcs_from_oltc), ref(pm, nw, :arcs_to_oltc), p)
end

"variable: `q[l,i,j]` for `(l,i,j)` in `arcs`"
function variable_reactive_oltc_flow(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool=true, report::Bool=true)
    q = var(pm, nw)[:qoltc] = JuMP.@variable(pm.model,
        [(l,i,j) in ref(pm, nw, :arcs_oltc)], base_name="$(nw)_qoltc",
        start = 0
    )

    if bounded
        for arc in ref(pm, nw, :arcs_oltc)
            l,i,j = arc
                JuMP.set_lower_bound(q[arc], -ref(pm, nw, :oltc, l)["rateA"])
                JuMP.set_upper_bound(q[arc], ref(pm, nw, :oltc, l)["rateA"])
        end
    end

    report && sol_component_value_edge(pm, nw, :oltc, :qf, :qt, ref(pm, nw, :arcs_from_oltc), ref(pm, nw, :arcs_to_oltc), q)
end

"variable: `t[i]` for `i` in `bus`es"
function variable_oltc_tap(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool=true, report::Bool=true)
    tap = var(pm, nw)[:otap] = JuMP.@variable(pm.model,
        [i in ids(pm, nw, :oltc)], base_name="$(nw)_otap",
        start = 0
    )
    if bounded
        for (i, oltc) in ref(pm, nw, :oltc)
            JuMP.set_lower_bound(tap[i], oltc["tapmin"])
            JuMP.set_upper_bound(tap[i], oltc["tapmax"])
        end
    end
    report && sol_component_value(pm, nw, :oltc, :tap, ids(pm, nw, :oltc), tap)
end

###############################################
# Constraint templates
function constraint_ohms_y_from_oltc(pm::AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    oltc = ref(pm, nw, :oltc, i)
    f_bus = oltc["fbus"]
    t_bus = oltc["tbus"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    g, b = calc_branch_y(oltc)
    g_fr = oltc["g_fr"]
    b_fr = oltc["b_fr"]

    constraint_ohms_y_from_oltc(pm, nw, i, f_bus, t_bus, f_idx, t_idx, g, b, g_fr, b_fr)
end

function constraint_ohms_y_to_oltc(pm::AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    oltc = ref(pm, nw, :oltc, i)
    f_bus = oltc["fbus"]
    t_bus = oltc["tbus"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    g, b = calc_branch_y(oltc)
    g_to = oltc["g_to"]
    b_to = oltc["b_to"]

    constraint_ohms_y_to_oltc(pm, nw, i, f_bus, t_bus, f_idx, t_idx, g, b, g_to, b_to)
end

function constraint_power_balance_oltc(pm::AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    bus = ref(pm, nw, :bus, i)
    bus_arcs = ref(pm, nw, :bus_arcs, i)
    bus_arcs_oltc = ref(pm, nw, :bus_arcs_oltc, i)
    bus_arcs_dc = ref(pm, nw, :bus_arcs_dc, i)
    bus_arcs_sw = ref(pm, nw, :bus_arcs_sw, i)
    bus_gens = ref(pm, nw, :bus_gens, i)
    bus_loads = ref(pm, nw, :bus_loads, i)
    bus_shunts = ref(pm, nw, :bus_shunts, i)
    bus_storage = ref(pm, nw, :bus_storage, i)

    bus_pd = Dict(k => ref(pm, nw, :load, k, "pd") for k in bus_loads)
    bus_qd = Dict(k => ref(pm, nw, :load, k, "qd") for k in bus_loads)

    bus_gs = Dict(k => ref(pm, nw, :shunt, k, "gs") for k in bus_shunts)
    bus_bs = Dict(k => ref(pm, nw, :shunt, k, "bs") for k in bus_shunts)

    constraint_power_balance_oltc(pm, nw, i, bus_arcs, bus_arcs_oltc, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs)
end

###############################################
# PST Constraints
function constraint_ohms_y_from_oltc(pm::AbstractACPModel, n::Int, i::Int, f_bus, t_bus, f_idx, t_idx, g, b, g_fr, b_fr)
    tap = var(pm, n,  :otap, i)
    p_fr  = var(pm, n,  :poltc, f_idx)
    q_fr  = var(pm, n,  :qoltc, f_idx)
    vm_fr = var(pm, n, :vm, f_bus)
    vm_to = var(pm, n, :vm, t_bus)
    va_fr = var(pm, n, :va, f_bus)
    va_to = var(pm, n, :va, t_bus)

    JuMP.@NLconstraint(pm.model, p_fr ==  (g+g_fr)*(vm_fr/tap)^2 - g*vm_fr/(tap)*vm_to*cos(va_fr-va_to) + -b*vm_fr/(tap)*vm_to*sin(va_fr-va_to) )
    JuMP.@NLconstraint(pm.model, q_fr == -(b+b_fr)*(vm_fr/tap)^2 + b*vm_fr/(tap)*vm_to*cos(va_fr-va_to) + -g*vm_fr/(tap)*vm_to*sin(va_fr-va_to) )
end

function constraint_ohms_y_to_oltc(pm::AbstractACPModel, n::Int, i::Int, f_bus, t_bus, f_idx, t_idx, g, b, g_to, b_to)
    tap = var(pm, n,  :otap, i)
    p_to  = var(pm, n,  :poltc, t_idx)
    q_to  = var(pm, n,  :qoltc, t_idx)
    vm_fr = var(pm, n, :vm, f_bus)
    vm_to = var(pm, n, :vm, t_bus)
    va_fr = var(pm, n, :va, f_bus)
    va_to = var(pm, n, :va, t_bus)

    JuMP.@NLconstraint(pm.model, p_to ==  (g+g_to)*vm_to^2 - g*vm_to*vm_fr/(tap)*cos(va_to-va_fr) + -b*vm_to*vm_fr/(tap)*sin(va_to-va_fr) )
    JuMP.@NLconstraint(pm.model, q_to == -(b+b_to)*vm_to^2 + b*vm_to*vm_fr/(tap)*cos(va_to-va_fr) + -g*vm_to*vm_fr/(tap)*sin(va_to-va_fr) )
    end

function constraint_limits_oltc(pm::AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    oltc = ref(pm, nw, :oltc, i)
    srated = oltc["rateA"]
    tapmin = oltc["tapmin"]
    tapmax = oltc["tapmax"]

    f_bus = oltc["fbus"]
    t_bus = oltc["tbus"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    tap = var(pm, nw,  :otap, i)
    p_fr  = var(pm, nw,  :poltc, f_idx)
    q_fr  = var(pm, nw,  :qoltc, f_idx)
    p_to  = var(pm, nw,  :poltc, t_idx)
    q_to  = var(pm, nw,  :qoltc, t_idx)

    JuMP.@NLconstraint(pm.model, p_fr^2 + q_fr^2 <= srated^2)
    JuMP.@NLconstraint(pm.model, p_to^2 + q_to^2 <= srated^2)
    JuMP.@constraint(pm.model, tap <= tapmax)
    JuMP.@constraint(pm.model, tap >= tapmin)
end

function constraint_power_balance_oltc(pm::AbstractACPModel, n::Int, i::Int, bus_arcs, bus_arcs_oltc, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs)
    vm   = var(pm, n, :vm, i)
    p    = get(var(pm, n),    :p, Dict()); _check_var_keys(p, bus_arcs, "active power", "branch")
    q    = get(var(pm, n),    :q, Dict()); _check_var_keys(q, bus_arcs, "reactive power", "branch")
    poltc    = get(var(pm, n),    :poltc, Dict()); _check_var_keys(p, bus_arcs_oltc, "active power", "pst")
    qoltc    = get(var(pm, n),    :qoltc, Dict()); _check_var_keys(q, bus_arcs_oltc, "reactive power", "pst")
    pg   = get(var(pm, n),   :pg, Dict()); _check_var_keys(pg, bus_gens, "active power", "generator")
    qg   = get(var(pm, n),   :qg, Dict()); _check_var_keys(qg, bus_gens, "reactive power", "generator")
    ps   = get(var(pm, n),   :ps, Dict()); _check_var_keys(ps, bus_storage, "active power", "storage")
    qs   = get(var(pm, n),   :qs, Dict()); _check_var_keys(qs, bus_storage, "reactive power", "storage")
    psw  = get(var(pm, n),  :psw, Dict()); _check_var_keys(psw, bus_arcs_sw, "active power", "switch")
    qsw  = get(var(pm, n),  :qsw, Dict()); _check_var_keys(qsw, bus_arcs_sw, "reactive power", "switch")
    p_dc = get(var(pm, n), :p_dc, Dict()); _check_var_keys(p_dc, bus_arcs_dc, "active power", "dcline")
    q_dc = get(var(pm, n), :q_dc, Dict()); _check_var_keys(q_dc, bus_arcs_dc, "reactive power", "dcline")

    cstr_p = JuMP.@constraint(pm.model,
        sum(p[a] for a in bus_arcs)
        + sum(poltc[a] for a in bus_arcs_oltc)
        + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
        + sum(psw[a_sw] for a_sw in bus_arcs_sw)
        ==
        sum(pg[g] for g in bus_gens)
        - sum(ps[s] for s in bus_storage)
        - sum(pd for (i,pd) in bus_pd)
        - sum(gs for (i,gs) in bus_gs)*vm^2
    )
    cstr_q = JuMP.@constraint(pm.model,
        sum(q[a] for a in bus_arcs)
        + sum(qoltc[a] for a in bus_arcs_oltc)
        + sum(q_dc[a_dc] for a_dc in bus_arcs_dc)
        + sum(qsw[a_sw] for a_sw in bus_arcs_sw)
        ==
        sum(qg[g] for g in bus_gens)
        - sum(qs[s] for s in bus_storage)
        - sum(qd for (i,qd) in bus_qd)
        + sum(bs for (i,bs) in bus_bs)*vm^2
    )

    if report_duals(pm)
        sol(pm, n, :bus, i)[:lam_kcl_r] = cstr_p
        sol(pm, n, :bus, i)[:lam_kcl_i] = cstr_q
    end
end

###############################################
# ADD REF MODEL
function ref_add_oltc!(pm::AbstractPowerModel)
    for (nw, nw_ref) in pm.ref[:nw]
        if !haskey(nw_ref, :oltc)
            error(_LOGGER, "required pst data not found")
        end

        nw_ref[:oltc] = Dict(x for x in nw_ref[:oltc] if (x.second["status"] == 1 && x.second["fbus"] in keys(nw_ref[:bus]) && x.second["tbus"] in keys(nw_ref[:bus])))

        nw_ref[:arcs_from_oltc] = [(i,oltc["fbus"],oltc["tbus"]) for (i,oltc) in nw_ref[:oltc]]
        nw_ref[:arcs_to_oltc]   = [(i,oltc["tbus"],oltc["fbus"]) for (i,oltc) in nw_ref[:oltc]]
        nw_ref[:arcs_oltc] = [nw_ref[:arcs_from_oltc]; nw_ref[:arcs_to_oltc]]

        bus_arcs_oltc = Dict((i, []) for (i,bus) in nw_ref[:bus])
        for (l,i,j) in nw_ref[:arcs_oltc]
            push!(bus_arcs_oltc[i], (l,i,j))
        end
        nw_ref[:bus_arcs_oltc] = bus_arcs_oltc
        # if !haskey(nw_ref, :buspairs_pst)
        #     nw_ref[:buspairs_pst] = calc_buspair_parameters(nw_ref[:bus], nw_ref[:pst], conductor_ids(pm, nw), ismulticonductor(pm, nw))
        # end
    end
end

###############################################
# DATA SCALINNG PST
function process_oltc_data!(data)
    if !haskey(data, "multinetwork") || data["multinetwork"] == false
        to_pu_single_network_oltc!(data)
        fix_data_single_network_oltc!(data)
    else
        to_pu_multi_network_oltc!(data)
        fix_data_multi_network_oltc!(data)
    end
end

function to_pu_single_network_oltc!(data)
    MVAbase = data["baseMVA"]
    for (i, oltc) in data["oltc"]
        scale_oltc_data!(oltc, MVAbase)
    end
end

function fix_data_single_network_oltc!(data)
    for (i, oltc) in data["oltc"]
        oltc["g_fr"] = 0
        oltc["b_fr"] = 0
        oltc["g_to"] = 0
        oltc["b_to"] = 0
    end
end
function to_pu_multi_network_oltc!(data)
    MVAbase = data["baseMVA"]
    for (n, network) in data["nw"]
        MVAbase = network["baseMVA"]
        for (i, oltc) in network[n]["oltc"]
            scale_oltc_data!(oltc, MVAbase)
        end
    end
end

function fix_data_multi_network_oltc!(data)
    for (n, network) in data["nw"]
        for (i, oltc) in network[n]data["oltc"]
            oltc["g_fr"] = 0
            oltc["b_fr"] = 0
            oltc["g_to"] = 0
            oltc["b_to"] = 0
        end
    end
end

function scale_oltc_data!(oltc, MVAbase)
    rescale_power = x -> x/MVAbase
    _apply_func!(oltc, "rateA", rescale_power)
    _apply_func!(oltc, "rateB", rescale_power)
    _apply_func!(oltc, "rateC", rescale_power)
end
