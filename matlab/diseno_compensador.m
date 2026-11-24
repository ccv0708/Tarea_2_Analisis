% análisis del control P, especificaciones y diseño del PI
%
% Planta: celda Peltier TEC1-12706
% entrada = corriente I [A]
% salida  = temperatura del bloque frío Tb [C]
% Punto de operación: Tb = 5 C, I0 = 1.19 A, ventilador de 400 LFM
%
% Tiene que estar parametros.mat (sale de peltier_modelo.m)
% Tiene que estar datos/estatica.txt (de la Tarea 1)
% Se necesita el Control System Toolbox

clear; clc; close all;

load('parametros.mat')   % p, I0, Tc0, Th0, numG, denG, etc.

if ~exist('figuras_diseno', 'dir')
    mkdir('figuras_diseno');
end

s = tf('s');
t = 0:0.5:1500;   % tiempo para las simulaciones [s]


%% 1. Planta de la Tarea 1
G = tf(numG, denG);
disp('Planta G(s) = Tb/I:')
G

polos_G = pole(G);
cero_G = zero(G);
K_G = dcgain(G);
disp(['Polos de G: ' num2str(polos_G(1)) ' y ' num2str(polos_G(2)) ' 1/s'])
disp(['Cero de G: ' num2str(cero_G) ' 1/s'])
disp(['Ganancia en DC: ' num2str(K_G) ' K/A'])

% La ganancia es negativa: más corriente enfria el bloque.
% Para trabajar con números positivos usamos Gp = -G
% y el error se calcula como e = Tb - Tref.
Gp = -G;

% Tiempo de asentamiento en lazo abierto (para comparar)
info_LA = stepinfo(Gp);
disp(['ts en lazo abierto = ' num2str(info_LA.SettlingTime) ' s'])

% Perturbaciones. Salen de los mismos balances de la Tarea 1.
% 1) Temperatura ambiente Tamb (entra al bloque por RCA y al disipador por RHA)
% 2) Carga de calor Q en el bloque, por ejemplo al meter una muestra
%    (es la misma prueba de 2 W que usa el integrante 1)
gC = 1/p.RCA + p.K + p.alpha*I0;
gH = p.K + 1/p.RHA - p.alpha*I0;
den_Gd = (p.CC*s + gC)*(p.CH*s + gH) - p.K^2;
Gd = ((p.CH*s + gH)/p.RCA + p.K/p.RHA) / den_Gd;   % de Tamb a Tb [K/K]
Gq = (p.CH*s + gH) / den_Gd;                         % de Q a Tb [K/W]
disp(['Ganancia DC de Tamb a Tb = ' num2str(dcgain(Gd)) ' K/K'])
disp(['Ganancia DC de Q a Tb = ' num2str(dcgain(Gq)) ' K/W'])


%% 2. Límite de corriente
% En la Tarea 1 la curva Tb(I) tiene un mínimo. Después de ese punto más
% corriente CALIENTA el bloque, entonces no se puede usar 6.4 A como límite.
datos_est = readmatrix('datos/estatica.txt');
I_est = datos_est(:,1);
Tb_est = datos_est(:,4);     % columna de 400 LFM

Tb_min = Tb_est(1);
I_optima = I_est(1);
for i = 1:length(Tb_est)
    if Tb_est(i) < Tb_min
        Tb_min = Tb_est(i);
        I_optima = I_est(i);
    end
end
disp(['Mínimo de la curva: Tb = ' num2str(Tb_min) ' C con I = ' num2str(I_optima) ' A'])

I_max_ctrl = 2.0;   % [A] límite del controlador (menor que I_optima)
I_min_ctrl = 0;     % [A] la fuente no da corriente negativa

figure(1)
plot(I_est, Tb_est, 'k-', 'LineWidth', 1.3)
hold on
plot(I_optima, Tb_min, 'ko', 'MarkerSize', 7, 'LineWidth', 1.2)
plot([2 2], [-5 30], 'k--')
plot([6.4 6.4], [-5 30], 'k:')
hold off
grid on
xlim([0 6.5])
ylim([-5 30])
xlabel('Corriente I [A]')
ylabel('Temperatura de equilibrio T_b [\circC]')
title('Temperatura de equilibrio del bloque (400 LFM)')
legend('T_b de equilibrio', 'Mínimo de T_b', 'Límite del controlador (2 A)', ...
       'I_{max} de la hoja de datos (6.4 A)', 'Location', 'north')
exportgraphics(gcf, 'figuras_diseno/limite_corriente.pdf', 'ContentType', 'vector')


%% 3. Control proporcional
% Se prueban varios Kp con el modelo lineal
Kp_lista = [0.2 0.5 1 2 5];

disp(' ')
disp('Control P:')
disp('   Kp     ess[%]   ts[s]   dImax[A]   dTb_Tamb[K]   dTb_2W[K]')
for i = 1:length(Kp_lista)
    Kp = Kp_lista(i);

    T_P = feedback(Kp*Gp, 1);          % de Tref a Tb
    U_P = feedback(Kp, Gp);            % de Tref a I
    D_P = minreal(Gd/(1 + Kp*Gp));     % de Tamb a Tb
    Q_P = minreal(Gq/(1 + Kp*Gp));     % de Q a Tb

    info_P = stepinfo(T_P);
    ess = 1 - dcgain(T_P);
    u = step(U_P, t);
    d = step(5*D_P, t);                % Tamb sube 5 K
    dq = step(2*Q_P, t);               % carga de 2 W

    fprintf('  %4.1f    %5.1f    %6.1f    %4.2f       %5.3f        %5.3f\n', ...
        Kp, 100*ess, info_P.SettlingTime, max(u), d(end), dq(end));
end

% Lugar de las raíces: para cada Kp se sacan las raíces de
% den + Kp*num  (num de Gp es -numG)
num_p = [0 -numG];    % se le pone un cero adelante para que mida igual que denG
Kp_vec = 0:0.005:3;
raices = zeros(2, length(Kp_vec));
for i = 1:length(Kp_vec)
    raices(:,i) = roots(denG + Kp_vec(i)*num_p);
end

figure(2)
subplot(1,2,1)
plot(real(raices(:)), imag(raices(:)), 'k.', 'MarkerSize', 4)
hold on
plot(real(polos_G), imag(polos_G), 'kx', 'MarkerSize', 10, 'LineWidth', 1.5)
plot(real(cero_G), imag(cero_G), 'ko', 'MarkerSize', 8, 'LineWidth', 1.5)
hold off
grid on
xlim([-0.4 0.02])
ylim([-0.01 0.01])
xlabel('Parte real [s^{-1}]')
ylabel('Parte imaginaria [s^{-1}]')
title('Control P, 0 \leq K_p \leq 3 A/K')
legend('Polos de lazo cerrado', 'Polos de G_p(s)', 'Cero de G_p(s)', 'Location', 'southwest')
subplot(1,2,2)
plot(real(raices(:)), imag(raices(:)), 'k.', 'MarkerSize', 4)
hold on
plot(real(polos_G), imag(polos_G), 'kx', 'MarkerSize', 10, 'LineWidth', 1.5)
plot(real(cero_G), imag(cero_G), 'ko', 'MarkerSize', 8, 'LineWidth', 1.5)
hold off
grid on
xlim([-0.06 0.005])
ylim([-0.01 0.01])
xlabel('Parte real [s^{-1}]')
title('Acercamiento cerca del origen')
exportgraphics(gcf, 'figuras_diseno/lgr_P.pdf', 'ContentType', 'vector')


%% 4. Especificaciones
% (la justificación está en la tabla de especificaciones del informe)
esp_ess = 0.1;       % [K] error permanente máximo
esp_Mp = 10;         % [%] sobrepaso máximo
esp_ts = 180;        % [s] tiempo de asentamiento máximo
esp_dI = 2 - 1.19;   % [A] para un escalón de -1 K no se debe pasar de 2 A
esp_pico = 0.5;      % [K] pico máximo por perturbación (5 K en Tamb o 2 W)
esp_rec = 400;       % [s] tiempo máximo para volver a +-0.1 K
esp_MF = 45;         % [grados] margen de fase mínimo

% ¿Qué Kp necesitaría el control P?
Kp_por_error = (3/esp_ess - 1)/abs(K_G);           % escalón de 3 K
Kp_por_pert = (5*dcgain(Gd)/esp_ess - 1)/abs(K_G); % Tamb sube 5 K
Kp_por_carga = (2*dcgain(Gq)/esp_ess - 1)/abs(K_G); % carga de 2 W
Kp_por_corriente = esp_dI/1;                       % escalón de 1 K
disp(' ')
disp(['Kp mínimo por error:        ' num2str(Kp_por_error) ' A/K'])
disp(['Kp mínimo por Tamb:         ' num2str(Kp_por_pert) ' A/K'])
disp(['Kp mínimo por carga de 2 W: ' num2str(Kp_por_carga) ' A/K'])
disp(['Kp máximo por corriente:    ' num2str(Kp_por_corriente) ' A/K'])
disp('No hay un Kp que cumpla todo -> se necesita un PI')


%% 5. Diseño del PI
% C(s) = Kc*(s + z)/s
% Paso 1: el cero del PI se pone encima del polo lento de la planta
p_lento = max(polos_G);    % el polo más cerca del origen (-0.0086)
z = -p_lento;
Ti = 1/z;
disp(' ')
disp(['Cero del PI: z = ' num2str(z) ' 1/s,  Ti = ' num2str(Ti) ' s'])

% Paso 2: se prueban varios Kc y se revisa cuáles cumplen
Kc_lista = 0.1:0.05:1.5;
ts_lista = zeros(1, length(Kc_lista));
dI_lista = zeros(1, length(Kc_lista));

disp('   Kc     ts[s]   Mp[%]   dImax[A]   pico[K]   t_rec[s]   MF   ¿cumple?')
for i = 1:length(Kc_lista)
    Kc = Kc_lista(i);
    C = Kc*(s + z)/s;
    L = C*Gp;

    T_PI = feedback(L, 1);
    U_PI = feedback(C, Gp);
    D_PI = minreal(Gd/(1 + L));
    Q_PI = minreal(Gq/(1 + L));

    info = stepinfo(T_PI);
    u = step(U_PI, t);
    d = step(5*D_PI, t);
    dq = step(2*Q_PI, t);
    [~, MF] = margin(L);

    % se toma el peor caso de las dos perturbaciones
    pico = max(max(abs(d)), max(abs(dq)));

    % tiempo en que la perturbación vuelve a quedar dentro de 0.1 K
    t_rec = 0;
    for k = 1:length(t)
        if abs(d(k)) > 0.1 || abs(dq(k)) > 0.1
            t_rec = t(k);
        end
    end

    ts_lista(i) = info.SettlingTime;
    dI_lista(i) = max(u);

    if info.SettlingTime <= esp_ts && info.Overshoot <= esp_Mp && max(u) <= esp_dI ...
            && pico <= esp_pico && t_rec <= esp_rec && MF >= esp_MF
        cumple = 'sí';
    else
        cumple = 'no';
    end

    fprintf('  %4.2f   %6.1f   %4.2f    %4.2f      %5.3f     %5.1f   %4.1f    %s\n', ...
        Kc, info.SettlingTime, info.Overshoot, max(u), pico, t_rec, MF, cumple);
end

figure(3)
subplot(2,1,1)
plot(Kc_lista, ts_lista, 'k-o', 'MarkerSize', 4)
hold on
plot([0 1.5], [esp_ts esp_ts], 'k--')
hold off
grid on
xlim([0 1.5])
ylabel('t_s (2 %) [s]')
title('Barrido de K_c del PI (cero en z = 0.0086 s^{-1})')
legend('t_s del lazo cerrado', 'Especificación t_s \leq 180 s')
subplot(2,1,2)
plot(Kc_lista, dI_lista, 'k-s', 'MarkerSize', 4)
hold on
plot([0 1.5], [esp_dI esp_dI], 'k--')
hold off
grid on
xlim([0 1.5])
xlabel('K_c [A/K]')
ylabel('\DeltaI máximo [A]')
legend('\DeltaI máximo (escalón de -1 K)', 'Especificación \DeltaI \leq 0.81 A', 'Location', 'northwest')
exportgraphics(gcf, 'figuras_diseno/barrido_Kc.pdf', 'ContentType', 'vector')

% Paso 3: cumplen de 0.65 a 0.80, se escoge uno en el medio
Kc = 0.75;
Ki = Kc/Ti;
disp(' ')
disp(['Kc = ' num2str(Kc) ' A/K,  Ti = ' num2str(Ti) ' s,  Ki = ' num2str(Ki) ' A/(K s)'])


%% 6. Revisión del PI escogido
C = Kc*(s + z)/s;
L = C*Gp;
T_PI = feedback(L, 1);
U_PI = feedback(C, Gp);
D_PI = minreal(Gd/(1 + L));
Q_PI = minreal(Gq/(1 + L));

polos_LC = pole(T_PI);
disp('Polos de lazo cerrado:')
disp(polos_LC)

[GM, MF, w_GM, w_MF] = margin(L);
disp(['Margen de fase = ' num2str(MF) ' grados en w = ' num2str(w_MF) ' rad/s'])
disp(['Margen de ganancia = ' num2str(GM)])

info_PI = stepinfo(T_PI);
disp(['ts = ' num2str(info_PI.SettlingTime) ' s,  Mp = ' num2str(info_PI.Overshoot) ' %'])
disp(['ess = ' num2str(1 - dcgain(T_PI)) ' K'])

d_PI = step(5*D_PI, t);
dq_PI = step(2*Q_PI, t);
disp(['Pico por Tamb +5 K = ' num2str(max(abs(d_PI))) ' K'])
disp(['Pico por carga de 2 W = ' num2str(max(abs(dq_PI))) ' K'])

% Lugar de las raíces con el PI (Kc de 0 a 2)
% Lazo abierto con Kc = 1:  Gp*(s+z)/s
num_L = conv(-numG, [1 z]);         % numerador
den_L = conv(denG, [1 0]);          % denominador
num_L = [0 num_L];                  % mismo largo que den_L
polos_L = roots(den_L);
ceros_L = roots(num_L(2:end));

Kc_vec = 0:0.002:2;
raices = zeros(3, length(Kc_vec));
for i = 1:length(Kc_vec)
    raices(:,i) = roots(den_L + Kc_vec(i)*num_L);
end

figure(4)
subplot(1,2,1)
plot(real(raices(:)), imag(raices(:)), 'k.', 'MarkerSize', 4)
hold on
plot(real(polos_L), imag(polos_L), 'kx', 'MarkerSize', 10, 'LineWidth', 1.5)
plot(real(ceros_L), imag(ceros_L), 'ko', 'MarkerSize', 8, 'LineWidth', 1.5)
plot(real(polos_LC), imag(polos_LC), 'ks', 'MarkerSize', 9, 'LineWidth', 1.5)
hold off
grid on
xlim([-0.4 0.02])
ylim([-0.01 0.01])
xlabel('Parte real [s^{-1}]')
ylabel('Parte imaginaria [s^{-1}]')
title('Control PI, 0 \leq K_c \leq 2 A/K')
legend('Polos de lazo cerrado', 'Polos de lazo abierto', 'Ceros de lazo abierto', ...
       'Polos con K_c = 0.75 A/K', 'Location', 'southwest')
subplot(1,2,2)
plot(real(raices(:)), imag(raices(:)), 'k.', 'MarkerSize', 4)
hold on
plot(real(polos_L), imag(polos_L), 'kx', 'MarkerSize', 10, 'LineWidth', 1.5)
plot(real(ceros_L), imag(ceros_L), 'ko', 'MarkerSize', 8, 'LineWidth', 1.5)
plot(real(polos_LC), imag(polos_LC), 'ks', 'MarkerSize', 9, 'LineWidth', 1.5)
hold off
grid on
xlim([-0.06 0.005])
ylim([-0.01 0.01])
xlabel('Parte real [s^{-1}]')
title('Acercamiento (cuadros: K_c = 0.75 A/K)')
exportgraphics(gcf, 'figuras_diseno/lgr_PI.pdf', 'ContentType', 'vector')

% Bode de L(s)
w = logspace(-4, 1, 500);
[mag, fase] = bode(L, w);
mag = mag(:);
fase = fase(:);

figure(5)
subplot(2,1,1)
semilogx(w, 20*log10(mag), 'k-', 'LineWidth', 1.3)
hold on
semilogx([w_MF w_MF], [-60 80], 'k--')
hold off
grid on
ylabel('Magnitud [dB]')
title('Diagrama de Bode de L(s) = C(s) G_p(s)')
subplot(2,1,2)
semilogx(w, fase, 'k-', 'LineWidth', 1.3)
hold on
semilogx([w_MF w_MF], [-200 0], 'k--')
hold off
grid on
ylim([-200 0])
xlabel('Frecuencia [rad/s]')
ylabel('Fase [grados]')
text(w_MF*1.3, -150, ['MF = ' num2str(round(MF)) ' grados'])
exportgraphics(gcf, 'figuras_diseno/bode_PI.pdf', 'ContentType', 'vector')

% Comparación P contra PI (mismo Kp = Kc = 0.75)
T_P = feedback(0.75*Gp, 1);
U_P = feedback(0.75, Gp);
D_P = minreal(Gd/(1 + 0.75*Gp));
Q_P = minreal(Gq/(1 + 0.75*Gp));

y_P = -step(T_P, t);      % escalón de referencia de -1 K
y_PI = -step(T_PI, t);
u_P = step(U_P, t);
u_PI = step(U_PI, t);

figure(6)
subplot(2,1,1)
plot(t, y_P, 'k--', 'LineWidth', 1.2)
hold on
plot(t, y_PI, 'k-', 'LineWidth', 1.2)
plot([0 600], [-1 -1], 'k:')
hold off
grid on
xlim([0 600])
ylabel('\DeltaT_b [K]')
title('Escalón de referencia de -1 K (modelo lineal)')
legend('P (K_p = 0.75 A/K)', 'PI (K_c = 0.75 A/K, T_i = 116 s)', 'Referencia')
subplot(2,1,2)
plot(t, u_P, 'k--', 'LineWidth', 1.2)
hold on
plot(t, u_PI, 'k-', 'LineWidth', 1.2)
hold off
grid on
xlim([0 600])
xlabel('Tiempo [s]')
ylabel('\DeltaI [A]')
exportgraphics(gcf, 'figuras_diseno/escalon_P_PI.pdf', 'ContentType', 'vector')

d_LA = step(5*Gd, t);
d_P = step(5*D_P, t);
dq_LA = step(2*Gq, t);
dq_P = step(2*Q_P, t);

figure(7)
subplot(2,1,1)
plot(t, d_LA, 'k:', 'LineWidth', 1.2)
hold on
plot(t, d_P, 'k--', 'LineWidth', 1.2)
plot(t, d_PI, 'k-', 'LineWidth', 1.2)
hold off
grid on
ylabel('\DeltaT_b [K]')
title('Escalón de +5 K en la temperatura ambiente (modelo lineal)')
legend('Lazo abierto', 'P (K_p = 0.75 A/K)', 'PI', 'Location', 'east')
subplot(2,1,2)
plot(t, dq_LA, 'k:', 'LineWidth', 1.2)
hold on
plot(t, dq_P, 'k--', 'LineWidth', 1.2)
plot(t, dq_PI, 'k-', 'LineWidth', 1.2)
hold off
grid on
xlabel('Tiempo [s]')
ylabel('\DeltaT_b [K]')
title('Carga de 2 W en el bloque (modelo lineal)')
exportgraphics(gcf, 'figuras_diseno/perturbacion_P_PI.pdf', 'ContentType', 'vector')


%% 7. Prueba rápida con el modelo no lineal (arranque desde 25 C)
% Se usa Euler con las ecuaciones de la Tarea 1. La función está en
% simular_arranque.m. La prueba formal se hace en Simscape.
Tref = 5;
[t1, Tb1, I1] = simular_arranque(p, I0, Kc, Ki, Tref, 6.4, 1);   % límite 6.4 A
[t2, Tb2, I2] = simular_arranque(p, I0, Kc, Ki, Tref, 2, 0);     % 2 A sin anti-windup
[t3, Tb3, I3] = simular_arranque(p, I0, Kc, Ki, Tref, 2, 1);     % 2 A con anti-windup

disp(' ')
disp(['Límite 6.4 A: Tb final = ' num2str(Tb1(end)) ' C'])
disp(['2 A sin anti-windup: Tb mínima = ' num2str(min(Tb2)) ' C'])
disp(['2 A con anti-windup: Tb mínima = ' num2str(min(Tb3)) ' C'])

t_entra = 0;
for k = 1:length(t3)
    if abs(Tb3(k) - Tref) > 0.5
        t_entra = t3(k);
    end
end
disp(['Entra a 5 +- 0.5 C en ' num2str(t_entra) ' s'])

figure(8)
subplot(2,1,1)
plot(t1, Tb1, 'k:', 'LineWidth', 1.3)
hold on
plot(t2, Tb2, 'k--', 'LineWidth', 1.2)
plot(t3, Tb3, 'k-', 'LineWidth', 1.2)
plot([0 1500], [2 2], 'k-.')
hold off
grid on
xlim([0 1500])
ylim([0 30])
ylabel('T_b [\circC]')
title('Arranque desde 25 \circC con T_{ref} = 5 \circC (modelo no lineal)')
legend('PI, límite 6.4 A', 'PI, límite 2 A, sin anti-windup', ...
       'PI, límite 2 A, con anti-windup', 'Límite inferior 2 \circC')
subplot(2,1,2)
plot(t1, I1, 'k:', 'LineWidth', 1.3)
hold on
plot(t2, I2, 'k--', 'LineWidth', 1.2)
plot(t3, I3, 'k-', 'LineWidth', 1.2)
hold off
grid on
xlim([0 1500])
ylim([0 7])
xlabel('Tiempo [s]')
ylabel('Corriente I [A]')
exportgraphics(gcf, 'figuras_diseno/arranque_nl.pdf', 'ContentType', 'vector')


%% 8. Guardar para Simulink
% Bloque PID Controller: P = Kc, I = Ki, D = 0, anti-windup Clamping,
% límites de salida de 0 a 2 A (si I0 se suma antes de saturar).
% la entrada del PID es e = Tb - Tref.
% numC y denC son los que pide revisar_compensador.m:
% C(s) = (Kc*s + Ki)/s
numC = [Kc Ki];
denC = [1 0];
save('parametros_control.mat', 'Kc', 'Ki', 'Ti', 'z', 'numC', 'denC', ...
     'I_max_ctrl', 'I_min_ctrl', 'Tref', 'I0')
disp('Se guardó parametros_control.mat')