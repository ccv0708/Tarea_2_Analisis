% Autor: GR09, Integrante 1 (completar nombre).
% Proposito: generar los dos SLX con bloques normales de Simulink.
% Entrada: peltier_validacion.slx de Tarea 1. Salida: dos modelos P.
% Las funciones add_block/add_line solo automatizan el dibujo del diagrama.

%% 1. Planta lineal: estados termicos y una FT de comprobacion
modelo = 'peltier_lazo_P_lineal';
if bdIsLoaded(modelo)
    close_system(modelo,0);
end
new_system(modelo);
agregar_control_P(modelo);
add_block('simulink/Math Operations/Bias',[modelo '/delta_I'], ...
    'Bias','-I0','Position',[680 -290 740 -250]);
add_block('simulink/Signal Routing/Mux',[modelo '/Entradas'], ...
    'Inputs','3','Position',[790 -240 810 -160]);
add_block('simulink/Sources/From Workspace',[modelo '/Ambiente_delta'], ...
    'VariableName','senal_ambiente','Interpolate','off', ...
    'OutputAfterFinalValue','Holding final value', ...
    'Position',[680 10 780 45]);
add_block('simulink/Continuous/State-Space',[modelo '/Planta_lineal'], ...
    'A','A','B','[B [1/p.CC;0] [1/(p.CC*p.RCA);1/(p.CH*p.RHA)]]', ...
    'C','eye(2)','D','zeros(2,3)', ...
    'X0','[Tc_init-Tc0;Th_init-Th0]','Position',[850 -240 980 -160]);
add_block('simulink/Signal Routing/Demux',[modelo '/Estados'], ...
    'Outputs','2','Position',[1010 -235 1030 -165]);
add_block('simulink/Math Operations/Bias',[modelo '/Tc_K'], ...
    'Bias','Tc0','Position',[1060 10 1130 45]);
add_block('simulink/Math Operations/Bias',[modelo '/Th_K'], ...
    'Bias','Th0','Position',[1060 80 1130 115]);
add_block('simulink/Math Operations/Sum',[modelo '/Delta_T'], ...
    'Inputs','+-','Position',[1190 30 1220 75]);
add_block('simulink/Math Operations/Gain',[modelo '/Seebeck_V'], ...
    'Gain','p.alpha','Position',[1270 30 1340 70]);
add_block('simulink/Math Operations/Gain',[modelo '/Ohmica_V'], ...
    'Gain','p.R','Position',[1050 160 1120 200]);
add_block('simulink/Math Operations/Sum',[modelo '/Voltaje'], ...
    'Inputs','++','Position',[1390 75 1420 120]);
add_block('simulink/Sinks/To Workspace',[modelo '/I_ssc'], ...
    'VariableName','I_ssc','SaveFormat','Timeseries','MaxDataPoints','inf', ...
    'Position',[680 -370 780 -335]);
add_block('simulink/Sinks/To Workspace',[modelo '/V_ssc'], ...
    'VariableName','V_ssc','SaveFormat','Timeseries','MaxDataPoints','inf', ...
    'Position',[1470 80 1570 115]);
add_block('simulink/Sinks/To Workspace',[modelo '/Th_ssc'], ...
    'VariableName','Th_ssc','SaveFormat','Timeseries','MaxDataPoints','inf', ...
    'Position',[1190 160 1290 195]);
add_block('simulink/Continuous/Transfer Fcn',[modelo '/G_s'], ...
    'Numerator','numG','Denominator','denG','Position',[850 260 1030 310]);
add_block('simulink/Sinks/To Workspace',[modelo '/Guardar_FT'], ...
    'VariableName','dTb_FT','SaveFormat','Timeseries','MaxDataPoints','inf', ...
    'Position',[1090 265 1190 300]);
add_line(modelo,'Dinamica_corriente/1','delta_I/1','autorouting','on');
add_line(modelo,'Dinamica_corriente/1','I_ssc/1','autorouting','on');
add_line(modelo,'delta_I/1','Entradas/1','autorouting','on');
add_line(modelo,'Carga/1','Entradas/2','autorouting','on');
add_line(modelo,'Ambiente_delta/1','Entradas/3','autorouting','on');
add_line(modelo,'Entradas/1','Planta_lineal/1','autorouting','on');
add_line(modelo,'Planta_lineal/1','Estados/1','autorouting','on');
add_line(modelo,'Estados/1','Tc_K/1','autorouting','on');
add_line(modelo,'Estados/2','Th_K/1','autorouting','on');
add_line(modelo,'Tc_K/1','Tb_C/1','autorouting','on');
add_line(modelo,'Th_K/1','Delta_T/1','autorouting','on');
add_line(modelo,'Tc_K/1','Delta_T/2','autorouting','on');
add_line(modelo,'Delta_T/1','Seebeck_V/1','autorouting','on');
add_line(modelo,'Dinamica_corriente/1','Ohmica_V/1','autorouting','on');
add_line(modelo,'Seebeck_V/1','Voltaje/1','autorouting','on');
add_line(modelo,'Ohmica_V/1','Voltaje/2','autorouting','on');
add_line(modelo,'Voltaje/1','V_ssc/1','autorouting','on');
add_line(modelo,'Th_K/1','Th_ssc/1','autorouting','on');
add_line(modelo,'Voltaje/1','Potencia/1','autorouting','on');
add_line(modelo,'Dinamica_corriente/1','Potencia/2','autorouting','on');
add_line(modelo,'delta_I/1','G_s/1','autorouting','on');
add_line(modelo,'G_s/1','Guardar_FT/1','autorouting','on');
save_system(modelo,fullfile(carpeta,[modelo '.slx']));
close_system(modelo,0);

%% 2. Planta Simscape: conservar la red fisica de Tarea 1
modelo = 'peltier_lazo_P';
if bdIsLoaded(modelo)
    close_system(modelo,0);
end
copyfile(fullfile(carpeta,'base_tarea1','peltier_validacion.slx'), ...
    fullfile(carpeta,[modelo '.slx']),'f');
load_system(fullfile(carpeta,[modelo '.slx']));
% El modelo original guarda parametros internos que ocultarian los nuevos.
W = get_param(modelo,'ModelWorkspace');
clear(W);
% Desconectar las antiguas entradas antes de borrar los bloques de prueba.
delete_line(modelo,'delta_corriente/1','SS/1');
delete_line(modelo,'delta_corriente/1','FT/1');
delete_line(modelo,'delta_corriente/1','corriente_total/2');
delete_line(modelo,'Ibase/1','corriente_total/1');
delete_line(modelo,'corriente_total/1','I_A/1');
delete_line(modelo,'SS/1','dTc_ss/1');
delete_line(modelo,'FT/1','dTc_tf/1');
borrar = {'SS','FT','dTc_ss','dTc_tf','delta_corriente','Ibase','corriente_total'};
for k = 1:length(borrar)
    delete_block([modelo '/' borrar{k}]);
end
agregar_control_P(modelo);
add_line(modelo,'Dinamica_corriente/1','I_A/1','autorouting','on');
add_line(modelo,'Tc_ssc_convert/1','Tb_C/1','autorouting','on');
add_line(modelo,'V_ssc_convert/1','Potencia/1','autorouting','on');
add_line(modelo,'I_ssc_convert/1','Potencia/2','autorouting','on');

% Agregar calor al bloque: copiar Joule_frio conserva su orientacion A->B.
add_block([modelo '/Joule_frio'],[modelo '/Carga_termica'], ...
    'Position',[1270 620 1357 680]);
add_block([modelo '/I_A'],[modelo '/Carga_PS'], ...
    'Position',[1240 510 1280 550]);
set_param([modelo '/Carga_PS'],'Unit','W');
add_line(modelo,'Carga/1','Carga_PS/1','autorouting','on');
puerto_original = get_param([modelo '/Joule_frio'],'PortHandles');
puerto_carga = get_param([modelo '/Carga_termica'],'PortHandles');
puerto_convertidor = get_param([modelo '/Carga_PS'],'PortHandles');
add_line(modelo,puerto_original.LConn(1),puerto_carga.LConn(1),'autorouting','on');
add_line(modelo,puerto_original.RConn(2),puerto_carga.RConn(2),'autorouting','on');
add_line(modelo,puerto_convertidor.RConn(1),puerto_carga.RConn(1),'autorouting','on');
save_system(modelo,fullfile(carpeta,[modelo '.slx']));
close_system(modelo,0);
disp('Modelos P reconstruidos en la carpeta actual.');
