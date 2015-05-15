%% Fit control parameters
addpath('..\..\code\tools\jsonlab\');
batch_size = 391; % last batch has 391 entries
start = 2001;
% raw_data = loadjson(['.\converted_',num2str(start),'_',num2str(batch_size-1+start),'.json']);
w = zeros(batch_size,10);
% original_data = loadjson('.\data.json');
score = zeros(batch_size,1);

a = 1000; %weight on acc and brk;
options = optimset('MaxFunEvals', 1e4);
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
    D(:,5) = D(:,2)./D(:,3);
    D(:,6) = D(:,1).*D(:,4);
    D(:,7) = D(:,1).*D(:,2);
    D(:,8) = D(:,2).^2;
    D(:,9) = D(:,2).^3;
    
    % acc: -D*w +0.5 <0
    % brk: D*w +0.5 <0
    % other: -0.5 -D*w <0 && D*w -0.5 <0
    % convert to A*w < b
    A = [-a*D(x>0,:);a*D(x<0,:);-D(x==0,:);D(x==0,:)];
    b = 0.5*[-a*ones(sum(x>0),1);-a*ones(sum(x<0),1);...
        ones(sum(x==0)*2,1);];
    %%% solve min_w exp(A*w-b) %%%
%     w(i,2:4) = fmincon(@(x)obj(x,A,b),zeros(3,1),[],[],[],[],-3*ones(3,1),3*ones(3,1));
    w(i,2:10) = fminunc(@(x)obj(x,A,b),zeros(9,1),options);
    
    %test if A*w < b
    test = A*w(i,2:10)'-b;
%     if any(test>0)
%         wait = 1;
%     end
    
    w(i,1) = (original_data{start+i-1}.finaldrive-10)/30;
    score(i) = raw_data{i}.score;
end
savejson('controlparameter',struct('w',w,'score',score),...
    ['.\controlparameter_score_',num2str(start),'_',num2str(batch_size-1+start),'.json']);