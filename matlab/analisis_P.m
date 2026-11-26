% Autor: GR09, Integrante 1 (completar nombre).
% Proposito: calcular polos, error y esfuerzo inicial sin simular.
% Entrada: planta y Kp_lista cargados por configurar. Salida: CSV y figura.
ganancia_DC = numG(end)/denG(end);
tabla = zeros(length(Kp_lista),8);
for k = 1:length(Kp_lista)
    kp = Kp_lista(k);
    % Incluir H(s)=1/(tau_corriente*s+1), con e=Tb-referencia.
    den_cerrado = conv([tau_corriente 1],denG)-kp*[0 0 numG];
    polos = sort(roots(den_cerrado));
    fraccion_error = 1/(1-kp*ganancia_DC);
    I_inicial = I0+kp*20;
    tabla(k,:) = [kp, polos(1), polos(2), polos(3), fraccion_error, ...
        100*fraccion_error, I_inicial, min(Imax,max(Imin,I_inicial))];
end
T = array2table(tabla,'VariableNames',{'Kp_A_K','polo1','polo2','polo3', ...
    'ess_escalon_1K','ess_porcentaje','I_pedida_arranque_A','I_comando_limitado_A'});
disp(T);
writetable(T,fullfile(salida,'analisis_P.csv'));
disp('Estos polos y errores son del modelo lineal SIN saturacion.');
disp('El mando limitado no es I(0): la corriente aplicada inicia en I0.');

% Lugar de polos con la misma convencion; no requiere Control System Toolbox.
kp_barrido = linspace(0,10,201);
polos_barrido = zeros(3,length(kp_barrido));
for k = 1:length(kp_barrido)
    polos_barrido(:,k) = sort(roots(conv([tau_corriente 1],denG)-kp_barrido(k)*[0 0 numG]));
end
figure;
plot(real(polos_barrido(1,:)),imag(polos_barrido(1,:)),'k.'); hold on;
plot(real(polos_barrido(2,:)),imag(polos_barrido(2,:)),'kx');
plot(real(polos_barrido(3,:)),imag(polos_barrido(3,:)),'k+');
grid on; xlabel('Parte real [1/s]'); ylabel('Parte imaginaria [1/s]');
title('Polos del lazo P con dinamica de corriente');
exportgraphics(gcf,fullfile(salida,'polos_P.pdf'),'ContentType','vector');
