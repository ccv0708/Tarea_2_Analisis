%% =======================================================================
%  Este script:
%    1. Extrae los parámetros equivalentes alpha, R y K de la hoja de datos.
%    2. Define masas y resistencias térmicas.
%    3. Calcula el punto de operación: corriente I0 necesaria para que el
%       bloque llegue a la temperatura objetivo Tb_obj partiendo de 25 °C.
%    4. Linealiza el modelo (Jacobiano analítico) -> espacio de estados.
%    5. Construye la función de transferencia DIRECTAMENTE desde los
%       balances de energía linealizados (sin usar A, B, C, D).
%    6. Analiza la estabilidad (valores propios, Routh, corriente crítica).
%    7. Simula: validación SS/FT/no lineal(/Simscape) y escenarios.
%    8. Exporta todos los resultados a .txt en ./datos para pgfplots.
%
%  Convenciones: temperaturas internas en kelvin; las absolutas se exportan
%  en °C y las desviaciones en K. Tiempo en segundos.
%  Este archivo analitico requiere MATLAB base.
%  Los modelos Simulink/Simscape se entregan como archivos .slx y se
%  ejecutan con ejecutar_simulink.m para reproducir las simulaciones.
%  =======================================================================
clear; clc; close all;

outdir = fullfile(fileparts(mfilename('fullpath')), 'datos');
if ~exist(outdir, 'dir'), mkdir(outdir); end

%% 1. Datos de la hoja de HB TEC1-12706 (columna T_H = 25 °C) 
ds.Th_ref = 25 + 273.15;   % temperatura del lado caliente de referencia [K]
ds.dTmax  = 66;            % salto máximo de temperatura [K]
ds.Imax   = 6.4;           % corriente máxima [A]
ds.Vmax   = 14.4;          % tensión máxima [V]
ds.Qmax   = 50;            % calor máximo bombeado (dT = 0) [W]
ds.R      = 1.98;          % resistencia reportada (medición AC) [ohm]

%% 2. Parámetros termoeléctricos equivalentes
% A partir de las relaciones de máximo desempeño del modelo ideal:
%   Vmax = alpha*Th            ->  alpha = Vmax/Th
%   Imax = alpha*Tc/R,  Tc = Th - dTmax
%   dTmax = alpha^2 Tc^2 /(2 K R)
Tc_ref  = ds.Th_ref - ds.dTmax;                     % [K]
p.alpha = ds.Vmax / ds.Th_ref;                      % [V/K]
p.R     = p.alpha * Tc_ref / ds.Imax;               % [ohm]
p.K     = p.alpha * Tc_ref * ds.Imax / (2*ds.dTmax);% [W/K]

% Comprobaciones contra la hoja de datos
chk.Z        = p.alpha^2/(p.R*p.K);                 % figura de mérito [1/K]
chk.Qmax_mod = p.alpha*ds.Th_ref*ds.Imax-0.5*p.R*ds.Imax^2; % dT=0, Imax [W]
chk.errR     = 100*(p.R - ds.R)/ds.R;               % [%]
chk.errQ     = 100*(chk.Qmax_mod - ds.Qmax)/ds.Qmax;% [%]

fprintf('--- Parámetros equivalentes del módulo ---\n');
fprintf('alpha = %.4f V/K | R = %.3f ohm | K = %.4f W/K | Z = %.2e 1/K\n', ...
        p.alpha, p.R, p.K, chk.Z);
fprintf('R hoja = %.2f ohm (dif. %.1f %%) | Qc(dT=0, I=6.4 A) = %.1f W (dif. %.1f %%)\n', ...
        ds.R, chk.errR, chk.Qmax_mod, chk.errQ);

%% 3. Masas y resistencias térmicas 
p.Tamb = 25 + 273.15;            % temperatura ambiente [K]
rhoAl  = 2700;                   % densidad del aluminio [kg/m^3]
cpAl   = 900;                    % calor específico del aluminio [J/(kg K)]

% Bloque frío de aluminio 40 x 40 x 10 mm (PROVISIONAL: ajustar geometría)
blk.L = 0.040; blk.W = 0.040; blk.H = 0.010;        % [m]
p.mC  = rhoAl*blk.L*blk.W*blk.H;                    % [kg]
p.CC  = p.mC*cpAl;                                  % [J/K]

% Intercambio bloque-ambiente: convección natural sobre cara superior y
% cuatro laterales (la cara inferior está pegada a la celda).
h_nat   = 10;                                       % [W/(m^2 K)]
A_exp   = blk.L*blk.W + 2*(blk.L + blk.W)*blk.H;    % [m^2]
p.RCA   = 1/(h_nat*A_exp);                          % [K/W]

% Disipador Wakefield 910-40-1-23-2-B-0. Masa PROVISIONAL: el peso bruto
% de catálogo (50 g, con empaque y pines) es una cota superior.
p.mH  = 0.035;                                      % [kg]
p.CH  = p.mH*cpAl;                                  % [J/K]

% Resistencia disipador-ambiente: catálogo + contacto (pasta térmica)
R_contacto = 0.10;                                  % [K/W]
RHA.nat    = 8.30 + R_contacto;                     % convección natural
RHA.f200   = 2.01 + R_contacto;                     % ventilador 200 LFM
RHA.f400   = 1.19 + R_contacto;                     % ventilador 400 LFM (nominal)
p.RHA      = RHA.f400;

%% 4. Punto de operación 
% Para corriente constante el equilibrio (f1 = f2 = 0) es LINEAL en
% (Tc0, Th0): se resuelve un sistema 2x2. La corriente para alcanzar la
% temperatura objetivo se obtiene con fzero.
Tb_obj = 5 + 273.15;                                % objetivo del bloque [K]
I0 = fzero(@(I) [1 0]*equilibrio(I, p) - Tb_obj, [0, 2]);
x0 = equilibrio(I0, p);  Tc0 = x0(1);  Th0 = x0(2);
V0 = p.alpha*(Th0 - Tc0) + p.R*I0;                   % tensión del módulo
fprintf('\n--- Punto de operación (ventilador 400 LFM) ---\n');
fprintf('Tb objetivo = %.2f °C -> I0 = %.4f A, Th0 = %.2f °C, V0 = %.2f V, P0 = %.2f W\n', ...
        Tc0-273.15, I0, Th0-273.15, V0, V0*I0);

% Curva estática Tc0(I) para tres disipadores
I_barrido = (0:0.02:6.4)';
Tc_est = zeros(numel(I_barrido), 3);
casosR = [RHA.nat, RHA.f200, RHA.f400];
for k = 1:3
    pk = p; pk.RHA = casosR(k);
    for j = 1:numel(I_barrido)
        xe = equilibrio(I_barrido(j), pk);
        Tc_est(j,k) = xe(1) - 273.15;
    end
end
[Tmin, imin] = min(Tc_est(:,3));
fprintf('Mínima Tb del modelo (400 LFM, barrido 0:0.02:6.4 A): %.2f °C con I = %.2f A\n', Tmin, I_barrido(imin));

%% 5. Linealización a espacio de estados 
gC = 1/p.RCA + p.K + p.alpha*I0;      % conductancia efectiva lado frío [W/K]
gH = p.K + 1/p.RHA - p.alpha*I0;      % conductancia efectiva lado caliente [W/K]
bC = p.alpha*Tc0 - p.R*I0;            % sensibilidad de enfriamiento [W/A]
bH = p.alpha*Th0 + p.R*I0;            % sensibilidad de rechazo [W/A]

A = [ -gC/p.CC,  p.K/p.CC ;
       p.K/p.CH, -gH/p.CH ];
B = [ -bC/p.CC ;  bH/p.CH ];
C = [1 0];  D = 0;

%% 6. Función de transferencia desde los balances físicos 
% Balances linealizados en Laplace (condiciones iniciales nulas):
%   (CC s + gC) dTc - K dTh = -bC dI
%   -K dTc + (CH s + gH) dTh =  bH dI
% Eliminando dTh (Cramer):
%   G(s) = [ -bC (CH s + gH) + K bH ] / [ (CC s + gC)(CH s + gH) - K^2 ]
numG = [ -bC*p.CH, -bC*gH + p.K*bH ];
denG = conv([p.CC, gC], [p.CH, gH]) - [0, 0, p.K^2];
numG = numG/denG(1);  denG = denG/denG(1);       % forma mónica
Kdc  = numG(end)/denG(end);                       % G(0) [K/A]
fprintf('\n--- Función de transferencia G(s) = dTc/dI ---\n');
fprintf('G(s) = (%.4f s %+.6f) / (s^2 %+.5f s %+.7f)\n', numG, denG(2:3));

% Verificación (solo comprobación, NO forma parte de la derivación):
% ganancia DC -C*inv(A)*B y valores propios de A contra la FT.
err_tf = abs(Kdc - (-C*(A\B))) + max(abs(sort(roots(denG)) - sort(eig(A))));
fprintf('Verificación FT vs SS: error ganancia DC = %.2e K/A; error polos = %.2e 1/s\n', ...
        abs(Kdc - (-C*(A\B))), max(abs(sort(roots(denG)) - sort(eig(A)))));


%% 7. Estabilidad 
% Polinomio característico s^2 + a1 s + a0, con
%   a1 = gC/CC + gH/CH,   a0 = (gC gH - K^2)/(CC CH)
% Routh (2.º orden): estable <=> a1 > 0 y a0 > 0.
a1 = gC/p.CC + gH/p.CH;
a0 = (gC*gH - p.K^2)/(p.CC*p.CH);
polos = roots([1 a1 a0]);
fprintf('\n--- Estabilidad en I0 ---\n');
fprintf('a1 = %.4e 1/s, a0 = %.4e 1/s^2\n', a1, a0);
fprintf('Polos: %.5f y %.5f 1/s -> tau = %.1f s y %.1f s\n', polos, -1./polos);
fprintf('Ganancia DC = %.3f K/A\n', Kdc);

% Corriente crítica: a0 = 0  <=>  (G1 + alpha I)(G2 - alpha I) = K^2
I_crit = @(RHAk) corriente_critica(p, RHAk);
Icr = [I_crit(RHA.nat), I_crit(RHA.f200), I_crit(RHA.f400)];
fprintf('Corriente crítica: natural %.2f A | 200 LFM %.2f A | 400 LFM %.2f A\n', Icr);

% Polos en función de I (para la tabla del informe)
I_tab = [0; 1; I0; 2; 4; 6.4];
fprintf('\n   I [A]   polo1 [1/s]   polo2 [1/s]   (400 LFM)\n');
for j = 1:numel(I_tab)
    Aj = jacobiano(I_tab(j), p);
    ev = sort(eig(Aj), 'descend');
    fprintf('  %5.2f   %10.5f   %10.5f\n', I_tab(j), ev);
end

%% 8. Simulaciones
opts = odeset('RelTol', 1e-9, 'AbsTol', 1e-9);
t = (0:2:900)';                                   % malla común [s]

% 8.1 Validación: escalón pequeño dI = +0.1 A desde el equilibrio
dI = 0.1;
y_ss = resp_ss(A, B, C, [0; 0], dI, t);          % espacio de estados
y_tf = resp_ft_escalon(numG, denG, dI, t);       % función de transferencia
[~, Xnl] = ode45(@(tt,x) peltier_nl(x, I0 + dI, p), t, [Tc0; Th0], opts);
y_nl = Xnl(:,1) - Tc0;
fprintf('\nValidación: max|SS-FT| = %.2e K, max|SS-NL| = %.2e K\n', ...
        max(abs(y_ss - y_tf)), max(abs(y_ss - y_nl)));
exportar(fullfile(outdir,'validacion.txt'), ...
    {'t','dTc_ss','dTc_tf','dTc_nl'}, [t, y_ss, y_tf, y_nl]);

% 8.2 Escenario 1: arranque desde 25 °C con I = I0 (ventilador 400 LFM)
t1 = (0:2:1200)';
[~, X1] = ode45(@(tt,x) peltier_nl(x, I0, p), t1, [p.Tamb; p.Tamb], opts);
% Modelo lineal con condición inicial de desviación y dI = 0
yl1 = resp_ss(A, B, C, [p.Tamb - Tc0; p.Tamb - Th0], 0, t1);
exportar(fullfile(outdir,'esc1_arranque.txt'), {'t','Tc','Th','Tc_lin'}, ...
    [t1, X1(:,1)-273.15, X1(:,2)-273.15, yl1+Tc0-273.15]);
i90 = find(X1(:,1) <= p.Tamb - 0.9*(p.Tamb - Tc0), 1);
fprintf('Escenario 1: Tb llega al 90 %% del cambio en %.0f s\n', t1(i90));

% 8.3 Escenario 2: misma I0 con disipador en convección natural
pn = p; pn.RHA = RHA.nat;
[~, X2] = ode45(@(tt,x) peltier_nl(x, I0, pn), t1, [p.Tamb; p.Tamb], opts);
xe2 = equilibrio(I0, pn);
fprintf('Escenario 2 (natural), EQUILIBRIO: Tc = %.2f °C, Th = %.2f °C\n', xe2 - 273.15);
fprintf('Escenario 2 (natural), a %.0f s: Tc = %.2f °C, Th = %.2f °C\n', ...
        t1(end), X2(end,:) - 273.15);
exportar(fullfile(outdir,'esc2_disipador.txt'), ...
    {'t','Tc_f400','Th_f400','Tc_nat','Th_nat'}, ...
    [t1, X1-273.15, X2-273.15]);

% 8.4 Escenario 3: escalones grandes de corriente (validez del modelo lineal)
dIs = [-1.0, 1.0];
M3 = t;  cab3 = {'t'};
for k = 1:numel(dIs)
    [~, Xk] = ode45(@(tt,x) peltier_nl(x, I0 + dIs(k), p), t, [Tc0; Th0], opts);
    ylin = resp_ss(A, B, C, [0; 0], dIs(k), t);
    M3 = [M3, Xk(:,1) - Tc0, ylin]; %#ok<AGROW>
    tag = sprintf('%s%02d', ternario(dIs(k) < 0, 'm', 'p'), round(10*abs(dIs(k))));
    cab3 = [cab3, {['nl_' tag], ['lin_' tag]}]; %#ok<AGROW>
    fprintf('Escenario 3, dI = %+.1f A: dTc a 900 s NL = %.2f K, lineal = %.2f K\n', ...
            dIs(k), Xk(end,1) - Tc0, ylin(end));
end
exportar(fullfile(outdir,'esc3_escalones.txt'), cab3, M3);

% Curva estática
exportar(fullfile(outdir,'estatica.txt'), {'I','Tc_nat','Tc_f200','Tc_f400'}, ...
    [I_barrido, Tc_est]);

%% 8.5 Validacion con Simscape
% ejecutar_simulink.m reproduce las simulaciones de los modelos .slx incluidos.
% Este script calcula y exporta los datos analiticos de referencia.

% Resumen numérico para el informe
fid = fopen(fullfile(outdir,'resumen.txt'), 'w');
fprintf(fid, 'alpha %.6f\nR %.6f\nK %.6f\nZ %.6e\nCC %.4f\nCH %.4f\nRCA %.4f\nRHA %.4f\n', ...
        p.alpha, p.R, p.K, chk.Z, p.CC, p.CH, p.RCA, p.RHA);
fprintf(fid, 'I0 %.6f\nTc0_C %.4f\nTh0_C %.4f\nV0 %.4f\n', I0, Tc0-273.15, Th0-273.15, V0);
fprintf(fid, 'a1 %.6e\na0 %.6e\np1 %.6f\np2 %.6f\nKdc %.6f\n', a1, a0, polos, Kdc);
fprintf(fid, 'Icrit_nat %.4f\nIcrit_f200 %.4f\nIcrit_f400 %.4f\n', Icr);
fprintf(fid, 'num %.6e %.6e\nden %.6e %.6e %.6e\n', numG, denG);
fclose(fid);
fprintf('\nDatos exportados en %s\n', outdir);
% Parametros para construir modelos sin depender del base workspace.
save(fullfile(fileparts(mfilename('fullpath')),'parametros.mat'), ...
    'p','I0','Tc0','Th0','A','B','C','D','numG','denG');
informe_datos=fullfile(fileparts(mfilename('fullpath')),'..','informe','datos');
if isfolder(informe_datos), copyfile(fullfile(outdir,'*.txt'),informe_datos); end
fprintf('Datos analiticos actualizados. Use ejecutar_simulink.m para reproducir las simulaciones.\n');

%% =======================================================================
%  Funciones locales
%  =======================================================================
function dx = peltier_nl(x, I, p)
% Modelo no lineal: x = [Tc; Th] en K, I en A.
Tc = x(1); Th = x(2);
Qc    = p.alpha*Tc*I - 0.5*I^2*p.R - p.K*(Th - Tc);   % calor absorbido
Qh    = p.alpha*Th*I + 0.5*I^2*p.R - p.K*(Th - Tc);   % calor rechazado
Qload = (p.Tamb - Tc)/p.RCA;                          % ambiente -> bloque
Qdiss = (Th - p.Tamb)/p.RHA;                          % disipador -> ambiente
dx = [ (Qload - Qc)/p.CC ;
       (Qh - Qdiss)/p.CH ];
end

function x0 = equilibrio(I, p)
% Equilibrio para corriente constante: sistema lineal 2x2 en (Tc0, Th0).
M = [ -(1/p.RCA + p.K + p.alpha*I),  p.K ;
       p.K,  -(p.K + 1/p.RHA - p.alpha*I) ];
b = [ -p.Tamb/p.RCA - 0.5*I^2*p.R ;
      -p.Tamb/p.RHA - 0.5*I^2*p.R ];
x0 = M \ b;
end

function A = jacobiano(I, p)
% Matriz A del modelo linealizado (solo depende de I0).
A = [ -(1/p.RCA + p.K + p.alpha*I)/p.CC,  p.K/p.CC ;
       p.K/p.CH,  -(p.K + 1/p.RHA - p.alpha*I)/p.CH ];
end

function Ic = corriente_critica(p, RHAk)
% Raíz positiva de (G1 + alpha I)(G2 - alpha I) - K^2 = 0.
G1 = 1/p.RCA + p.K;  G2 = p.K + 1/RHAk;
Ic = ((G2 - G1) + sqrt((G2 - G1)^2 + 4*(G1*G2 - p.K^2))) / (2*p.alpha);
end

function y = resp_ss(A, B, C, x0, du, t)
% Respuesta exacta del modelo lineal dx/dt = A x + B du (du constante) con
% condición inicial x0, usando la matriz de transición expm(A t):
%   x(t) = e^{At} x0 + A^{-1}(e^{At} - I) B du
y = zeros(numel(t), 1);
for k = 1:numel(t)
    Phi  = expm(A*t(k));
    x    = Phi*x0 + A\((Phi - eye(size(A)))*B*du);
    y(k) = C*x;
end
end

function y = resp_ft_escalon(num, den, du, t)
% Respuesta al escalón de amplitud du de G(s) = num/den, invirtiendo
% Laplace por fracciones parciales: Y(s) = G(s) du / s.
[r, pl, kd] = residue(du*num, [den, 0]);
y = real(exp(t(:)*pl.') * r);
if ~isempty(kd), y = y + kd(end)*(t(:) == 0); end
end

function exportar(archivo, cabecera, M)
% Escribe una tabla con cabecera separada por espacios (lectura con pgfplots).
fid = fopen(archivo, 'w');
assert(fid>=0,'No se puede escribir %s.',archivo);
fprintf(fid, '%s ', cabecera{1:end-1}); fprintf(fid, '%s\n', cabecera{end});
fmt = [repmat('%.6e ', 1, size(M,2)-1), '%.6e\n'];
fprintf(fid, fmt, M.');
fclose(fid);
end

function r = ternario(c, a, b)
if c, r = a; else, r = b; end
end
