%% get player weights
% get control weights and gear ratio for the first 5 attempts from all
% players
addpath('..\..\code\tools\jsonlab\');

% load plays 1 - 500
start = 1;
batch_size = 500;
% original_data = loadjson('.\data.json');
parameter_data = loadjson(['.\controlparameter_score_',num2str(start),'_',num2str(batch_size-1+start),'.json']);
parameter_data = parameter_data.controlparameter;
w1 = parameter_data.w;
score1 = parameter_data.score;

% load plays 501 - 1000
start = 501;
parameter_data = loadjson(['.\controlparameter_score_',num2str(start),'_',num2str(batch_size-1+start),'.json']);
parameter_data = parameter_data.controlparameter;
w2 = parameter_data.w;
score2 = parameter_data.score;

% load plays 1001 - 1500
start = 1001;
parameter_data = loadjson(['.\controlparameter_score_',num2str(start),'_',num2str(batch_size-1+start),'.json']);
parameter_data = parameter_data.controlparameter;
w3 = parameter_data.w;
score3 = parameter_data.score;

% load plays 1501 - 2000
start = 1501;
parameter_data = loadjson(['.\controlparameter_score_',num2str(start),'_',num2str(batch_size-1+start),'.json']);
parameter_data = parameter_data.controlparameter;
w4 = parameter_data.w;
score4 = parameter_data.score;


% combine data
w = [w1;w2;w3;w4];
score = [score1;score2;score3;score4];

num_game = 5;
max_player = 250; % the total number of players should be less than this

x = zeros(max_player*num_game,4);
y = zeros(max_player*num_game,1);
count = ones(max_player,1); % pointer

for i = 1:length(score)
    userid = original_data{i}.userid;
    if count(userid)<=num_game
        x((userid-1)*num_game+count(userid),:) = w(i,:);
        y((userid-1)*num_game+count(userid),:) = score(i);
        count(userid) = count(userid) + 1;
    end
end

use_id = sum(x.^2,2)>0;
x = x(use_id,:);
y = y(use_id,:);
[x,IA,IC] = unique(x,'rows');
y = y(IA);

l = length(y);
R = zeros(l);
% x = bsxfun(@rdivide, x, [1,3,3,3]);

% R could be nearly singular since some x are close to each other


for i = 1:l
    for j = 1:length(y)
        R(i,j) = exp(-1*norm(x(i,:)-x(j,:))^2);
    end
end
b = (ones(l,1)'*(R\y))/(ones(l,1)'*(R\ones(l,1)));

% savejson('user_data',struct('x',x,'y',-y','R',R,'b',b'),...
%     ['.\user_initial_',num2str(num_game),'_games.json']);
