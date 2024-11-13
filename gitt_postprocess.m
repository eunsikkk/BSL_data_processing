% 파일 경로 가져오기
clc; clear; close all;

data_folder = 'G:\공유 드라이브\BSL-Data\Processed_data\Hyundai_dataset\RPT_GITT (1)\CHC_(4)_GITT';
save_path = data_folder;
I_1C = 0.000477; %[A]
id_cfa = 1; % 1 for cathode, 2 for fullcell , 3 for anode 

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

%% Figure plot

% SOC-Voltage
total_soc = [];
total_voltage = [];



total_voltage = [];
total_current = [];
total_t = [];


for i = 1:length(data)
    total_t = [total_t; data(i).t];
    total_current = [total_current; data(i).I];
    total_voltage = [total_voltage; data(i).V];
end

% time- voltage

figure(3);
yyaxis left
plot(total_t, total_voltage, 'b-');
xlabel('Time');
ylabel('Voltage (V)');


yyaxis right
plot(total_t, total_current, 'r-');
ylabel('Current (A)');
ylim([-0.0005 0.0005])



% 충전 시 SOC-Voltage 데이터
total_soc_chg = [];
total_voltage_chg = [];

for i = step_chg
    total_soc_chg = [total_soc_chg; data(i).SOC];
    total_voltage_chg = [total_voltage_chg; data(i).V];
end

% 방전 시 SOC-Voltage 데이터
total_soc_dis = [];
total_voltage_dis = [];

for i = step_dis
    total_soc_dis = [total_soc_dis; data(i).SOC];
    total_voltage_dis = [total_voltage_dis; data(i).V];
end

% 그래프 그리기
figure;
hold on;
plot(total_soc_chg, total_voltage_chg, 'b', 'LineWidth', 1.5); % 충전: 빨간색
plot(total_soc_dis, total_voltage_dis, 'r', 'LineWidth', 1.5); % 방전: 검정색
xlabel('State of Charge');
ylabel('Voltage');
legend('Charge', 'Discharge');
grid on;
hold off;






