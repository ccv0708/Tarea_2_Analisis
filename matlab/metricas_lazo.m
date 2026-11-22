function m = metricas_lazo(t,r,y,I,inicio,banda,Imin,Imax)
% Autor: GR09, Integrante 1 (completar nombre).
% Proposito: medir seguimiento, transitorio y esfuerzo en un tramo del ensayo.
% Entradas: tiempo [s], referencia/salida [C], corriente [A], inicio [s],
% banda absoluta [K], limites de corriente [A]. Salida: estructura m.
t = t(:); r = r(:); y = y(:); I = I(:);
if length(t)~=length(y) || length(t)~=length(r) || length(t)~=length(I)
    error('Las cuatro senales deben tener la misma longitud.');
end
if any(diff(t)<=0) || any(~isfinite([t;r;y;I])) || banda<=0
    error('Revise tiempos, valores finitos y banda positiva.');
end
antes = find(t<inicio,1,'last');
if isempty(antes)
    y0 = y(1);
else
    y0 = y(antes);
end
usar = t>=inicio;
tt = t(usar)-inicio; rr = r(usar); yy = y(usar); ii = I(usar);
if length(tt)<3
    error('El tramo de evaluacion debe contener al menos tres muestras.');
end
if max(abs(rr-rr(end)))>1e-8
    error('La referencia debe ser constante en el tramo evaluado.');
end
% El ultimo 10 % del TIEMPO estima el valor final; no demuestra equilibrio.
cola = tt>=0.9*tt(end);
if sum(cola)>=2
    yfinal = trapz(tt(cola),yy(cola))/(tt(end)-tt(find(cola,1)));
else
    yfinal = yy(end);
end
error_real = rr-yy;
m.yfinal_C = yfinal;
m.rango_cola_K = max(yy(cola))-min(yy(cola));
m.error_medio_cola_K = rr(end)-yfinal;
m.estacionario_observado = m.rango_cola_K<=banda;
m.ess_K = NaN;
if m.estacionario_observado
    m.ess_K = m.error_medio_cola_K;
end
m.ess_abs_K = abs(m.ess_K);
m.ISE_K2s = trapz(tt,error_real.^2);
m.Imax_A = max(ii);
m.Imin_A = min(ii);
saturado = ii<=Imin+1e-6 | ii>=Imax-1e-6;
m.t_saturacion_s = trapz(tt,double(saturado));
m.tr_s = NaN;
m.sobrepaso_pct = NaN;
% tr: 10-90 % del cambio ALCANZADO, no del cambio pedido.
if abs(yfinal-y0)>1e-6 && (yfinal-y0)*(rr(end)-y0)>0
    avance = (yy-y0)/(yfinal-y0);
    i10 = find(avance>=0.1,1);
    i90 = find(avance>=0.9,1);
    if ~isempty(i10) && ~isempty(i90)
        m.tr_s = tt(i90)-tt(i10);
    end
end
% ts: permanencia dentro de la banda alrededor de la REFERENCIA.
fuera = find(abs(error_real)>banda,1,'last');
m.ts_ref_s = NaN;
if isempty(fuera)
    m.ts_ref_s = 0;
elseif fuera<length(tt)
    m.ts_ref_s = tt(fuera+1);
end
% Otro ts: estabilizacion alrededor del valor final estimado.
fuera = find(abs(yy-yfinal)>banda,1,'last');
m.ts_final_s = NaN;
if isempty(fuera)
    m.ts_final_s = 0;
elseif fuera<length(tt)
    m.ts_final_s = tt(fuera+1);
end
if ~m.estacionario_observado
    m.tr_s = NaN;
    m.ts_final_s = NaN;
end
% En enfriamiento, bajar POR DEBAJO de la referencia es sobrepaso.
cambio_pedido = rr(end)-y0;
if abs(cambio_pedido)>1e-6
    exceso = sign(cambio_pedido)*(yy-rr(end));
    m.sobrepaso_pct = 100*max(0,max(exceso))/abs(cambio_pedido);
end
% Fluctuacion en el ultimo 20 %; para ruido tambien mirar el ensayo limpio.
cola = tt>=0.8*tt(end);
m.Tb_std_K = std(yy(cola));
m.I_std_A = std(ii(cola));
m.banda_K = banda;
end
