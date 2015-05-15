%% create a one-class classifier using control parameters and simulated scores
addpath('..\..\code\tools\jsonlab\');
% raw_data = loadjson('score_after_parameter.json');
% l = length(raw_data);
% X = [];
% 
% for i = 1:l
%     score = raw_data{i}.score;
%     if score>0 
%         x = loadjson(raw_data{i}.keys);
%         if ~any(abs(x)>10)
%             fr = raw_data{i}.finaldrive;
%             fr = (fr-10)/30;
%             X = [X;[fr,x]];
%         end
%     end
% end
% 
% addpath('..\..\code\tools\libsvm\matlab\');
% model = svmtrain(ones(size(X,1),1), X, '-s 2 -t 2 -n 1e-6 -e 1e-12');
% % test prediction function
% f = zeros(size(X,1),1);
% svs = model.SVs;
% w = model.sv_coef;
% rho = model.rho;
% gamma = 1/10; % one over #features
% for i = 1:size(X,1)
%     x = X(i,:);
%     for j = 1:model.totalSV
%         f(i) = f(i) + w(j)*exp(-gamma*norm(x - svs(j,:))^2);
%     end
%     f(i) = f(i) - rho;
% end
% sum(f>0)
% 
% hitrate = svmpredict(ones(size(X,1),1), X, model);
% model.SVs = full(model.SVs);
% model.sv_coef = model.sv_coef';
% % savejson('model',model,'.\player_model.json');
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
data = loadjson('.\player_model.json');
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

% test conditions:
% distance = 0~900
% slope = 1
% speed = 0

%check uphill, zero speed, should acc
test_d = 0:0.1:1;
test_s = 1;
test_v = 0;
test_t = 0:0.1:1;

% %check downhill, max speed, close to the end, should brk
% test_d = 0:0.01:0.1;
% test_s = -1;
% test_v = 1;
% test_t = 0.1:0.1:1;

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
% correct_positive = sum(sum(positive>0.5))/numel(positive);
% correct_negative = sum(sum(negative>0.5))/numel(negative);
correct_positive = sum(sum(positive<-0.5))/numel(positive);
correct_test_signal = sum(sum(test_signal<-0.5))/numel(test_signal);

% plot the chance to follow rules at each state
% signal_for_state_in_positive = sum(positive>0.5)/size(positive,1);
% signal_for_state_in_test_signal = sum(test_signal>0.5)/size(test_signal,1);
signal_for_state_in_positive = sum(positive<-0.5)/size(positive,1);
signal_for_state_in_test_signal = sum(test_signal<-0.5)/size(test_signal,1);
figure; hold on;
surf(reshape(signal_for_state_in_positive,length(test_t),length(test_d)));
surf(reshape(signal_for_state_in_test_signal,length(test_t),length(test_d)));
colormap(gray)
caxis([0,1])
colorbar

contourf(reshape(signal_for_state_in_positive,length(test_t),length(test_d)),100)
colormap(gray)
shading flat
caxis([0.4,0.9])
colorbar
figure
contourf(reshape(signal_for_state_in_test_signal,length(test_t),length(test_d)),100)
colormap(gray)
shading flat
caxis([0.4,0.9])
colorbar

% figure; hold on;
% for i = 1:1000
%     if test_y(i)>0
% %         plot(test_signal(i,:),'k');
%     else
%         plot(test_signal(i,:),'r');
%     end
% end