function main()
    % MAIN - Entry point for gesture recognition data collection.
    % Collects sensor data, processes it, and conditionally saves the acquisition.
    try
        cfg = config();  % Load configuration settings.
        [gestureName, gestureFolder] = gesture.setup(cfg.GestureFolder);  % Set up environment.
        m = sensors.initializeSensors();  % Initialize sensors.
        sensors.setSampleRate(m, cfg.SampleRate);  % Set sensor sampling rate.
        
        % Collect sensor data and common time vector.
        [acc, gyro, orientation, mag, time] = sensors.collectFixedSamples(m);
        
        % Crop data to the target sample count.
        [acc, time, cropIdx] = sensors.cropAndAdjustData(acc, time, cfg.TargetSamples);
        gyro = gyro(cropIdx, :);
        orientation = orientation(cropIdx, :);
        mag = mag(cropIdx, :);
        
        % Determine trial number by counting existing combined plot files.
        trialNum = length(dir(fullfile(gestureFolder, '*_combined.png'))) + 1;
        
        % Save the acquisition temporarily.
        tempFileName = files.saveTemp(gestureFolder, gestureName, trialNum, acc, gyro, orientation, mag);
        
        % Ask the user whether to save the acquisition.
        if files.getUserSaveChoice()
            metadata = files.handleMetadata(gestureName, trialNum, cfg.GestureFolder);
            files.saveFinal(tempFileName, cfg.GestureFolder, metadata);
            files.savePlots(acc, gyro, orientation, mag, time, gestureFolder, trialNum, gestureName);
        else
            delete(tempFileName);
            disp('Data discarded and deleted. Program exiting.');
        end
        
        sensors.cleanup(m);  % Clean up sensor connections.
    catch ME
        disp(['Error: ', ME.message]);
        if exist('m','var')
            sensors.cleanup(m);
        end
        rethrow(ME);
    end
end