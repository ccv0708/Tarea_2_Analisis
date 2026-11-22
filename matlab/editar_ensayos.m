% Autor: GR09, Integrante 1 (completar nombre).
% Proposito: editar y guardar los valores comunes de los ensayos.
% Entrada: valores de abajo. Salida: parametros_ensayos.mat.
Kp_lista = [0.2 1 5];       % A/K
Kp_base = 1;               % P usado en sensibilidad; acordarlo con el grupo
Imin = 0; Imax = 6.4;      % A
t_final = 1200;            % s; cada ensayo supera 900 s
dt_salida = 0.2;           % s; malla para tablas y metricas
t_ref = 20;               % s; instante del escalon 5 -> 4 grados C
t_pert = 300;             % s; inicio de carga o ruido
Q_pert = 2;               % W; calor que ENTRA al bloque frio
sigma_ruido = 0.05;        % K; desviacion estandar elegida para comparar
Ts_ruido = 1;             % s; ruido mantenido constante entre muestras
semilla = 9;
carpeta = fileparts(mfilename('fullpath'));
save(fullfile(carpeta,'parametros_ensayos.mat'), ...
    'Kp_lista','Kp_base','Imin','Imax','t_final','dt_salida', ...
    't_ref','t_pert','Q_pert','sigma_ruido','Ts_ruido','semilla');
disp('Valores guardados. Vuelva a ejecutar configurar o ejecutar_integrante1.');
