"Build multinetwork branch flow storage OPF"
function build_mn_Strg(pm::AbstractPowerModel)
    for (n, network) in nws(pm)
        variable_voltage(pm, nw=n)
        variable_generation(pm, nw=n)
        variable_storage_mi(pm, nw=n)
        variable_branch_flow(pm, nw=n)
        variable_branch_current(pm, nw=n)
        variable_dcline_flow(pm, nw=n)

        constraint_model_current(pm, nw=n)

        for i in ids(pm, :ref_buses, nw=n)
            constraint_theta_ref(pm, i, nw=n)
        end

        for i in ids(pm, :bus, nw=n)
            constraint_power_balance(pm, i, nw=n)
        end

        for i in ids(pm, :storage, nw=n)
            constraint_storage_complementarity_mi(pm, i, nw=n)
            constraint_storage_loss(pm, i, nw=n)
            constraint_storage_thermal_limit(pm, i, nw=n)
        end

        for i in ids(pm, :branch, nw=n)
            constraint_flow_losses(pm, i, nw=n)
            constraint_voltage_magnitude_difference(pm, i, nw=n)

            constraint_voltage_angle_difference(pm, i, nw=n)

            constraint_thermal_limit_from(pm, i, nw=n)
            constraint_thermal_limit_to(pm, i, nw=n)
        end

        for i in ids(pm, :dcline, nw=n)
            constraint_dcline(pm, i, nw=n)
        end
    end

    network_ids = sort(collect(nw_ids(pm)))

    n_1 = network_ids[1]
    for i in ids(pm, :storage, nw=n_1)
        constraint_storage_state(pm, i, nw=n_1)
    end

    for n_2 in network_ids[2:end]
        for i in ids(pm, :storage, nw=n_2)
            constraint_storage_state(pm, i, n_1, n_2)
        end
        n_1 = n_2
    end

    objective_min_fuel_and_flow_cost(pm)
end
