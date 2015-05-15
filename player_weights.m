% input: player control file
% output: weights for control

% userData format: [s, d, t, v, c]
% s: slope, 1 for uphill, 0 for flat, -1 for downhill
% d: remaining distance
% t: remaining time
% v: vehicle speed
% c: control, 1 for acc, 0 for nothing, -1 for brk

% data from the best user
% userData = [[1,900,36,0,1],[1,896,35,16,1],[1,886,34,29,1],[1,872,33,37,1],[1,854,32,43,1],[1,834,31,47,1],[1,812,30,51,1],[-1,788,29,53,0],[-1,763,28,62,1],[0,734,27,66,1],[1,704,26,69,1],[1,673,25,69,1],[0,642,24,69,1],[-1,611,23,72,0],[0,579,22,72,0],[-1,546,21,72,0],[1,515,20,69,0],[0,485,19,64,0],[0,457,18,62,0],[-1,429,17,64,0],[0,400,16,67,0],[1,371,15,63,0],[0,345,14,57,1],[-1,318,13,62,1],[-1,289,12,67,0],[-1,259,11,69,0],[1,228,10,68,0],[1,198,9,65,0],[1,170,8,62,0],[0,142,7,61,0],[-1,116,6,58,-1],[0,90,5,58,0],[1,64,4,55,0],[0,41,3,48,-1],[-1,21,2,44,-1],[-1,2,1,40,-1]];
% userData = reshape(userData, 5,length(userData)/5)';

% convert data from all users from data.json
% use the data to simulate and collect data to fit the control parameters
% addpath('..\..\code\tools\jsonlab\');
% loadjson('data.json')
% raw_data = ans;
l = length(raw_data);


alluser = cell(1,l);
allscore = zeros(1,l);
for i = 1:l
    raw_key = raw_data{i}.keys;
    if ~isempty(raw_key) && raw_key(1)~='"'
        keys = loadjson(raw_key);
    end

    acc = keys.acc;
    if isempty(acc)
        acc = [];
    elseif length(acc)>1
        if acc(1)==acc(2) %issue with js ghost click
            acc = acc(1:2:end);
        end
    end
    acc_sig = ones(1,length(acc));
    brk = keys.brake;
    if isempty(brk)
        brk = [];
    elseif length(brk)>1
        if brk(1)==brk(2) %issue with js ghost click
            brk = brk(1:2:end);
        end
    end
    brk_sig = -ones(1,length(brk));
    if (mod(length(acc),2)~=0)
        acc = [acc,908*20];
        acc_sig = [acc_sig,1];
    end
    if (mod(length(brk),2)~=0)
        brk = [brk,909*20];
        brk_sig = [brk_sig,-1];
    end
    x = [acc,brk];
    sig = [acc_sig,brk_sig];
    [x_sort,id] = sort(x,'ascend');
    sig_sort = sig(id);
    sig_sort(2:2:end-1) = 0;

    alluser{i} = struct('x',x_sort,'sig',sig_sort,...
        'fr',raw_data{i}.finaldrive,'score',raw_data{i}.score);
    allscore(i) = raw_data{i}.score;
end
savejson('alluser_control',alluser,...
    '.\alluser_control.json');


%%
% model: acc = (1+max(min(w_1*s + w_2*d/t - w_3*v, 1),-1))/3>0.5
%        brk = (1-max(min(w_1*s + w_2*d/t - w_3*v, 1),-1))/3>0.5

% % preprocess data
% D = zeros(size(userData,1),4);
% D(:,1) = userData(:,1);
% % D(:,2) = userData(:,2)/900./(userData(:,3)+1)*36;
% D(:,2) = userData(:,2)/900;
% D(:,3) = (userData(:,3)+1)/36;
% D(:,4) = -userData(:,4)/80;
% x = userData(:,5);





