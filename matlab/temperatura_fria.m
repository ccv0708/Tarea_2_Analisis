function Tc = temperatura_fria(I,p)
% Autor: GR09, Integrante 1 (completar nombre).
% Proposito: devolver solo Tc para buscar la corriente de equilibrio.
% Entrada: I y p. Salida: Tc [K].
x = equilibrio_peltier(I,p);
Tc = x(1);
end
