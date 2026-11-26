% Autor: GR09, Integrante 1 (completar nombre).
% Proposito: comprobar si el enfriamiento solicitado es alcanzable.
% Entrada: configurar. Salida: tabla y curvas estaticas del modelo.
RHA_lista = [1.29 2.11 8.4];  % 400 LFM, 200 LFM, natural; incluye contacto
% Barrido fisico completo; el controlador sigue limitado a Imax = 2 A.
I_barrido = (0:0.001:Imax_celda)';
curvas = NaN(length(I_barrido),3);
tabla = zeros(3,6);
for caso = 1:3
    q = p_nom; q.RHA = RHA_lista(caso);
    for j = 1:length(I_barrido)
        Ij = I_barrido(j);
        x = equilibrio_peltier(Ij,q);
        gc = 1/q.RCA+q.K+q.alpha*Ij;
        gh = q.K+1/q.RHA-q.alpha*Ij;
        Aj = [-gc/q.CC q.K/q.CC; q.K/q.CH -gh/q.CH];
        % Excluir equilibrios inestables y temperaturas absolutas no fisicas.
        if all(real(eig(Aj))<0) && all(x>0)
            curvas(j,caso) = x(1)-273.15;
        end
    end
    [minimo,indice] = min(curvas(:,caso),[],'omitnan');
    permitido = I_barrido<=Imax;
    [minimo_ctrl,indice_ctrl] = min(curvas(permitido,caso),[],'omitnan');
    corrientes_ctrl = I_barrido(permitido);
    tabla(caso,:) = [RHA_lista(caso),minimo,I_barrido(indice), ...
        minimo_ctrl,corrientes_ctrl(indice_ctrl),minimo_ctrl<=5];
end
F = array2table(tabla,'VariableNames', ...
    {'RHA_K_W','Tb_min_fisica_C','I_min_fisica_A', ...
    'Tb_min_control_C','I_min_control_A','objetivo_5C_alcanzable'});
disp(F);
writetable(F,fullfile(salida,'factibilidad_termica.csv'));
figure;
estilos = {'k-','k--','k:'};
for caso = 1:3
    plot(I_barrido,curvas(:,caso),estilos{caso},'LineWidth',1.2); hold on;
end
grid on;
ylim([-5 50]); xlabel('Corriente [A]'); ylabel('Tb de equilibrio [grados C]');
title('Factibilidad estatica: equilibrios estables del modelo');
legend('400 LFM','200 LFM','Natural','Location','best');
yline(5,'k--','HandleVisibility','off');
xline(Imax,'k:','Limite operativo: 2 A','HandleVisibility','off');
exportgraphics(gcf,fullfile(salida,'factibilidad_termica.pdf'),'ContentType','vector');
