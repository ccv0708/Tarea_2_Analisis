% Autor: GR09, Integrante 1 (completar nombre).
% Proposito: repetir la sensibilidad con el compensador ENTREGADO por el grupo.
% Entrada: peltier_lazo_comp.slx y parametros_control.mat. Salida: CSV.
configurar;
factibilidad_termica;
modelo = 'peltier_lazo_comp';
if ~isfile(fullfile(carpeta,[modelo '.slx']))
    error('Falta el modelo compensado del Integrante 3. Vea guias/04_cierre_del_grupo.md.');
end
control = load(fullfile(carpeta,'parametros_control.mat'));
if control.I_max_ctrl~=Imax || control.I_min_ctrl~=Imin
    error('Los limites del P y del PI no coinciden. Deben ser 0 y 2 A.');
end
% El modelo debe usar control.Kc y control.Ki, o numC/denC.
if isfield(control,'numC') && isfield(control,'denC')
    numC = control.numC; denC = control.denC;
elseif isfield(control,'C')
    [numC,denC] = tfdata(tf(control.C),'v');
else
    error('Faltan numC/denC o C(s) en parametros_control.mat.');
end
load_system(fullfile(carpeta,[modelo '.slx']));
casos = {'nominal','natural','aire_200','masa_menos20','masa_mas20','operacion_10C'};
resumen = table;
for caso = 1:6
    p = p_nom; I0 = I0_nom; Tc0 = Tc0_nom; Th0 = Th0_nom;
    if caso==2
        p.RHA = 8.4;
    elseif caso==3
        p.RHA = 2.11;
    elseif caso==4
        p.mC = 0.8*p_nom.mC; p.CC = 900*p.mC;
    elseif caso==5
        p.mC = 1.2*p_nom.mC; p.CC = 900*p.mC;
    elseif caso==6
        % Nuevo sesgo de equilibrio; mantener el MISMO compensador.
        I0 = fzero(@(i) temperatura_fria(i,p)-(10+273.15),[0 2]);
        xe = equilibrio_peltier(I0,p);
        Tc0 = xe(1); Th0 = xe(2);
    end
    case_RHA = p.RHA;
    Tc_init = Tc0; Th_init = Th0;
    Kp = Kp_base;
    r_antes = Tc0-273.15; r_despues = r_antes-1;
    instante_ref = t_ref;
    senal_ruido = [tiempo_ruido,zeros(size(tiempo_ruido))];
    senal_carga = [0 0; t_final 0];
    simout = sim(modelo);
    Tb = interp1(simout.Tb.Time,simout.Tb.Data,t);
    Th = interp1(simout.Th_ssc.Time,simout.Th_ssc.Data,t)-273.15;
    I = interp1(simout.I_ssc.Time,simout.I_ssc.Data,t);
    r = r_antes*ones(size(t)); r(t>=t_ref) = r_despues;
    m = metricas_lazo(t,r,Tb,I,t_ref,0.02,Imin,Imax);
    % 100 C es una marca de extrapolacion para el ANALISIS, no un rating.
    extrapolacion = max([Tb;Th])>100;
    if extrapolacion
        warning('Caso %s: supera 100 C. No interpretar como operacion fisica valida.',casos{caso});
    end
    fila = [table(string(casos{caso}),Kp,p.RHA,p.mC,max(Th),extrapolacion, ...
        'VariableNames',{'caso','Kp_P_de_comparacion','RHA_K_W','masa_kg','Th_max_C','extrapolacion'}), ...
        struct2table(m)];
    if caso==1
        resumen = fila;
    else
        resumen = [resumen;fila];
    end
    R = table(t,r,Tb,Th,I,'VariableNames',{'t_s','ref_C','Tb_C','Th_C','I_A'});
    writetable(R,fullfile(salida,['sens_comp_' casos{caso} '.csv']));
end
writetable(resumen,fullfile(salida,'sensibilidad_compensado.csv'));
close_system(modelo,0);
disp(resumen);
configurar;  % restaurar el nominal para los siguientes analisis
