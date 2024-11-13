clc; clear; close all;

data_folder = 'G:\공유 드라이브\BSL-Data\Processed_data\Hyundai_dataset\RPT_GITT\AHC_(3)_GITT';
save_path = data_folder;
I_1C = 0.000477; %[A]
id_cfa = 3; % 1 for cathode, 2 for fullcell , 3 for anode 

% MAT 파일 가져오기
slash = filesep;
files = dir([data_folder slash '*.mat']);

for i = 1:length(files)
   fullpath_now = [data_folder slash files(i).name];% path for i-th file in the folder
   load(fullpath_now);
   data(1)= [];

end
% 충전, 방전 스텝(필드) 구하기 

step_chg = [];
step_dis = [];

for i = 1:length(data)
    % type 필드가 C인지 확인
    if strcmp(data(i).type, 'C')
        % C가 맞으면 idx 1 추가
        step_chg(end+1) = i;
    % type 필드가 D인지 확인
    elseif strcmp(data(i).type, 'D')

        % 맞으면 idx 1 추가
        step_dis(end+1) = i;
    end
end



% STEP 내부에서의 전하량 구하기

for j = 1:length(data)
     %calculate capacities
     data(j).Q = trapz(data(j).t,data(j).I)/3600; %[Ah]
     data(j).cumQ = cumtrapz(data(j).t,data(j).I)/3600; %[Ah]
     

     % data(j).cumQ = abs(cumtrapz(data(j).t,data(j).I))/3600; %[Ah]
     
end

% Total QC, QD값 구하기 ( 전체 전하량 구하기) 
total_QC = sum(abs([data(step_chg).Q]));  % charge 상태 전체 Q값
total_QD = sum(abs([data(step_dis).Q])); % discharge 상태 전체 Q값

% % cumsumQ 필드 추가
% for i = 1:length(data)
%     if i == 1
%         data(i).cumsumQ = data(i).cumQ;
%     else
%         data(i).cumsumQ = data(i-1).cumsumQ(end) + data(i).cumQ;
%     end
% end
% 
% for i = 1 : length(data)
%     % CATODE, FCC -- > data(i).SOC = data(i).cumsumQ/total_QC\
%     data(i).SOC = data(i).cumsumQ/total_QC; % Anode
% end

% cumsumQ 필드 추가
for i = 1:length(data)
    if i == 1
        data(i).cumsumQ = data(i).cumQ;
    else
        data(i).cumsumQ = data(i-1).cumsumQ(end) + data(i).cumQ;
    end
end

for i = 1 : length(data)
    if id_cfa == 1 || id_cfa == 2 % FCC, Cathode
        data(i).SOC = data(i).cumsumQ/total_QC; 

    elseif id_cfa == 3 % Anode
        data(i).SOC = 1 + data(i).cumsumQ/total_QD;
    else
        error('Invalid id_cfa value. Please choose 1 for cathode, 2 for FCC, or 3 for anode.');
    end
end

% I의 평균을 필드에 저장하기 

for i = 1:length(data)
    data(i).avgI = mean(data(i).I);
end

% V 변화량 구하기
for i = 1 : length(data)
    if i == 1
       data(i).deltaV = zeros(size(data(i).V));
    else
       data(i).deltaV = data(i).V() - data(i-1).V(end);
    end
end

% Resistance 구하기 
for i = 1 : length(data)
    if data(i).avgI == 0
        data(i).R = zeros(size(data(i).V));
    else 
        data(i).R = (data(i).deltaV / data(i).avgI) .* ones(size(data(i).V));
    end
end


SOC1sc = [];
R1sc = [];

SOC1sd = [];
R1sd = [];



% 1s , 10s, 30s 에서 Resistance 
for i = 1:length(step_chg)-1

   data(step_chg(i)).R1s = data(step_chg(i)).R(10);

end


% 충전
for i = 1:length(step_chg)-1

    SOC1sc = [SOC1sc, data(step_chg(i)).SOC(10)];
    R1sc = [R1sc, data(step_chg(i)).R(10)];

end
% 방전
for i = 1:length(step_dis)

    SOC1sd = [SOC1sd, data(step_dis(i)).SOC(10)];
    R1sd = [R1sd, data(step_dis(i)).R(10)];

end


% spline을 사용하여 점들을 부드럽게 이어주기

smoothed_SOC_1sc = linspace(min(SOC1sc), max(SOC1sc), 100); 
smoothed_R_1sc = spline(SOC1sc, R1sc, smoothed_SOC_1sc); 

% Generate smoothed data for 'sd' case

smoothed_SOC_1sd = linspace(min(SOC1sd), max(SOC1sd), 100); 
smoothed_R_1sd = spline(SOC1sd, R1sd, smoothed_SOC_1sd); 



% 그래프 그리기
figure;
hold on;

plot(SOC1sc, R1sc, 'o');
plot(smoothed_SOC_1sc, smoothed_R_1sc);

hold off;

xlabel('SOC');
ylabel('Resistance (\Omega )', 'fontsize', 12);
title('SOC vs Resistance (charge)');
legend('1s', '1s (line)'); 
legend('1s', '1s (line)'); 
xlim([0 1])

% 방전 그래프
% 그래프 그리기
% Plot the graph for 'sd' case
figure(2);
hold on;

plot(SOC1sd, R1sd, 'o');
plot(smoothed_SOC_1sd, smoothed_R_1sd);


xlabel('SOC');
ylabel('Resistance (\Omega)', 'fontsize', 12);
title('SOC vs Resistance (Discharge)');
legend('1s', '1s (line)');
xlim([0 1]);


% 시간 초기화
for i = 1 : length(data)
    initialTime = data(i).t(1); % 초기 시간 저장
    data(i).t = data(i).t - initialTime; % 초기 시간을 빼서 시간 초기화
end
 

save('gitt_fit.mat','data')