classdef volviewer2 < handle

	properties (Access = protected)
		slicecount = 1;
		slice = 1;
		direction = 'z';
		scale_min = 0;
		scale_max = 1;
		volume = [];
		linkname = '';
		name = '';
	end
	
	properties (Access = private)
		slice_text = [];
		min_text = [];
		max_text = [];
		sld = [];
		sliceAxes = [];
		dir_bg = [];
		dir_x = [];
		dir_y = [];
		dir_z = [];
	end
	
	methods

		% -----------------------------------------------------------------
		% constructor
		function this = volviewer2(vol, varargin)
			global global_syncs;
			
			this.volume = vol;
			this.direction = 'z';
			this.scale_min = min(this.volume(:));
			this.scale_max = max(this.volume(:));
			for i = 1:2:numel(varargin)
				if strcmp(varargin{i},'linkname')
					this.linkname = varargin{i+1};
				end
				if strcmp(varargin{i},'name')
					this.name = varargin{i+1};
				end				
			end
						
			if numel(this.linkname) > 0;
				if numel(global_syncs) == 0
					global_syncs = {{this.linkname, @this.sync}};
				else
					global_syncs{end+1} = {this.linkname, @this.sync};
				end
			end
			
			this.show();
		end	
	
		function show(this)

			% variables
			this.slicecount = size(this.volume,3);

			% open window
			f = figure('Visible','off');

			% label: slicenumber
			this.slice_text = uicontrol(f, 'Style','text');
			this.slice_text.String = 'Slice 1';
			this.slice_text.Units = 'normalized';
			this.slice_text.Position = [0.10 0.09 0.8 0.06];

			% label: min
			this.min_text = uicontrol(f, 'Style','text');
			this.min_text.String = '1';
			this.min_text.Units = 'normalized';
			this.min_text.Position = [0.05 0.04 0.05 0.05];

			% label: max
			this.max_text = uicontrol(f, 'Style','text');
			this.max_text.String = num2str(this.slicecount);
			this.max_text.Units = 'normalized';
			this.max_text.Position = [0.90 0.04 0.05 0.05];	

			% slider
			this.sld = uicontrol(f, 'Style', 'slider');
			this.sld.Min = 1;
			this.sld.Max = this.slicecount;
			this.sld.SliderStep = [1 1]/this.slicecount;
			this.sld.Value = 1;
			this.sld.Units = 'normalized';
			this.sld.Position = [0.10 0.05 0.8 0.05];
			this.sld.Callback = @this.updateSlice;

			% axes
			this.sliceAxes = axes('Parent',f);
			this.sliceAxes.Position = [0.10 0.20 0.8 0.7];
			
			% direction
			this.dir_bg = uibuttongroup(f);
			this.dir_bg.Title = 'direction';
			this.dir_bg.Position = [.02 .78 .1 .2];

			this.dir_x = uicontrol(this.dir_bg,'Style','radiobutton');
			this.dir_x.String = 'x';
			this.dir_x.Units = 'normalized';
			this.dir_x.Position = [.15 .7 .8 .2];
			this.dir_x.Callback = @this.setDirectionX;

			this.dir_y = uicontrol(this.dir_bg,'Style','radiobutton');
			this.dir_y.String = 'y';
			this.dir_y.Units = 'normalized';
			this.dir_y.Position = [.15 .4 .8 .2];
			this.dir_y.Callback = @this.setDirectionY;

			this.dir_z = uicontrol(this.dir_bg,'Style','radiobutton');
			this.dir_z.String = 'z';
			this.dir_z.Units = 'normalized';
			this.dir_z.Position = [.15 .1 .8 .2];
			this.dir_z.Callback = @this.setDirectionZ;
			this.dir_z.Value = 1;

			% display projection 1
			this.displaySlice(1);	

			f.Visible = 'on';
		end

		function updateSlice(this, source, ~)
			this.slice = floor(source.Value);
			this.slice_text.String = ['Slice ' num2str(this.slice)];
			this.displaySlice(this.slice);
			this.sync_links();
		end

		function displaySlice(this, s)
			if strcmp(this.direction,'z')
				imshow(this.volume(:,:,s),[this.scale_min this.scale_max],'Parent', this.sliceAxes);
			elseif strcmp(this.direction,'y')
				imshow(squeeze(this.volume(:,s,:)),[this.scale_min this.scale_max],'Parent', this.sliceAxes);
			else
				imshow(squeeze(this.volume(s,:,:)),[this.scale_min this.scale_max],'Parent', this.sliceAxes);
			end
		end

		function setDirectionX(this, ~, ~)
			this.direction = 'x';
			this.slicecount = size(this.volume,1);
			this.sld.Value = 1;
			this.sld.Max = this.slicecount;
			this.sld.SliderStep = [1 1]/this.slicecount;
			this.max_text.String = num2str(this.slicecount);
			this.displaySlice(1);
			this.dir_x.Value = 1;
			this.sync_links()
		end
		function setDirectionY(this, ~, ~)
			this.direction = 'y';
			this.slicecount = size(this.volume,2);
			this.sld.Value = 1;
			this.sld.Max = this.slicecount;
			this.sld.SliderStep = [1 1]/this.slicecount;
			this.max_text.String = num2str(this.slicecount);
			this.displaySlice(1);
			this.dir_y.Value = 1;
			this.sync_links()
		end
		function setDirectionZ(this, ~, ~)
			this.direction = 'z';
			this.slicecount = size(this.volume,3);
			this.sld.Value = 1;
			this.sld.Max = this.slicecount;
			this.sld.SliderStep = [1 1]/this.slicecount;
			this.max_text.String = num2str(this.slicecount);
			this.displaySlice(1);
			this.dir_z.Value = 1;
			this.sync_links()
		end

		function sync_links(this)
			global global_syncs;
			if numel(this.linkname) == 0
				return;
			end
			for i = 1:numel(global_syncs)
				if strcmp(this.linkname, global_syncs{i}{1})
					global_syncs{i}{2}(this.slice, this.direction);
				end
			end
		end
		
		function sync(this, slice, direction)
			if ~strcmp(direction, this.direction)
				if strcmp(direction,'x'), this.setDirectionX(); end
				if strcmp(direction,'y'), this.setDirectionY(); end
				if strcmp(direction,'z'), this.setDirectionZ(); end
			end
			this.slice_text.String = ['Slice ' num2str(slice)];
			this.displaySlice(slice);
			this.sld.Value = slice;
		end
		
	end
	
end
