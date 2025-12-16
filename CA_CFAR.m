clear all
clc;

%% Radar Specifications 
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Frequency of operation = 77GHz
% Max Range = 200m
% Range Resolution = 1 m
% Max Velocity = 100 m/s
%%%%%%%%%%%%%%%%%%%%%%%%%%%

Rmax = 200;
range_res = 1;

%speed of light = 3e8
%% User Defined Range and Velocity of target
% define the target's initial position and velocity. Note : Velocity
% remains contant

c = 3e8;
target_range = 110;     % meters
target_velocity = -20;  % m/s (negative = approaching)

%% FMCW Waveform Generation

%Design the FMCW waveform by giving the specs of each of its parameters.
% Calculate the Bandwidth (B), Chirp Time (Tchirp) and Slope (slope) of the FMCW
% chirp using the requirements above.

Bsweep = c / (2 * range_res);

% Calculate the chirp time based on the Radar's Max Range
Tchirp = 5.5 * (2 * Rmax / c);
fprintf('Tchirp = %.2f microseconds\n', Tchirp * 1e6);

%FMCW Slope
slope = Bsweep / Tchirp;

fprintf('Chirp slope = %.4e Hz/s\n', slope);


%Operating carrier frequency of Radar 
fc= 77e9;             %carrier freq

                                                          
%The number of chirps in one sequence. Its ideal to have 2^ value for the ease of running the FFT
%for Doppler Estimation. 
Nd=128;                   % #of doppler cells OR #of sent periods % number of chirps

%The number of samples on each chirp. 
Nr=1024;                  %for length of time OR # of range cells

% Timestamp for running the displacement scenario for every sample on each
% chirp
t=linspace(0,Nd*Tchirp,Nr*Nd); %total time for samples


%Creating the vectors for Tx, Rx and Mix based on the total samples input.
Tx=zeros(1,length(t)); %transmitted signal
Rx=zeros(1,length(t)); %received signal
Mix = zeros(1,length(t)); %beat signal

%Similar vectors for range_covered and time delay.
r_t=zeros(1,length(t));
td=zeros(1,length(t));


%% Signal generation and Moving Target simulation
% Running the radar scenario over the time. 

for i=1:length(t)         
    
    
    % Update target range for constant velocity
    r_t(i) = target_range + target_velocity * t(i);

    % Time delay (round trip)
    td(i) = 2 * r_t(i) / c;
    
    %For each time sample we need update the transmitted and
    %received signal. 
    Tx(i) = cos(2*pi*( fc*t(i) + (slope*t(i)^2)/2 ));

    Rx(i) = cos(2*pi*( fc*(t(i) - td(i)) + (slope*(t(i) - td(i))^2)/2 ));
    

    % Beat signal (mixing)
    Mix(i) = Tx(i) * Rx(i);
    
end

%% RANGE MEASUREMENT


 % *%TODO* :
%reshape the vector into Nr*Nd array. Nr and Nd here would also define the size of
%Range and Doppler FFT respectively.
% Reshape the beat signal into Nr x Nd
Mix_reshaped = reshape(Mix, Nr, Nd);


 % *%TODO* :
%run the FFT on the beat signal along the range bins dimension (Nr) and
%normalize.

% Run FFT along range dimension
sig_fft = fft(Mix_reshaped, Nr);

% Normalize
sig_fft = sig_fft ./ Nr;


% Take magnitude
sig_fft = abs(sig_fft);

% Take only one side of spectrum
sig_fft = sig_fft(1:Nr/2, :);


%plotting the range
figure('Name','Range from First FFT');


subplot(2,1,1)
plot(sig_fft(:,1))

xlabel('Range Bin')
ylabel('Normalized Amplitude')
title('Range FFT')

 
axis ([0 200 0 1]);
grid on


%% RANGE DOPPLER RESPONSE
% The 2D FFT implementation is already provided here. This will run a 2DFFT
% on the mixed signal (beat signal) output and generate a range doppler
% map.You will implement CFAR on the generated RDM


% Range Doppler Map Generation.

% The output of the 2D FFT is an image that has reponse in the range and
% doppler FFT bins. So, it is important to convert the axis from bin sizes
% to range and doppler based on their Max values.

Mix=reshape(Mix,[Nr,Nd]);

% 2D FFT using the FFT size for both dimensions.
sig_fft2 = fft2(Mix,Nr,Nd);

% Taking just one side of signal from Range dimension.
sig_fft2 = sig_fft2(1:Nr/2,1:Nd);
sig_fft2 = fftshift (sig_fft2);
RDM = abs(sig_fft2);
RDM = 10*log10(RDM) ;

%use the surf function to plot the output of 2DFFT and to show axis in both
%dimensions
doppler_axis = linspace(-100,100,Nd);
range_axis = linspace(-200,200,Nr/2)*((Nr/2)/400);


figure,surf(doppler_axis,range_axis,RDM);
xlabel('Doppler (m/s)')
ylabel('Range (m)')
zlabel('Amplitude')
title('Range Doppler Map');

%% CFAR implementation

%Slide Window through the complete Range Doppler Map

%Select the number of Training Cells in both the dimensions.
Tr = 10; % Training Cells in Range dimension (rows)
Td = 8;  % Training Cells in Doppler dimension (columns)

% *%TODO* :
%Select the number of Guard Cells in both dimensions around the Cell under 
%test (CUT) for accurate estimation

Gr = 4; % Guard Cells in Range dimension (rows)
Gd = 4; % Guard Cells in Doppler dimension (columns)

% *%TODO* :
% offset the threshold by SNR value in dB
offset = 6; % Desired SNR margin (e.g., 6 dB)

% *%TODO* :
%Create a vector to store noise_level for each iteration on training cells
noise_level = zeros(1,1);

% Initialize CFAR output map
RDM_cfar = zeros(size(RDM));

[range_size, doppler_size] = size(RDM);


% *%TODO* :
%design a loop such that it slides the CUT across range doppler map by
%giving margins at the edges for Training and Guard Cells.
%For every iteration sum the signal level within all the training
%cells. To sum convert the value from logarithmic to linear using db2pow
%function. Average the summed values for all of the training
%cells used. After averaging convert it back to logarithimic using pow2db.
%Further add the offset to it to determine the threshold. Next, compare the
%signal under CUT with this threshold. If the CUT level > threshold assign
%it a value of 1, else equate it to 0.

% Slide the CUT across the RDM avoiding edges
first_iter = true;
for i = (Tr + Gr + 1):(range_size - (Tr + Gr))
    for j = (Td + Gd + 1):(doppler_size - (Td + Gd))
        
        % Extract training + guard + CUT block
        block = RDM(i-(Tr+Gr):i+Tr+Gr, j-(Td+Gd):j+Td+Gd);

        % 2. Convert the block to LINEAR POWER
        block_linear = db2pow(block);
        
        % Zero out guard cells + CUT
        block_linear(Tr+1 : Tr+2*Gr+1, Td+1 : Td+2*Gd+1) = 0;
        %block_linear(Tr+1 : end - Tr, Td+1 : end - Td) = 0;

        % Noise level (linear scale)
        noise_level = sum((block_linear(:)));
        
        % Number of training cells
        num_training_cells = ((2*(Tr+Gr)+1)*(2*(Td+Gd)+1)) - ((2*Gr+1)*(2*Gd+1));

         if first_iter
            fprintf('First CFAR iteration:\n');
            fprintf('Block size: %d x %d\n', size(block,1), size(block,2));
            fprintf('Number of training cells: %d\n', num_training_cells);
            first_iter = false;
        end
        
        % Threshold in dB
        threshold = pow2db(noise_level / num_training_cells);
        threshold = threshold + offset;
        
        % Apply threshold to CUT
        if RDM(i,j) > threshold
            RDM_cfar(i,j) = 1;   % target detected
        else
            RDM_cfar(i,j) = 0;   % noise
        end
    end
end


% Plot CFAR output
figure('Name','CA-CFAR on RDM')
surf(doppler_axis, range_axis, RDM_cfar)
xlabel('Doppler')
ylabel('Range')
zlabel('Detection')
title('2D CA-CFAR Detection Map')
colorbar



 
