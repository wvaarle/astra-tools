function proj_geom = astra_parse_skyscan_log(fname)

	% parse log
	log = skyscan_read_log(fname);

	% parse angles
	angles = (0:log.acquisition.rotation_step_deg:(log.acquisition.number_of_files-1)*log.acquisition.rotation_step_deg) / 180 * pi + pi;
	if isfield(log.acquisition,'cs_static_rotation_deg')
		angles = angles - (log.acquisition.cs_static_rotation_deg / 180 * pi) - (1.50 * log.acquisition.rotation_step_deg / 180 * pi);
	end	
	%if strcmp(this.flipdata, 'yes')
	%	angles = fliplr(angles);
	%end							
			
	% create projection geometry
	proj_geom = astra_create_proj_geom(	'fanflat', ...													  % type
										1, ...															  % # rows
										log.acquisition.number_of_columns,...										  % # cols
										angles,	...														  % angles
										log.acquisition.object_to_source_mm * 1000 / log.acquisition.image_pixel_size_um, ... % object to source
										0);		
end

function log = skyscan_read_log(fname)

	fid = fopen(fname,'r');
	S = textscan(fid,'%s','delimiter','\n');
	fclose(fid);
	
	log = struct();
	subname = '';
	for i = 1:numel(S{1})
		line = lower(S{1}{i});
		if line(1) == '['
			subname = line(2:end-1);
		else
			% split by '='
			%C = strsplit(line, '=');
			%if numel(C) == 2 
			
			tmp = find(line == '=');
			if numel(tmp) > 0
				C{1} = line(1:tmp-1);
				C{2} = line(tmp+1:end);
				
				% parse parameter
				param = C{1};
				param(param == 40 | param == 41) = ' ';
				param = strtrim(param);
				param(~isletter(param) & ~(param>47 & param<57)) = '_';	
				param = strrep(param, '__', '_');
				param = strrep(param, '__', '_');
				if param(end) == '_'
					param = param(1:end-1);
				end
				% parse value
				value = strtrim(C{2});
				valueNum = str2double(value);
				if ~isnan(valueNum)
					value = valueNum;
				end			
				log.(subname).(param) = value;
			end
		end
	end
	
end
