% =========================================================================
% Bulletproof Bandwidth Plotter (Reads frequency from filename)
% =========================================================================

clear; clc; close all;

folder_name = 'frequencySweepNoAmp'; 
files = dir(fullfile(folder_name, '*.csv'));

if isempty(files)
    error('No CSV files found in the SweepData folder!');
end

freq_points = zeros(length(files), 1);
vpp1_points = zeros(length(files), 1);
vpp2_points = zeros(length(files), 1);

fprintf('Processing %d files...\n', length(files));

for k = 1:length(files)
    filename = fullfile(folder_name, files(k).name);
    
    % --- THE NEW FIX: Extract the frequency number directly from the filename ---
    % This grabs the first chunk of numbers it sees in the filename (e.g., "200" from "200.csv")
    parsed_num = regexp(files(k).name, '\d+', 'match', 'once');
    if isempty(parsed_num)
        error('Could not find a number in filename: %s. Please name files like 200.csv', files(k).name);
    end
    freq_points(k) = str2double(parsed_num);
    
    % Read data
    opts = detectImportOptions(filename);
    data = readtable(filename, opts);
    
    t = data.TIME; y1_raw = data.CH1; y2_raw = data.CH2;
    
    if iscell(t) || isstring(t), t = str2double(strrep(t, ',', '.')); end
    if iscell(y1_raw) || isstring(y1_raw), y1_raw = str2double(strrep(y1_raw, ',', '.')); end
    if iscell(y2_raw) || isstring(y2_raw), y2_raw = str2double(strrep(y2_raw, ',', '.')); end
    
    % Remove DC Offset & Calculate Vpp
    y1 = y1_raw - mean(y1_raw);
    y2 = y2_raw - mean(y2_raw);
    vpp1_points(k) = max(y1) - min(y1);
    vpp2_points(k) = max(y2) - min(y2);
end

% --- SORT AND PLOT ---
[freq_points, sort_indices] = sort(freq_points);
vpp1_points = vpp1_points(sort_indices);
vpp2_points = vpp2_points(sort_indices);

figure('Name', 'Sensor Bandwidth Characterisation', 'Position', [100, 100, 1000, 600]);

semilogx(freq_points, vpp1_points, '-ob', 'LineWidth', 2, 'MarkerSize', 6, 'MarkerFaceColor', 'b'); hold on;
semilogx(freq_points, vpp2_points, '-or', 'LineWidth', 2, 'MarkerSize', 6, 'MarkerFaceColor', 'r');

y_limits = ylim;
patch([400 1500 1500 400], [y_limits(1) y_limits(1) y_limits(2) y_limits(2)], ...
    'green', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
text(750, y_limits(2)*0.9, 'Target Siren Range', 'Color', [0 0.5 0], 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

title('Microphone Bandwidth / Frequency Response (Task 6)');
xlabel('Frequency (Hz) - Log Scale');
ylabel('Peak-to-Peak Amplitude (V_{pp})');
legend('Mic 1', 'Mic 2', 'Siren Bandwidth (400-1500Hz)', 'Location', 'northeast');
grid on;
set(gca, 'XMinorGrid', 'on'); 
xlim([100, 15000]); % Widened slightly to show your 200Hz point nicely
% Force the X-axis to display normal numbers instead of scientific notation
set(gca, 'XTickLabel', num2str(get(gca, 'XTick')'));
fprintf('Complete! Frequency Response curve generated.\n');