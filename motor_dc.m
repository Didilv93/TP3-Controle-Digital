% Controle Digital
% Alunos: Diego Santos / Virgínia Almeida

% Exemplo de projeto de controlador digital pelo lugar das raizes:
% Sistema motor DC;
% No domínio 's', G(s) = K/[(Js + b) * (Ls + R) + K^2];
% Entrada: Tensão
% Saída: Velocidade

close all; clear; clc;

%% Escolha do periodo de amostragem:
J = 0.01;
b = 0.1;
K = 0.01;
R = 1;
L = 0.5;

%% Modelo continuo do processo

% Processo em MA:
num=K;
den = [(J * L) (J * R + L * b) (b * R + K ^ 2)];
Gs = tf(num, den);

% Espaco de estados:
[Ac, Bc, Cc, Dc] = tf2ss(num, den);
SysS = ss(Ac, Bc, Cc, Dc);

% Discretizacao do modelo em tempo continuo:
Ts = 0.15;
SysZ = c2d(SysS, Ts, 'zoh');
[A, B, C, D, Ts] = ssdata(SysZ);
[nGz, dGz] = ss2tf(A, B, C, D);
Gz = zpk(minreal(tf(nGz, dGz, Ts)));

%% Teste de Observabilidade:

% Validando se o sistema é observável:
Ob = obsv(A,C);
if (size(A,1)-rank(Ob)==0)
    disp('O sistema e observavel.');
end

%% Especificacoes de requisito:

% Autovalores desejados em z:
p1z = 0.5 + i*0.5;
p2z = 0.5 - i*0.5;

% Equacao caracteristica desejada:
alphacz = conv([1 -p1z],[1 -p2z]);

%% Projeto pela Formula de Ackerman

L = ( alphacz(1)*A^2 + alphacz(2)*A + alphacz(3)*eye(size(A)) )*inv(Ob)*[zeros(size(A,1)-1,1);  1];


%% Projeto do Controlador:

% Validando se o sistema é controlável
Co = [B A*B];
if (size(A,1)-rank(Co)==0)
    disp('O sistema e controlavel.');
end

%% Especificacoes de desempenho:

Mpmax = 10; % percentual de overshoot
ts = 1.82; % tempo de subida
ta = 3; % tempo de acomodacao

% Regioes que atendem as especificacoes:
zetamin = 0.6*(1 - Mpmax/100); % taxa de amortecimento
wnmin = 1.8/ts; % frequencia natural
zetawnmin = 4.6/ta; % zeta*wn, em que wn esta em rad/s

% Especificacoes (um pouco mais rigoross que valores minimos) que atendem regioes:
zeta = 0.5;
wn = 6.0*Ts; % em rad
zeta*wn / Ts; % Observe que  esse valor deve ser > zetawnmin calculado acima
r0 = exp(-zeta*wn); % a regiao interna a esse raio delimita o ta minimo

% Polos desejados em s:
p1s = -zetawnmin + i*wn*sqrt(1-zeta^2);
p2s = -zetawnmin - i*wn*sqrt(1-zeta^2);

% Polos desejados em z:
pc1z = exp(p1s*Ts);
pc2z = exp(p2s*Ts);

% Equacao caracteristica esperada:
alphacontz = conv([1 -p1z],[1 -p2z]);

% Alocacao de polos:
K = [zeros(1,size(A,1)-1)  1]*inv(Co)*( A^2 + alphacontz(2)*A + alphacontz(3)*eye(size(A)) );

%% Simulacao:

x0 = [1 1]';
N = 30;
u = 0;
kT = [0:Ts:(N-1)*Ts];
xmf = [x0 x0]; % Estado verdadeiro
ymf = C*x0;
xhat = [10 10]'; % Estado estimado
for k = 2:N
    xhat(:,k) = A*xhat(:,k-1) + B*u(k-1)  +  L*(ymf(:,k-1) - C*xhat(:,k-1)); % Observador de estado:
    u(k) = -K*xhat(:,k);  % Aplicando a lei de controle:
    % Processo controlado:
    xmf(:,k+1) = A*xmf(:,k) + B*u(k);
    ymf(:,k+1) = C*xmf(:,k+1);
end

figure; subplot(311); stairs(kT, xmf(1,1:end-1), 'b'); hold on; stairs(kT, xhat(1,:), 'r'); xlabel('kT (s)'); ylabel('x_1(k)'); legend('x_1(k)','xhat_1(k)')
        subplot(312); stairs(kT, xmf(2,1:end-1), 'b'); hold on; stairs(kT, xhat(2,:), 'r'); xlabel('kT (s)'); ylabel('x_2(k)');
        subplot(313); stairs(kT, u, 'b'); xlabel('kT (s)'); ylabel('u(k)');
        
