function main()
    % MAIN - Entry point for gesture recognition data collection.
    % Collects sensor data, processes it, and conditionally saves the acquisition.
    try
        cfg = config();  % Load configuration settings.
        [gestureName, gestureFolder] = gesture.setup(cfg.GestureFolder);  % Set up environment.
        m = sensors.initializeSensors(cfg.serialPort, cfg.baudRate);  % Initialize sensors.
        
        % Collect sensor data and common time vector.
        [acc, gyro, ts] = sensors.collectSamples(m, cfg.TargetSamples);
        time = ts/1e6;
        % Crop data to the target sample count.
        [acc, time, cropIdx] = sensors.cropAndAdjustData(acc, time, cfg.TargetSamples);
        gyro = gyro(cropIdx, :);
        
        % Determine trial number by counting existing combined plot files.
        trialNum = length(dir(fullfile(gestureFolder, '*_combined.png'))) + 1;
        
        % Save the acquisition temporarily.
        tempFileName = files.saveTemp(gestureFolder, gestureName, trialNum, acc, gyro);
        
        % Ask the user whether to save the acquisition.
        if files.getUserSaveChoice()
            metadata = files.handleMetadata(gestureName, trialNum, cfg.GestureFolder);
            files.saveFinal(tempFileName, cfg.GestureFolder, metadata);
            files.savePlots(acc, gyro, time, gestureFolder, trialNum, gestureName);
        else
            delete(tempFileName);
            disp('Data discarded and deleted. Program exiting.');
        end
        
        clear m;  % Clean up sensor connections.
    catch ME
        disp(['Error: ', ME.message]);
        if exist('m','var')
            clear m;
        end
        rethrow(ME);
    end
end