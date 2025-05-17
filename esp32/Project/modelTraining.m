%% modelTraining.m
% MODELTRAINING - Prepares gesture data and trains a classifier using MATLAB's Classification Learner.
% Processes data from signalsStructFile.mat and metadata.csv, extracts features from target gestures,
% and saves the resulting feature table for classification.
classdef modelTraining

    methods(Static)       
        function prepareGestureData(dataFolder, targetGestures, outputDir)
            % prepareGestureData - Loads MAT and CSV files, filters acquisitions for target gestures,
            % extracts features, and saves a feature table.
            matFile = fullfile(dataFolder, 'signalsStructFile.mat');
            metadataCSV = fullfile(dataFolder, 'metadata.csv');
            if ~exist(matFile, 'file')
                error('MAT file not found in %s', dataFolder);
            end
            if ~exist(metadataCSV, 'file')
                error('CSV file not found in %s', dataFolder);
            end
            aggData = load(matFile);  % Contains signalsStruct.
            signalsStruct = aggData.signalsStruct;
            C = readcell(metadataCSV);
            headers = string(C(1,:));
            if size(C,1) > 1
                dataRows = C(2:end,:);
            else
                dataRows = {};
            end
            metaTable = cell2table(dataRows, 'VariableNames', headers);
            targetGesturesStr = string(targetGestures);
            filteredIdx = find(ismember(string(metaTable.ID_Gesture), targetGesturesStr));
            numFiles = length(filteredIdx);
            if numFiles == 0
                error('No acquisitions found for the target gestures.');
            end
            cfg = config();  % Reload configuration for sample rate.
            firstIdx = filteredIdx(1);
            fieldName = ['acquisition_', num2str(firstIdx)];
            if ~isfield(signalsStruct, fieldName)
                error('Acquisition field %s not found in data', fieldName);
            end
            acqData = signalsStruct.(fieldName);
            numSamples = size(acqData.acc, 1);
            time = (0:numSamples-1)' / cfg.SampleRate;
            featuresFirst = classification.extractFeatures(acqData.acc, acqData.gyro, time);
            [tempVector, featureNames] = modelTraining.convertFeaturesToVector(featuresFirst);
            allFeatures = zeros(numFiles, length(tempVector));
            allLabels = zeros(numFiles, 1);
            currentIndex = 1;
            for i = 1:numFiles
                idx = filteredIdx(i);
                fieldName = ['acquisition_', num2str(idx)];
                if ~isfield(signalsStruct, fieldName)
                    warning('Acquisition field %s not found. Skipping.', fieldName);
                    continue;
                end
                dataAcq = signalsStruct.(fieldName);
                numSamples = size(dataAcq.acc, 1);
                time = (0:numSamples-1)' / cfg.SampleRate;
                features = classification.extractFeatures(dataAcq.acc, dataAcq.gyro, time);
                [featureVector, names] = modelTraining.convertFeaturesToVector(features);
                if isempty(featureNames)
                    featureNames = names;
                end
                allFeatures(currentIndex, :) = featureVector;
                gestureStr = string(metaTable.ID_Gesture(idx));
                labelIdx = find(targetGesturesStr == gestureStr, 1) - 1;
                if isempty(labelIdx)
                    warning('Gesture %s not found in target gestures.', gestureStr);
                    labelIdx = -1;
                end
                allLabels(currentIndex) = labelIdx;
                currentIndex = currentIndex + 1;
            end
            allFeatures = allFeatures(1:currentIndex-1, :);
            allLabels = allLabels(1:currentIndex-1, :);
            featureTable = array2table(allFeatures, 'VariableNames', featureNames);
            featureTable.Label = categorical(allLabels);
            modelTraining.saveProcessedData(featureTable, outputDir);
        end
        
        function [vector, names] = convertFeaturesToVector(features)
            % convertFeaturesToVector - Converts the feature structure to a vector and generates names.
            [totalElements, totalNames] = modelTraining.countFeatureElements(features);
            vector = zeros(1, totalElements);
            names = cell(1, totalNames);
            [vector, names, ~, ~] = modelTraining.fillFeatureArrays(features, vector, names, 1, 1);
        end
        
        function [numElements, numNames] = countFeatureElements(features)
            % countFeatureElements - Counts total elements and names in the feature structure.
            numElements = 0;
            numNames = 0;
            fields = fieldnames(features);
            for i = 1:length(fields)
                field = features.(fields{i});
                if isstruct(field)
                    [subElements, subNames] = modelTraining.countFeatureElements(field);
                    numElements = numElements + subElements;
                    numNames = numNames + subNames;
                else
                    fieldValues = field(:)';
                    numElements = numElements + length(fieldValues);
                    numNames = numNames + length(fieldValues);
                end
            end
        end
        
        function [vector, names, nextVectorIdx, nextNameIdx] = fillFeatureArrays(features, vector, names, vectorIdx, nameIdx)
            % fillFeatureArrays - Fills preallocated arrays with feature values and names.
            fields = fieldnames(features);
            for i = 1:length(fields)
                field = features.(fields{i});
                if isstruct(field)
                    [vector, names, vectorIdx, nameIdx] = modelTraining.fillFeatureArrays(field, vector, names, vectorIdx, nameIdx);
                else
                    fieldValues = field(:)';
                    numValues = length(fieldValues);
                    vector(vectorIdx:vectorIdx + numValues - 1) = fieldValues;
                    for j = 1:numValues
                        if numValues > 1
                            names{nameIdx} = sprintf('%s_%d', fields{i}, j);
                        else
                            names{nameIdx} = fields{i};
                        end
                        nameIdx = nameIdx + 1;
                    end
                    vectorIdx = vectorIdx + numValues;
                end
            end
            nextVectorIdx = vectorIdx;
            nextNameIdx = nameIdx;
        end
        
        function saveProcessedData(featureTable, outputDir)
            % saveProcessedData - Saves the feature table in MAT and CSV formats and creates a README.
            save(fullfile(outputDir, 'gesture_features.mat'), 'featureTable');
            writetable(featureTable, fullfile(outputDir, 'gesture_features.csv'));
            modelTraining.createDocumentation(outputDir, size(featureTable, 2) - 1);
        end
        
        function createDocumentation(outputDir, numFeatures)
            % createDocumentation - Creates a README file with dataset and instructions information.
            filename = fullfile(outputDir, 'README.txt');
            fid = fopen(filename, 'w');
            fprintf(fid, 'Gesture Classification Dataset Documentation\n');
            fprintf(fid, '=======================================\n\n');
            fprintf(fid, 'Dataset Information:\n');
            fprintf(fid, '-------------------\n');
            fprintf(fid, 'Total features: %d\n', numFeatures);
            fprintf(fid, 'Label encoding: 0-based indices (0, 1, 2, 3)\n\n');
            fprintf(fid, 'Using the Classification Learner App:\n');
            fprintf(fid, '--------------------------------\n');
            fprintf(fid, '1. In MATLAB, click on the "Apps" tab\n');
            fprintf(fid, '2. Click on "Classification Learner"\n');
            fprintf(fid, '3. Click "New Session"\n');
            fprintf(fid, '4. Select the file "gesture_features.mat"\n');
            fprintf(fid, '5. In the import dialog, select "Label" as the response variable and the others as predictors\n');
            fprintf(fid, '6. Choose cross-validation options (5-fold recommended)\n');
            fprintf(fid, '7. Click "Start Session"\n');
            fprintf(fid, '8. Try different classification methods\n\n');
            fprintf(fid, 'Exporting the Model:\n');
            fprintf(fid, '------------------\n');
            fprintf(fid, '1. Once you find the best performing model, click "Export"\n');
            fprintf(fid, '2. Choose "Export Model"\n');
            fprintf(fid, '3. Save the model to your workspace or as a MATLAB file\n');
            fclose(fid);
        end
        
        function displayInstructions()
            % displayInstructions - Displays instructions for using the Classification Learner.
            disp('Data preparation completed successfully!');
            disp(' ');
            disp('To train your model:');
            disp('1. Open Classification Learner from the Apps tab');
            disp('2. Create a New Session');
            disp('3. Import gesture_features.mat from the ClassificationLearner folder');
            disp('4. Select "Label" as the response variable');
            disp('5. Start the session and try different classification methods');
            disp(' ');
            disp('For detailed instructions, please refer to the README.txt file in the ClassificationLearner folder.');
        end
    end
end