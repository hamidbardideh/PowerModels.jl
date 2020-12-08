function variable_pflex_plus(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool=true, report::Bool=true)
    #if bounded
     p_flex_plus=var(pm, nw)[:pflex_plus] = JuMP.@variable(pm.model,
        [i in ids(pm, nw, :load)], base_name="$(nw)_pflex_plus",
        lower_bound = 0,
        upper_bound=ref(pm, nw, :load, i, "pd"),
        start = 0)
    #end
    print("this is Pflex Variables")
    print(var(pm, nw)[:pflex_plus])

    report && _IM.sol_component_value(pm, nw, :load, :pflex_plus, ids(pm, nw, :load), p_flex_plus)

end


function variable_pflex_minus(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool=true, report::Bool=true)
    #if bounded
    p_flex_minus =  var(pm, nw)[:pflex_minus] = JuMP.@variable(pm.model,
        [i in ids(pm, nw, :load)], base_name="$(nw)_Pflex_minus",
        lower_bound = 0,
        upper_bound=ref(pm, nw, :load, i, "pd"),
        start = 0)
    #end
    print(var(pm, nw)[:pflex_minus])

    report && _IM.sol_component_value(pm, nw, :load, :pflex_minus, ids(pm, nw, :load), p_flex_minus)

end

function variable_pflex(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool=true, report::Bool=true)
    #if bounded
    p_flex = var(pm, nw)[:p_flex] = JuMP.@variable(pm.model,
        [i in ids(pm, nw, :load)], base_name="$(nw)_pd_flex",
        lower_bound = 0,
        upper_bound = 2*ref(pm, nw, :load, i, "pd"),
        start = ref(pm, nw, :load, i, "pd"))
    #end

    report && _IM.sol_component_value(pm, nw, :load, :p_flex, ids(pm, nw, :load),p_flex)

end
