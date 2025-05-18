classdef sensors
    % SENSORS - Manages sensor initialization, data collection, processing, and cleanup.
    
    methods(Static)
        function m = initializeSensors(port, baud)
            % initializeSensors - Initializes the mobile device sensors.
            try
              m = serialport(port, baud, "Timeout", 10);
              configureTerminator(m, "LF");
              flush(m);
              disp("Serial bağlantı hazır: " + port + " @" + num2str(baud) + " baud.");
            catch ME
                error('Sensors:InitFailed', 'Failed to initialize sensors: %s', ME.message);
            end
        end
        
        function [acc, gyro, ts] = collectSamples(m, numSamples)
          acc  = zeros(numSamples,3);
          gyro = zeros(numSamples,3);
          ts   = zeros(numSamples,1);

          % 1) DATA_START bekle
          disp("Waiting for DATA_START...");
          while true
            line = readline(m);
            if startsWith(strtrim(line), "DATA_START")
              break;
            end
          end
          disp("DATA_START received. Please make your gesture...");
          pause(0.1);

          % 2) CSV satırlarını oku
          for i = 1:numSamples
            line = readline(m);
            vals = sscanf(line, '%f,')';
            if numel(vals) < 7
              error('Sensors:ReadError', ...
                'Line %d: beklenen 7 değer gelmedi: %s', i, line);
            end

            acc(i,:)  = vals(1:3);
            gyro(i,:) = vals(4:6);
            ts(i)     = vals(7);

            % Her 100 örnekte bir 1 saniye geçmiş demektir
            if mod(i,100) == 0
              sec = i/100;
              disp( string(sec) + " second(s) elapsed..." )
            end
          end

          % 3) DATA_END bekle (atla veya uyar)
          line = readline(m);
          if ~startsWith(strtrim(line), "DATA_END")
            warning('Sensors:EndTag', 'DATA_END beklenmedi, gelen: %s', line);
          end

          disp("Veri alımı tamamlandı: " + num2str(numSamples) + " örnek.");
        end

      function [croppedData, croppedTime, cropIdx] = cropAndAdjustData(data, time, targetSamples)
          % cropAndAdjustData - Crops sensor data and time vector to target samples.
          try
              if size(data, 1) ~= length(time)
                  error('Sensors:SizeMismatch', 'Data and time arrays must match in length.');
              end
              filteredData = medfilt1(data, 3);
              totalSamples = size(filteredData, 1);
              extraSamples = totalSamples - targetSamples;
              if extraSamples > 0
                  cropStart = floor(extraSamples / 2);
                  cropEnd = ceil(extraSamples / 2);
                  cropIdx = (cropStart + 1):(totalSamples - cropEnd);
                  croppedData = filteredData(cropIdx, :);
                  croppedTime = time(cropIdx);
              else
                  croppedData = filteredData;
                  croppedTime = time;
                  cropIdx = 1:totalSamples;
              end
              croppedTime = croppedTime - croppedTime(1);  % Normalize time.
          catch ME
              error('Sensors:ProcessingFailed', 'Data processing failed: %s', ME.message);
          end
      end
    end
end