classdef plotData
    methods(Static)
        function plot()
            % plot - Plots and saves sensor data for each acquisition.
            % For each acquisition, a folder named after the gesture (ID_Gesture) is created
            % in the Data folder. The trial number is computed by counting existing combined plot files.
            % A common time vector is constructed and files.savePlots is called.
        
            cfg = config();
            dataFolder = cfg.GestureFolder;

            D = dir(dataFolder);
            for k = 1:numel(D)
              n = D(k).name;
              if D(k).isdir && ~ismember(n, {'.','..'}) && ~isempty(regexp(n,'^\d','once'))
                  rmdir(fullfile(dataFolder,n),'s');
              end
            end
            % Define file paths.
            signalsMatFile = fullfile(dataFolder, 'signalsStructFile.mat');
            metadataCSV = fullfile(dataFolder, 'metadata.csv');
            
            % Verify that the required files exist.
            if ~exist(signalsMatFile, 'file')
                error('signalsStructFile.mat not found in %s', dataFolder);
            end
            if ~exist(metadataCSV, 'file')
                error('metadata.csv not found in %s', dataFolder);
            end
            
            % Load sensor data and metadata.
            dataStruct = load(signalsMatFile);  % Contains signalsStruct.
            signalsStruct = dataStruct.signalsStruct;
            metaTable = readtable(metadataCSV, 'TextType', 'string');
            
            % Process each acquisition.
            numAcquisitions = height(metaTable);
            for i = 1:numAcquisitions
                % Each row in metaTable corresponds to field 'acquisition_i'.
                fieldName = ['acquisition_', num2str(i)];
                if ~isfield(signalsStruct, fieldName)
                    warning('Field %s not found. Skipping.', fieldName);
                    continue;
                end
                
                dataAcq = signalsStruct.(fieldName);
                
                % Reconstruct the common time vector.
                numSamples = size(dataAcq.acc, 1);
                timeVec = (0:numSamples-1)' / cfg.SampleRate;
                
                % Get the gesture ID from metadata (convert to string).
                currentGesture = num2str(metaTable.ID_Gesture(i));
                
                % Create folder for this gesture if it does not exist.
                gestureFolder = fullfile(dataFolder, currentGesture);
                if ~exist(gestureFolder, 'dir')
                    mkdir(gestureFolder);
                end
                
                % Compute trial number by counting files ending with '_combined.png'.
                trialNum = length(dir(fullfile(gestureFolder, '*_combined.png'))) + 1;
                
                % Save sensor plots and a combined plot.
                files.savePlots(dataAcq.acc, dataAcq.gyro, timeVec, ...
                    gestureFolder, trialNum, currentGesture);
            end
            
            disp('All data plots have been saved.');
        end
    end
end