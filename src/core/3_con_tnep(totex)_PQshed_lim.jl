#1. flexible reactive power is added to the equation
#2. only the reactive power balance is added @ instead of 1.0 pu of vm, we use vm in active_power balance
using JuMP

" constraint_flexible_active_Power_flow"
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

" constraint_limited_flexible_active_Power_flow"
function constraint_limited_active_Power_flow(pm::AbstractPowerModel,  i::Int ; nw::Int=pm.cnw)
    constraint_limited_active_Power_flow(pm, nw, i)
end

function constraint_limited_active_Power_flow(pm::AbstractPowerModel, nw::Int, i::Int)
        p_real= ref(pm, nw, :load, i, "pd")
        p_flx = var(pm, nw, :p_flex, i)
        JuMP.@constraint(pm.model, 0.9 * p_real<= p_flx <= 1.1 * p_real)

end


" constraint_flexible_reactive_Power_flow"
function constraint_flexible_reactive_Power_flow(pm::AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    constraint_flexible_reactive_Power_flow(pm,i,nw)
end

function constraint_flexible_reactive_Power_flow(pm::AbstractPowerModel, i::Int, nw::Int=pm.cnw)
    q_flx = var(pm, nw, :q_flex, i)
    q_neg = var(pm, nw, :qflex_minus, i)
    q_pos = var(pm, nw, :qflex_plus, i)
    q_real= ref(pm, nw, :load, i, "qd")

    JuMP.@constraint(pm.model, q_flx == q_real + q_pos - q_neg)
end




" constraint_limited_flexible_reactive_Power_flow"
function constraint_limited_reactive_Power_flow(pm::AbstractPowerModel,  i::Int ; nw::Int=pm.cnw)
    constraint_limited_reactive_Power_flow(pm, nw, i)
end

function constraint_limited_reactive_Power_flow(pm::AbstractPowerModel, nw::Int, i::Int)
        q_real= ref(pm, nw, :load, i, "qd")
        q_flx = var(pm, nw, :q_flex, i)
        JuMP.@constraint(pm.model, 0.9 * q_real <= q_flx <= 1.1 * q_real )

end



"constraint nodal balance equation, both avtive and reactive"
function constraint_PQ_power_balance_ne_ls(pm::AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    bus = ref(pm, nw, :bus, i)                          # get bus i whole info (zone, bus_i, base kv,....)                          i==> dictionary of bus i info
    bus_arcs = ref(pm, nw, :bus_arcs, i)                # gets for bus i, all connected arcs info (branch id, bus i, bus j)         i==> tupple (branch id, bus i, bus j)
    bus_arcs_dc = ref(pm, nw, :bus_arcs_dc, i)          # gets for bus i, all dc_arcs info (branch id, bus i, bus j)
    bus_arcs_ne = ref(pm, nw, :ne_bus_arcs, i)          # gets for bus i, all new_arcs info (branch id, bus i, bus j)
    bus_arcs_sw = ref(pm, nw, :bus_arcs_sw, i)          #
    bus_gens = ref(pm, nw, :bus_gens, i)                # gets for bus i, the generator id which is connected to                    i==> gen_ID
    bus_loads = ref(pm, nw, :bus_loads, i)              # gets for bus i, the generator id which is connected to                    i==> load_ID

    bus_shunts = ref(pm, nw, :bus_shunts, i)            # gets for bus i, the generator id which is connected to                    i==> shunt_ID
    bus_storage = ref(pm, nw, :bus_storage, i)          # gets for bus i, the generator id which is connected to                    i==> storage_ID
    #bus_storage_new= ref(pm, nw, :bus_ne_storage, i)    # gets for bus i, the generator id which is connected to                    i==> new_storage_ID

    bus_gs = Dict(k => ref(pm, nw, :shunt, k, "gs") for k in bus_shunts)    # for bus i,                shunt_ID==> gs
    bus_bs = Dict(k => ref(pm, nw, :shunt, k, "bs") for k in bus_shunts)    # for bus i,                shunt_ID==> bs

    constraint_PQ_power_balance_ne_ls(pm, nw, i, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_arcs_ne, bus_gens, bus_storage, bus_gs, bus_bs, bus_loads)
end

function constraint_PQ_power_balance_ne_ls(pm::AbstractPowerModel, n::Int, i, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_arcs_ne, bus_gens, bus_storage, bus_gs, bus_bs, bus_loads)
# get(collection, key, default)           :Return the value stored for the given key, or the given default value if no mapping for the key is present.
        p       =  get(var(pm, n),   :p, Dict())
        psw     =  get(var(pm, n),   :psw, Dict())
        p_dc    =  get(var(pm, n),   :p_dc, Dict())
        p_ne    =  get(var(pm, n),   :p_ne, Dict())
        pg      =  get(var(pm, n),   :pg, Dict())
        ps      =  get(var(pm, n),   :ps, Dict())
        p_flex  =  get(var(pm,n),    :p_flex, Dict())



        vm      =  var(pm, n, :vm, i)

        q       =  get(var(pm, n),     :q, Dict())
        qsw     =  get(var(pm, n),     :qsw, Dict())
        q_dc    =  get(var(pm, n),     :q_dc, Dict())
        q_ne    =  get(var(pm, n),     :q_ne, Dict())
        qg      =  get(var(pm, n),     :qg, Dict())
        qs      =  get(var(pm, n),     :qs, Dict())
        q_flex  =  get(var(pm,n),    :q_flex, Dict())



        cstr_p = JuMP.@constraint(pm.model,
            sum(p[a] for a in bus_arcs)
            + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(psw[a_sw] for a_sw in bus_arcs_sw)
            + sum(p_ne[a] for a in bus_arcs_ne)
        ==
            sum(pg[g] for g in bus_gens)
            - sum(ps[s] for s in bus_storage)
            - sum(p_flex[d] for d in (bus_loads))
            - sum(gs for gs in values(bus_gs))*vm^2
        )


        cstr_q = JuMP.@constraint(pm.model,
              sum(q[a] for a in bus_arcs)
            + sum(q_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(qsw[a_sw] for a_sw in bus_arcs_sw)
            + sum(q_ne[a] for a in bus_arcs_ne)
        ==
              sum(qg[g] for g in bus_gens)
            - sum(qs[s] for s in bus_storage)
            - sum(q_flex[d] for d in (bus_loads))
            + sum(bs for (i,bs) in bus_bs)* vm^2
        )


        if _IM.report_duals(pm)
            sol(pm, n, :bus, i)[:lam_kcl_r] = cstr_p
            sol(pm, n, :bus, i)[:lam_kcl_i] = cstr_q

        end

    end
