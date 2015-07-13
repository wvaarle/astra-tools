function [sinogram, angles,data] = skyscan_rebin_fan2par(Datafilename, logfilename)
%------------------------------------------------------------------------
% [sinogram, angles,data] = skyscan_rebin_fan2par(Datafilename, logfilename)
% 
% Reads log file and sinogram made by SkyScanSinogramMaker and transforms 
% it into parallel beam projection data.
% 
% Datafilename: name of the file containing the raw projection data.
% logfilename: name of the skyscan log file.
% 
% author : Gert Van Gompel
% 12/03/2008% 
%------------------------------------------------------------------------
%------------------------------------------------------------------------
% This file is part of the
% All Scale Tomographic Reconstruction Antwerp Toolbox ("ASTRA-Toolbox")
%
% Copyright: iMinds-Vision Lab, University of Antwerp
% License: Open Source under GPLv3
% Contact: mailto:astra@ua.ac.be
% Website: http://astra.ua.ac.be
%------------------------------------------------------------------------
% $Id: skyscan_rebin_fan2par.m 1846 2014-10-14 13:47:04Z wvaarle $

%% Parse .log file
data = skyscan_read_log(logfilename);

% get distance betwee source and center of rotation
AfstandBronObject = data.object_to_source__mm_; 

% get pixel size (volume)
if isfield(data,'image_pixel_size__um_')
	ImagePixelSize = data.image_pixel_size__um_ * 10^(-3);
elseif isfield(data,'pixel_size__um_')
	ImagePixelSize = data.pixel_size__um_ * 10^(-3);
else
	disp('warning');
	ImagePixelSize=1;
end

% get Rotation Step
RotStep = data.rotation_step__deg_;
ThetaStep = RotStep;
Rot360=0;
% switch data.Use_____Rotation
%     case 'YES'
%         Rot360=1;
%     case 'NO'
%         Rot360=0;
% end

% D = afstand bron - rotatiecentrum in pixels, dus afstand
D = AfstandBronObject / ImagePixelSize;

%% Read Sinogram image
sinogramBg = double(imread(Datafilename,'tif'));
% SinoMax=max(max(sinogramBg));
sinogramNew = flipdim(sinogramBg',1);%/SinoMax;

%% Compute Angles

% No Full Scan
if Rot360 == 0 
	
	% Number of projections
    NumDeg = size(sinogramNew,2);
    
	% Fan-beam angles
	BetaDeg = 90-(NumDeg-1)/2*RotStep:RotStep:90+(NumDeg-1)/2*RotStep;

	% Parallel-beam angles
	ThetaDeg = ThetaStep/2:ThetaStep:180-ThetaStep/2;
	
elseif Rot360 == 1
	
	sinogramNewtemp = zeros(size(sinogramNew,1),size(sinogramNew,2)+100);
    sinogramNewtemp(:,1:50) = sinogramNew(:,end-49:end);
    sinogramNewtemp(:,51:end-50) = sinogramNew;
    sinogramNewtemp(:,end-49:end) = sinogramNew(:,1:50);
    sinogramNew = sinogramNewtemp;
    NumDeg = size(sinogramNew,2);
    BetaDeg = 180-(NumDeg-1)/2*RotStep:RotStep:180+(NumDeg-1)/2*RotStep;
    ThetaDeg = ThetaStep/2:ThetaStep:360-ThetaStep/2;
end
theta = ThetaDeg;

%% Actual Rebinning
F = rebin_fan2par(sinogramNew, BetaDeg, D, ThetaDeg);
F(F < 0) = 0;


%% Make Compatible with Astra toolbox
sinogram = fliplr(F)';
angles = theta * pi / 180;


