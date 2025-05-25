function main()
    % MAIN - Entry point for gesture tool: collect or classify.
        cfg = config();  

        % Mode selection
        disp('==== Gesture Tool ====');
        disp('1: Data Collection');
        disp('2: Classification');
        disp('3: Raw Streaming');
        disp('4: Extract Features');
        disp('5: Plot Data');
        mode = input('Select mode (1, 2, 3, 4 or 5) ');
        assert(ismember(mode,[1,2,3,4,5]), 'Invalid mode.');

        switch mode
            case 1
                try
                    m = sensors.initializeSensors(cfg.port, cfg.baudRate);
                    runDataCollection(m, cfg);
                    flush(m);
                    clear m;
            
                catch ME
                    disp(['Error: ', ME.message]);
                    if exist('m','var'), clear m; end
                    rethrow(ME);
                end
                
            case 2
                try
                    m = sensors.initializeSensors(cfg.port, cfg.baudRate);
                    runClassification(m, cfg);
                catch ME
                    disp(['Error: ', ME.message]);
                    if exist('m','var'), clear m; end
                    rethrow(ME);
                end
            case 3 
                try
                    m = sensors.initializeSensors(cfg.port, cfg.baudRate);
                    runRawStreaming  (m, cfg);
                catch ME
                    disp(['Error: ', ME.message]);
                    if exist('m','var'), clear m; end
                    rethrow(ME);
                end
            case 4
                runModelTraining();
            case 5
                plotData.plot();
        end
end

function runDataCollection(m, cfg)
    [gestureName, gestureFolder] = gesture.setup(cfg.GestureFolder);
    writeline(m, "COLLECT");
    [acc, gyro, ts] = sensors.collectSamples(m, cfg.TargetSamples);
    time = ts/1e6;
    [acc, time, cropIdx] = sensors.cropAndAdjustData(acc, time, cfg.TargetSamples);
    gyro = gyro(cropIdx, :);

    trialNum = length(dir(fullfile(gestureFolder,'*_combined.png'))) + 1;
    tempFile = files.saveTemp(gestureFolder, gestureName, trialNum, acc, gyro);

    if files.getUserSaveChoice()
        metadata = files.handleMetadata(gestureName, trialNum, cfg.GestureFolder);
        files.saveFinal(tempFile, cfg.GestureFolder, metadata);
        files.savePlots(acc, gyro, time, gestureFolder, trialNum, gestureName);
        disp('Data saved.');
    else
        delete(tempFile);
        disp('Data discarded.');
    end
end

function runClassification(m, cfg)
    disp('--- Classification Mode ---');
    fprintf('Collecting %d samples per gesture window.\n', cfg.TargetSamples);
    fprintf('Press Ctrl-C to exit.\n\n');
    while true
        writeline(m, "COLLECT");
        [acc, gyro, time] = sensors.collectSamples(m, cfg.TargetSamples);

        features = classification.extractFeatures(acc, gyro, time);

        [xVec, varNames] = modelTraining.convertFeaturesToVector(features);
        featureTable = array2table(xVec, 'VariableNames',varNames);
        [yfit, scores] = cfg.trainedModel.predictFcn(featureTable);
        [maxScore, ~] = max(scores, [], 2);

        if maxScore < cfg.threshold
            disp("No gesture recognized");
            fprintf('Result: Not recognized (with confidence %.2f)\n', maxScore);

        else
            if yfit >= 0 && yfit < numel(cfg.labelMap)
                gesture = cfg.labelMap{yfit + 1};
                fprintf('Result: %s (with confidence %.2f)\n', gesture, maxScore);
            else
                fprintf('Unknown gesture index %d (confidence %.2f)\n', yfit, maxScore);
            end
        end
        pause(1);
    end
end


function runRawStreaming(m, cfg)
    disp('--- Raw Streaming Mode ---');
    fprintf('Window size: %d samples\n\n', cfg.TargetSamples);

    while true
        writeline(m, "COLLECT");
        [acc, gyro, ts] = sensors.collectSamples(m, cfg.TargetSamples);

        for i = 1:cfg.TargetSamples
            fprintf('%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%d\n', ...
                acc(i,1), acc(i,2), acc(i,3), ...
                gyro(i,1),gyro(i,2),gyro(i,3), ...
                ts(i));
        end
        pause(0.1);
    end
end

function runModelTraining()
    % Main function to prepare data for classification.
    try
        if ~exist(cfg.learnerDir, 'dir')
            mkdir(cfg.learnerDir);
        end
        modelTraining.prepareGestureData(cfg.GestureFolder, cfg.targetGestures, cfg.learnerDir);
        modelTraining.displayInstructions();
    catch ME
        rethrow(ME);
    end
end