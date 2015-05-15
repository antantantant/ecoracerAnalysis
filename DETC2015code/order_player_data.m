% reorganize original data
% data downloaded from server do not have continuous order
% original_data = loadjson('.\data.json');

order = zeros(length(original_data),1);
for i = 1:length(original_data)
    id = original_data{i}.id;
    order(i) = id;
end
save('player_data_order.mat','order');