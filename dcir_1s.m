clc;clear;close all;
%% Data
data_folder = 'G:\공유 드라이브\BSL-Data\Processed_data\Hyundai_dataset\RPT_data(Formation,OCV,DCIR,C-rate,GITT,RPT)\DCIR_data\DCIR3\DCIR3_(6)_FCC_cyc';
save_path = data_folder;
I_1C = 0.00382; %[A]
id_cfa = 2; % 1 for cathode, 2 for fullcell , 3 for anode 

% MAT 파일 가져오기
slash = filesep;
files = dir([data_folder slash '*.mat']);

% 선택할 파일의 인덱스
selected_file_index = 1; % 첫 번째 파일 선택

% 선택한 파일 load
fullpath_now = [data_folder slash files(selected_file_index).name];
load(fullpath_now);
data(1) = [];

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

%% 내부 전하량 값들 구하기

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



% cumsumQ 필드 추가
for i = 1:length(data)
    if i == 1
        data(i).cumsumQ = data(i).cumQ;
    else
        data(i).cumsumQ = data(i-1).cumsumQ(end) + data(i).cumQ;
    end
end

%% SOC calculation

for i = 1 : length(data)
    if id_cfa == 1 || id_cfa == 2
        if id_cfa == 1
            
             data(i).SOC = data(i).cumsumQ/total_QC; % Cathode
            

          
        elseif id_cfa == 2
           
             data(i).SOC = data(i).cumsumQ/total_QC; % FCC
            
                        
        end
        % 큰 I 가지는 index 추출
        BigI = [];
        for i = 1:length(data)
            if abs(data(i).I) > (1/3 * I_1C)
               BigI = [BigI , i];
            end
        end
        
        if id_cfa == 1 || id_cfa == 2
            % BigIC, BigID 계산
            BigIC = BigI(BigI < step_chg(end));
            BigID = BigI(BigI >= step_chg(end));
        end
    elseif id_cfa == 3 % Anode
        BigI = [];
        for i = 1:length(data)
            data(i).SOC = 1 + data(i).cumsumQ/total_QD;
            if abs(data(i).I) > (1/3 * I_1C)
               BigI = [BigI , i];
               
            end
        end
        % BigI 계산
         BigI = BigI;
       
    else
        error('Invalid id_cfa value. Please choose 1 for cathode, 2 for FCC, or 3 for anode.');
    end
end

%% Calculate Iavg, DeltaV (To calculate resistance)
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


% 1s resistance
for i = 1:length(BigI)
 data(BigI(i)).R1s = data(BigI(i)).R(11);
end


SOC1sc = [];
R1sc = [];

SOC1sd = [];
R1sd = [];



if id_cfa == 1 || id_cfa == 2
    for i = 1:length(BigIC)
        SOC1sc = [SOC1sc, data(BigIC(i)).SOC(11)];
        R1sc = [R1sc, data(BigIC(i)).R1s];
    end
    for i = 1 : length(BigID)

        SOC1sd = [SOC1sd, data(BigID(i)).SOC(11)];
        R1sd = [R1sd, data(BigID(i)).R1s];
    end
elseif id_cfa == 3
    for i = 1:length(BigI)
        SOC1s = [SOC1s, data(BigI(i)).SOC(11)];
        R1s = [R1s, data(BigI(i)).R1s];

    end
end

% Generate smoothed data for 'sc' case

smoothed_SOC_1sc = linspace(min(SOC1sc), max(SOC1sc), 100);
smoothed_R_1sc = spline(SOC1sc, R1sc, smoothed_SOC_1sc);


% Plot the graph for 'sc' case
figure(1);
hold on;

plot(SOC1sc, R1sc, 'o');
plot(smoothed_SOC_1sc, smoothed_R_1sc);

hold off;

xlabel('SOC');
ylabel('Resistance (\Omega)', 'fontsize', 12);
title('SOC vs Resistance (Charge)');
legend('1s', '1s (line)');
xlim([0 1]);

% Generate smoothed data for 'sd' case

smoothed_SOC_1sd = linspace(min(SOC1sd), max(SOC1sd), 100);
smoothed_R_1sd = spline(SOC1sd, R1sd, smoothed_SOC_1sd);


% Plot the graph for 'sd' case
figure(2);
hold on;

plot(SOC1sd, R1sd, 'o');
plot(smoothed_SOC_1sd, smoothed_R_1sd);

hold off;

xlabel('SOC');
ylabel('Resistance (\Omega)', 'fontsize', 12);
title('SOC vs Resistance (Discharge)');
legend('1s', '1s (line)');
xlim([0 1]);


% 시간 초기화
for i = 1 : length(BigIC)
    initialTime = data(BigIC(i)).t(1); % 초기 시간 저장
    data(BigIC(i)).t = data(BigIC(i)).t - initialTime; % 초기 시간을 빼서 시간 초기화
end
 


save('dcir_fit.mat','data')