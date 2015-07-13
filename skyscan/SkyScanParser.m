classdef SkyScanParser < handle

	% Class for parsing SkyScan projection data preprocessed by the NRecon software
	% (Shift+Ctrl+Alt+E > "generate sinogram for later use" > yes > yes)

	properties (GetAccess=public, SetAccess=public)

		directory	= [];			% SETTING: Directory where all files are stored.

		log_file	= [];			% SETTING: Location of the .log file (optional if directory is specified)
		img_prefix	= [];			% SETTING: Prefix to all images files (optional if directory is specified)
		projections = 0;			% SETTING: List of all available projection numbers (optional if directory is specified)

		progress	= 'no';			% SETTING: Show progress bar? {'no', 'yes'}
		allow_vec	= 'yes';		% SETTING: Allow the creation of vector projection geometries.  Should be disabled if cpu algorithms will be used.  {'yes', 'no'}  Disabling this will also disable automatic postalignment correction.

		flipdata	= 'yes';			% SETTING: flip the data? TODO: check if this is necessary?

		downsampling = 1;			% SETTING downsample sinogram?

		% data
		log			= struct();		% Parsed log file.
	end

	properties (GetAccess=public, SetAccess=private)
		initialized = 0;			% Is the object initialized?
		img_files	= {};			% Cell array with all the image files.
	end

	properties (GetAccess=private, SetAccess=private)
		waitbar_handle;				% GUI handle for the progress bar.
	end

	methods (Access=public)

		%------------------------------------------------------------------
		function this = SkyScanParser(directory)
			% Constructor
			% >> parser = SkyScanParser();
			% >> parser = SkyScanParser(directory);

			if nargin > 0
				this.directory = directory;
			end
		end

		%------------------------------------------------------------------
		function ok = initialize(this)
			% Initializes the object and parses the .log file.
			% >> parser.initialize();

			% find log file from directory
			if numel(this.log_file) == 0
				A = dir(this.directory);
				for i = 1:numel(A)
					if strfind(A(i).name,'.log')
						this.log_file = [this.directory '/' A(i).name];
						break;
					end
				end
			end

			% img files
			if numel(this.img_prefix) == 0 % from directory
				A = dir(this.directory);
				for i = 1:numel(A)
					% if numel(strfind(A(i).name,'.tif')) > 0 && numel(strfind(lower(A(i).name),'_prj_')) > 0
					if numel(strfind(A(i).name,'.img')) > 0 && numel(strfind(lower(A(i).name),'_prj')) > 0
						number = str2double(A(i).name(end-7:end-4)) + 1;
						this.img_files{number} = [this.directory '/' A(i).name];
					end
				end
				this.projections = numel(this.img_files);

			else % from prefix
				for i = 1:this.projections
					this.img_files{i} = sprintf('%s%0.4d.img',this.img_prefix, i-1);
				end
			end

			% parse log file
			this.log = SkyScanParser.read_log(this.log_file);

			this.initialized = 1;
			ok = this.initialized;
		end

		%------------------------------------------------------------------
		function out = get_log(this)
			% Get SkyScan log
			% >> log = parser.log();
			if this.initialized == 0
				this.initialize();
			end

			out = this.log;
		end

		%------------------------------------------------------------------
		function [sinogram, proj_geom] = central_slice(this)
			% Fetch central slice data (fan beam).
			% >> [sinogram, proj_geom] = parser.central_slice();

			[sinogram, proj_geom] = this.fanbeam();
		end

		%------------------------------------------------------------------
		function proj_geom = geometry(this, type)

			if this.initialized == 0
				this.initialize();
			end

			acq = this.log.acquisition;
			rec = this.log.reconstruction;

			if nargin < 2
				type = 'cone';
			end

			if strcmp(type,'fan')
				angles = (0:acq.rotation_step__deg_:((this.projections-1)*acq.rotation_step__deg_)) / 180 * pi + pi;
				if isfield(acq,'cs_static_rotation__deg_')
					angles = angles - (acq.cs_static_rotation__deg_ / 180 * pi) - (1.50 * acq.rotation_step__deg_ / 180 * pi);
				end
				if strcmp(this.flipdata, 'yes')
					angles = fliplr(angles);
				end

				proj_geom = astra_create_proj_geom(	'fanflat', ...                                                                          % type
													1, ...                                                                                  % # rows
													acq.number_of_columns / this.downsampling ,...                                          % # cols
													angles,	...                                                                             % angles
													acq.object_to_source__mm_ * 1000 / (acq.image_pixel_size__um_ * this.downsampling), ... % object to source
													0);                                                                                     % object to detector

				if strcmp(this.allow_vec,'yes') && isfield(rec,'postalignment')
					proj_geom = astra_geom_2vec(proj_geom);
					if strcmp(this.flipdata, 'yes')
						proj_geom = astra_geom_postalignment(proj_geom, -rec.postalignment / this.downsampling);
					else
						proj_geom = astra_geom_postalignment(proj_geom, rec.postalignment / this.downsampling);
					end
				end

			elseif strcmp(type,'cone')

			end

		end

		%------------------------------------------------------------------
		function [sinogram, proj_geom] = fanbeam(this, slices)
			% Fetch fan beam data.
			% >> [sinogram, proj_geom] = parser.fanbeam();       fetches central slice
			% >> [sinogram, proj_geom] = parser.fanbeam(slices); fetches user specified slice

			if this.initialized == 0
				this.initialize();
			end

			proj_geom = this.geometry('fan');

			% read data
			if nargin >= 2
				sinogram = read_slices2d(this, slices);
			else
				sinogram = read_slices2d(this, this.log.acquisition.optical_axis__line_);
			end
			sinogram = downsample_sinogram(sinogram, this.downsampling);

			if strcmp(this.flipdata, 'yes')
				if nargin < 2
					sinogram = fliplr(sinogram);
				else
					for i = 1:numel(slices)
						sinogram(:,:,i) = fliplr(sinogram(:,:,i));
					end
				end
			end

		end

		%------------------------------------------------------------------
		function [sinogram, proj_geom, sinogram_par, proj_geom_par] = parallelbeam(this, slices)
			% Fetch fan beam data and rebins it to parallel beam data. (Broken!)
			% >> [sinogram, proj_geom] = parser.parallelbeam();       fetches central slice
			% >> [sinogram, proj_geom] = parser.parallelbeam(slices); fetches user specified slice

			if this.initialized == 0
				this.initialize();
			end

			% parse angles
			angles = (0:this.log.rotation_step__deg_:((this.projections-1)*this.log.rotation_step__deg_)) / 180 * pi;
			if isfield(this.log,'cs_static_rotation__deg_')
				angles = angles - (this.log.cs_static_rotation__deg_ / 180 * pi);
			end
			if strcmp(this.flipdata, 'yes')
				angles = fliplr(angles);
			end

			% create projection geometry
			proj_geom = astra_create_proj_geom(	'fanflat', ...						% type
												1, ...								% # rows
												this.log.number_of_columns,...		% # cols
												angles,	...							% angles
												this.log.object_to_source__mm_ * 1000 / this.log.image_pixel_size__um_, ... % object to source
												0);									% object to detector

			% read data
			if nargin >= 2
				sinogram = read_slices2d(this, slices);
			else
				sinogram = read_slices2d(this, this.log.optical_axis__line_);
			end

			% rebin
			[sinogram_par, proj_geom_par] = this.rebinfan2par(sinogram, proj_geom);

			if strcmp(this.allow_vec,'yes') && isfield(this.log,'postalignment')
				proj_geom = astra_geom_2vec(proj_geom);
				proj_geom = astra_geom_postalignment(proj_geom, this.log.postalignment);
				proj_geom_par = astra_geom_2vec(proj_geom_par);
				proj_geom_par = astra_geom_postalignment(proj_geom_par, this.log.postalignment);
			end

			if strcmp(this.flipdata, 'yes')
				if nargin < 2
					sinogram = fliplr(sinogram);
				else
					for i = 1:numel(slices)
						sinogram(:,:,i) = fliplr(sinogram(:,:,i));
					end
				end
			end

		end
		%------------------------------------------------------------------

		function [sinogram, proj_geom] = conebeam(this, slices)
			% Fetch cone beam data.
			% >> [sinogram, proj_geom] = parser.conebeam(slices);

			if this.initialized == 0
				this.initialize();
			end

			% parse angles
			angles = (0:this.log.rotation_step__deg_:((this.projections-1)*this.log.rotation_step__deg_)) / 180 * pi + pi;
			if isfield(this.log,'cs_static_rotation__deg_')
				angles = angles - (this.log.cs_static_rotation__deg_ / 180 * pi) - (1.50 * this.log.rotation_step__deg_ / 180 * pi);
			end
			if strcmp(this.flipdata, 'yes')
				angles = fliplr(angles);
			end

			% create projection geometry
			proj_geom = astra_create_proj_geom(	'cone', ...							% type
												1, ...								% detector row size
												1, ...								% detector column size
												numel(slices), ...					% # rows
												this.log.number_of_columns,...		% # cols
												angles,	...							% angles
												this.log.object_to_source__mm_ * 1000 / this.log.image_pixel_size__um_, ... % object to source
												0);									% object to detector

			% read data
			sinogram = read_slices3d(this, slices);

			if strcmp(this.flipdata, 'yes')
				proj_geom.angles = fliplr(proj_geom.angles);
				sinogram = fliplr(sinogram);
			end

			if strcmp(this.allow_vec,'yes') && isfield(this.log,'postalignment')
				proj_geom = astra_geom_2vec(proj_geom);
				proj_geom = astra_geom_postalignment(proj_geom, this.log.postalignment);
			end

		end

	end

	%----------------------------------------------------------------------
	methods (Access=protected)

		function sinogram = read_slices2d(this, slices)
			% read slices

			% waitbar
			if strcmp(this.progress,'yes')
				this.waitbar_handle = waitbar(0, 'Reading data...');
			end

			acq = this.log.acquisition;

			% if acq.depth__bits_ == 16
			% 	depth = 'uint16=>single';
			% elseif acq.depth__bits_ == 32
			% 	depth = 'single';
			% else
			% 	depth = 'double=>single';
			% end
			depth = 'single';

			% read data lines
			sinogram = zeros(this.projections, acq.number_of_columns, numel(slices));
			for proj = 1:this.projections

				% read entire image from file
				fid = fopen(this.img_files{proj});
				data = fread(fid, [acq.number_of_columns, acq.number_of_rows], depth)';
				data = flipud(data);
				fclose(fid);

				% fetch correct slices
				for slice = 1:numel(slices)
					sinogram(proj,:,slice) = data(end-slices(slice),:);
				end

				% waitbar
				if strcmp(this.progress,'yes')
					waitbar(proj/this.projections, this.waitbar_handle);
				end

			end

			% waitbar
			if strcmp(this.progress,'yes')
				close(this.waitbar_handle);
			end

		end
		%------------------------------------------------------------------

		function sinogram = read_slices3d(this, slices)
			% read slices

			% waitbar
			if strcmp(this.progress,'yes')
				this.waitbar_handle = waitbar(0, 'Reading data...');
			end

			% read data lines
			sinogram = zeros(this.log.number_of_columns, this.projections, numel(slices));
			for proj = 1:this.projections

				% read entire image from file
				fid = fopen(this.img_files{proj});
				data = fread(fid,[this.log.number_of_columns, this.log.number_of_rows],'single')';
				data = flipud(data);
				fclose(fid);

				% fetch correct slices
				for slice = 1:numel(slices)
					sinogram(:,proj,slice) = data(slices(slice),:);
				end

				% waitbar
				if strcmp(this.progress,'yes')
					waitbar(proj/this.projections, this.waitbar_handle);
				end

			end

			% waitbar
			if strcmp(this.progress,'yes')
				close(this.waitbar_handle);
			end

		end

		%------------------------------------------------------------------
		function [sinogram_par, proj_geom_par] = rebinfan2par(this, sinogram, proj_geom)
			% F = rebin_fan2par(RadonData, BetaDeg, D, thetaDeg)
			%
			% Deze functie zet fan beam data om naar parallelle data, door interpolatie
			% (fast resorting algorithm, zie Kak en Slaney)
			% Radondata zoals altijd: eerste coord gamma , de rijen
			%                          tweede coord beta, de kolommen, beide hoeken in
			%                          radialen
			% PixPProj: aantal pixels per projectie (voor skyscan data typisch 1000)
			% BetaDeg: vector met alle draaihoeken in graden
			% D: afstand bron - rotatiecentrum in pixels, dus afstand
			% bron-rotatiecentrum(um) gedeeld door image pixel size (um).
			% thetaDeg: vector met gewenste sinogramwaarden voor theta in graden
			%       de range van thetaDeg moet steeds kleiner zijn dan die van betadeg
			% D,gamma,beta, theta zoals gebruikt in Kak & Slaney



			% Fan-beam angles
			BetaDeg = proj_geom.ProjectionAngles;

			% Parallel-beam angles
			ThetaStep = this.log.rotation_step__deg_;
			ThetaDeg = ThetaStep/2:ThetaStep:180-ThetaStep/2;
			%theta = ThetaDeg;
			%theta = theta / 180 * pi;

			NpixPProj = size(sinogram,2);  % aantal pixels per projectie
			NpixPProjNew = NpixPProj;

			%----------------------------------
			% FAN-BEAM RAYS

			% flip sinogram, why?
			%sinogram = flipdim(sinogram,2);  %  matlab gebruikt tegengestelde draairichting (denkik) als skyscan, of er is een of andere flipdim geweest die gecorrigeerd moet worden))

			% DetPixPos: distance of each detector to the ray through the origin (theta)
			if isfield(this.log,'postalignment');
				DetPixPos = (-(NpixPProj-1)/2:(NpixPProj-1)/2) + this.log.postalignment;
			else
				DetPixPos = -(NpixPProj-1)/2:(NpixPProj-1)/2;
			end

			% D: afstand bron object / image pixel size
			% get pixel size (volume)
			if isfield(this.log,'image_pixel_size__um_')
				ImagePixelSize = this.log.image_pixel_size__um_ * 10^(-3);
			elseif isfield(this.log,'pixel_size__um_')
				ImagePixelSize = this.log.pixel_size__um_ * 10^(-3);
			end
			D = this.log.object_to_source__mm_ / ImagePixelSize;

			% GammaStralen: alpha's? (result in radians!!)
			GammaStralen = atan(DetPixPos/D); % alle met de detectorpixelposities overeenkomstige gammahoeken

			% put beta (theta) and gamma (alpha) for each ray in 2D matrices
			[beta gamma] = meshgrid(BetaDeg,GammaStralen);

			% t: minimal distance between each ray and the ray through the origin
			t = D*sin(gamma); % t-waarden overeenkomstig met de verschillende gamma's

			theta = gamma*180/pi + beta;  % theta-waarden in graden overeenkomstig met verschillende gamma en beta waarden

			%----------------------------------
			% PARALLEL BEAM RAYS

			% DetPixPos: distance of each detector to the ray through the origin (theta)
			if isfield(this.log,'postalignment');
				DetPixPos = (-(NpixPProjNew-1)/2:(NpixPProjNew-1)/2) + this.log.postalignment;
			else
				DetPixPos = -(NpixPProjNew-1)/2:(NpixPProjNew-1)/2;
			end

			% GammaStralen: alpha's? (result in radians!!)
			GammaStralenNew = atan(DetPixPos/D); % alle met de detectorpixelposities overeenkomstige gammahoeken

			% put beta (theta) and gamma (alpha) for each ray in 2D matrices
			[~, gamma] = meshgrid(BetaDeg,GammaStralenNew);

			% t: minimal distance between each ray and the ray through the origin
			tnew = D * sin(gamma); % t-waarden overeenkomstig met de verschillende gamma's

			% calculate new t
			step = (max(tnew)-min(tnew)) / (NpixPProjNew-1);
			t_para = min(tnew):step:max(tnew);

			[thetaNewCoord tNewCoord] = meshgrid(ThetaDeg, t_para);

			%----------------------------------
			% Interpolate
			Interpolant = TriScatteredInterp(theta(:), t(:), sinogram(:),'nearest');
			sinogram_par = Interpolant(thetaNewCoord,tNewCoord);
			proj_geom_par = astra_create_proj_geom('parallel', proj_geom.DetectorWidth, size(sinogram,2), theta);

		end
		%------------------------------------------------------------------


	end

	methods (Static)

		function data = read_log(fname)

			lines = textread(fname,'%s','delimiter','\n');
			current = '';
			data = struct();
			for i = 1:length(lines)
				if strcmp(lines{i}(1),'[')
					current = lower(lines{i}(2:end-1));
					current(~isletter(current) & ~(current>47 & current<57)) = '_';
					data.(current) = struct();
				else
					iEQ = find(lines{i} == '=');
					if ~isempty(iEQ)
						iEQ = iEQ(1);
						varName = lower(strtrim(lines{i}(1:iEQ-1)));

						% remove non-letters
						varName(~isletter(varName) & ~(varName>47 & varName<57)) = '_';
						varValue = strtrim(lines{i}(iEQ+1:end));

						% try to convert to numerical value
						if ~isnan(str2double(varValue))
							varValue = str2double(varValue);
						end
						data.(current).(varName) = varValue;
					end
				end

			end
		end

		function data = read_log_old(fname)

			S = textread(fname,'%s','delimiter','\n');
			vars = repmat({[]}, length(S), 2);
			for i = 1:length(S)
				iEQ = find(S{i} == '=');
				if ~isempty(iEQ)
					iEQ = iEQ(1);
					varName = lower(strtrim(S{i}(1:iEQ-1)));

					% remove non-letters
					varName(~isletter(varName) & ~(varName>47 & varName<57)) = '_';
					varValue = strtrim(S{i}(iEQ+1:end));

					% try to convert to numerical value
					varNum = str2double(varValue);
					if ~isnan(varNum)
						varValue = varNum;
					end

					vars(i,:) = {varName,varValue};
				end
			end
			vars = vars(~cellfun('isempty', vars(:,1)), :).';
			data = struct(vars{:});
		end

	end

end

