% Autor: GR09, Integrante 1 (completar nombre).
% Proposito: comprobar si el enfriamiento solicitado es alcanzable.
% Entrada: configurar. Salida: tabla y curvas estaticas del modelo.
RHA_lista = [1.29 2.11 8.4];  % 400 LFM, 200 LFM, natural; incluye contacto
I_barrido = (Imin:0.001:Imax)';
curvas = NaN(length(I_barrido),3);
tabla = zeros(3,4);
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
    tabla(caso,:) = [RHA_lista(caso),minimo,I_barrido(indice),minimo<=5];
end
F = array2table(tabla,'VariableNames', ...
    {'RHA_K_W','Tb_min_C','I_en_min_A','objetivo_5C_alcanzable'});
disp(F);
writetable(F,fullfile(salida,'factibilidad_termica.csv'));
figure;
plot(I_barrido,curvas,'LineWidth',1.2); grid on;
ylim([-5 50]); xlabel('Corriente [A]'); ylabel('Tb de equilibrio [grados C]');
title('Factibilidad estatica: equilibrios estables del modelo');
legend('400 LFM','200 LFM','Natural','Location','best');
yline(5,'k--','HandleVisibility','off');
exportgraphics(gcf,fullfile(salida,'factibilidad_termica.pdf'),'ContentType','vector');
