% Autor: GR09, Integrante 1 (completar nombre).
% Proposito: ejecutar las pruebas comunes en las dos plantas.
% Entrada: configurar y modelos P. Salida: CSV por ensayo y tabla de metricas.
preparar_modelos_P;
modelos = {'peltier_lazo_P_lineal','peltier_lazo_P'};
nombres = {'lineal','simscape'};
pruebas = {'escalon','arranque','carga','ruido','ambiente'};
resumen = table;
for planta = 1:2
    modelo = modelos{planta};
    load_system(fullfile(carpeta,[modelo '.slx']));
    for ensayo = 1:length(pruebas)
        if planta==2 && ensayo==5
            continue;  % el escalon de Tamb se exige solo en la planta lineal
        end
        for k = 1:length(Kp_lista)
            Kp = Kp_lista(k);
            p = p_nom; case_RHA = p.RHA;
            I0 = I0_nom; Tc0 = Tc0_nom; Th0 = Th0_nom;
            Tc_init = Tc0; Th_init = Th0;
            r_antes = Tc0-273.15; r_despues = r_antes;
            instante_ref = t_ref;
            senal_ruido = [tiempo_ruido, zeros(size(tiempo_ruido))];
            senal_carga = [0 0; t_pert 0; t_final 0];
            senal_ambiente = [0 0; t_final 0];
            inicio = t_pert; banda = 0.02;
            if ensayo==1
                r_despues = r_antes-1;
                inicio = t_ref; banda = 0.02;
            elseif ensayo==2
                Tc_init = p.Tamb; Th_init = p.Tamb;
                inicio = 0; banda = 0.02*20;
            elseif ensayo==3
                senal_carga = [0 0; t_pert Q_pert; t_final Q_pert];
            elseif ensayo==4
                senal_ruido = [tiempo_ruido, ruido_comun];
            elseif ensayo==5
                senal_ambiente = [0 0; t_pert dTamb_pert; t_final dTamb_pert];
            end
            fprintf('Planta %s, prueba %s, Kp = %.2f\n', ...
                nombres{planta},pruebas{ensayo},Kp);
            simout = sim(modelo);
            Tb = interp1(simout.Tb.Time,simout.Tb.Data,t);
            Th = interp1(simout.Th_ssc.Time,simout.Th_ssc.Data,t)-273.15;
            I = interp1(simout.I_ssc.Time,simout.I_ssc.Data,t);
            V = interp1(simout.V_ssc.Time,simout.V_ssc.Data,t);
            Pot = interp1(simout.P_electrica.Time,simout.P_electrica.Data,t);
            r = r_antes*ones(size(t)); r(t>=instante_ref) = r_despues;
            if any(~isfinite([Tb;Th;I;V;Pot]))
                error('Senales incompletas o no finitas. Revise la simulacion.');
            end
            assert(min(I)>Imin-1e-4 && max(I)<Imax+1e-4);
            % La FT y el estado frio deben coincidir en el escalon desde equilibrio.
            if planta==1 && ensayo==1
                dTb_FT = interp1(simout.dTb_FT.Time,simout.dTb_FT.Data,t);
                assert(max(abs(Tb-(Tc0-273.15)-dTb_FT))<1e-4);
            end
            m = metricas_lazo(t,r,Tb,I,inicio,banda,Imin,Imax);
            m.deltaImax_A = max(abs(I-I0));
            m.Tb_min_C = min(Tb);
            m.pico_pert_K = NaN;
            m.t_rec_01_s = NaN;
            m.t_arranque_05_s = NaN;
            if ensayo==3 || ensayo==5
                m.pico_pert_K = max(abs(Tb(t>=inicio)-r(t>=inicio)));
                recuperacion = metricas_lazo(t,r,Tb,I,inicio,0.1,Imin,Imax);
                m.t_rec_01_s = recuperacion.ts_ref_s;
            elseif ensayo==2
                arranque = metricas_lazo(t,r,Tb,I,0,0.5,Imin,Imax);
                m.t_arranque_05_s = arranque.ts_ref_s;
            end
            m.Th_max_C = max(Th);
            m.extrapolacion = max([Tb;Th])>100;
            if m.extrapolacion
                warning('La simulacion supera 100 C: revisar validez del modelo termico.');
            end
            if ensayo>=3
                m.tr_s = NaN; m.sobrepaso_pct = NaN;
            end
            if ensayo==4
                m.ts_ref_s = NaN; m.ts_final_s = NaN;
            end
            fila = [table(string(nombres{planta}),string(pruebas{ensayo}),Kp, ...
                'VariableNames',{'planta','prueba','Kp_A_K'}),struct2table(m)];
            if planta==1 && ensayo==1 && k==1
                resumen = fila;
            else
                resumen = [resumen;fila];
            end
            ruido = interp1(senal_ruido(:,1),senal_ruido(:,2),t,'previous');
            carga = interp1(senal_carga(:,1),senal_carga(:,2),t,'previous');
            Tb_medida = Tb+ruido;
            ambiente_delta = interp1(senal_ambiente(:,1),senal_ambiente(:,2),t,'previous');
            registro = table(t,r,Tb,Th,I,V,Pot,ruido,Tb_medida,carga,ambiente_delta, ...
                'VariableNames',{'t_s','ref_C','Tb_C','Th_C','I_A','V_V','P_W', ...
                'ruido_K','Tb_medida_C','carga_W','ambiente_delta_K'});
            archivo = sprintf('%s_%s_Kp_%g.csv',nombres{planta},pruebas{ensayo},Kp);
            writetable(registro,fullfile(salida,archivo));
        end
    end
    close_system(modelo,0);
end
writetable(resumen,fullfile(salida,'metricas_P.csv'));
save(fullfile(salida,'resultados_P.mat'),'resumen','Kp_lista','p_nom');
disp(resumen);
