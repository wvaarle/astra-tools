
fname = 'barbapapa/AlCuFilter_28um_.log';

fid = fopen(fname,'r');

S = textscan(fid,'%s','delimiter','\n');

log = struct();
current = [];
subname = '';
for i = 1:numel(S{1})
	line = lower(S{1}{i});
	if line(1) == '['
		subname = line(2:end-1);
	else
		% split by '='
		C = strsplit(line, '=');
		if numel(C) == 2 
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
