%% Input values EA, L, type of load, type of boundary condition
EA = input('Section Stiffness (EA) (in kN) = ');
L = input('Length (L) (in m) = ');

load_type = input('Load Type (1 = Constant, 2 = Linear Ramp up, 3 = Linear Ramp Down, 4 = Trapezoidal, 5 = Half Sinusoidal, 6 = Load on a patch) = ');
switch load_type
    case 1
        P = input('Load (in kN/m) = ');
    case 2
        P = input('Max. Load (i.e. at highest point) (in kN/m) = ');
    case 3
        P = input('Max. Load (i.e. at highest point) (in kN/m)= ');
    case 4
        P = input('Max. Load (in kN/m) = ');
        q = input('Fraction of length over which max. load occurs (between 0 and 1) = ');
    case 5
        P = input('Max. Load (in kN/m) = ');
    case 6
        P = input('Load (in kN/m) = ');
        a = input('Start of patch as a fraction of length (0 to 1) = ');
        b = input('End of patch as a fraction of length (0 to 1, should be > start of patch) = ');
end

bc_type = input('Boundary Condition Type (1 = Fixed at both ends, 2 = Fixed at left end only, 3 = Fixed at right end only) = ');


%% Input Simpson's Rule and GTR parameters
simpsonNPTS = input('No. of points for Simpson''s rule = ');
gtrNPTS = input('No. of points for GTR = ');
beta = input('Parameter beta for GTR (between 0 and 1) = ');

%% Call Simpson() to calculate z = [I_0; I_1]
switch load_type
    case 1
        z = Simpson(L, load_type, simpsonNPTS);
    case 2
        z = Simpson(L, load_type, simpsonNPTS);
    case 3
        z = Simpson(L, load_type, simpsonNPTS);
    case 4
        z = Simpson(L, load_type, simpsonNPTS, q);
    case 5
        z = Simpson(L, load_type, simpsonNPTS);
    case 6
        z = Simpson(L, load_type, simpsonNPTS, a, b);
end
z(1) = z(1) * P;
z(2) = z(2) * P/EA;
        
%% make boundary condition array
% BC = [N_0; u_0; N_L; u_L] 
BC = [1; 1; 1; 1];
switch bc_type
    case 1
        BC(2) = 0;
        BC(4) = 0;
    case 2 
        BC(2) = 0;
        BC(3) = 0;
    case 3
        BC(1) = 0;
        BC(4) = 0;
end

%% compute full system 2*4 matrix
d = L/EA;
B = [1 0 -1 0; d 1 0 -1];

%% get reduced system matrix
C = B(:, BC == 1);

%% solve for unknowns
s = C\z;
% get array of solved bcs.
% index = 1;
% for i = 1:4
%     if BC(i) == 1
%         BC(i) = s(index);
%     end
%     index = index + 1;
% end 
% alternate method
f = [0; 0; 0; 0];
f(BC == 1) = s;

%% for debugging
f;

%% Initialize N and u vector
N = zeros(1, gtrNPTS);
u = zeros(1, gtrNPTS);
N(1) = f(1);
u(1) = f(2);

%% use GTR to populate N and u vectors
h = L/(gtrNPTS - 1);
for i = 2:gtrNPTS
    x = L * (i - 1)/(gtrNPTS - 1);
    
    switch load_type
        case 1
            N(i) = N(i-1) - (h * (beta * P*LoadFunctionCP(x, L, load_type) + (1 - beta) * P*LoadFunctionCP(x+h, L, load_type)));
        case 2
            N(i) = N(i-1) - (h * (beta * P*LoadFunctionCP(x, L, load_type) + (1 - beta) * P*LoadFunctionCP(x+h, L, load_type)));
        case 3
            N(i) = N(i-1) - (h * (beta * P*LoadFunctionCP(x, L, load_type) + (1 - beta) * P*LoadFunctionCP(x+h, L, load_type)));
        case 4
            N(i) = N(i-1) - (h * (beta * P*LoadFunctionCP(x, L, load_type, q) + (1 - beta) * P*LoadFunctionCP(x+h, L, load_type, q)));
        case 5
            N(i) = N(i-1) - (h * (beta * P*LoadFunctionCP(x, L, load_type) + (1 - beta) * P*LoadFunctionCP(x+h, L, load_type)));
        case 6
            N(i) = N(i-1) - (h * (beta * P*LoadFunctionCP(x, L, load_type, a, b) + (1 - beta) * P*LoadFunctionCP(x+h, L, load_type, a, b)));
    end
    
    u(i) = u(i-1) + ((h/EA) * (beta * N(i-1) + (1 - beta) * N(i)));
end

%% plot state diagrams
subplot(2,2,1) 
x = 0:h:L;
Load = zeros(1, gtrNPTS);
for i = 1:gtrNPTS
    switch load_type
        case 1
            Load(i) = P * LoadFunctionCP(x(i), L, load_type);
        case 2
            Load(i) = P * LoadFunctionCP(x(i), L, load_type);
        case 3
            Load(i) = P * LoadFunctionCP(x(i), L, load_type);
        case 4
            Load(i) = P * LoadFunctionCP(x(i), L, load_type, q);
        case 5
            Load(i) = P * LoadFunctionCP(x(i), L, load_type);
        case 6
            Load(i) = P * LoadFunctionCP(x(i), L, load_type, a, b);
    end    
end

area(x, Load, 'FaceColor', [1, 0, 0])
xlabel('Position (m)')
ylabel('Load (kN/m)')
title('Load vs. Position') 

subplot(2,2,2) 
area(x, N, 'FaceColor', [0, 1, 0])
xlabel('Position (m)')
ylabel('Axial Force (kN)')
title('Axial Force vs. Position')

subplot(2,2,3)
area(x, u, 'FaceColor', [0, 0, 1])
xlabel('Position (m)')
ylabel('Displacement (m)')
title('Displacement vs. Position')





