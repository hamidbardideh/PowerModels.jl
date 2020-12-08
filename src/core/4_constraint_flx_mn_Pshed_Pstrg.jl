
### Storage Constraints

# 0. Dynamic Equation Constraint(Old_storage) Because new parameters( energy_ext and storage_loss are added as arguments here) are added
# 1. Dynamic Equation Constraint (new_storage)
#     a.constraint_storage_state_initial
#     b.constraint_storage_state
# 2.  charging/discharging exlusivity
# 3.  Min/Max energy constraint (check if defined in variables)
# 4.  Min/Max charging/discharging constraint
# 5.  Investment and status constraint
# ____________REACTIVE POWER FLEXIBILITY added for LOAD MANAGEMENT/SHEDDING___________
# 6.  constraint_flexible_active_Power_floww
# 7.  constraint_flexible_reactive_Power_flow
# 8.  constraint_power_balance_flx_ne_strg_shed (New Nodal Balance Constraint)
##


" 0. Dyanmic EQuation Constraint (already existing storage)"
#NOTE: parameters after being added to matpower data and creating reference, should ba added here

function constraint_strg_state_initial(pm::AbstractPowerModel, n::Int, i::Int, energy, charge_eff, discharge_eff,  time_elapsed)
    sc = var(pm, n, :sc, i)
    sd = var(pm, n, :sd, i)
    se = var(pm, n, :se, i)

    JuMP.@constraint(pm.model, se - energy == time_elapsed*(charge_eff*sc - sd/discharge_eff))
end



function constraint_strg_state(pm::AbstractPowerModel, n_1::Int, n_2::Int, i::Int, charge_eff, discharge_eff,  time_elapsed)
    sc_2 = var(pm, n_2, :sc, i)
    sd_2 = var(pm, n_2, :sd, i)
    se_2 = var(pm, n_2, :se, i)
    se_1 = var(pm, n_1, :se, i)

    JuMP.@constraint(pm.model, se_2 - se_1 == time_elapsed*(charge_eff*sc_2 - sd_2/discharge_eff))
end



function constraint_strg_state(pm::AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    storage = ref(pm, nw, :storage, i)

    if haskey(ref(pm, nw), :time_elapsed)
        time_elapsed = ref(pm, nw, :time_elapsed)
    else
        Memento.warn(_LOGGER, "network data should specify time_elapsed, using 1.0 as a default")
        time_elapsed = 1.0
    end

    constraint_strg_state_initial(pm, nw, i, storage["energy"], storage["charge_efficiency"], storage["discharge_efficiency"], time_elapsed)
end



function constraint_strg_state(pm::AbstractPowerModel, i::Int, nw_1::Int, nw_2::Int)
    storage = ref(pm, nw_2, :storage, i)

    if haskey(ref(pm, nw_2), :time_elapsed)
        time_elapsed = ref(pm, nw_2, :time_elapsed)
    else
        Memento.warn(_LOGGER, "network $(nw_2) should specify time_elapsed, using 1.0 as a default")
        time_elapsed = 1.0
    end

    if haskey(ref(pm, nw_1, :storage), i)
        constraint_strg_state(pm, nw_1, nw_2, i, storage["charge_efficiency"], storage["discharge_efficiency"], time_elapsed)
    else
        # if the storage device has status=0 in nw_1, then the stored energy variable will not exist. Initialize storage from data model instead.
        Memento.warn(_LOGGER, "storage component $(i) was not found in network $(nw_1) while building constraint_storage_state between networks $(nw_1) and $(nw_2). Using the energy value from the storage component in network $(nw_2) instead")
        constraint_strg_state_initial(pm, nw_2, i, storage["energy"], storage["charge_efficiency"], storage["discharge_efficiency"], time_elapsed)
    end
end






"1. Dynamic Equation Constraint (new_storage)"
# energy_ext and storage_loss are added as arguments here
function constraint_storage_new_state_initial(pm::AbstractPowerModel, n::Int, i::Int, energy, charge_eff, discharge_eff, ext_inj_energy, lost_wasted_energy, time_elapsed)
    sc_new = var(pm, n, :sc_new, i)
    sd_new = var(pm, n, :sd_new, i)
    se_new = var(pm, n, :se_new, i)

    JuMP.@constraint(pm.model, se_new - energy == time_elapsed*(charge_eff*sc_new - sd_new/discharge_eff) + ext_inj_energy - lost_wasted_energy   )
end



"__constraintt storage state__INITIAL__"
function constraint_storage_new_state(pm::AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    storage = ref(pm, nw, :ne_storage, i)

    if haskey(ref(pm, nw), :time_elapsed)
        time_elapsed = ref(pm, nw, :time_elapsed)

    else
        Memento.warn(_LOGGER, "network data should specify time_elapsed, using 1.0 as a default")
        time_elapsed = 1.0
    end

    constraint_storage_new_state_initial(pm, nw, i, storage["energy"], storage["charge_efficiency"], storage["discharge_efficiency"],   0,       0,      time_elapsed)
end



`    constraint_storage_state`
function constraint_storage_new_state(pm::AbstractPowerModel, n_1::Int, n_2::Int, i::Int, charge_eff, discharge_eff,ext_inj_energy, lost_wasted_energy, time_elapsed)
    sc_2 = var(pm, n_2, :sc_new, i)
    sd_2 = var(pm, n_2, :sd_new, i)
    se_2 = var(pm, n_2, :se_new, i)
    se_1 = var(pm, n_1, :se_new, i)
#2. I think it should be se_1-se_2(make an issue)
    JuMP.@constraint(pm.model, se_2 - se_1 == time_elapsed*(charge_eff*sc_2 - sd_2/discharge_eff)  )
end



"   constraint_storage_state"
function constraint_storage_new_state(pm::AbstractPowerModel, i::Int, nw_1::Int, nw_2::Int)
    storage = ref(pm, nw_2, :ne_storage, i)

    if haskey(ref(pm, nw_2), :time_elapsed)
        time_elapsed = ref(pm, nw_2, :time_elapsed)
    else
        Memento.warn(_LOGGER, "network $(nw_2) should specify time_elapsed, using 1.0 as a default")
        time_elapsed = 1.0
    end

    if haskey(ref(pm, nw_1, :ne_storage), i)
        constraint_storage_new_state(pm, nw_1, nw_2, i, storage["charge_efficiency"], storage["discharge_efficiency"], storage["ext_inj_energy"], storage["lost_wasted_energy"], time_elapsed)
    else
        # if the storage device has status=0 in nw_1, then the stored energy variable will not exist. Initialize storage from data model instead.
        Memento.warn(_LOGGER, "storage component $(i) was not found in network $(nw_1) while building constraint_storage_state between networks $(nw_1) and $(nw_2). Using the energy value from the storage component in network $(nw_2) instead")
        constraint_storage_new_state_initial(pm, nw_2, i, storage["energy"], storage["charge_efficiency"], storage["discharge_efficiency"], 0 , 0 , time_elapsed)
    end
end





# The following charge/discharge complementarity constraint is a non-convex nonlinear constraint that has undesirable numerical properties. Consequently
# " 2. charging/discharging exlusivity"
# function constraint_Pstrg_new_chr_dischr_exclusivity(pm::AbstractPowerModel, i::Int; nw::Int=pm.cnw)
#     storage_ne = var(pm, nw, :storage_ne,i)
#     sc_new = var(pm, nw, :sc_new, i)
#     sd_new = var(pm, nw, :sd_new, i)
#     excl   = sd_new * sc_new
#     JuMP.@constraint(pm.model, excl==0)
#     # JuMP.@constraint(pm.model, storage_ne*excl==0)
# end


# we reformulate the above charge/discharge constraint by introducing a binary variable,as below:
" 2. charging/discharging exlusivity"
function constraint_Pstrg_new_chr_dischr_exclusivity(pm::AbstractPowerModel, i::Int; nw::Int=pm.cnw)

    z_bin = var(pm, nw, :storage_ch_dch_bin, i)
    Z_strg = var(pm, nw, :storage_ne, i)
    ps_ch_new = var(pm, nw, :ps_ch_new, i)
    ps_dch_new = var(pm, nw, :ps_dch_new, i)

    storage = ref(pm, nw, :ne_storage, i)
    max_strg_ch= storage["charge_rating"]
    max_strg_disch= storage["discharge_rating"]


    JuMP.@constraint(pm.model,  0 <= ps_ch_new )
    JuMP.@constraint(pm.model,  ps_ch_new <= max_strg_ch * z_bin * Z_strg )      # this is nonlinear!!!!!!!!!!!!
    JuMP.@constraint(pm.model,  0 <= ps_dch_new)
    JuMP.@constraint(pm.model,  ps_dch_new <= max_strg_disch * (1-z_bin) * Z_strg)

end



"3.  Min/Max energy constraint"
# already defined in bounding of variable definition (not necessary)
function constraint_storage_new_energy_limit(pm::AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    se_new  = var(pm, nw, :se_new, i)
    storage = ref(pm, nw, :ne_storage, i)
    min_strg_limit= storage["energy_min"]
    max_strg_limit = storage["energy_rating"]

    JuMP.@constraint(pm.model, min_strg_limit <= se_new)
    JuMP.@constraint(pm.model, se_new <= max_strg_limit)
end


"4. Min_Max charging_discharging constraint"
# already defined in bounding of variable definition (not necessary)
function constraint_storage_new_chrg_limit(pm::AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    sc_new = var(pm, nw, :sc_new, i)

    time_elapsed= ref(pm, nw, :time_elapsed)
    storage = ref(pm, nw, :ne_storage, i)
    min_strg_ch=storage["min_charge_rating"]
    max_strg_ch= storage["charge_rating"]

    JuMP.@constraint(pm.model, min_strg_ch <= sc_new )
    JuMP.@constraint(pm.model, sc_new <= max_strg_ch)
end

function constraint_storage_new_dischrg_limit(pm::AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    sd_new = var(pm, nw, :sd_new, i)

    time_elapsed= ref(pm, nw, :time_elapsed)
    storage = ref(pm, nw, :ne_storage, i)
    min_strg_disch= storage["min_discharge_rating"]
    max_strg_disch= storage["discharge_rating"]

    JuMP.@constraint(pm.model, min_strg_disch <= sd_new )
    JuMP.@constraint(pm.model, sd_new <= max_strg_disch)
end




# "5. Investment and status constraint"
# function constraint_storage_new_investment_status(pm::AbstractPowerModel, i::Int; nw::Int=pm.cnw)
#     se_new = var(pm, nw, :se_new, i)
#     invst_decision=var(pm, nw, :storage_ne, i)
#
#     time_elapsed= ref(pm, nw, :time_elapsed)
#
#     storage = ref(pm, nw, :ne_storage, i)
#     min_energy=storage["energy_min"]
#     max_energy=storage["energy_rating"]
#     status=storage["status"]
#
#
#     JuMP.@constraint(pm.model, ( min_energy/max_energy) * status      <=      se_new/max_energy )
#     JuMP.@constraint(pm.model, se_new/max_energy    <=       status)
#     # JuMP.@constraint(pm.model, status       <=      invst_decision)
# end





"6. constraint_flexible_active_power_floww"

function constraint_flexible_active_Power_floww(pm::AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    constraint_flexible_active_Power_floww(pm,i,nw)
end

function constraint_flexible_active_Power_floww(pm::AbstractPowerModel,  i::Int, nw::Int=pm.cnw)
    p_flx = var(pm, nw, :p_flex, i)
    p_neg = var(pm, nw, :pflex_minus, i)
    p_pos = var(pm, nw, :pflex_plus, i)
    p_real= ref(pm, nw, :load, i, "pd")
    JuMP.@constraint(pm.model, p_flx == p_real + p_pos - p_neg)
end


function constraint_limited_active_Power_flow(pm::AbstractPowerModel,  i::Int ; nw::Int=pm.cnw)
    constraint_limited_active_Power_flow(pm, i, nw)
end

function constraint_limited_active_Power_flow(pm::AbstractPowerModel,  i::Int, nw::Int)
        p_real= ref(pm, nw, :load, i, "pd")
        p_flx = var(pm, nw, :p_flex, i)
        JuMP.@constraint(pm.model, 0.9 * p_real <= p_flx <= 1.1 * p_real)

end




# "7. constraint_flexible_reactive_Power_flow"
#
# function constraint_flexible_reactive_Power_flow(pm::AbstractPowerModel, i::Int; nw::Int=pm.cnw)
#     constraint_flexible_reactive_Power_flow(pm,i,nw)
# end
#
#
#
# function constraint_flexible_reactive_Power_flow(pm::AbstractPowerModel, i::Int, nw::Int=pm.cnw)
#     q_flx = var(pm, nw, :q_flex, i)
#     q_neg = var(pm, nw, :qflex_minus, i)
#     q_pos = var(pm, nw, :qflex_plus, i)
#     q_real= ref(pm, nw, :load, i, "qd")
#
#     JuMP.@constraint(pm.model, q_flx == q_real + q_pos - q_neg)
# end
#
#
#
# function constraint_limited_reactive_Power_flow(pm::AbstractPowerModel,  i::Int ; nw::Int=pm.cnw)
#     constraint_limited_reactive_Power_flow(pm, i, nw)
# end
#
# function constraint_limited_reactive_Power_flow(pm::AbstractPowerModel, i::Int, nw::Int)
#         q_real= ref(pm, nw, :load, i, "qd")
#         q_flx = var(pm, nw, :q_flex, i)
#         JuMP.@constraint(pm.model, 0.9 * q_real <= q_flx <= 1.1 * q_real )
# end


"8.  constraint Nodal Balance (active and reac)"


function constraint_power_balance_flx_ne_Pshed_Pstrg(pm::AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    bus = ref(pm, nw, :bus, i)                          # get bus i whole info (zone, bus_i, base kv,....)                          i==> dictionary of bus i info
    bus_arcs = ref(pm, nw, :bus_arcs, i)                # gets for bus i, all connected arcs info (branch id, bus i, bus j)         i==> tupple (branch id, bus i, bus j)
    bus_arcs_dc = ref(pm, nw, :bus_arcs_dc, i)          # gets for bus i, all dc_arcs info (branch id, bus i, bus j)
    bus_arcs_ne = ref(pm, nw, :ne_bus_arcs, i)          # gets for bus i, all new_arcs info (branch id, bus i, bus j)
    bus_arcs_sw = ref(pm, nw, :bus_arcs_sw, i)          #
    bus_gens = ref(pm, nw, :bus_gens, i)                # gets for bus i, the generator id which is connected to                    i==> gen_ID
    bus_loads = ref(pm, nw, :bus_loads, i)              # gets for bus i, the generator id which is connected to                    i==> load_ID

    bus_shunts = ref(pm, nw, :bus_shunts, i)            # gets for bus i, the generator id which is connected to                    i==> shunt_ID
    bus_storage = ref(pm, nw, :bus_storage, i)          # gets for bus i, the generator id which is connected to                    i==> storage_ID
    bus_storage_new= ref(pm, nw, :bus_ne_storage, i)    # gets for bus i, the generator id which is connected to                    i==> new_storage_ID

    bus_gs = Dict(k => ref(pm, nw, :shunt, k, "gs") for k in bus_shunts)    # for bus i,                shunt_ID==> gs
    bus_bs = Dict(k => ref(pm, nw, :shunt, k, "bs") for k in bus_shunts)    # for bus i,                shunt_ID==> bs

    constraint_power_balance_flx_ne_Pshed_Pstrg(pm, nw, i, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_arcs_ne, bus_gens, bus_storage, bus_storage_new, bus_gs, bus_bs, bus_loads)
end

function constraint_power_balance_flx_ne_Pshed_Pstrg(pm::AbstractPowerModel, n::Int, i, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_arcs_ne, bus_gens, bus_storage, bus_storage_new, bus_gs, bus_bs, bus_loads)
# get(collection, key, default)           :Return the value stored for the given key, or the given default value if no mapping for the key is present.
        p       =  get(var(pm, n),   :p, Dict())
        psw     =  get(var(pm, n),   :psw, Dict())
        p_dc    =  get(var(pm, n),   :p_dc, Dict())
        p_ne    =  get(var(pm, n),   :p_ne, Dict())
        pg      =  get(var(pm, n),   :pg, Dict())
        ps      =  get(var(pm, n),   :ps, Dict())
        # ps_new  =  get(var(pm, n),   :ps_new, Dict())
        ps_ch_new  =  get(var(pm, n),   :ps_ch_new, Dict())
        ps_dch_new  =  get(var(pm, n), :ps_dch_new, Dict())
        p_flex  =  get(var(pm,n),    :p_flex, Dict())
        Z_strg = get(var(pm,n), :storage_ne, Dict())


        # vm      =  var(pm, n, :vm, i)
        #
        # q       =  get(var(pm, n),     :q, Dict())
        # qsw     =  get(var(pm, n),     :qsw, Dict())
        # q_dc    =  get(var(pm, n),     :q_dc, Dict())
        # q_ne    =  get(var(pm, n),     :q_ne, Dict())
        # qg      =  get(var(pm, n),     :qg, Dict())
        # qs      =  get(var(pm, n),     :qs, Dict())
        # # qs_new  =  get(var(pm, n), :qs_new, Dict())
        # # q_flex  =  get(var(pm,n),    :q_flex, Dict())



        cstr_p = JuMP.@constraint(pm.model,
            sum(p[a] for a in bus_arcs)
            + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(psw[a_sw] for a_sw in bus_arcs_sw)
            + sum(p_ne[a] for a in bus_arcs_ne)
        ==
            sum(pg[g] for g in bus_gens)
            + sum(ps_dch_new[sn]*Z_strg[sn] for sn in bus_storage_new)
            - sum(ps[s] for s in bus_storage)
            - sum(ps_ch_new[sn]*Z_strg[sn] for sn in bus_storage_new)
            - sum(p_flex[d] for d in (bus_loads))
            - sum(gs for gs in values(bus_gs))* (1.0 ^ 2 )                            # 1 replaced by vm
        )


        # cstr_q = JuMP.@constraint(pm.model,
        #       sum(q[a] for a in bus_arcs)
        #     + sum(q_dc[a_dc] for a_dc in bus_arcs_dc)
        #     + sum(qsw[a_sw] for a_sw in bus_arcs_sw)
        #     + sum(q_ne[a] for a in bus_arcs_ne)
        # ==
        #       sum(qg[g] for g in bus_gens)
        #     - sum(qs[s] for s in bus_storage)
        #     # - sum(qs_new[sn]*Z_strg[sn] for sn in bus_storage_new)
        #     - sum(q_flex[d] for d in (bus_loads))
        #     + sum(bs for (i,bs) in bus_bs)* vm^2
        # )


        if _IM.report_duals(pm)
            sol(pm, n, :bus, i)[:lam_kcl_r] = cstr_p
            # sol(pm, n, :bus, i)[:lam_kcl_i] = cstr_q

        end

end


"9.  constraint sc_sd relationships between ps_ch ps_dch  and sc_new, sd_new   "
function constraint_storage_new_sc_ps_and_sd_pd(pm::AbstractPowerModel, i::Int; nw::Int=pm.cnw)

    storage = ref(pm, nw, :ne_storage, i)
    Z_strg = var(pm, nw, :storage_ne, i)
    sc_new = var(pm, nw, :sc_new, i)
    sd_new = var(pm, nw, :sd_new, i)


    ps_ch_new = var(pm, nw, :ps_ch_new, i)
    ps_dch_new = var(pm, nw, :ps_dch_new, i)


    JuMP.@constraint(pm.model, sc_new == ps_ch_new *Z_strg   )
    JuMP.@constraint(pm.model, sd_new == ps_dch_new *Z_strg   )

end


# function same_strg_decision_variable(pm::AbstractPowerModel, i::Int; nw::Int=pm.cnw)
#     n=0
#     for (nw, nw_ref) in nws(pm)
#         n=n+1
#         return n
#     end
#
#
#         for (nw, nw_ref) in nws(pm)
#             for (i,storage) in nw_ref[:ne_storage]
#                 if nw<=n-1
#                     z_1_strg = var(pm, nw, :storage_ne, i)
#                     z_2_strg = var(pm, nw+1, :storage_ne, i)
#                     if z_1== 1
#                     JuMP.@constraint(pm.model, z_2_strg  == z_1_strg)
#                 end
#             end
#         end
#     end
# end

function same_strg_decision_variable(pm::AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    if nw>=2
                print(nw)
                z_1_strg = var(pm, nw-1, :storage_ne, i)
                z_2_strg = var(pm, nw, :storage_ne, i)
                JuMP.@constraint(pm.model, z_2_strg  == z_1_strg)

            else
                Nothing
    end

end
