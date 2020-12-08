
#__all the new variables for the project are listed here___________________________________________________________________________________________________________________________________
"0. already_existing_storage variables redefined here
 1. binary decision variable for ne_storages are built
 2. new_storage variables"
# 0.  It gave me an error that :sc keword os not recognized, so I add nw::Int=pm.cnw and error is solved
 function variable_strg(pm::AbstractPowerModel; nw::Int=pm.cnw,  kwargs...)
     variable_active_storage(pm; kwargs...)
     variable_reactive_storage(pm; kwargs...)
     variable_current_storage(pm; kwargs...)
     variable_storage_energy(pm; kwargs...)
     variable_storage_charge(pm; kwargs...)
     variable_storage_discharge(pm; kwargs...)
 end


# 1. this variable is the binary decision variable (only for network expansion) of new storage elements(it reflects in objective function )====>   DONE
"variable: `0 <= branch_ne[l] <= 1` for `l` in `branch`es"
function variable_storage_ne(pm::AbstractPowerModel; nw::Int=pm.cnw, relax::Bool=false, report::Bool=true)
    if !relax
        storage_ne = var(pm, nw)[:storage_ne] = JuMP.@variable(pm.model,
            [l in ids(pm, nw, :ne_storage)], base_name="$(nw)_storage_ne",
            binary = true,
             start = comp_start_value(ref(pm, nw, :ne_storage, l), "storage_tnep_start", 1.0)
        )
    else
        storage_ne = var(pm, nw)[:storage_ne] = JuMP.@variable(pm.model,
            [l in ids(pm, nw, :ne_storage)], base_name="$(nw)_storage_ne",
            lower_bound = 0.0,
            upper_bound = 1.0,
            start = comp_start_value(ref(pm, nw, :ne_storage, l), "storage_tnep_start", 1.0)
        )
    end

    report && _IM.sol_component_value(pm, nw, :ne_storage, :built, ids(pm, nw, :ne_storage), storage_ne)
end


# 2. all storage variables were redefined for new_storage
"variables for modeling storage units, includes grid injection and internal variables"
function variable_ne_storage(pm::AbstractPowerModel; kwargs...) # it reflects in Prblem definition file!===>    DONE
    variable_active_ne_storage(pm; kwargs...)
    variable_reactive_ne_storage(pm; kwargs...)
    variable_current_ne_storage(pm; kwargs...)
    variable_ne_storage_energy(pm; kwargs...)
    variable_ne_storage_charge(pm; kwargs...)
    variable_ne_storage_discharge(pm; kwargs...)
end


""
function variable_active_ne_storage(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool=true, report::Bool=true)
    ps_new = var(pm, nw)[:ps_new] = JuMP.@variable(pm.model,
        [i in ids(pm, nw, :ne_storage)], base_name="$(nw)_ps_new",
         start = comp_start_value(ref(pm, nw, :ne_storage, i), "ps_new_start")
    )

    if bounded
        inj_lb, inj_ub = ref_calc_storage_injection_bounds(ref(pm, nw, :ne_storage), ref(pm, nw, :bus))

        for i in ids(pm, nw, :ne_storage)
            if !isinf(inj_lb[i])
                JuMP.set_lower_bound(ps_new[i], inj_lb[i])
            end
            if !isinf(inj_ub[i])
                JuMP.set_upper_bound(ps_new[i], inj_ub[i])
            end
        end
    end

    report && _IM.sol_component_value(pm, nw, :ne_storage, :ps_new, ids(pm, nw, :ne_storage), ps_new)
end

""
function variable_reactive_ne_storage(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool=true, report::Bool=true)
    qs_new = var(pm, nw)[:qs_new] = JuMP.@variable(pm.model,
        [i in ids(pm, nw, :ne_storage)], base_name="$(nw)_qs_new",
         start = comp_start_value(ref(pm, nw, :ne_storage, i), "qs_new_start")
    )

    if bounded
        inj_lb, inj_ub = ref_calc_storage_injection_bounds(ref(pm, nw, :ne_storage), ref(pm, nw, :bus))

        for (i, storage) in ref(pm, nw, :ne_storage)
            JuMP.set_lower_bound(qs_new[i], max(inj_lb[i], storage["qmin"]))
            JuMP.set_upper_bound(qs_new[i], min(inj_ub[i], storage["qmax"]))
        end
    end

    report && _IM.sol_component_value(pm, nw, :ne_storage, :qs_new, ids(pm, nw, :ne_storage), qs_new)
end

"do nothing by default but some formulations require this"
function variable_current_ne_storage(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool=true, report::Bool=true)
end


""
function variable_ne_storage_energy(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool=true, report::Bool=true)
    se_new = var(pm, nw)[:se_new] = JuMP.@variable(pm.model,
        [i in ids(pm, nw, :ne_storage)], base_name="$(nw)_se_new"
        #start = comp_start_value(ref(pm, nw, :ne_storage, i), "se_new_start", 1)
    )

    if bounded
        for (i, storage) in ref(pm, nw, :ne_storage)
            JuMP.set_lower_bound(se_new[i], storage["energy_min"])
            JuMP.set_upper_bound(se_new[i], storage["energy_rating"])
        end
    end

    report && _IM.sol_component_value(pm, nw, :ne_storage, :se_new, ids(pm, nw, :ne_storage), se_new)
end

""
function variable_ne_storage_charge(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool=true, report::Bool=true)
    sc_new = var(pm, nw)[:sc_new] = JuMP.@variable(pm.model,
        [i in ids(pm, nw, :ne_storage)], base_name="$(nw)_sc_new",
        start = comp_start_value(ref(pm, nw, :ne_storage, i), "sc_new_start", 1)
    )

    if bounded
        for (i, storage) in ref(pm, nw, :ne_storage)
            JuMP.set_lower_bound(sc_new[i], storage["min_charge_rating"])
            JuMP.set_upper_bound(sc_new[i], storage["charge_rating"])
        end
    end

    report && _IM.sol_component_value(pm, nw, :ne_storage, :sc_new, ids(pm, nw, :ne_storage), sc_new)
end

""
function variable_ne_storage_discharge(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool=true, report::Bool=true)
    sd_new = var(pm, nw)[:sd_new] = JuMP.@variable(pm.model,
        [i in ids(pm, nw, :ne_storage)], base_name="$(nw)_sd_new",
        start = comp_start_value(ref(pm, nw, :ne_storage, i), "sd_new_start", 1)
    )

    if bounded
        for (i, storage) in ref(pm, nw, :ne_storage)
            JuMP.set_lower_bound(sd_new[i], storage["min_discharge_rating"])
            JuMP.set_upper_bound(sd_new[i], storage["discharge_rating"])
        end
    end

    report && _IM.sol_component_value(pm, nw, :ne_storage, :sd_new, ids(pm, nw, :ne_storage), sd_new)
end

#_____________________________________________________________________________________________________
#  3. here I add the reactive_power variable used for demand management or load shedding
function variable_qflex_plus(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool=true, report::Bool=true)
    #if bounded
     q_flex_plus=var(pm, nw)[:qflex_plus] = JuMP.@variable(pm.model,
        [i in ids(pm, nw, :load)], base_name="$(nw)_qflex_plus",
        lower_bound = 0,
        upper_bound=ref(pm, nw, :load, i, "qd"),
        start = 0
        )
    #end
    print("this is qflex Variables")
    print(var(pm, nw)[:qflex_plus])

    report && _IM.sol_component_value(pm, nw, :load, :qflex_plus, ids(pm, nw, :load), q_flex_plus)

end


function variable_qflex_minus(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool=true, report::Bool=true)
    #if bounded
    q_flex_minus =  var(pm, nw)[:qflex_minus] = JuMP.@variable(pm.model,
        [i in ids(pm, nw, :load)], base_name="$(nw)_qflex_minus",
        lower_bound = 0,
        upper_bound=ref(pm, nw, :load, i, "qd"),
        start = 0
        )
    #end
    print(var(pm, nw)[:qflex_minus])

    report && _IM.sol_component_value(pm, nw, :load, :qflex_minus, ids(pm, nw, :load), q_flex_minus)

end

function variable_qflex(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool=true, report::Bool=true)
    #if bounded
    q_flex = var(pm, nw)[:q_flex] = JuMP.@variable(pm.model,
        [i in ids(pm, nw, :load)], base_name="$(nw)_qd_flex",
        lower_bound = 0,
        upper_bound = 2*ref(pm, nw, :load, i, "qd"),
        start = ref(pm, nw, :load, i, "qd")
        )
    #end

    report && _IM.sol_component_value(pm, nw, :load, :q_flex, ids(pm, nw, :load),q_flex)

end
