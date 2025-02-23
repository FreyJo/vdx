clear all
close all
%%
import casadi.*
import vdx.*

T = 1;
R = 0.5;
R_obj = 5;
%% Define projected system
x1 = SX.sym('x1', 2);
x2 = SX.sym('x2', 3);
theta = x2(3);
R_matrix = [cos(theta) -sin(theta);...
           sin(theta) cos(theta)];
x = [x1;x2];
data.x = x;
data.lbx = [-inf;-inf;-inf;-inf;-inf];
data.ubx = [inf;inf;inf;inf;inf];
data.x0 = [-10;0;0;0;-pi/8];
x_target = [-10;0;0;-10;pi/9]; 
u1 = SX.sym('u1', 2);
data.u = [u1];
data.lbu = [-100/sqrt(2);-100/sqrt(2)];
data.ubu = [100/sqrt(2);100/sqrt(2)];
data.u0 = [0;0];
p = 4;
data.c = [sum((R_matrix*(x1-x2(1:2))).^p)-(R+R_obj)^p];
data.f_x = [u1;0;0;0];

% costs
data.f_q = 1e0*norm_2(data.u)^2 + (x-x_target)'*diag([0,0,1,1,1])*(x-x_target);
data.f_q_T = (x-x_target)'*diag([1e-6,1e-6,1e3,1e3,1e3])*(x-x_target);

data.T = T;
data.N_stages = 25;
data.N_fe = 3;
data.n_s = 2;
data.irk_scheme = 'radau';

opts = struct();
%opts.elastic_ell_inf = 1;

prob = InclusionProblem(data, opts);

prob.generate_constraints();

%% create solver
default_tol = 1e-6;

%opts_casadi_nlp.ipopt.print_level = 1;
opts_casadi_nlp.print_time = 0;
opts_casadi_nlp.ipopt.sb = 'yes';
opts_casadi_nlp.verbose = false;
opts_casadi_nlp.ipopt.max_iter = 50000;
opts_casadi_nlp.ipopt.bound_relax_factor = 0;
%opts_casadi_nlp.ipopt.bound_relax_factor = 1e-8;
%opts_casadi_nlp.ipopt.honor_original_bounds = 'yes';
opts_casadi_nlp.ipopt.tol = default_tol;
opts_casadi_nlp.ipopt.dual_inf_tol = default_tol;
opts_casadi_nlp.ipopt.dual_inf_tol = default_tol;
opts_casadi_nlp.ipopt.compl_inf_tol = default_tol;
opts_casadi_nlp.ipopt.acceptable_tol = 1e-6;
opts_casadi_nlp.ipopt.mu_strategy = 'adaptive';
opts_casadi_nlp.ipopt.mu_oracle = 'quality-function';
opts_casadi_nlp.ipopt.warm_start_init_point = 'yes';
opts_casadi_nlp.ipopt.warm_start_entire_iterate = 'yes';
opts_casadi_nlp.ipopt.linear_solver = 'ma27';
prob.create_solver(opts_casadi_nlp);

%% Do homotopy
prob.w.x(0,0,data.n_s).init = data.x0;
prob.w.x(0,0,data.n_s).lb = data.x0;
prob.w.x(0,0,data.n_s).ub = data.x0;
homotopy(prob,100,1e-6);
%% plot
x_res = prob.w.x(0:data.N_stages,0:data.N_fe,data.n_s).res;
u_res = prob.w.u(1:data.N_stages).res;
h_res = prob.w.h(:).res;
t_res = [0,cumsum(h_res)];
plot_discs(h_res,x_res,[R,R_obj], ["circle", "square"])
