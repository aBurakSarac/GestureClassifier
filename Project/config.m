function cfg = config()
    % CONFIG System configuration settings for gesture recognition
    %
    % Configuration parameters for:
    % - Sensor data collection and processing
    % - File storage settings
    % - Feature extraction and classification
    
    cfg.BluetoothName = 'ESP32';  % Serial port for sensor connection
    cfg.BTChannel = 1;          % Bluetooth channel for ESP32
    cfg.baudRate = 115200;     % Baud rate for serial communication
    cfg.COMPort = 'COM6';  % COM port for Windows (e.g., 'COM3')
    cfg.serialPort = 'COM3';

    % Data Collection and Processing
    cfg.SampleRate = 100;        % Desired sample rate in Hz
    cfg.TargetSamples = 250;     % Number of samples after cropping
    cfg.MedianFilterWindow = 3;  % Window size for median filtering
    % Storage Settings
    cfg.GestureFolder = 'Data';  % Base folder for saving data
    cfg.MaxFileNameLength = 50;  % Maximum length for generated filenames
    
    % Feature Extraction and Classification
    cfg.FFTWindowSize = 256;     % Window size for FFT analysis
    cfg.PeakDetectionThreshold = 0.1;  % Threshold for peak detection
    cfg.FeatureNormalization = true;   % Enable feature normalization
    cfg.CrossValidationFolds = 5;      % Number of folds for cross-validation
    
    % Machine Learning Configuration
    cfg.ClassificationMethod = 'SVM';  % Default classification algorithm
    cfg.ModelSavePath = fullfile(cfg.GestureFolder, 'trained_model.mat');
    
    % Logging and Debugging
    cfg.EnableDetailedLogging = true;
    cfg.LogFolder = fullfile(cfg.GestureFolder, 'logs');
end