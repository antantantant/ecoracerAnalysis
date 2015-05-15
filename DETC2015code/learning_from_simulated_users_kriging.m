%% create a one-class classifier using control parameters and simulated scores
addpath('..\..\..\code\tools\jsonlab\');
raw_data = loadjson('score_after_parameter.json');
l = length(raw_data);

% for record: the game played for the conference paper, after
% parameterization and re-simulation
% for the first 500 games, there are 80 successful ones
% for the first 1000 games, there are 221 successful ones
% all games together, there are 617 successful ones
y0 = zeros(l,1);
X0 = zeros(l,10);
for i = 1:l
    y0(i) = raw_data{i}.score;
    x = loadjson(raw_data{i}.keys);
    fr = raw_data{i}.finaldrive;
    fr = (fr-10)/30;
    X0(i,:) = [fr,x];
end

X = X0(1:limit,:);
y = y0(1:limit);

% use kriging for regression
% normalize X
Xmean = mean(X);
Xstd = std(X);
ymean = mean(y);
ystd = std(y);
X = bsxfun(@minus,X,Xmean);
X = bsxfun(@rdivide,X,Xstd);
y = (y-ymean)/ystd;
[n,p] = size(X);
lambda = 0.01*p;

% update kriging model
R = zeros(n);
for pp = 1:n
    for qq = (pp+1):n
        R(pp,qq) = exp(-1/lambda*norm(X(pp,:)-X(qq,:))^2);
    end
end
R = R + R';
R = R + eye(n);
b = (ones(1,n)*(R\y))/(ones(1,n)*(R\ones(n,1)));

savejson('model',struct('Xmean',Xmean,'Xstd',Xstd,'ymean',ymean,...
    'ystd',ystd,'lambda',lambda,'X',X,'y',y,'R',R,'b',b),'.\player_model_1000.json');
