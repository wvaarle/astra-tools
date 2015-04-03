classdef Generator < handle
	
	properties (Access = protected)
		nextIndex = 1
	end
	
	methods

		% -----------------------------------------------------------------
		% constructor
		function this = Generator()

		end

		% -----------------------------------------------------------------
		% get next image
		function Im = next(this)
			if this.nextIndex > this.length()
				Im = [];
			else
				Im = this.index(this.nextIndex);
			end
			this.nextIndex = this.nextIndex + 1;
		end		
	
		% -----------------------------------------------------------------
		% done?
		function d = done(this)
			d = this.nextIndex > this.length();
		end
		
	end
	
end

