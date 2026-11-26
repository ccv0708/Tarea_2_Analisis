function [t, Tb, I] = simular_arranque(p, I0, Kc, Ki, Tref, Imax, anti_windup)
% Simula el arranque del bloque desde 25 C con el PI.
% Usa las ecuaciones no lineales de la Tarea 1 y el método de Euler.
% Imax        = corriente máxima que puede dar el controlador [A]
% anti_windup = 1 para usarlo, 0 para no usarlo
% El control es I = I0 + Kc*e + Ki*integral(e), con e = Tb - Tref.

dt = 0.05;          % paso de tiempo [s]
t = 0:dt:1500;
Tb = zeros(1, length(t));
I = zeros(1, length(t));

Tc = p.Tamb;        % todo empieza a temperatura ambiente [K]
Th = p.Tamb;
integral = 0;

for k = 1:length(t)
    e = (Tc - 273.15) - Tref;
    I_pedida = I0 + Kc*e + Ki*integral;

    % saturación
    I_real = I_pedida;
    if I_real > Imax
        I_real = Imax;
    end
    if I_real < 0
        I_real = 0;
    end

    % Clamping: detener solo la integracion que aumentaria la saturacion.
    % Si el error cambia de signo, se permite descargar el integrador.
    if anti_windup == 1
        if I_real == I_pedida || (I_pedida>Imax && e<0) || (I_pedida<0 && e>0)
            integral = integral + e*dt;
        end
    else
        integral = integral + e*dt;
    end

    % guardar resultados
    Tb(k) = Tc - 273.15;
    I(k) = I_real;

    % ecuaciones de la Tarea 1
    Qc = p.alpha*Tc*I_real - 0.5*I_real^2*p.R - p.K*(Th - Tc);
    Qh = p.alpha*Th*I_real + 0.5*I_real^2*p.R - p.K*(Th - Tc);
    Qcarga = (p.Tamb - Tc)/p.RCA;
    Qdisipador = (Th - p.Tamb)/p.RHA;

    Tc = Tc + dt*(Qcarga - Qc)/p.CC;
    Th = Th + dt*(Qh - Qdisipador)/p.CH;
end
end