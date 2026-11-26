% Autor: GR09, Integrante 1 (completar nombre).
% Proposito: evaluar el MISMO P ante variaciones termicas y de operacion.
% Entrada: modelo P, configurar. Salida: CSV de sensibilidad.
preparar_modelos_P;
factibilidad_termica;
modelo = 'peltier_lazo_P';
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
        % Nuevo sesgo de equilibrio, mismas ganancias: no se redisena el P.
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
        'VariableNames',{'caso','Kp_A_K','RHA_K_W','masa_kg','Th_max_C','extrapolacion'}), ...
        struct2table(m)];
    if caso==1
        resumen = fila;
    else
        resumen = [resumen;fila];
    end
    R = table(t,r,Tb,Th,I,'VariableNames',{'t_s','ref_C','Tb_C','Th_C','I_A'});
    writetable(R,fullfile(salida,['sens_P_' casos{caso} '.csv']));
end
writetable(resumen,fullfile(salida,'sensibilidad_P.csv'));
close_system(modelo,0);
disp(resumen);
configurar;  % restaurar el nominal para los siguientes analisis
