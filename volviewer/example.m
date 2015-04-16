close all

%% Create test example
Im = phantom(256);

data = zeros(256,256,120);
for i = 1:120
	Im2 = imrotate(Im,(i-1)*3,'bilinear','crop');
	data(:,:,i) = Im2;
end

%%
volviewer(data,'linkname','data1');
volviewer(data,'linkname','data1');
volviewer(data,'linkname','data2');
