classdef classification
    % classification - Extracts features from sensor data for gesture recognition.
    % Provides methods to extract basic statistical and temporal features from
    % accelerometer, gyroscope, and orientation data.
    
    methods(Static)
        function features = extractFeatures(acc, gyro, time)
            % extractFeatures - Extracts statistical and temporal features.
            features.statistical = classification.getStatisticalFeatures(acc, gyro);
            features.temporal = classification.getTemporalFeatures(acc, gyro, time);
        end
        
        function features = getStatisticalFeatures(accData, gyroData)
            % getStatisticalFeatures - Computes basic statistics for each sensor.
            % For each axis of the accelerometer, gyroscope, and orientation data, calculates:
            %   Mean, Standard Deviation, Range (max-min), and RMS.
            % Also computes accelerometer magnitude mean and standard deviation.
            features = struct();
            sensors = {accData, gyroData};
            sensorNames = {'acc', 'gyro'};
            axisNames = {'x', 'y', 'z'};
            for i = 1:length(sensors)
                data = sensors{i};
                name = sensorNames{i};
                for axis = 1:3
                    axisData = data(:, axis);
                    features.([name '_mean_' axisNames{axis}]) = mean(axisData);
                    features.([name '_std_' axisNames{axis}]) = std(axisData);
                    features.([name '_range_' axisNames{axis}]) = max(axisData) - min(axisData);
                    features.([name '_rms_' axisNames{axis}]) = rms(axisData);
                end
            end
            % Accelerometer magnitude features.
            magnitude = sqrt(sum(accData.^2, 2));
            features.acc_magnitude_mean = mean(magnitude);
            features.acc_magnitude_std = std(magnitude);
        end
        
        function features = getTemporalFeatures(accData, gyroData, time)
            % getTemporalFeatures - Computes the dominant frequency for each sensor axis.
            % For each axis of the accelerometer, gyroscope, and orientation data, performs an FFT
            % and extracts the frequency corresponding to the maximum amplitude, as well as that amplitude.
            features = struct();
            Fs = 1 / mean(diff(time));
            sensors = {accData, gyroData};
            sensorNames = {'acc', 'gyro'};
            axisNames = {'x', 'y', 'z'};
            for i = 1:length(sensors)
                data = sensors{i};
                name = sensorNames{i};
                for axis = 1:3
                    Y = fft(data(:, axis));
                    n = length(Y);
                    P2 = abs(Y / n);
                    P1 = P2(1:floor(n/2)+1);
                    if length(P1) > 2
                        P1(2:end-1) = 2 * P1(2:end-1);
                    end
                    f = Fs * (0:floor(n/2)) / n;
                    [~, idxPeak] = max(P1);
                    features.([name '_dom_freq_' axisNames{axis}]) = f(idxPeak);
                    features.([name '_dom_freq_magnitude_' axisNames{axis}]) = P1(idxPeak);
                end
            end
        end
    end
end