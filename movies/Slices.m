classdef Slices < Generator

	properties (Access = private)
		data = [];
		direction = 3;
		scale = 1;
	end

	methods

		% -----------------------------------------------------------------
		% constructor
		function this = Slices(data, direction)
			this.data = data;
			this.scale = max(data(:));
			if nargin >= 2
				this.direction = direction;
			end
		end

		% -----------------------------------------------------------------
		% length
		function l = length(this)
			l = size(this.data, this.direction);
		end

		% -----------------------------------------------------------------
		% size
		function s = size(this)
			s = size(this.data);
			if this.direction == 1 
				s = s([2 3]);
			elseif this.direction == 2
				s = s([1 3]);
			else 
				s = s([1 2]);
			end
		end
		
		% -----------------------------------------------------------------
		% get image by index
		function Im = index(this, i)
			if i > this.length()
				Im = [];
			end
			if this.direction == 1 
				Im = squeeze(this.data(i,:,:));
			elseif this.direction == 2
				Im = squeeze(this.data(:,i,:));
			else 
				Im = squeeze(this.data(:,:,i));
			end
			Im = Im / this.scale * 255;
		end

	end

end

