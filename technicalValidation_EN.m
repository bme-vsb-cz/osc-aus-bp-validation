%% Technical validation of OSC vs. AUS
% Script for technical validation of oscillometric (OSC) and auscultatory (AUS)
% blood pressure measurements. Visualization of basic box plots, correlation, Bland–Altman
% analysis of differences between OSC and AUS, and assessment of intra-visit
% repeatability.
%
% Input: cleaned and anonymized JSON dataset obtained from the data processing
% pipeline.
% Output: figures and numerical summaries for technical validation.
% Author: T. Kauzlaričová
% Created: 2026-01-06
% MATLAB version: R2023b 

txt = "bp_measurements_processed.json";
data = readstruct(txt);

%% Distribution of blood pressure values (AUS and OSC)
% Boxplots comparing AUS and OSC measurements
%   - Systolic blood pressure (SYS)
%   - Diastolic blood pressure (DIA)
arrayBP = [data.sysPressureA; data.diasPressureA; data.sysPressureO; data.diasPressureO]';

BP_SYS = [arrayBP(:,3); arrayBP(:,1)];
clear BP_SYS_group BP_DIA_group
BP_SYS_group(1:size(arrayBP, 1),1) = 0;
BP_SYS_group(size(arrayBP, 1) + 1:size(arrayBP, 1)*2,1) = 1;
BP_SYS_group = categorical(logical(BP_SYS_group),logical([1 0]),{'OSC','AUS'});

figure("Units","centimeters", "Position",[5 5 15 7])
tiledlayout("flow", "TileSpacing","compact", "Padding","tight")
nexttile(); boxchart(BP_SYS_group,BP_SYS)
title("Systolic blood pressure")
grid on
xlabel('Measurement methods'); ylabel('Blood pressure (mmHg)')

BP_DIA = [arrayBP(:,4); arrayBP(:,2)];
BP_DIA_group(1:size(arrayBP, 1),1) = 0;
BP_DIA_group(size(arrayBP, 1) + 1:size(arrayBP, 1)*2,1) = 1;
BP_DIA_group = categorical(logical(BP_DIA_group),logical([1 0]),{'OSC','AUS'});

nexttile(); 
boxchart(BP_DIA_group,BP_DIA)
grid on
title("Diastolic blood pressure")
xlabel('Measurement methods'); ylabel('Blood pressure (mmHg)')

clear BP_SYS_group BP_DIA_group BP_DIA BP_SYS
%% Correlation between methods 
    % Pearson r
    % Spearman ρ

% Pearson Correlation
r_sys = corr(arrayBP(:,1), arrayBP(:,3));
r_dia = corr(arrayBP(:,2), arrayBP(:,4));

% Spearman Correlation
rho_sys = corr(arrayBP(:,1), arrayBP(:,3), "type","Spearman");
rho_dia = corr(arrayBP(:,2), arrayBP(:,4), "type","Spearman");

fprintf("\t\t\tSYS\t\tDIA\n");
fprintf("Pearson r:\t%0.3f\t%0.3f\n", r_sys, r_dia);
fprintf("Spearman ρ:\t%0.3f\t%0.3f\n", rho_sys, rho_dia);

% Scatter plot
figure("Units","centimeters", "Position",[5 5 15 7])
tiledlayout("flow", "TileSpacing","compact", "Padding","tight")
nexttile(); scatter(arrayBP(:,1), arrayBP(:,3))
grid on
title('Systolic blood pressure')
xlabel('AUS (mmHg)'); ylabel("OSC (mmHg)")
nexttile(); scatter(arrayBP(:,2), arrayBP(:,4))
grid on
title("Diastolic blood pressure")
xlabel('AUS (mmHg)'); ylabel("OSC (mmHg)")

%% Bland–Altman analysis: OSC vs. AUS
% Analysis of differences between OSC and AUS measurements

% Differences (OSC – AUS)
diff_sys = arrayBP(:,3) - arrayBP(:,1);
diff_dia = arrayBP(:,4) - arrayBP(:,2);

% Means
mean_sys = (arrayBP(:,3) + arrayBP(:,1)) / 2;
mean_dia = (arrayBP(:,4) + arrayBP(:,2)) / 2;

% Mean difference
MD_sys = mean(diff_sys);
MD_dia = mean(diff_dia);
fprintf("Mean difference:\t%0.3f\t%0.3f\n", MD_sys, MD_dia);

% SD of differences
sd_sys = std(diff_sys);
sd_dia = std(diff_dia);
fprintf("Difference deviation:\t%0.3f\t%0.3f\n", sd_sys, sd_dia);

% LoA
LoA_sys = [MD_sys + 1.96*sd_sys, MD_sys - 1.96*sd_sys];
LoA_dia = [MD_dia + 1.96*sd_dia, MD_dia - 1.96*sd_dia];
fprintf("LoA systolic:\t%0.3f\t%0.3f\n", LoA_sys);
fprintf("LoA diastolic:\t%0.3f\t%0.3f\n", LoA_dia);

% RPC = Repeatability Coefficient
RPC_sys = 1.96*sd_sys;
RPC_dia = 1.96*sd_dia;
fprintf("Repeatability Coefficient:\t%0.3f\t%0.3f\n", RPC_sys, RPC_dia);
% Plot SYS
figure("Units","centimeters", "Position",[5 5 17 8])
tiledlayout(1,2, "TileSpacing","loose", "Padding","compact")
nexttile(); plot(mean_sys, diff_sys, '.');
hold on; grid on
yline(LoA_sys(1), '--', 'Color','r', 'LineWidth', 1)
yline(LoA_sys(2), '--', 'Color','r', 'LineWidth', 1)
yline(MD_sys, 'LineWidth',1)
xlabel('Mean of OSC and AUS methods (mmHg)')
ylabel('Difference between OSC and AUS methods (mmHg)', 'FontSize',8)
title("Bland-Altman analysis of systolic BP")
text(max(mean_sys)-20, MD_sys+2, sprintf("MD = %0.2f", MD_sys), 'HorizontalAlignment','left', 'FontWeight','bold', 'FontSize',8);
text(max(mean_sys)-30, LoA_sys(1)+5, sprintf("LoA_{upper} = %0.1f", LoA_sys(1)), 'HorizontalAlignment','left', 'FontWeight','bold', 'FontSize',8);
text(max(mean_sys)-30, LoA_sys(2)-5, sprintf("LoA_{lower} = %0.1f", LoA_sys(2)), 'HorizontalAlignment','left', 'FontWeight','bold', 'FontSize',8);
ax = gca;
box(ax,'off')
grid on

% Plot DIA
nexttile(); plot(mean_dia, diff_dia, '.');
hold on; grid on
yline(LoA_dia(1), '--', 'Color','r', 'LineWidth', 1)
yline(LoA_dia(2), '--', 'Color','r', 'LineWidth', 1)
yline(MD_dia, 'LineWidth',1)
xlabel('Mean of OSC and AUS methods (mmHg)')
ylabel('Difference between OSC and AUS methods (mmHg)', 'FontSize',8)
title("Bland-Altman analysis of diastolic BP")
text(max(mean_dia)-10, MD_dia+2, sprintf("MD = %0.1f", MD_dia), 'HorizontalAlignment','left', 'FontWeight','bold', 'FontSize',8);
text(max(mean_dia)-20, LoA_dia(1)+4, sprintf("LoA_{upper} = %0.1f", LoA_dia(1)), 'HorizontalAlignment','left', 'FontWeight','bold', 'FontSize',8);
text(max(mean_dia)-20, LoA_dia(2)-4, sprintf("LoA_{lower} = %0.1f", LoA_dia(2)), 'HorizontalAlignment','left', 'FontWeight','bold', 'FontSize',8);
ax = gca;
box(ax,'off')

clear diff_sys diff_dia mean_sys mean_dia 
%% Repeatability - intra-visit repeatability
    % Evaluation of repeatability of repeated measurements within a single visit
patient_ID = string([data.personalId]');

in = 1;
label = 1;
clear label_array
size_array = size(patient_ID, 1);
label_array = zeros(size_array,1);

while in < size_array

    if in + 3 <= size_array

        if patient_ID(in) == patient_ID(in + 3)
            label_array(in:in+3) = label;
            label = label + 1;
            in = in + 3;
        elseif patient_ID(in) == patient_ID(in + 2)
            label_array(in:in+2) = label;
            label = label + 1;
            in = in + 2;
        elseif patient_ID(in) == patient_ID(in + 1)
            label_array(in:in+1) = label;
            label = label + 1;
            in = in + 1;
        else 
            in = in + 1;
        end

    elseif in + 2 <= size_array
        
        if patient_ID(in) == patient_ID(in + 2)
            label_array(in:in+2) = label;
            label = label + 1;
            in = in + 2;
        elseif patient_ID(in) == patient_ID(in + 1)
            label_array(in:in+1) = label;
            label = label + 1;
            in = in + 1;
        else 
            in = in + 1;
        end

    elseif in + 1 <= size_array
        
        if patient_ID(in) == patient_ID(in + 1)
            label_array(in:in+1) = label;
            label = label + 1;
            in = in + 1;
        else 
            in = in + 1;
        end
        
    end
end


num_repetition = max(label_array);

idx_repetition = unique(label_array);
clear patient_ID patient_ID in size_array label

% Search for repetitions
% for two, three, and four visits

num_2visits = 0;
num_3visits = 0;
num_4visits = 0;
idx_diff2 = 1;
idx_diff3 = 1;
idx_diff4 = 1;
clear array_diff array_diff2 array_diff3 array_diff4

for typ_BP = 1:4
    idx_diff2 = 1;
    idx_diff3 = 1;
    idx_diff4 = 1;

    for i = 1:size(idx_repetition, 1)
        idx = label_array == i;
        num_meas = sum(idx);
    
        if num_meas == 2
            values = arrayBP(idx,typ_BP);
            diffrence = abs(values(1) - values(2));
            array_diff2(idx_diff2, typ_BP) = diffrence;
    
            idx_diff2 = idx_diff2 + 1;
            num_2visits = num_2visits + 1;
    
        elseif num_meas == 3
            values = arrayBP(idx,typ_BP);
            diffrence1 = abs(values(1) - values(2));
            diffrence2 = abs(values(1) - values(3));
            diffrence3 = abs(values(2) - values(3));
    
            array_diff3(idx_diff3:idx_diff3+2, typ_BP) = [diffrence1, diffrence2, diffrence3] ;
            
            idx_diff3 = idx_diff3 + 3;
            num_3visits = num_3visits + 1;
    
        elseif num_meas == 4
            values = arrayBP(idx,typ_BP);
            diffrence1 = abs(values(1) - values(2));
            diffrence2 = abs(values(1) - values(3));
            diffrence3 = abs(values(1) - values(4));
            diffrence4 = abs(values(2) - values(3));
            diffrence5 = abs(values(2) - values(4));
            diffrence6 = abs(values(3) - values(4));
    
            array_diff4(idx_diff4:idx_diff4+5, typ_BP) = [diffrence1, diffrence2, diffrence3, diffrence4, diffrence5, diffrence6] ;
            
            idx_diff4 = idx_diff4 + 6;    
             num_4visits = num_4visits + 1;
    
        end
        
    end
end

fprintf("Total number of repetitions: %d\nNumber of 2 visits: %d\nNumber of 3 visits: %d\nNumber of 4 visits: %d\n", num_repetition,num_2visits/4,num_3visits/4,num_4visits/4);
clear idx_diff2 idx_diff3 idx_diff4 idx_repetition values num_meas idx typ_BP diffrence diffrence1 diffrence2 diffrence3 diffrence4 diffrence5 diffrence6


array_diff = [array_diff2', array_diff3', array_diff4'];
median_diff = median(array_diff');
std_diff = std(array_diff');
Q1 = quantile(array_diff', 0.25);
Q3 = quantile(array_diff', 0.75);
q_diff = iqr(array_diff');
rpc_diff = 1.96 * std_diff;

fprintf("\t\tSYS_AUS\tDIA_AUS\tSYS_OSC\tDIA_OSC\n");
fprintf("Median:\t%d\t\t%d\t\t%d\t\t%d\n", median_diff);
fprintf("STD:\t%0.2f\t%0.2f\t%0.2f\t%0.2f\n", std_diff);
fprintf("RPC:\t%0.2f\t%0.2f\t%0.2f\t%0.2f\n", rpc_diff);
fprintf("Q1:\t\t%d\t\t%d\t\t%d\t\t%d\n", Q1);
fprintf("IQR:\t%d\t\t%d\t\t%d\t\t%d\n", q_diff);
fprintf("Q3:\t\t%d\t\t%d\t\t%d\t\t%d\n", Q3);