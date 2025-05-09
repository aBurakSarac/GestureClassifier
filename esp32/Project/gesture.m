classdef gesture
    % GESTURE - Handles gesture setup and validation.
    % Provides functions for validating gesture names, creating storage folders,
    % and displaying recording instructions.
    
    methods(Static)
      function [gestureName, gestureFolder] = setup(baseFolder)
        % SETUP - Initializes the gesture recording environment.
        gestureName = gesture.validate();
        gestureFolder = gesture.createFolder(gestureName, baseFolder);
        gesture.displayInstructions();
    end
        
        function gestureName = validate()
            % VALIDATE - Prompts and validates a gesture name.
            while true
                gestureName = input('Gesture Name (e.g., Hand Up): ', 's');
                if isempty(gestureName)
                    disp('Gesture name cannot be empty. Please provide a valid name.');
                    continue;
                end
                invalidChars = ['\\', '/', ':', '*', '?', '"', '<', '>', '|'];
                if any(ismember(gestureName, invalidChars))
                    disp('Gesture name contains invalid characters. Please use only letters, numbers, spaces, and underscores.');
                    continue;
                end
                if length(gestureName) > 50
                    disp('Gesture name too long. Please use a shorter name.');
                    continue;
                end
                break;
            end
        end
        
        function gestureFolder = createFolder(gestureName, baseFolder)
            % CREATEFOLDER - Creates the folder for storing gesture data.
            gestureFolder = fullfile(baseFolder, gestureName);
            if ~exist(gestureFolder, 'dir')
                mkdir(gestureFolder);
            end
        end
        
        function displayInstructions()
            % DISPLAYINSTRUCTIONS - Displays the recording instructions.
            fprintf('\nGesture Recording Instructions:\n');
            fprintf('--------------------------------\n');
            fprintf('1. Hold the device steady at a standing position\n');
            fprintf('2. Wait for the "Recording..." message\n');
            fprintf('3. Perform the gesture when prompted\n');
            fprintf('4. Remain stationary until recording stops\n');
            fprintf('5. Review and confirm the recording\n\n');
            input('Press Enter when ready to begin... ');
            disp("Please wait...");
        end
    end
end