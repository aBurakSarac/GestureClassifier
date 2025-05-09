classdef files
    % FILES - Manages file operations for gesture recognition.
    % Handles saving temporary files, appending acquisitions to the main MAT and CSV files,
    % and saving sensor plots.
    
    methods(Static)
        function tempFileName = saveTemp(gestureFolder, gestureName, trialNum, acc, gyro, orientation, mag)
            % saveTemp - Saves a temporary MAT file with sensor data (without time).
            try
                tempFileName = fullfile(gestureFolder, ['Class_', gestureName, '_Temp_', num2str(trialNum), '.mat']);
                save(tempFileName, 'acc', 'gyro', 'orientation', 'mag');
                if ~exist(tempFileName, 'file')
                    error('Files:TempFileFailed', 'Failed to create temporary file: %s', tempFileName);
                end
            catch ME
                error('Files:SaveTempFailed', 'Failed to save temporary data: %s', ME.message);
            end
        end

        function saveFinal(tempFileName, dataFolder, metadata)
            % saveFinal - Appends the new acquisition to signalsStructFile.mat and metadata.csv.
            % Loads the temporary file and appends its content to the MAT file,
            % and appends the corresponding metadata to the CSV file.
            
            matFile = fullfile(dataFolder, 'signalsStructFile.mat');
            newAcqData = load(tempFileName);
            
            if exist(matFile, 'file')
                agg = load(matFile);
                signalsStruct = agg.signalsStruct;
                fieldsList = fieldnames(signalsStruct);
                nextIndex = length(fieldsList) + 1;
            else
                signalsStruct = struct();
                nextIndex = 1;
            end
            
            fieldName = ['acquisition_', num2str(nextIndex)];
            signalsStruct.(fieldName) = newAcqData;
            save(matFile, 'signalsStruct');
            
            metadataCSV = fullfile(dataFolder, 'metadata.csv');
            if exist(metadataCSV, 'file')
                T = readtable(metadataCSV, 'TextType', 'string');
                T.ID_Subject = string(T.ID_Subject);
                T.Idx_Acquisition = string(T.Idx_Acquisition);
                T.Hand = string(T.Hand);
                T.Smartphone_model = string(T.Smartphone_model);
                T.Available_Sensors = string(T.Available_Sensors);
                T.ID_Gesture = string(T.ID_Gesture);
                
                T.ID_Subject = pad(T.ID_Subject, 2, 'left', '0');
                metadata.ID_Subject = pad(string(metadata.ID_Subject), 2, 'left', '0');
                
                userRows = T.ID_Subject == metadata.ID_Subject;
                idxAcq = sum(userRows) + 1;
            else
                idxAcq = 1;
                T = table('Size',[0 6], 'VariableTypes', repmat("string",1,6), ...
                    'VariableNames', {'ID_Subject','Idx_Acquisition','Hand','Smartphone_model','Available_Sensors','ID_Gesture'});
            end
            
            newRow = table(...
                string(metadata.ID_Subject), ...          % Subject ID (padded)
                string(idxAcq), ...                         % Acquisition index for subject
                string(metadata.Hand), ...
                string(metadata.Smartphone_model), ...
                string(metadata.Available_Sensors), ...
                string(metadata.ID_Gesture), ...            % Gesture identifier (set to gestureName)
                'VariableNames', {'ID_Subject','Idx_Acquisition','Hand','Smartphone_model','Available_Sensors','ID_Gesture'});
            
            T = [T; newRow];
            writetable(T, metadataCSV);
            
            fprintf('Acquisition appended successfully.\n');
            fprintf('MAT file: %s\n', matFile);
            fprintf('CSV file: %s\n', metadataCSV);
            
            delete(tempFileName);
        end

        function plotSensorData(data, time, labels, titlePrefix, units, folder, gestureName, trialNum, sensorType)
            % plotSensorData - Plots sensor data and saves the figure.
            try
                fig = figure('Position', [100, 100, 800, 500]);
                plot(time, data, 'LineWidth', 1.5);
                title([titlePrefix, ' - ', gestureName, ' (Trial ', num2str(trialNum), ')'], 'FontSize', 12, 'FontWeight', 'bold');
                xlabel('Time (s)', 'FontSize', 10);
                ylabel([titlePrefix, ' (', units, ')'], 'FontSize', 10);
                legend(labels, 'Location', 'best');
                grid on;
                for i = 1:size(data,2)
                    meanVal = mean(data(:,i));
                    maxVal = max(abs(data(:,i)));
                    text(0.02, 0.98 - (i-1)*0.05, sprintf('%s: Mean=%.2f, Max=%.2f', labels{i}, meanVal, maxVal), ...
                        'Units', 'normalized', 'FontSize', 8);
                end
                filename = fullfile(folder, ['Class_', gestureName, '_Trial_', num2str(trialNum), '_', sensorType, '.png']);
                saveas(fig, filename);
                close(fig);
            catch ME
                warning('Files:PlotGenerationFailed', 'Failed to generate %s plot: %s', sensorType, ME.message);
                if exist('fig', 'var') && ishandle(fig)
                    close(fig);
                end
            end
        end

        function plotCombinedData(accData, gyroData, orientData, magData, time, folder, gestureName, trialNum)
            % plotCombinedData - Creates a 2x2 plot of sensor data and saves the figure.
            try
                fig = figure('Position', [100, 100, 1280, 800]);
                subplot(2,2,1);
                plot(time, accData, 'LineWidth', 1.5);
                title('Accelerometer Data');
                ylabel('Acceleration (m/s^2)');
                legend('X', 'Y', 'Z');
                grid on;
                
                subplot(2,2,2);
                plot(time, gyroData, 'LineWidth', 1.5);
                title('Gyroscope Data');
                ylabel('Angular Velocity (rad/s)');
                legend('X', 'Y', 'Z');
                grid on;
                
                subplot(2,2,3);
                plot(time, orientData, 'LineWidth', 1.5);
                title('Orientation Data');
                ylabel('Angle (degrees)');
                legend('Roll', 'Pitch', 'Yaw');
                grid on;
                
                subplot(2,2,4);
                plot(time, magData, 'LineWidth', 1.5);
                title('Magnetometer Data');
                xlabel('Time (s)');
                ylabel('Magnetic Field (µT)');
                legend('X', 'Y', 'Z');
                grid on;
                
                sgtitle(['Class ', gestureName, ' - Trial ', num2str(trialNum)], 'FontSize', 14, 'FontWeight', 'bold');
                filename = fullfile(folder, ['Class_', gestureName, '_Trial_', num2str(trialNum), '_combined.png']);
                saveas(fig, filename);
                close(fig);
            catch ME
                warning('Files:CombinedPlotFailed', 'Failed to generate combined plot: %s', ME.message);
                if exist('fig', 'var') && ishandle(fig)
                    close(fig);
                end
            end
        end

        function saveChoice = getUserSaveChoice()
            % getUserSaveChoice - Prompts the user to decide whether to save the recorded acquisition.
            while true
                response = input('Save this recording? (yes/no): ', 's');
                response = lower(strtrim(response));
                if any(strcmp(response, {'yes','y'}))
                    saveChoice = true;
                    return;
                elseif any(strcmp(response, {'no','n'}))
                    saveChoice = false;
                    return;
                else
                    disp('Invalid input. Please enter "yes" or "no".');
                end
            end
        end

        function metadata = handleMetadata(gestureName, trialNum, dataFolder)
            % handleMetadata - Collects metadata for the gesture recording.
            % Prompts the user for the following fields:
            %   ID_Subject, Hand, Smartphone_model, Available_Sensors, ID_Gesture.
            % Idx_Acquisition is computed automatically.
            % The CSV file will record fields in the order:
            %   ID_Subject, Idx_Acquisition, Hand, Smartphone_model, Available_Sensors, ID_Gesture.
            
            disp('Metadata provides details about the collected gesture data:');
            disp('  ID_Subject: The subject identifier (padded to two digits).');
            disp('  Hand: The hand used during the acquisition.');
            disp('  Smartphone_model: The smartphone model used for the acquisition.');
            disp('  Available_Sensors: Lists the sensors available (default "5").');
            disp('  ID_Gesture: The gesture identifier (set to the gesture name).');
            disp('Note: Idx_Acquisition will be computed automatically based on the subject''s acquisitions.');
            
            choice = input('Would you like to use a preset for metadata? (1, 2, 3, or 4 for presets, or any other key to enter manually): ', 's');
            
            switch lower(choice)
                case '1'
                    metadata.ID_Subject = '01';
                    metadata.Hand = 'Right';
                    metadata.Smartphone_model = 'Xiaomi Mi 9T';
                case '2'
                    metadata.ID_Subject = '01';
                    metadata.Hand = 'Left';
                    metadata.Smartphone_model = 'Xiaomi Mi 9T';
                case '3'
                    metadata.ID_Subject = '02';
                    metadata.Hand = 'Right';
                    metadata.Smartphone_model = 'Samsung Galaxy S22';
                case '4'
                    metadata.ID_Subject = '02';
                    metadata.Hand = 'Left';
                    metadata.Smartphone_model = 'Samsung Galaxy S22';
                otherwise
                    while true
                        metadata.ID_Subject = input('Please enter the Subject ID: ', 's');
                        if ~isempty(metadata.ID_Subject)
                            break;
                        end
                        disp('Subject ID cannot be empty.');
                    end
                    while true
                        hand = lower(input('Please specify the hand used (right/left or r/l): ', 's'));
                        hand = strtrim(hand);
                        if strcmp(hand, 'right') || strcmp(hand, 'r')
                            metadata.Hand = 'Right';
                            break;
                        elseif strcmp(hand, 'left') || strcmp(hand, 'l')
                            metadata.Hand = 'Left';
                            break;
                        else
                            disp('Please enter "Right", "Left", "r", or "l".');
                        end
                    end
                    metadata.Smartphone_model = input('Please enter the smartphone model: ', 's');
            end
            
            % Normalize subject ID.
            metadata.ID_Subject = pad(string(metadata.ID_Subject), 2, 'left', '0');
            % Set gesture ID to gestureName (no padding).
            metadata.ID_Gesture = string(gestureName);
            metadata.Available_Sensors = "5";  % Default sensors.
            
            % Compute Idx_Acquisition by reading metadata CSV.
            metadataCSV = fullfile(dataFolder, 'metadata.csv');
            if exist(metadataCSV, 'file')
                C = readcell(metadataCSV);
                if size(C,1) > 1
                    headers = string(C(1,:));
                    dataRows = C(2:end,:);
                    T = cell2table(dataRows, 'VariableNames', headers);
                    T.ID_Subject = pad(string(T.ID_Subject), 2, 'left', '0');
                    userRows = T.ID_Subject == metadata.ID_Subject;
                    idxAcq = sum(userRows) + 1;
                else
                    idxAcq = 1;
                end
            else
                idxAcq = 1;
            end
            
            metadata.Idx_Acquisition = string(idxAcq);
            
            % Order fields as in CSV.
            orderedMetadata = struct(...
                'ID_Subject', metadata.ID_Subject, ...
                'Idx_Acquisition', metadata.Idx_Acquisition, ...
                'Hand', metadata.Hand, ...
                'Smartphone_model', metadata.Smartphone_model, ...
                'Available_Sensors', metadata.Available_Sensors, ...
                'ID_Gesture', metadata.ID_Gesture);
            metadata = orderedMetadata;
            
            disp('Here is the metadata you entered (as it will be recorded in the CSV file):');
            disp(metadata);
            
            confirm = input('Is this metadata correct? (y/n): ', 's');
            if ~strcmpi(confirm, 'y')
                disp('Re-entering metadata...');
                metadata = files.handleMetadata(gestureName, trialNum, dataFolder);
            end
        end

        function savePlots(acc, gyro, orientation, mag, time, folder, trialNum, gestureName)
            % savePlots - Saves individual sensor plots and a combined plot.
            try
                files.plotSensorData(acc, time, {'X', 'Y', 'Z'}, 'Accelerometer', 'm/s^2', folder, gestureName, trialNum, 'Accelerometer');
                files.plotSensorData(gyro, time, {'X', 'Y', 'Z'}, 'Gyroscope', 'rad/s', folder, gestureName, trialNum, 'Gyroscope');
                files.plotSensorData(orientation, time, {'Roll', 'Pitch', 'Yaw'}, 'Orientation', 'degrees', folder, gestureName, trialNum, 'Orientation');
                files.plotSensorData(mag, time, {'X', 'Y', 'Z'}, 'Magnetometer', 'µT', folder, gestureName, trialNum, 'Magnetometer');
                files.plotCombinedData(acc, gyro, orientation, mag, time, folder, gestureName, trialNum);
            catch ME
                warning('Files:PlotSavingFailed', 'Failed to save plots: %s', ME.message);
            end
        end
    end
end