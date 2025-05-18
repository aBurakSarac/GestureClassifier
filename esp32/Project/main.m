function main()
    % MAIN - Entry point for gesture tool: collect or classify.
        cfg = config();  % your existing config.m       

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
                        % 3. Cleanup
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
    disp('--- Classification Mode ---');
    fprintf('Collecting %d samples per gesture window.\n', cfg.TargetSamples);
    fprintf('Press Ctrl-C to exit.\n\n');

    % Modeli yükle
    modelData = load('Data/ClassificationLearner/wideNeuralNetwork.mat');
    trainedModel = modelData.wideNeuralNetwork;

    while true
        % ESP32'den veri al
        writeline(m, "COLLECT");
        [acc, gyro, time] = sensors.collectSamples(m, cfg.TargetSamples);

        % Özellik çıkarımı (örneğin ortalama, varyans vs.)
        % Burayı kendi eğitim sırasında kullandığın özelliklere göre doldur
        features = classification.extractFeatures(acc, gyro, time);

        [xVec, varNames] = modelTraining.convertFeaturesToVector(features);
        featureTable = array2table(xVec, 'VariableNames',varNames);
        [yfit, scores] = trainedModel.predictFcn(featureTable);
        [maxScore, ~] = max(scores, [], 2);
        threshold = 0.7;

        if maxScore < threshold
            disp("No gesture recognized");
        else
            switch yfit
                case 0
                    gesture = '13 - Come';
                case 1
                    gesture = '15 - Stop';
                case 2
                    gesture = '16 - Turn Left';
                case 3
                    gesture = '17 - Turn Right';
                case 4
                    gesture = '19 - Sit Down';
                case 5
                    gesture = '20 - Rotate';
                case 6
                    gesture = '23 - Hello';
            end
            fprintf('Result: %s (with confidence %2.f)\n', gesture, maxScore);

        end
        % Sonucu yazdır
        %disp(['Tahmin edilen jest: ', num2str(predictedClass)]);
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
        cfg = config();  % Load configuration settings.
        targetGestures = [13, 15, 16, 17, 19, 20, 23];  % Gestures to process.
        learnerDir = fullfile(cfg.GestureFolder, 'ClassificationLearner');
        if ~exist(learnerDir, 'dir')
            mkdir(learnerDir);
        end
        modelTraining.prepareGestureData(cfg.GestureFolder, targetGestures, learnerDir);
        modelTraining.displayInstructions();
    catch ME
        rethrow(ME);
    end
end