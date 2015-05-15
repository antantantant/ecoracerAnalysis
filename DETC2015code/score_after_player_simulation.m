%% Fit control parameters
addpath('..\..\code\tools\jsonlab\');
batch_size = 500; % last batch as 391 entries
start = 1;
raw_data = loadjson(['.\converted_',num2str(start),'_',num2str(batch_size-1+start),'.json']);
% original_data = loadjson('.\data.json');
score = zeros(2391,1);
for i = 1:batch_size
    score(i) = raw_data{i}.score;
end

start = 501;
raw_data = loadjson(['.\converted_',num2str(start),'_',num2str(batch_size-1+start),'.json']);
for i = 1:batch_size
    score(start-1+i) = raw_data{i}.score;
end

start = 1001;
raw_data = loadjson(['.\converted_',num2str(start),'_',num2str(batch_size-1+start),'.json']);
for i = 1:batch_size
    score(start-1+i) = raw_data{i}.score;
end

start = 1501;
raw_data = loadjson(['.\converted_',num2str(start),'_',num2str(batch_size-1+start),'.json']);
for i = 1:batch_size
    score(start-1+i) = raw_data{i}.score;
end

start = 2001;
batch_size = 391; % last batch as 391 entries
raw_data = loadjson(['.\converted_',num2str(start),'_',num2str(batch_size-1+start),'.json']);
for i = 1:batch_size
    score(start-1+i) = raw_data{i}.score;
end
save('score_after_player_simulation.mat','score');

original_score = zeros(2391,1);
for i = 1:2391
    original_score(i) = (1-original_data{i}.score/3600/0.55/1000)*100*...
        sign(original_data{i}.score+1);
end

score(score<0) = 0;
plot(score,original_score,'.');

score_successful = score;
original_score_successful = original_score;
failed = (score==0)|(original_score==0);
score_successful(failed) = [];
original_score_successful(failed) = [];
plot(score_successful,original_score_successful,'.');

corr([score,original_score])
corr([score_successful,original_score_successful])