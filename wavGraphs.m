% =========================================================================
% Dual-Mic Analysis (With DC Offset Removal)
% =========================================================================

clear; clc; close all;

% --- 1. SETUP ---
filename = 'whiteNoiseNoAmp3.csv'; 
opts = detectImportOptions(filename);
data = readtable(filename, opts);

t = data.TIME; 
y1_raw = data.CH1; 
y2_raw = data.CH2; 

if iscell(t) || isstring(t), t = str2double(strrep(t, ',', '.')); end
if iscell(y1_raw) || isstring(y1_raw), y1_raw = str2double(strrep(y1_raw, ',', '.')); end
if iscell(y2_raw) || isstring(y2_raw), y2_raw = str2double(strrep(y2_raw, ',', '.')); end

dt = t(2) - t(1); 
Fs = 1 / dt;      

% --- 2. REMOVE DC OFFSET (Centers the wave at 0V) ---
y1 = y1_raw - mean(y1_raw);
y2 = y2_raw - mean(y2_raw);

% --- 3. AMPLITUDE (For Vpp) ---
num_samples = length(t);
V_pp1 = max(y1) - min(y1);
V_pp2 = max(y2) - min(y2);

fprintf('--- Analysis Results ---\n');
fprintf('Mic 1 Vpp: %.4f V\n', V_pp1);
fprintf('Mic 2 Vpp: %.4f V\n', V_pp2);

% --- 4. FREQUENCY DOMAIN (FFT) ---
% Mic 1 FFT
Y1 = fft(y1);
P2_1 = abs(Y1 / num_samples); 
P1_1 = P2_1(1:floor(num_samples/2)+1);
P1_1(2:end-1) = 2 * P1_1(2:end-1);

% Mic 2 FFT
Y2 = fft(y2);
P2_2 = abs(Y2 / num_samples); 
P1_2 = P2_2(1:floor(num_samples/2)+1);
P1_2(2:end-1) = 2 * P1_2(2:end-1);

f = Fs * (0:floor(num_samples/2)) / num_samples;

% --- 5. PLOTTING ---
figure('Name', 'Sensor Characterisation', 'Position', [100, 100, 1000, 700]);

% Subplot 1: Time Domain
subplot(2,1,1);
plot(t, y1, 'b', 'LineWidth', 1); hold on;
plot(t, y2, 'r', 'LineWidth', 1); hold off;
title('Time Domain Waveform (AC Coupled / DC Removed)');
xlabel('Time (s)'); ylabel('Voltage (V)');
legend('Mic 1 (CH1)', 'Mic 2 (CH2)', 'Location', 'northeast');
grid on; axis tight;


% Add Vpp text boxes to the graph (Updated for high contrast)
y_limit = ylim;
text_x = min(t) + 0.02*(max(t)-min(t));

text(text_x, y_limit(2)*0.85, sprintf('Mic 1 V_{pp} = %.4f V', V_pp1), ...
    'BackgroundColor', 'white', 'EdgeColor', 'blue', ...
    'Color', 'black', 'FontWeight', 'bold');

text(text_x, y_limit(2)*0.65, sprintf('Mic 2 V_{pp} = %.4f V', V_pp2), ...
    'BackgroundColor', 'white', 'EdgeColor', 'red', ...
    'Color', 'black', 'FontWeight', 'bold');

% Subplot 2: Frequency Spectrum
subplot(2,1,2);
plot(f, P1_1, 'b', 'LineWidth', 1.2); hold on;
plot(f, P1_2, 'r', 'LineWidth', 1.2); hold off;
title('Frequency Spectrum (FFT)');
xlabel('Frequency (Hz)'); ylabel('Magnitude');
legend('Mic 1 (CH1)', 'Mic 2 (CH2)', 'Location', 'northeast');
grid on;
xlim([0, 5000]);