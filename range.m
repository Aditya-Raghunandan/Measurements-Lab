% =========================================================================
% Dual-Mic Range Characterisation (Distance vs. Amplitude)
% =========================================================================

clear; clc; close all;

% --- 1. ENTER YOUR DATA HERE ---
distances = [0, 10, 20, 30, 40, 50]; % Distances in cm

% --- MIC 1 DATA (CH1) in Volts ---
vpp_mic1_400Hz  = [0.093, 0.080, 0.080, 0.080, 0.080, 0.080]; % Your actual 400Hz data
vpp_mic1_1500Hz = [0.104, 0.085, 0.080, 0.080, 0.080, 0.080]; % <-- REPLACE THESE with your 1500Hz data
vpp_mic1_2000Hz = [0.142, 0.097, 0.080, 0.080, 0.080, 0.080]; % <-- REPLACE THESE with your 2000Hz data

% --- MIC 2 DATA (CH2) in Volts ---
vpp_mic2_400Hz  = [0.087, 0.080, 0.080, 0.080, 0.080, 0.080]; % Your actual 400Hz data
vpp_mic2_1500Hz = [0.103, 0.090, 0.080, 0.080, 0.080, 0.080]; % <-- REPLACE THESE with your 1500Hz data
vpp_mic2_2000Hz = [0.160, 0.090, 0.080, 0.080, 0.080, 0.080]; % <-- REPLACE THESE with your 2000Hz data

% --- 2. PLOT THE RANGE DECAY CURVES ---
figure('Name', 'Dual Mic Range Characterisation', 'Position', [150, 150, 1000, 600]);

% Mic 1 (Solid Lines, Filled Circles)
plot(distances, vpp_mic1_400Hz, '-ob', 'LineWidth', 2, 'MarkerSize', 6, 'MarkerFaceColor', 'b'); hold on;
plot(distances, vpp_mic1_1500Hz, '-og', 'LineWidth', 2, 'MarkerSize', 6, 'MarkerFaceColor', 'g');
plot(distances, vpp_mic1_2000Hz, '-or', 'LineWidth', 2, 'MarkerSize', 6, 'MarkerFaceColor', 'r');

% Mic 2 (Dashed Lines, Empty Circles)
plot(distances, vpp_mic2_400Hz, '--ob', 'LineWidth', 2, 'MarkerSize', 6);
plot(distances, vpp_mic2_1500Hz, '--og', 'LineWidth', 2, 'MarkerSize', 6);
plot(distances, vpp_mic2_2000Hz, '--or', 'LineWidth', 2, 'MarkerSize', 6);

% Graph Formatting
title('Dual Microphone Range Decay (Distance vs. V_{pp})');
xlabel('Distance from Sound Source (cm)');
ylabel('Peak-to-Peak Amplitude (V_{pp})');
legend('Mic 1: 400 Hz', 'Mic 1: 1500 Hz', 'Mic 1: 2000 Hz', ...
       'Mic 2: 400 Hz', 'Mic 2: 1500 Hz', 'Mic 2: 2000 Hz', 'Location', 'northeast');
grid on;
xlim([0 50]);

% --- 3. ADD THE 80mV NOISE FLOOR ZONE ---
% Force the Y-axis to start at 0 so we can see the red box!
ylim([0, 0.18]); 

% Get current x-axis limits to draw the patch perfectly across the bottom
x_limits = xlim;

% Draw the red shaded danger zone from 0V to 0.080V
patch([x_limits(1) x_limits(2) x_limits(2) x_limits(1)], [0 0 0.080 0.080], ...
    'red', 'FaceAlpha', 0.1, 'EdgeColor', 'red', 'LineStyle', '--', 'LineWidth', 1.5, 'HandleVisibility', 'off');

% Add text label inside the red zone
text(25, 0.040, 'UNUSABLE RANGE (Noise Floor ~80mV)', ...
    'Color', 'red', 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

fprintf('Ready! Just replace the 1500Hz and 2000Hz placeholder data and run.\n');