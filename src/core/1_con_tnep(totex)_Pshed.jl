using JuMP

function constraint_flexible_active_Power_flow(pm::AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    constraint_flexible_active_Power_flow(pm,nw,i)
end

function constraint_flexible_active_Power_flow(pm::AbstractPowerModel, nw::Int, i::Int)
    p_flx = var(pm, nw, :p_flex, i)
    p_neg = var(pm, nw, :pflex_minus, i)
    p_pos = var(pm, nw, :pflex_plus, i)
    p_real= ref(pm, nw, :load, i, "pd")
    display("p_real is equal to:")
    display(p_real)
    display("p_flx is equal to:")

    display(p_flx)
    display("p_neg is equal to:")
    display(p_neg)
    display("p_pos is equal to:")
    display(p_pos)
    JuMP.@constraint(pm.model, p_flx == p_real + p_pos - p_neg)
end

function constraint_power_balance_ne_ls(pm::AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    bus = ref(pm, nw, :bus, i)
    bus_arcs = ref(pm, nw, :bus_arcs, i)
    bus_arcs_dc = ref(pm, nw, :bus_arcs_dc, i)
    bus_arcs_ne = ref(pm, nw, :ne_bus_arcs, i)
    bus_arcs_sw = ref(pm, nw, :bus_arcs_sw, i)
    bus_gens = ref(pm, nw, :bus_gens, i)
    bus_loads = ref(pm, nw, :bus_loads, i)

    bus_shunts = ref(pm, nw, :bus_shunts, i)
    bus_storage = ref(pm, nw, :bus_storage, i)


    bus_pd = Dict(k => ref(pm, nw, :load, k, "pd") for k in bus_loads)
    bus_qd = Dict(k => ref(pm, nw, :load, k, "qd") for k in bus_loads)

    bus_gs = Dict(k => ref(pm, nw, :shunt, k, "gs") for k in bus_shunts)
    bus_bs = Dict(k => ref(pm, nw, :shunt, k, "bs") for k in bus_shunts)

    constraint_power_balance_ne_ls(pm, nw, i, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_arcs_ne, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs, bus_loads)
end

function constraint_P_power_balance_ne_ls(pm::AbstractPowerModel, n::Int, i, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_arcs_ne, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs, bus_loads)
        p    = get(var(pm, n),    :p, Dict())
        pg   = get(var(pm, n),   :pg, Dict())
        ps   = get(var(pm, n),   :ps, Dict())
        psw  = get(var(pm, n),  :psw, Dict())
        p_dc = get(var(pm, n), :p_dc, Dict())
        p_ne = get(var(pm, n), :p_ne, Dict())
        p_sh   = get(var(pm),   :p_flex, Dict())
        cstr = JuMP.@constraint(pm.model,
            sum(p[a] for a in bus_arcs)
            + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(psw[a_sw] for a_sw in bus_arcs_sw)
            + sum(p_ne[a] for a in bus_arcs_ne)
            ==
            sum(pg[g] for g in bus_gens)
            - sum(ps[s] for s in bus_storage)
            - sum(p_sh[d] for d in (bus_loads))
            - sum(gs for gs in values(bus_gs))*1.0^2
        )

        if report_duals(pm)
            sol(pm, n, :bus, i)[:lam_kcl_r] = cstr
        end
    end
