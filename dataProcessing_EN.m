%% Data processing and quality control pipeline
%
% This script performs data preprocessing, quality control, and preparation
% of a clinical blood pressure dataset for subsequent statistical analysis.
% The workflow includes sorting and filtering of raw records, detection of
% physiologically implausible values, handling of missing data, and harmonization
% of categorical variables.
%
% A semi-automated, human-in-the-loop approach is employed for selected quality
% control steps. Whenever potentially incorrect or incomplete records are detected,
% the script outputs the record to the command window and requests user input to
% either remove the record or manually correct the identified value. This strategy
% was chosen to ensure data integrity while preserving borderline but clinically
% plausible measurements that cannot be reliably resolved by fully automated rules.
%
% Additional processing steps include correction of anthropometric inconsistencies,
% translation of categorical variables from Czech to English, anonymization of
% personal identifiers, derivation of subject age, and generation of an "incomplete"
% flag indicating missing key measurements.
%
% The final output is a cleaned and anonymized dataset exported in JSON format,
% suitable for reproducible analysis and sharing as supplementary material.
%
% Input: raw JSON export from data collection platform. 
% Output: cleaned and anonymized JSON dataset.
% Author: T. Kauzlaričová
% Created: 2025-11-15
% MATLAB version: R2023b


disp("Start")
disp("Loading dataset...")
txt = "bloodPressure31._12. 2025.json";
dataRaw = readstruct(txt);
disp("Done loading.")

% 1. Sort the dataset by record ID
[~,index] = sortrows([dataRaw.id].'); dataRaw = dataRaw(index); clear index;
disp("Sorting the dataset by record ID")

% 2. Delete the first records -> test records, record ID from 100 upwards
dataRaw(1:77) = [];
disp("First 99 records deleted -> test records, record ID from 100 upwards.")

% 3. The first records without arm width information (added later during data collection)
disp("The first 106 records (ID 100–206) have no arm width information (added later during the process).")

%% Semi-automated data cleaning
% If the algorithm encounters incorrect data, it prints the record and waits for user input.
% User response:
%   0 - incorrect record -> delete the record
%   2 - incorrect value, but the correct value can be estimated -> correct the record
%
% First cleaning: extreme values outside physiological limits
% Second cleaning: incomplete values (missing AUS or OSC data)
% Third cleaning: cases where DIA is greater than or equal to SYS

SBP_min = 50; SBP_max = 250;
DBP_min = 30; DBP_max = 150;
MAP_min = 40; MAP_max = 160;

% 1st and 2nd cleaning
arrayBP = [dataRaw.sysPressureA; dataRaw.diasPressureA; dataRaw.sysPressureO; dataRaw.diasPressureO; dataRaw.meanPressureO]';

valid_idx = arrayBP(:,1) >= SBP_min & arrayBP(:,1) <= SBP_max & ...
            arrayBP(:,2) >= DBP_min & arrayBP(:,2) <= DBP_max & ...
            arrayBP(:,3) >= SBP_min & arrayBP(:,3) <= SBP_max & ...
            arrayBP(:,4) >= DBP_min & arrayBP(:,4) <= DBP_max & ...
            arrayBP(:,5) >= MAP_min & arrayBP(:,5) <= MAP_max & ...
            not(isnan(arrayBP(:,1))) & not(isnan(arrayBP(:,2))) & not(isnan(arrayBP(:,3))) & not(isnan(arrayBP(:,4))) & not(isnan(arrayBP(:,5))) ;

fprintf("Cleaning the dataset of extreme values outside physiological limits and incomplete values." + ...
    " Semi-automated process: user response required when evaluating incorrect data," + ...
    " whether it is an incomplete or completely incorrect record to be deleted, or whether it is," + ...
    " for example, a typo that can be corrected.\n");

for i = 1:size(valid_idx, 1)
    if valid_idx(i) == false
        disp(dataRaw(i))
        prompt = sprintf("\t0 - incorrect record -> delete\t2 - incorrect value, but can be estimated -> correct\nUser input: ");
        feedback(i) = input(prompt);
    end
end
clear prompt arrayBP valid_idx

%% Semi-automated correction of incorrect values (requires user intervention)
for i = 1:size(feedback, 2)
    if feedback(i) == 2
        disp(dataRaw(i))
        prompt = sprintf("From this selection sysA, diaA, sysO, diaO or mapO, write where the error is: ");
        typeBPError(i) = string(input(prompt)); 
        prompt = sprintf("Enter the corrected value: ");
        CorrectBP(i) = input(prompt); 
    end
end

dataBPclean = dataRaw;
for i = 1:size(typeBPError, 2)
    switch typeBPError(i)
        case "sysA"
            dataBPclean(i).sysPressureA = CorrectBP(i);
        case "diaA"
            dataBPclean(i).diasPressureA = CorrectBP(i);
        otherwise
            continue
    end
end

clear prompt

%% Remove missing and incorrect pressure values
% Any corrected record (feedback==2) is kept; records flagged for deletion are removed.
feedback(feedback == 2) = 1;
feedback = logical(feedback);
dataBPvalid = dataBPclean(feedback);

%% Check the 1st and 2nd cleaning
arrayBP = [dataBPvalid.sysPressureA; dataBPvalid.diasPressureA; dataBPvalid.sysPressureO; dataBPvalid.diasPressureO; dataBPvalid.meanPressureO]';

valid_idx = arrayBP(:,1) >= SBP_min & arrayBP(:,1) <= SBP_max & ...
            arrayBP(:,2) >= DBP_min & arrayBP(:,2) <= DBP_max & ...
            arrayBP(:,3) >= SBP_min & arrayBP(:,3) <= SBP_max & ...
            arrayBP(:,4) >= DBP_min & arrayBP(:,4) <= DBP_max & ...
            arrayBP(:,5) >= MAP_min & arrayBP(:,5) <= MAP_max & ...
            not(isnan(arrayBP(:,1))) & not(isnan(arrayBP(:,2))) & not(isnan(arrayBP(:,3))) & not(isnan(arrayBP(:,4))) & not(isnan(arrayBP(:,5))) ;

if all(valid_idx == 1)
    disp('BP data are OK')
else
    disp('ERROR in BP data')
end

clear valid_idx

%% 3rd cleaning
valid_idx = arrayBP(:,1) > arrayBP(:,2) & ... % sysA > diaA
            arrayBP(:,3) > arrayBP(:,4) & ... % sysO > diaO
            arrayBP(:,5) > arrayBP(:,4);      % mapO > diaO

if all(valid_idx == 1)
    disp('BP data are OK')
else
    disp('ERROR in BP data')
end

clear valid_idx

%% Check remaining variables: replace 0 with missing values where appropriate
dataAnthroClean = dataBPvalid;

for i = 1:length(dataBPvalid)
    if dataBPvalid(i).height == 0
        dataAnthroClean(i).height = NaN;
        dataAnthroClean(i).bmi = NaN;
    end
end

for i = 1:length(dataAnthroClean)
    if dataBPvalid(i).weight == 0
        dataAnthroClean(i).weight = NaN;
        dataAnthroClean(i).bmi = NaN;
    end
end

for i = 1:length(dataAnthroClean)
    if dataBPvalid(i).armSize == 0
        dataAnthroClean(i).armSize = NaN;
        dataAnthroClean(i).cuffType = missing;
    end
end

BMI = [dataAnthroClean.bmi]';
valid_idx = BMI >= 15 & BMI <= 60 & not(isnan(BMI));

%% Semi-automated correction of BMI-related errors (requires user intervention)
for i = 1:size(valid_idx, 1)
    if valid_idx(i) == 0
        disp(dataAnthroClean(i))
        prompt = sprintf("From this selection W for weight or H for height, write where the error is: ");
        typeBMIError(i) = string(input(prompt)); 
        prompt = sprintf("Enter the corrected value: ");
        CorrectBMI(i) = input(prompt); 
    end
end

dataTranslated = dataAnthroClean;
for i = 1:size(typeBMIError, 2)
    switch typeBMIError(i)
        case "W"
            dataTranslated(i).weight = CorrectBMI(i);
            dataTranslated(i).bmi = dataTranslated(i).weight / ((dataTranslated(i).height / 100) ^2);
        case "H"
            dataTranslated(i).height = CorrectBMI(i);
            dataTranslated(i).bmi = dataTranslated(i).weight / ((dataTranslated(i).height / 100) ^2);
        otherwise
            continue
    end
end
clear prompt valid_idx

%% Translation (CZ -> EN)
% Gender
cz_gender = ["Muž", "Žena", "Jiné"];
en_gender = ["man", "woman", "other"];
translation_gender = translationCZ_EN([dataTranslated.gender], cz_gender, en_gender);

% Cardiac arrhythmias
cz_rhythm = ["Sinusový rytmus", "FISI/FLUSI", "Četné SVES", "Četné KES"];
en_rhythm = ["sinus rhythm", "AF/AFL", "frequent PACs", "frequent PVCs"];
translation_rhythm = translationCZ_EN([dataTranslated.rhytmDisorders], cz_rhythm, en_rhythm);

% Hypertension class
cz_hypertension = ["Optimální", "Normální", "Vysoký normální", "Hypertenze stupeň 1", "Hypertenze stupeň 2", "Hypertenze stupeň 3"];
en_hypertension = ["optimal", "normal", "high normal", "hypertension grade 1", "hypertension grade 2", "hypertension grade 3"];
translation_hypertension = translationCZ_EN([dataTranslated.hypertensionClass], cz_hypertension, en_hypertension);
translation_hypertensionSYS = translationCZ_EN([dataTranslated.sysPressureClassification], cz_hypertension, en_hypertension);
translation_hypertensionDIA = translationCZ_EN([dataTranslated.diasPressureClassification], cz_hypertension, en_hypertension);

% Measurement method
cz_method = ["Metoda 1", "Metoda 2", "Metoda 3"];
en_method = ["method 1", "method 2", "method 3"];
translation_method = translationCZ_EN([dataTranslated.method], cz_method, en_method);

% Cuff type
cat_cuff = [dataTranslated.cuffType];
cz_cuff = ["Klasická", "Větší"];
en_cuff = ["standard", "bigger"];

M = containers.Map(cz_cuff, en_cuff);

translation_cuff = strings(size(cat_cuff));
translation_cuff(:) = missing;

valid = ~ismissing(cat_cuff);
translation_cuff(valid) = arrayfun(@(s) M(s), cat_cuff(valid), 'UniformOutput', false);
clear cz_gender en_gender cz_rhythm en_rhythm cz_hypertension en_hypertension cz_cuff en_cuff cat_cuff M valid

%% Map personalID to pac_XXXX style
ID_patient = [dataTranslated.personalId];
unique_ID = unique(ID_patient, 'stable');
n = numel(unique_ID);
new_ID = arrayfun(@(x) sprintf('pac_%04d', x), 1:n, 'UniformOutput', false);

[~, idx] = ismember(ID_patient, unique_ID);
ID_pacXXX = new_ID(idx);
clear ID_patient unique_ID n  new_ID idx

%% Convert date of birth to age
clear age
num_corrected = 1;
dataFinal = dataTranslated;

for i = 1:size(dataTranslated, 2)
    current_date = datetime(dataTranslated(i).creationDate,'InputFormat','uuuu-MM-dd''T''HH:mm:ss.SSSX','TimeZone','UTC');
    birth_date= datetime(dataTranslated(i).birthday,'InputFormat','uuuu-MM-dd''T''HH:mm:ss.SSSX','TimeZone','UTC');
    if year(birth_date) == 2054
        birth_date.Year = 1954;      % Fix year 2054 to 1954 due to incorrect parsing of birth number/date
        num_corrected = num_corrected + 1;
        idx_corrected(num_corrected) = i; 
    end
    age(i,1) = years(current_date - birth_date);
    dataFinal(i).birthday = floor(years(current_date - birth_date)); 
    age = floor(age);
end
clear birth_date current_date i num_corrected idx_corrected

%% Insert all updates (stored in separate variables) back into the structure

[dataFinal.age] = dataFinal.birthday; dataFinal = orderfields(dataFinal,[1:3,24,4:23]); dataFinal = rmfield(dataFinal,'birthday');
dataFinal = rmfield(dataFinal, 'medications'); % Does not carry information

for i = 1:size(dataTranslated, 2)
    dataFinal(i).age = age(i);
    dataFinal(i).gender = translation_gender(i);
    dataFinal(i).rhytmDisorders = translation_rhythm(i);
    dataFinal(i).hypertensionClass = translation_hypertension(i);
    dataFinal(i).sysPressureClassification = translation_hypertensionSYS(i);
    dataFinal(i).diasPressureClassification = translation_hypertensionDIA(i);
    dataFinal(i).cuffType = translation_cuff(i);
    dataFinal(i).method = translation_method(i);
    dataFinal(i).personalId = ID_pacXXX(i);
end

%% Add an INCOMPLETE flag
valid_idx = not(isnan([dataFinal.armSize])) & not(isnan([dataFinal.height])) & not(isnan([dataFinal.weight]));

for i = 1:size(dataFinal, 2)
    if valid_idx(i) == true
        dataFinal(i).incomplete = false;
    else
        dataFinal(i).incomplete = true;
    end
end

%% Export JSON
dataExport = dataFinal;

for i = 1:size(dataRaw, 2)
    dataExport(i).gender = string(dataRaw(i).gender);
    dataExport(i).rhytmDisorders = string(dataRaw(i).rhytmDisorders);
    dataExport(i).hypertensionClass = string(dataRaw(i).hypertensionClass);
    dataExport(i).method = string(dataRaw(i).method);
    dataExport(i).personalId = string(dataRaw(i).personalId);
    dataExport(i).sysPressureClassification = string(dataRaw(i).sysPressureClassification);
    dataExport(i).diasPressureClassification = string(dataRaw(i).diasPressureClassification);
    dataExport(i).cuffType = string(dataRaw(i).cuffType);
end

encoded = jsonencode(dataExport,PrettyPrint=true);
fid = fopen('bp_measurements_processed.json','w');
fprintf(fid,'%s',encoded);
fclose(fid);

%% Functions
function [translation] = translationCZ_EN (kat, cz, en)
    M = containers.Map(cz, en);
    translation = arrayfun(@(s) M(s), kat, 'UniformOutput', false);
end
