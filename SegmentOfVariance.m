% This procedure is used to split the step data based on the variance distribution.
% The height data are first processed using a moving variance filter to obtain 
% the fluctuations centered on each data point. Then the data points are sorted 
% by variance size. Finally we select the desired number of data segments.

% This program is designed to avoid falling into boundary values and to prevent 
% data segments from overlapping. During the experiment, please try to ensure 
% the boundary data and the length of each data segment. In addition, unlike the
% program SegmentOfHeight, which splits the data according to a predetermined 
% height, this program does not take into account the deviation from the mean 
% value of each data segment. 

% However, to ensure the accuracy of the integration, please adjust the number 
% of data segments in the parameter setting so that the position of the data 
% segments can cover all heights.




% pkg load signal
clear;clc;

% Enter the file name to read in the data
Data = csvread('211124_15_chounanGround.csv');
LatitudeData = Data(:,11);
HeightData = LatitudeData - LatitudeData(1);
HeightData = HeightData * 2;

meas_time = 63;                         % Length of time for measurement in all height
Tc = 8;                                 % Time Constant of Sensor
stable_time = meas_time - 4 * Tc;       % Length of time of stable data
N_segment = 15;                         % Number of Data Segment


%%% Middle Point%%%
% if length of HeighData is odd    ==>  (length - 1)/2 : 1 : (length - 1)/2
% if length of HeightData is even  ==>   length/2 : 1 : (length/2 - 1)

%%% Boundary (endpoints)%%%
% "shrink" (default)
% The window is truncated at the beginning and end of the array to exclude elements 
% for which there is no source data. For example, with a window of length 3, 
% y(1) = var (x(1:2)), and y(end) = var (x(end-1:end)).
var = movvar(HeightData, stable_time);

% sort by variance
[var_sorted, time] = sort(var);

Segment_mid = zeros(1, N_segment);
Segment_start = zeros(1, N_segment);
Segment_end = zeros(1, N_segment);
n = 1; i = 0;
length_Data = length(time);


while(n < N_segment + 1)
  i = i + 1;
  if(i >= length_Data)
    error("Insufficient Data!");
  endif
  
  % Boundary data is prohibited from being taken to prevent crosing the boundary
  if( (time(i)-(stable_time-1)/2 < 1) || time(i)+(stable_time-1)/2 > length_Data )
    continue;
  endif  
  
  % Prevention of Overlap
  overrange = 0;
  for j = 1 : n
    if( abs(Segment_mid(j)-time(i)) < stable_time )
      overrange = 1;
      break;
    endif
  endfor
  if overrange > 0
    continue;
  endif
  
  % mid, start and end position (position in the entire measurement data) of each segment
  Segment_mid(n) = time(i);
  Segment_start(n) = time(i) - (stable_time-1)/2;
  Segment_end(n) = time(i) + (stable_time-1)/2;
  n = n + 1;
  
endwhile


%plot result of segments
fig = figure;
plot(1:length_Data, HeightData, 'b');
title("Height Data");
xlabel('Time / s');
ylabel('Height / m');
drawnow
frame = getframe(fig);
im{1} = frame2im(frame);

for i = 1 : N_segment
  plot(1:length_Data, HeightData, 'b');
  hold on;
  plot(Segment_start(i) : Segment_end(i), HeightData(Segment_start(i) : Segment_end(i)), 'r');
  title(['Data segment with the ',num2str(i),' th smallest variance']);
  xlabel('Time / s');
  ylabel('Height / m');

  drawnow
  frame = getframe(fig);
  im{i + 1} = frame2im(frame); 
endfor

plot(1:length_Data, HeightData);
title(['Data Segment of Variance']);
xlabel('Time / s');
ylabel('Height / m');

hold on;
for i = 1 : N_segment
  plot(Segment_start(i) : Segment_end(i), HeightData(Segment_start(i) : Segment_end(i)), 'r');
  hold on;
endfor
drawnow
frame = getframe(fig);
im{N_segment + 2} = frame2im(frame); 

close;

% Expert GIF file
filename = 'SegmentOfVariance.gif';
for idx = 1:(N_segment + 2)
    [A,map] = rgb2ind(im{idx});
    if idx == 1
        imwrite(A,map,filename,'gif','LoopCount',Inf,'DelayTime',1);
    else
        imwrite(A,map,filename,'gif','WriteMode','append','DelayTime',1);
    end
end

