classdef Files < Generator
	
	properties (Access = private)
		files = {}
	end
	
	methods

		% -----------------------------------------------------------------
		% constructor
		function this = Files(filenames)
			this.files = filenames;
		end
	
		% -----------------------------------------------------------------
		% length
		function l = length(this)
			l = length(this.files);
		end

		% -----------------------------------------------------------------
		% size
		function s = size(this)
			s = size(imread(this.files{1}));
		end		
		
		% -----------------------------------------------------------------
		% get image by index
		function Im = index(this, i)
			if i > length(this.files)
				Im = [];
			else
				Im = imread(this.files{i});
			end
		end
		
	end
	
end

