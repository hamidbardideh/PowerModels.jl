function get_pu_bases(MVAbase, kVbase)
    eurobase = 1 #
    hourbase = 1 #

    Sbase = MVAbase * 1e6
    Vbase = kVbase  * 1e3
    #Zbase = (Vbase)^2 / (Sbase) # TODO
    kAbase = MVAbase / (sqrt(3) * kVbase)
    Zbase = 1/(kAbase^2 / MVAbase)
    Ibase = (Sbase)   / (Vbase)
    timebase = hourbase*3600
    Ebase = Sbase * timebase

    bases = Dict{String, Any}(
    "Z" => Zbase,         # Impedance (Ω)
    "I" => Ibase,         # Current (A)
    "€" => eurobase,      # Currency (€)
    "t" => timebase,      # Time (s)
    "S" => Sbase,         # Power (W)
    "V" => Vbase,         # Voltage (V)
    "E" => Ebase          # Energy (J)
    )
    return bases
end

function process_additional_data!(data)
    to_pu!(data)
end

function is_single_network(data)
    return !haskey(data, "multinetwork") || data["multinetwork"] == false
end

function to_pu!(data)
    if is_single_network(data)
        to_pu_single_network!(data)
    else
        to_pu_multinetwork!(data)
    end
end

function to_pu_single_network!(data)
    MVAbase = data["baseMVA"]
    if haskey(data, "ne_storage")
        for (i, strg) in data["ne_storage"]
            set_ne_storage_pu_power(strg, MVAbase)

        end
    end

end

function to_pu_multinetwork!(data)
    for (n, network) in data["nw"]
        MVAbase = network["baseMVA"]
        if haskey(data["nw"][n], "ne_storage")
            for (i, strg) in data["nw"][n]["ne_storage"]
                set_ne_storage_pu_power(strg, MVAbase)

            end
        end

    end

end

function set_ne_storage_pu_power(ne_storage, MVAbase)
    # MVAbase = data["baseMVA"]

    rescale        = x -> x/MVAbase

    _apply_func!(ne_storage, "ps", rescale)
    _apply_func!(ne_storage, "qs", rescale)
    _apply_func!(ne_storage, "energy", rescale)
    _apply_func!(ne_storage, "energy_rating", rescale)
    _apply_func!(ne_storage, "charge_rating", rescale)
    _apply_func!(ne_storage, "discharge_rating", rescale)
    _apply_func!(ne_storage, "thermal_rating", rescale)
    _apply_func!(ne_storage, "qmin", rescale)
    _apply_func!(ne_storage, "qmax", rescale)
    _apply_func!(ne_storage, "p_loss", rescale)
    _apply_func!(ne_storage, "q_loss", rescale)
    _apply_func!(ne_storage, "min_charge_rating", rescale)
    _apply_func!(ne_storage, "min_discharge_rating", rescale)
    _apply_func!(ne_storage, "ext_inj_energy", rescale)
    _apply_func!(ne_storage, "lost_wasted_energy", rescale)
end
