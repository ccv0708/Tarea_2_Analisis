% Autor: GR09, Integrante 1 (completar nombre).
% Proposito: superponer temperatura, corriente, tension y potencia.
% Entrada: CSV de simular_P. Salida: figuras PDF vectoriales.
nombres = {'lineal','simscape'};
pruebas = {'escalon','arranque','carga','ruido'};
for planta = 1:2
    for ensayo = 1:4
        figure;
        for k = 1:length(Kp_lista)
            archivo = sprintf('%s_%s_Kp_%g.csv', ...
                nombres{planta},pruebas{ensayo},Kp_lista(k));
            R = readtable(fullfile(salida,archivo));
            etiqueta = sprintf('Kp = %g A/K',Kp_lista(k));
            subplot(2,2,1);
            plot(R.t_s,R.Tb_C,'LineWidth',1.2,'DisplayName',etiqueta); hold on;
            subplot(2,2,2);
            plot(R.t_s,R.I_A,'LineWidth',1.2,'DisplayName',etiqueta); hold on;
            subplot(2,2,3);
            plot(R.t_s,R.V_V,'LineWidth',1.2,'DisplayName',etiqueta); hold on;
            subplot(2,2,4);
            plot(R.t_s,R.P_W,'LineWidth',1.2,'DisplayName',etiqueta); hold on;
        end
        subplot(2,2,1);
        plot(R.t_s,R.ref_C,'k--','DisplayName','Referencia');
        grid on; xlabel('Tiempo [s]'); ylabel('Tb [grados C]');
        title(['Temperatura: ' nombres{planta} ', ' pruebas{ensayo}]);
        legend('Location','best');
        subplot(2,2,2);
        yline(Imax,'k--','DisplayName','Limite superior');
        grid on; xlabel('Tiempo [s]'); ylabel('Corriente [A]');
        title('Esfuerzo de control'); legend('Location','best');
        subplot(2,2,3);
        grid on; xlabel('Tiempo [s]'); ylabel('Tension [V]'); title('Tension del modulo');
        subplot(2,2,4);
        grid on; xlabel('Tiempo [s]'); ylabel('Potencia [W]'); title('Potencia electrica');
        archivo = [nombres{planta} '_' pruebas{ensayo} '.pdf'];
        exportgraphics(gcf,fullfile(salida,archivo),'ContentType','vector');
    end
end
