%% Fit control parameters
addpath('..\..\code\tools\jsonlab\');
batch_size = 391; % last batch has 391 entries
start = 2001;
raw_data = loadjson(['.\converted_',num2str(start),'_',num2str(batch_size-1+start),'.json']);
% original_data = loadjson('.\data.json');
score = zeros(batch_size,1);
match = zeros(batch_size,1);

HIDDEN_NEURON = 4; %number of neurons for a single hidden layer net
p = 4; %number of input parameters
w = zeros(batch_size,(HIDDEN_NEURON*p+2*HIDDEN_NEURON+1)+1);
for i = 1:batch_size
    cd = loadjson(raw_data{i}.control_data);
    l = length(cd);
    x = zeros(l,1);
    D = zeros(l,3);
    DD = zeros(1,4);
    if(iscell(cd))
        for j = 1:l
            temp = cd{j};
            if(iscell(temp))
                x(j) = 0;
                DD(j,:) = [temp{1:4}];
            else
                x(j) = temp(end);
                DD(j,:) = temp(1:4);
            end
        end
    else
        x = cd(:,end);
        DD = cd(:,1:4);
    end
    D(:,1) = DD(:,1);
    D(:,2) = DD(:,2)/900;
    D(:,3) = (DD(:,3)+1)/36;
    D(:,4) = DD(:,4)/80;
    remove_id = DD(:,3)==-1;
    D(remove_id,:) = [];
    x(remove_id,:) = [];
%     D(:,5) = D(:,2)./D(:,3);
%     D(:,6) = D(:,1).*D(:,4);
%     D(:,7) = D(:,1).*D(:,2);
%     D(:,8) = D(:,2).^2;
%     D(:,9) = D(:,2).^3;
    
    % acc: -D*w +0.5 <0
    % brk: D*w +0.5 <0
    % other: -0.5 -D*w <0 && D*w -0.5 <0
    % convert to A*w < b
    
    if sum(x.^2)==0 || sum(x) == -length(x) % if all zeros or all -1
        w(i,2:end) = 0;
        match(i) = 1;
    elseif sum(x)==length(x) % if all ones
        w(i,2:end) = [zeros(1,24),1]; % set the final bias to 1, not looking at states at all
        match(i) = 1;
    else
        % train with feedforward net
        net = feedforwardnet(4);
        net.inputs{1}.processFcns = {};
        net.trainParam.showWindow = false;
        net.trainParam.showCommandLine = true;
        net.divideParam.trainRatio = 1.0;
        net.divideParam.valRatio = 0.0;
        net.divideParam.testRatio = 0.0;
        [net,tr] = train(net,D',x');
        xbar = net(D');
        match(i) = sum(abs(xbar'-x)<0.49)/length(x);
        w(i,2:end) = getwb(net);
    end
    w(i,1) = (original_data{start+i-1}.finaldrive-10)/30;
    score(i) = raw_data{i}.score;
end
savejson('controlparameter',struct('w',w,'score',score,'match',match),...
    ['.\controlparameter_score_',num2str(start),'_',num2str(batch_size-1+start),'.json']);