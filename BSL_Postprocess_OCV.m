% BSL OCV Code
clc; clear; close all;


%% Interface

% data folder
data_folder = 'C:\Users\jsong\Documents\MATLAB\Data\OCP\OCP0.05C_Full cell(half)(5)';
% data_folder = 'C:\Users\jsong\Documents\MATLAB\Data\OCP\OCP0.01C_Cathode Half cell(5)';

% cathode, fullcell, or anode
id_cfa = 1; % 1 for cathode, 2 for fullcell, 3 for anode, 0 for automatic (not yet implemented)

% OCV steps
    % chg/dis sub notation: with respect to the full cell operation
step_ocv_chg = 4;
step_ocv_dis = 6;

% parameters
y1 = 0.215685; % cathode stoic at soc = 100%. reference: AVL NMC811


save_path = data_folder;
sample_plot =2;





%% Engine
slash = filesep;
files = dir([data_folder slash '*.mat']);

for i = 1:length(files)
    fullpath_now = [data_folder slash files(i).name];% path for i-th file in the folder
    load(fullpath_now);
    
    for j = 1:length(data)
    % calculate capacities
        if length(data(j).t) >1
            data(j).Q = abs(trapz(data(j).t,data(j).I))/3600; %[Ah]
            data(j).cumQ = abs(cumtrapz(data(j).t,data(j).I))/3600; %[Ah]
        end
    end
    
   data(step_ocv_chg).soc = data(step_ocv_chg).cumQ/data(step_ocv_chg).Q;
   data(step_ocv_dis).soc = 1-data(step_ocv_dis).cumQ/data(step_ocv_dis).Q;

   % stoichiometry for cathode and anode (not for fullcell)
   if id_cfa == 1 % cathode
        data(step_ocv_chg).stoic = 1-(1-y1)*data(step_ocv_chg).soc;
        data(step_ocv_dis).stoic = 1-(1-y1)*data(step_ocv_dis).soc; 
   elseif id_cfa ==2 % anode
        data(step_ocv_chg).stoic = data(step_ocv_chg).soc;
        data(step_ocv_dis).stoic = data(step_ocv_dis).soc; 
   end


    % plot
    color_mat=lines(3);
    figure
    hold on; box on;
    plot(data(step_ocv_chg).soc,data(step_ocv_chg).V,'-',"Color",color_mat(1,:))
    plot(data(step_ocv_dis).soc,data(step_ocv_dis).V,'-',"Color",color_mat(2,:))
    %axis([0 1 3 4.2])
    xlim([0 1])
    set(gca,'FontSize',12)

    % capacity matrix
    capacity_chg(i,1) = data(step_ocv_chg).Q;
    capacity_dis(i,1) = data(step_ocv_dis).Q;


   % make an overall OCV struct
    
   % save the OCV struc

end