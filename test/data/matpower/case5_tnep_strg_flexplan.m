% tests extra data needed for tnep_fx_mn problems

function mpc = case5_tnep
mpc.version = '2';
mpc.baseMVA = 100.0;

%% bus data
%	bus_i	type	Pd	Qd	Gs	Bs	area	Vm	Va	baseKV	zone	Vmax	Vmin
mpc.bus = [
	1	 2	 0.0	 0.0	 0.0	 0.0	 1	    1.07762	    2.80377	 230.0	 1	    1.10000	    0.90000;
	2	 1	 500.0	 98.61	 0.0	 0.0	 1	    1.08407	   -0.73465	 230.0	 1	    1.10000	    0.90000;
	3	 2	 400.0	 98.61	 0.0	 0.0	 1	    1.10000	   -0.55972	 230.0	 1	    1.10000	    0.90000;
	4	 3	 600.0	 131.47	 0.0	 0.0	 1	    1.06414	    0.00000	 230.0	 1	    1.10000	    0.90000;
	5	 2	 0.0	 0.0	 0.0	 0.0	 1	    1.06907	    3.59033	 230.0	 1	    1.10000	    0.90000;
];

%% generator data
%	bus	Pg	Qg	Qmax	Qmin	Vg	mBase	status	Pmax	Pmin
mpc.gen = [
	1	 40.0	 30.0	 30.0	 -30.0	 1.07762	 100.0	 1	 40.0	 0.0;
	1	 170.0	 127.5	 127.5	 -127.5	 1.07762	 100.0	 1	 170.0	 0.0;
	3	 324.498	 390.0	 390.0	 -390.0	 1.1	 100.0	 1	 520.0	 0.0;
	4	 0.0	 -10.802	 150.0	 -150.0	 1.06414	 100.0	 1	 200.0	 0.0;
	5	 470.694	 -165.039	 450.0	 -450.0	 1.06907	 100.0	 1	 600.0	 0.0;
];

%% generator cost data
%	2	startup	shutdown	n	c(n-1)	...	c0
mpc.gencost = [
	2	 0.0	 0.0	 3	   0.000000	  14.000000	   0.000000;
	2	 0.0	 0.0	 3	   0.000000	  15.000000	   0.000000;
	2	 0.0	 0.0	 3	   0.000000	  30.000000	   0.000000;
	2	 0.0	 0.0	 3	   0.000000	  40.000000	   0.000000;
	2	 0.0	 0.0	 3	   0.000000	  10.000000	   0.000000;
];

%% branch data
%	fbus	tbus	r	x	b	rateA	rateB	rateC	ratio	angle	status	angmin	angmax
mpc.branch = [
%	1	 2	 0.00281	 0.0281	 0.00712	 400.0	 400.0	 400.0	 0.0	 0.0	 1	 -30.0	 30.0;
%	1	 4	 0.00304	 0.0304	 0.00658	 426	 426	 426	 0.0	 0.0	 1	 -30.0	 30.0;
	1	 5	 0.00064	 0.0064	 0.03126	 426	 426	 426	 0.0	 0.0	 1	 -30.0	 30.0;
	2	 3	 0.00108	 0.0108	 0.01852	 426	 426	 426	 0.0	 0.0	 1	 -30.0	 30.0;
	3	 4	 0.00297	 0.0297	 0.00674	 426	 426	 426	 1.05	 1.0	 1	 -30.0	 30.0;
	4	 5	 0.00297	 0.0297	 0.00674	 240.0	 240.0	 240.0	 0.0	 0.0	 1	 -30.0	 30.0;
];

%column_names%	f_bus	t_bus	br_r	br_x	br_b	rate_a	rate_b	rate_c	tap	shift	br_status	angmin	angmax	construction_cost
mpc.ne_branch = [
	1	 2	 0.00281	 0.0281	 0.00712	 300.0	 300.0	 300.0	 0.0	 0.0	 1	 -30.0	 30.0	 102.75;
	1	 4	 0.00304	 0.0304	 0.00658	 426	 426	 426	 0.0	 0.0	 1	 -30.0	 30.0	 128.25;
	1	 4	 0.00304	 0.0304	 0.00658	 1.0	 1.0	 1.0	 0.0	 0.0	 1	 -30.0	 30.0	 128.25;
];

%% dcline data
%	fbus	tbus	status	Pf	Pt	Qf	Qt	Vf	Vt	Pmin	Pmax	QminF	QmaxF	QminT	QmaxT	loss0	loss1
mpc.dcline = [
	3	5	1	10	8.9	99.9934	-10.4049	1.1	1.05304	10	100 	-100	100	-100 100	1	0.01;
];

%% dcline cost data
%	2	startup	shutdown	n	c(n-1)	...	c0
mpc.dclinecost = [
	2	 0.0	 0.0	 3	   0.000000	  40.000000	   0.000000;
];






% hours
mpc.time_elapsed = 1.0


%% storage data
%   storage_bus ps qs energy  energy_rating charge_rating  discharge_rating  charge_efficiency  discharge_efficiency  thermal_rating  qmin  qmax  r  x  p_loss  q_loss  status
	 3	 0.0	 0.0	 20.0	 100.0	 50.0	 70.0	 0.8	 0.9	 100000.0	 -50000.0	 7000000.0	 0.1	 0.0	 0.0	 0.0	 0;
];



%% new storage data
%column_names%   storage_bus ps qs energy  energy_rating charge_rating  discharge_rating  charge_efficiency  discharge_efficiency  thermal_rating  qmin  qmax  r  x  p_loss  q_loss  status                 energy_min 		min_charge_rating 	min_discharge_rating    ext_inj_energy   lost_wasted_energy   construction_cost
mpc.ne_storage = [
	 2	 0.0	 0.0	 0.15	 0.6	 0.6	 0.6	 0.8	 0.9	 1	 -0.5	 0.7	 0.1	 0.0	 0.0	 0.0	 1	  				0.1		0.0		0.0	   	0.0		0.0		102.75;
	 4	 0.0	 0.0	 0.15	 0.6	 0.6	 0.6	 0.9	 0.8	 1	 -0.5	 0.7	 0.1	 0.0	 0.0	 0.0	 1						0.1		0.0		0.0			0.0		0.0		102.75;
];





%% extra storage info
%column_names%    storage_bus		status		energy_min 		min_charge_rating 	min_discharge_rating    ext_inj_energy   lost_wasted_energy
%mpc.extra_strg = [
%	 3	1.0		0.0		0.0		0.0		0.0		0.0;
%];
