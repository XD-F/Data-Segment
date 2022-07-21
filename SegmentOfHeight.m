% This program is used to segment the sensor data according to a gradient. The 
% sensor data obtained during a long measurement period may not present a good 
% step feature or even show a chaotic trend due to environmental factors such as
% high winds that prevent effective control of the sensor height.
%
% Sliding average filtering of the data allows the data segments to be sorted 
% according to the proximity of their mean values to each target height. The 
% most appropriate data segments are then selected based on statistical 
% characteristics such as variance, polar deviation, etc.
%
% To ensure that the results can be output, the extreme difference is 
% dynamically increased depending on the data set, and its initial value is 
% determined according to the accuracy of the sensor. The average value, the 
% update threshold of the range, and the interval between data segments need to 
% be determined by yourself.

pkg load signal
clear;clc;

% Enter the file name to read in the data
Data = csvread('211124_15_chounanGround.csv');
LatitudeData = Data(:,11);
HeightData = LatitudeData - LatitudeData(1);
HeightData = HeightData * 2;


%%%%%%%%%%%%%%%%%%%%%

%Filter System

Lowpass = fir1(10, 0.1, "low");
HeightData_lowpass = filter(Lowpass, 1, HeightData);

figure(1);
plot(HeightData);
hold on;
plot(HeightData_lowpass);

figure(2);
freqz(Lowpass);






%%%%%%%%%%%%%%%%%%%%%
Tc = 8;% Time constant

N_candi = 4; % Number of candidate

range_limit = 1.3;                % limitation of range (This value will increase adaptively) 
                                  % and the initial value is set according to the sensor accuracy
range_grad = 0.01;                % Gradient of range
range_update_limit = 1;           % Updata flag of range
average_limit = 2;                % Allowable average limit
segment_interval = 5;             % distance (number of sample point) between tow segments

meas_time = 70;                   % Length of time for measurement in all height
stable_time = meas_time - 4 * Tc; % Length of time of stable data
                                  % Tc : Time Constant of sensor
                                  
Height = 6 * 2;                   % Maximum data of height 


%%%%%%%%%%%%%%%%%%%%%  

ave = movmean(HeightData_lowpass, meas_time);
ave_log = ave;
maxvalue = movmax(HeightData_lowpass, stable_time/2);
minvalue = movmin(HeightData_lowpass, stable_time/2);
range = maxvalue - minvalue;
looptime = zeros(Height);
MinFive = zeros(Height, N_candi);
position = zeros(Height);


##while()
  
  for i = 1 : Height - 1 
    j = 1;
    ave_temp = ave;
    range_limit_temp = range_limit;
    do
      
      looptime(i + 1) = looptime(i + 1) + 1;
      
      if(min(ave_temp) >= i + 1 + range_update_limit)
        % Scheduled Height(i) + Range Update Threshhold      
        ave_temp = ave_log;
        range_limit_temp = range_limit_temp + range_grad
      endif
      
      overrange = 0;
      overlap = 0;
      tempabs = abs(ave_temp - i - 1);
      tempmin = min(tempabs);
      candi_bug = find( tempabs == tempmin ); 
      % Upstream Missing Feature in Octave (To be solved)      
      candi = candi_bug(1) * 1;
      
      

      
      ave_temp(candi) = 100;                                                    
      % Set the data of complemented judgments to 100
      
      if( abs(ave(candi) - i - 1) > average_limit )
        % Allowable Average Limit
        continue;
      endif
      
      if ((candi - stable_time/2 < 1)||(candi + stable_time/2 > 771)) 
        % Boundary data is prohibited from being taken to prevent
        % crosing the boundary
        continue;
      endif
      
      % Prevention of Overlap
      if(i > 1)
        for n = 1 : i - 1                                                             
          if(abs(Segment_mid(n + 1) - candi) <= stable_time/2 + segment_interval)
            % Length of Measurement + Data Segment Interval
            overlap = overlap + 1;
          endif
        endfor
      endif
      if(overlap >= 1)
        overlap = 0;
        continue;
      endif                                                                     
       
      for n = candi - stable_time/2: candi + stable_time/2
        % Allowable Range    
        if(range(n) > range_limit_temp)                                         
          overrange = overrange + 1;
        endif
      endfor
      if(overrange >= 1)
        overrange = 0;
        continue;
      endif
      
      ave_log(candi) = 100;
      % Set the data of complemented log to 100      
      
      MinFive(i + 1, j) = candi;
      clip(j,:) = HeightData_lowpass(MinFive(i + 1, j) - stable_time/2 : MinFive(i + 1, j) + stable_time/2 ); 
      j = j + 1;
     
    until (j > N_candi)
    
    
    position(i + 1) = find( var( clip(:) ) == min(var( clip(:) )) )
    
    % mid, start and end position (position in the entire measurement data) of each segment
    Segment_mid(i + 1) = MinFive(i + 1, position(i + 1));
    Segment_start(i + 1) = Segment_mid(i + 1) - stable_time/2;
    Segment_end(i + 1) = Segment_mid(i + 1) + stable_time/2;
    
  end


##endwhile


%plot result of segments
figure(3);
plot(1:771, HeightData_lowpass, 'r');
for i = 1 : Height - 1
  hold on;
  plot(Segment_start(i+1) : Segment_end(i+1), HeightData_lowpass(Segment_start(i+1) : Segment_end(i+1)), 'o', 'markersize', 3);
end

hold on;
plot(1:771, HeightData, 'b');







