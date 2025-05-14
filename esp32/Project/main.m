function main()
    % MAIN - Entry point for gesture tool: collect or classify.
    try
        cfg = config();  % your existing config.m
        % 1. Initialize serial link to ESP32
        m = sensors.initializeSensors(cfg.port, cfg.baudRate);

        % 2. Mode selection
        disp('==== Gesture Tool ====');
        disp('1: Data Collection');
        disp('2: Classification');
        disp('3: Raw Streaming');
        mode = input('Select mode (1, 2 or 3): ');
        assert(ismember(mode,[1,2,3]), 'Invalid mode.');

        switch mode
            case 1
                runDataCollection(m, cfg);
            case 2
                runClassification(m, cfg);
            case 3 
                runRawStreaming  (m, cfg);
        end

        % 3. Cleanup
        flush(m);
        clear m;

    catch ME
        disp(['Error: ', ME.message]);
        if exist('m','var'), clear m; end
        rethrow(ME);
    end
end

%% Sub-function: Data Collection (unchanged)
function runDataCollection(m, cfg)
    % identical to your old main: collect samples, ask to save, etc.
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

%% Sub-function: Classification
function runClassification(m, cfg)
    % Load your exported model (must define predictFcn)
    mdl = load(fullfile(cfg.GestureFolder,'gestureModel.mat'));
    predictFcn = mdl.trainedModel.predictFcn;

    disp('--- Classification Mode ---');
    fprintf('Collecting %d samples per gesture window.\n', cfg.TargetSamples);
    fprintf('Press Ctrl-C to exit.\n\n');

    while true
        % 1) grab one window
        writeline(m, "COLLECT"); 
        [acc, gyro, ts] = sensors.collectSamples(m, cfg.TargetSamples);
        time = ts/1e6;
        [acc_c, time_c, idx] = sensors.cropAndAdjustData(acc, time, cfg.TargetSamples);
        gyro_c = gyro(idx,:);

        % 2) feature extraction (must match training)
        %feats = classification.extractFeatures(acc_c, gyro_c, time_c);

        % 3) predict
        %label = predictFcn(feats);
        %fprintf('Predicted Gesture → %s\n\n', string(label));
        fprintf("acc: %i \n",acc_c)

        pause(0.5);
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