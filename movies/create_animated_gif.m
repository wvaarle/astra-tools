function create_animated_gif(input, file_out, varargin)
% input: image generator object
% file_out: output filename
% optional parameters:
%  - 'fps', 25
%  - 'pbar', {'off', 'topleft', 'topright', 'bottomleft', 'bottomright'}
%  - 'pbar_width', 50 (in pixels)
%  - 'pbar_height', 8 (in pixels)
%  - 'pbar_offset', 10 (in pixels)

% default settings
fps = 25;
pbar = 'off';
pbar_width = 50;
pbar_height = 8;
pbar_offset = 10;

% parse options
for i = 1:2:length(varargin)
	if strcmp(varargin{i},'fps')
		fps = varargin{i+1};
	elseif strcmp(varargin{i},'pbar')
		pbar = varargin{i+1};
	elseif strcmp(varargin{i},'pbar_width')
		pbar_width = varargin{i+1};
	elseif strcmp(varargin{i},'pbar_height')
		pbar_height = varargin{i+1};
	elseif strcmp(varargin{i},'pbar_offset')
		pbar_offset = varargin{i+1};
	end
end

% loop all images
s = input.size();
image = zeros(s(1),s(2),1,input.length());
%for i = 1:input.length()
i = 1;
while ~input.done()

	% get image
	%Im = input.index(i);
	Im = input.next();
	
	% add progress bar
	if ~strcmp(pbar,'off')

		if strcmp(pbar,'topleft')
			mincol = pbar_offset;
			maxcol = pbar_offset+pbar_width;
			minrow = pbar_offset;
			maxrow = pbar_offset+pbar_height;
		elseif strcmp(pbar,'topright')
			mincol = s(2)-pbar_offset-pbar_width;
			maxcol = s(2)-pbar_offset;
			minrow = pbar_offset;
			maxrow = pbar_offset+pbar_height;
		elseif strcmp(pbar,'bottomleft')
			mincol = pbar_offset;
			maxcol = pbar_offset+pbar_width;
			minrow = s(1)-pbar_offset-pbar_height;
			maxrow = s(1)-pbar_offset;
		elseif strcmp(pbar,'bottomright')
			mincol = s(2)-pbar_offset-pbar_width;
			maxcol = s(2)-pbar_offset;
			minrow = s(1)-pbar_offset-pbar_height;
			maxrow = s(1)-pbar_offset;
		else
			error('invalid pbar position')
		end
		
		progress = (i-1)/(input.length()-1);
		curcol = round((maxcol-mincol)*progress+mincol);
		
		val = max(Im(:));
		Im(minrow, mincol:maxcol) = val;
		Im(maxrow, mincol:maxcol) = val;
		Im(minrow:maxrow, mincol) = val;
		Im(minrow:maxrow, maxcol) = val;
		Im(minrow:maxrow, mincol:curcol) = val;

	end
	
	image(:,:,1,i) = Im;
	i = i + 1;
end

imwrite(image, file_out, 'DelayTime',1/fps, 'LoopCount',inf)

