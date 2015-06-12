% for record: the game played for the conference paper, after
% parameterization and re-simulation
% for the first 500 games, there are 80 successful ones
% for the first 1000 games, there are 221 successful ones
% all games together, there are 617 successful ones

addpath('..\..\code\tools\jsonlab\');

%% get a set of "good" players
original_data = loadjson('.\data.json');
player_performance = cell(250,1);
good_player = [];
player_gameid = cell(250,1);
for i = 1:length(original_data)
    data = original_data{i};
    score = (1-data.score/3600/0.55/1000)*100*sign(data.score+1);

    if isempty(player_performance{data.userid})
        player_performance{data.userid} = score;
        player_gameid{data.userid} = data.id;
    else
        player_performance{data.userid} = [player_performance{data.userid}, score];
        player_gameid{data.userid} = [player_gameid{data.userid}, data.id];
    end
end
for i = 1:length(player_performance)
    data = player_performance{i};
    if any(data(1:min(50,length(data)))>5)
        good_player = [good_player, i];
    end
end

%% create a one-class classifier using control parameters and simulated scores
limit = 500;
raw_data = loadjson('controlparameter_score_1_500.json');
raw_data = raw_data.controlparameter;
score_after_parameter = loadjson('score_after_parameter.json');
y = raw_data.score(:,:);
X = raw_data.w(:,:);
for i = 1:length(score_after_parameter)
    % NOTE score_after_parameter{i}.game_id starts from ZERO!!!
    if score_after_parameter{i}.game_id+1<=limit
        y(score_after_parameter{i}.game_id+1) = score_after_parameter{i}.score;
    end
end

% ID = zeros(limit,1);
% count = 1;
% % update score using simulation results after control parameterization
% for i = 1:length(y)
%     % NOTE game_id starts from ZERO!!!
%     if count<=limit
%         for j = 1:length(good_player)
%             gameid = player_gameid{good_player(j)};
%             if any(gameid==(i-1))
%                 ID(count) = i;
%                 count = count + 1;
%                 break;
%             end
%         end
%     end
% end
% 
% yy = y(ID);
% XX = X(ID,:);

yy = y;
XX = X;
Xtrain = XX(yy>0.1,:);
model = svmtrain(ones(size(Xtrain,1),1), Xtrain, '-s 2 -t 2 -n 1e-6 -e 1e-12');
model.SVs = full(model.SVs);
model.sv_coef = model.sv_coef';
savejson('model',model,'.\human_model_goodppl_threshold0_first500.json');

% %use SVM for regression
% % normalize X
% Xmean = mean(X);
% Xstd = std(X);
% ymean = mean(y);
% ystd = std(y);
% X = bsxfun(@minus,X,Xmean);
% X = bsxfun(@rdivide,X,Xstd);
% y = (y-ymean)/ystd;
% [n,p] = size(X);
% lambda = p;
% addpath('..\..\code\tools\libsvm\matlab\');
% model = svmtrain(y, X, '-s 3 -t 2');
% model.SVs = full(model.SVs);
% savejson('model',model,['.\player_model_',num2str(limit),'.json']);


% 
% % check classification using 2d projection
% D = squareform(pdist(X, 'euclidean'));
% X_ = mdscale(D,2, 'Criterion', 'sstress');
% y = sign(f);
% figure;hold on;
% for i = 1:size(X,1)
%     if y(i)>0
%         plot(X_(i,1),X_(i,2),'ok','MarkerSize',20);
%     else
%         plot(X_(i,1),X_(i,2),'or','MarkerSize',20);
%     end
% end


%% validate the classifier
data = loadjson('.\human_model_goodppl_threshold0_first500.json');
model = data.model;
svs = model.SVs;
w = model.sv_coef;
rho = model.rho;
gamma = 1/10; % one over #features
sample_size = 1e6;
test_parameters = [rand(sample_size,1),(rand(sample_size,9)-0.5)*6];
test_y = zeros(sample_size,1);
for i = 1:sample_size
    x = test_parameters(i,:);
    for j = 1:model.totalSV
        test_y(i) = test_y(i) + w(j)*exp(-gamma*norm(x - svs(j,:))^2);
    end
    test_y(i) = test_y(i) - rho;
end

testname = 'acc'; % acc for initial acceleration, brk for final braking

if strcmp(testname,'acc')
    % test conditions:
    % distance = 0~900
    % slope = 1
    % speed = 0

    %check uphill, zero speed, should acc
    test_d = 0:0.1:1;
    test_s = 1;
    test_v = 0;
    test_t = 0:0.1:1;
elseif strcmp(testname,'brk')
    %check downhill, max speed, close to the end, should brk
    test_d = 0:0.01:0.1;
    test_s = -1;
    test_v = 1;
    test_t = 0.1:0.1:1;
end

test_conditions = zeros(length(test_d)*length(test_t),9);
count = 1;
for i = 1:length(test_d)
    for j = 1:length(test_t)
        test_conditions(count,:) = [test_s, test_d(i), test_t(j),...
            test_v, test_d(i)*test_t(j), test_s*test_v,...
            test_s*test_d(i), test_d(i)^2, test_d(i)^3];
        count = count + 1;
    end
end

test_signal = zeros(sample_size,size(test_conditions,1));
for i = 1:sample_size
    for j = 1:size(test_conditions,1)
        test_signal(i,j) = test_parameters(i,2:end)*test_conditions(j,:)';
    end
end

positive = test_signal(test_y>0,:);
negative = test_signal(test_y<0,:);
% if strcmp(testname,'acc')
%     correct_positive = sum(sum(positive>0.5))/numel(positive);
%     correct_negative = sum(sum(negative>0.5))/numel(negative);
% elseif strcmp(testname,'brk')
%     correct_positive = sum(sum(positive<-0.5))/numel(positive);
%     correct_test_signal = sum(sum(test_signal<-0.5))/numel(test_signal);
% end

% plot the chance to follow rules at each state
if strcmp(testname,'acc')
    signal_for_state_in_positive = sum(positive>0.5)/size(positive,1);
    signal_for_state_in_test_signal = sum(test_signal>0.5)/size(test_signal,1);
elseif strcmp(testname,'brk')
    signal_for_state_in_positive = sum(positive<-0.5)/size(positive,1);
    signal_for_state_in_test_signal = sum(test_signal<-0.5)/size(test_signal,1);
end

figure; hold on;
surf(reshape(signal_for_state_in_positive,length(test_t),length(test_d)));
surf(reshape(signal_for_state_in_test_signal,length(test_t),length(test_d)));
colormap(gray)
caxis([0.2,0.7])
colorbar

% contourf(reshape(signal_for_state_in_positive,length(test_t),length(test_d)),100)
% colormap(gray)
% shading flat
% caxis([0.4,0.9])
% colorbar
% figure
% contourf(reshape(signal_for_state_in_test_signal,length(test_t),length(test_d)),100)
% colormap(gray)
% shading flat
% caxis([0.4,0.9])
% colorbar

% figure; hold on;
% for i = 1:1000
%     if test_y(i)>0
% %         plot(test_signal(i,:),'k');
%     else
%         plot(test_signal(i,:),'r');
%     end
% end