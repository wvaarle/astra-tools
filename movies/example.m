
%% Create test example
Im = phantom(256);

data = zeros(256,256,120);
mkdir('data');
for i = 1:120
	Im2 = imrotate(Im,(i-1)*3,'bilinear','crop');
	imwritesc(Im2,sprintf('data/im_%0.3d.png',i));
	data(:,:,i) = Im2;
end

%% Animated GIF from list of files
files = cell(1,120);
for i = 1:120
	files{i} = sprintf('data/im_%0.3d.png',i);
end
create_animated_gif(Files(files), 'out1.gif', 'pbar','bottomright', 'fps',50);

%% Animated GIF from matrix slices
create_animated_gif(Slices(data,3), 'out2.gif', 'pbar','bottomleft', 'pbar_height',6, 'pbar_width',30, 'fps',50);
