clc; clear; close all;

data_folder = 'G:\공유 드라이브\BSL-Data\Processed_data\Hyundai_dataset\RPT_data(Formation,OCV,DCIR,C-rate,GITT,RPT)\DCIR_data\DCIR3\DCIR3_(6)_FCC_cyc';
save_path = data_folder;
I_1C = 0.00382; %[A]
id_cfa = 1; % 1 for cathode, 2 for fullcell , 3 for anode 

% MAT 파일 가져오기
slash = filesep;
files = dir([data_folder slash '*.mat']);

% 선택할 파일의 인덱스
selected_file_index = 2; % 첫 번째 파일 선택

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



% STEP 내부에서의 전하량 구하기

for j = 1:length(data)
     %calculate capacities
     data(j).Q = abs(trapz(data(j).t,data(j).I))/3600; %[Ah]
     data(j).cumQ = abs(cumtrapz(data(j).t,data(j).I))/3600; %[Ah]
     

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

for i = 1: length(data)
    if id_cfa == 1 || id_cfa == 2
        data(i).SOC = data(i).cumsumQ/total_QC;
    elseif id_cfa == 3
        data(i).SOC = 1 - data(i).cumsumQ/total_QD;
    end
end

figure

% 모든 데이터 포인트를 하나의 배열로 결합
total_soc = [];
total_voltage = [];

for i = 1:length(data)
    total_soc = [total_soc; data(i).SOC];
    total_voltage = [total_voltage; data(i).V];
    plot(total_soc,total_voltage)
end



% 모든 데이터 포인트를 하나의 배열로 결합
total_soc = [];
total_current = [];

for i = 1:length(data)
    total_soc = [total_soc; data(i).SOC];
    total_current = [total_current; data(i).I];
end

% 연결된 SOC와 전류 그래프 플롯
figure
plot(total_soc, total_current, 'r');
xlabel('State of Charge (SOC)');
ylabel('Current (A)');
title('Current vs SOC');


% 모든 데이터 포인트를 하나의 배열로 결합
total_t = [];
total_current = [];

for i = 1:length(data)
    total_t = [total_t; data(i).t];
    total_current = [total_current; data(i).I];
end

% 연결된 SOC와 전류 그래프 플롯
figure
plot(total_t, total_current, 'r');
xlabel('time');
ylabel('Current (A)');
title('Current vs TIME');
