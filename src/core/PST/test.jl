result_DCOPF_pst_inv = run_opst_DC_investment(file_pst, DCPPowerModel, gurobi; setting = s)
result_DCOPF_pst_inv["solution"]["pst_ne"]["7"]
result_DCOPF_pst_inv["solution"]["pst_ne"]["14"]
result_DCOPF_pst_inv["solution"]["gen"]["5"]
result_DCOPF_pst_inv["solution"]["branch"]["7"]
result_DCOPF_pst_inv["solution"]["branch"]["7"]
result_DCOPF_pst_inv["solution"]["bus"]["1"]
result_DCOPF_pst_inv["solution"]["bus"]["10"]
result_DCOPF_pst_inv["solution"]["bus"]["4"]

result_DCOPF_pst_inv["solution"]["bus"]["2"]
result_DCOPF_pst_inv["solution"]["bus"]["3"]
result_DCOPF_pst_inv["solution"]["bus"]["6"]
result_DCOPF_pst_inv["solution"]["branch"]["1"]
result_DCOPF_pst_inv["solution"]["branch"]["4"]
result_DCOPF_pst_inv["solution"]["branch"]["5"]

result_DCOPF_pst_inv["solution"]["branch"]["7"]
# all the angles became zero?!!!! and it basically build the minimum PSTs to feed the load.




result_DCOPF_pst = run_opst_DC(file_pst, DCPPowerModel, gurobi; setting = s)
result_DCOPF_pst["solution"]["pst_ne"]["7"]
result_DCOPF_pst["solution"]["pst_ne"]["14"]
result_DCOPF_pst["solution"]["gen"]["5"]
result_DCOPF_pst["solution"]["branch"]["7"]
result_DCOPF_pst["solution"]["branch"]["7"]
result_DCOPF_pst["solution"]["bus"]["1"]
result_DCOPF_pst["solution"]["bus"]["10"]
result_DCOPF_pst["solution"]["bus"]["4"]

result_DCOPF_pst["solution"]["bus"]["2"]
result_DCOPF_pst["solution"]["bus"]["3"]
result_DCOPF_pst["solution"]["bus"]["6"]
result_DCOPF_pst["solution"]["branch"]["1"]
result_DCOPF_pst["solution"]["branch"]["4"]
result_DCOPF_pst["solution"]["branch"]["5"]

result_DCOPF_pst_inv["solution"]["branch"]["7"]




#If we have no PST-ne except 1 !
