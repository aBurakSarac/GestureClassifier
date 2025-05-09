# Gesture Recognition Data Collection and Classification Project

## Overview

This project collects data from an inertial sensor (via a smartphone or SensorTile) during the execution of a series of gestures. The data are stored in a MAT file and annotated in a CSV file. This format supports the development of IMU sensor–based gesture recognition models for applications such as human/machine interfaces or mixed/extended reality.

In addition, an optional task allows you to build a classifier using a feature extraction process and MATLAB’s Classification Learner app.

---

## File Structure and Executable Files

- **main.m**  
  Records a new acquisition when executed. Each time you run `main.m`, the system:
  - Initializes sensors and collects data.
  - Crops the data to 250 samples.
  - Saves a temporary MAT file.
  - Prompts you to confirm whether to save the acquisition.
    - If confirmed, the acquisition is appended to `signalsStructFile.mat` and its annotation is added to `metadata.csv`.
    - If not, the temporary file is deleted.

- **modelTraining.m**  
  Processes data from `signalsStructFile.mat` and `metadata.csv` to prepare a feature table for classification. This script:
  - Loads the recorded sensor data and metadata.
  - Filters acquisitions for target gestures (e.g., 16, 17, 22, 23).
  - Extracts features using the methods in `classification.m`.
  - Saves the feature table for use in MATLAB’s Classification Learner.

- **plotData.m**  
  Reads the data stored in `signalsStructFile.mat` and `metadata.csv` to generate and save sensor plots. For each acquisition, it:
  - Creates a folder (named after the gesture) in the Data folder.
  - Computes a trial number based on the count of combined plot files.
  - Constructs a common time vector.
  - Calls file functions to save individual sensor plots and a combined plot.

- **Other Scripts and Files:**  
  - `config.m`, `gesture.m`, `sensors.m`, `files.m`, and `classification.m` contain the core functions for data collection, processing, file management, and feature extraction.

---

## How to Run the Project

### Data Collection (Main Task)
1. **Recording an Acquisition:**
   - Run `main.m` from the main folder.
   - **Inputs:**
     - You will be prompted for a gesture name.
     - After data collection, you are asked for confirmation:  
       *"Save this recording? (yes/no):"*
       - If you type "yes", the acquisition is appended to `signalsStructFile.mat` and `metadata.csv`.
       - If you type "no", the temporary data is deleted.
   - **Note:**  
     Run `main.m` each time you want to record a new acquisition.

### Data Visualization
- **Viewing Graphs:**
  - Sensor plots are saved in folders named after the gesture (ID_Gesture) inside the Data folder.
  - **Options:**
    - You can use the graphs already present in the Data folder.
    - Alternatively, if you wish to refresh or recreate the plots, delete the existing plot files and run `plotData.m` before running `main.m` again.

### Classifier Training (Optional Task 1)
1. **Preparing the Data:**
   - Run `modelTraining.m` from the main folder.
   - The script loads `signalsStructFile.mat` and `metadata.csv`, extracts features for a subset of gestures (e.g., 16, 17, 22, 23), and saves a feature table.
2. **Training a Model:**
   - Open MATLAB’s Classification Learner app.
   - Create a new session and import the feature table (e.g., `gesture_features.mat`).
   - Select “Label” as the response variable.
   - Use cross-validation (5-fold is recommended) and try different classifiers (Decision Trees, SVM, KNN, etc.).
   - Export the best performing model as a MAT file.

---

## Dataset Description

### Raw Data
- **Sensors:**  
  - Accelerometer (3D vector)
  - Gyroscope (3D vector)
  - Orientation (3D vector)
  - Magnetometer (3D vector)
- **Sampling:**  
  Data is recorded at 100 Hz.
- **Duration:**  
  Each acquisition is cropped to 2.5 seconds (250 samples).

### Annotations
Annotations for each acquisition are stored in `metadata.csv` with the following columns:
- **ID_Subject:** The subject identifier (padded to two digits).
- **Idx_Acquisition:** The sequential number of the acquisition for that subject.
- **Hand:** The hand used during the acquisition.
- **Smartphone_Model:** The model of the smartphone used.
- **Available_Sensors:** A code indicating which sensors were available (default “5”).
- **ID_Gesture:** The gesture identifier (set to the gesture name provided).

---

## Feature Extraction (Optional Task 1)

The feature extraction process (in `classification.m`) currently computes:
- **Statistical Features:**
  - For each axis of the accelerometer, gyroscope, and orientation data:
    - Mean, Standard Deviation, Range (max-min), and RMS.
  - For the accelerometer, the mean and standard deviation of the resultant acceleration magnitude.
- **Temporal Features:**
  - For each sensor axis, the dominant frequency (and its amplitude) via FFT.
- *(Note: Orientation features have been removed; magnetometer features are not used in this version.)*

**Considerations:**  
You may later explore additional features such as average absolute deviation, median, median absolute deviation, interquartile range, or features based on the magnetometer if your environment is controlled.

---

## How to Train a Model (Optional Task 1)

1. **Prepare the Dataset:**  
   Run `modelTraining.m` to extract features from the acquisitions.
2. **Use Classification Learner:**  
   - Open the Classification Learner app in MATLAB.
   - Import the feature table (e.g., `gesture_features.mat`).
   - Set “Label” as the response variable.
   - Experiment with different classification methods and cross-validation.
3. **Export the Model:**  
   Export the best-performing model as a MAT file.

---

## Running the Project

- **Recording Data:**  
  Run `main.m` each time you want to record a new acquisition.
  
- **Visualizing Data:**  
  Use the plots already stored in the Data folder or run `plotData.m` to generate new plots before recording additional acquisitions.
  
- **Training a Classifier:**  
  When you are ready to train a model, run `modelTraining.m`.

*Note:* All files are expected to be in the main folder. If you relocate files, adjust the `cfg.GestureFolder` setting in `config.m` accordingly.

---

## Summary

This project collects and processes sensor data for gesture recognition, stores the data in a structured MAT file with corresponding annotations in a CSV file, and provides scripts for visualizing the data. Additionally, it offers a feature extraction pipeline for classifier training. Follow the instructions above to record new acquisitions, view data plots, and train your model.
