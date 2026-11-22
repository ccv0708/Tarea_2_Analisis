% Autor: GR09, Integrante 1 (completar nombre).
% Proposito: calcular polos, error y esfuerzo inicial sin simular.
% Entrada: planta y Kp_lista cargados por configurar. Salida: CSV y figura.
ganancia_DC = numG(end)/denG(end);
tabla = zeros(length(Kp_lista),7);
for k = 1:length(Kp_lista)
    kp = Kp_lista(k);
    % e = Tb - referencia. Por eso el denominador es D(s)-Kp*N(s).
    den_cerrado = denG-kp*[0 numG];
    polos = sort(roots(den_cerrado));
    fraccion_error = 1/(1-kp*ganancia_DC);
    I_inicial = I0+kp*20;
    tabla(k,:) = [kp, polos(1), polos(2), fraccion_error, ...
        100*fraccion_error, I_inicial, min(Imax,max(Imin,I_inicial))];
end
T = array2table(tabla,'VariableNames',{'Kp_A_K','polo1','polo2', ...
    'ess_escalon_1K','ess_porcentaje','I_pedida_arranque_A','I_aplicada_arranque_A'});
disp(T);
writetable(T,fullfile(salida,'analisis_P.csv'));
disp('Estos polos y errores son del modelo lineal SIN saturacion.');

% Lugar de polos con la misma convencion; no requiere Control System Toolbox.
kp_barrido = linspace(0,10,201);
polos_barrido = zeros(2,length(kp_barrido));
for k = 1:length(kp_barrido)
    polos_barrido(:,k) = sort(roots(denG-kp_barrido(k)*[0 numG]));
end
figure;
plot(real(polos_barrido(1,:)),imag(polos_barrido(1,:)),'b.'); hold on;
plot(real(polos_barrido(2,:)),imag(polos_barrido(2,:)),'r.');
grid on; xlabel('Parte real [1/s]'); ylabel('Parte imaginaria [1/s]');
title('Polos del lazo P: error Tb - referencia');
exportgraphics(gcf,fullfile(salida,'polos_P.pdf'),'ContentType','vector');
