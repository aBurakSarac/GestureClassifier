classdef sensors
    % SENSORS - Manages sensor initialization, data collection, processing, and cleanup.
    
    methods(Static)
        function m = initializeSensors()
            % initializeSensors - Initializes the mobile device sensors.
            try
                clear mobiledev;               % Clear existing mobile device objects.
                pause(0.5);                    % Wait for cleanup.
                m = mobiledev;                 % Create a new mobile device object.
                m.AccelerationSensorEnabled = 1;  % Enable accelerometer.
                m.AngularVelocitySensorEnabled = 1; % Enable gyroscope.
                m.OrientationSensorEnabled = 1;     % Enable orientation sensor.
                m.MagneticSensorEnabled = 1;        % Enable magnetometer.
                disp('Sensors initialized successfully.');
            catch ME
                error('Sensors:InitFailed', 'Failed to initialize sensors: %s', ME.message);
            end
        end

        function setSampleRate(m, desiredRate)
            % setSampleRate - Sets the sensor sampling rate.
            try
                if desiredRate == 100
                    m.SampleRate = 'high';
                elseif desiredRate == 10
                    m.SampleRate = 'medium';
                elseif desiredRate == 1
                    m.SampleRate = 'low';
                else
                    error('Sensors:InvalidRate', 'Unsupported sample rate.');
                end
                disp(['Sample rate set to: ', num2str(desiredRate), ' Hz']);
            catch ME
                error('Sensors:SampleRateError', 'Failed to set sample rate: %s', ME.message);
            end
        end

        function [acc, gyro, orientation, mag, time] = collectFixedSamples(m)
            % collectFixedSamples - Collects sensor data for a fixed duration.
            % Returns accelerometer, gyroscope, orientation, magnetometer data, and a common time vector.
            try
                disp('Starting data logging...');
                m.Logging = 1;
                for i = 1:3
                    pause(1);
                    disp(['Elapsed time: ', num2str(i), ' seconds']);
                end
                m.Logging = 0;
                [acc, accTime] = accellog(m);
                [gyro, ~] = angvellog(m);
                [orientation, ~] = orientlog(m);
                [mag, ~] = magfieldlog(m);
                time = accTime;  % Use accelerometer time as common time.
                if isempty(acc) || isempty(gyro) || isempty(orientation) || isempty(mag)
                    error('Sensors:NoData', 'One or more sensors failed to provide data.');
                end
                disp('Data collection completed successfully.');
            catch ME
                m.Logging = 0;
                error('Sensors:CollectionFailed', 'Data collection failed: %s', ME.message);
            end
        end

        function [croppedData, croppedTime, cropIdx] = cropAndAdjustData(data, time, targetSamples)
            % cropAndAdjustData - Crops sensor data and time vector to target samples.
            try
                if size(data, 1) ~= length(time)
                    error('Sensors:SizeMismatch', 'Data and time arrays must match in length.');
                end
                filteredData = medfilt1(data, 3);
                totalSamples = size(filteredData, 1);
                extraSamples = totalSamples - targetSamples;
                if extraSamples > 0
                    cropStart = floor(extraSamples / 2);
                    cropEnd = ceil(extraSamples / 2);
                    cropIdx = (cropStart + 1):(totalSamples - cropEnd);
                    croppedData = filteredData(cropIdx, :);
                    croppedTime = time(cropIdx);
                else
                    croppedData = filteredData;
                    croppedTime = time;
                    cropIdx = 1:totalSamples;
                end
                croppedTime = croppedTime - croppedTime(1);  % Normalize time.
            catch ME
                error('Sensors:ProcessingFailed', 'Data processing failed: %s', ME.message);
            end
        end

        function cleanup(m)
            % cleanup - Disables sensors and cleans up the mobile device object.
            try
                m.Logging = 0;
                m.AccelerationSensorEnabled = 0;
                m.AngularVelocitySensorEnabled = 0;
                m.OrientationSensorEnabled = 0;
                m.MagneticSensorEnabled = 0;
                clear m;
                disp('Sensors cleaned up successfully');
            catch ME
                warning('Sensors:CleanupFailed', 'Error during cleanup: %s', ME.message);
            end
        end
    end
end