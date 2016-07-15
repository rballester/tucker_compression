% Example: we will compress a bonsai CT volume
% (available at http://www.tc18.org/code_data_set/3D_greyscale/bonsai.raw.gz),
% from the repository http://www.tc18.org/code_data_set/3D_images.html

addpath(genpath('.'));

% Parameters
filename = 'bonsai.raw';
precision = 'uint8';
I = [256,256,256]; % Size of the tensor

% Read the volume into X
fid = fopen(filename);
if (fid == -1)
   error('Could not open "%s"', filename);   
end
X = reshape(fread(fid, prod(I),sprintf('*%s',precision)),I);
original_bits = getfield(whos('X'),'bytes')*8; % Count the input's number of bits
fclose(fid);

% Compress and decompress X
X = double(X); % We need doubles for the compression algorithm
fprintf('Compressing...\n');
tic;
[reco,n_bits] = thresholding_compression(X,0.025,9);
toc
fprintf('Compression rate: 1:%f\n',original_bits/n_bits);
fprintf('Relative error: %f\n',norm(X(:)-reco(:))/norm(X(:)));
fprintf('RMSE: %f\n',sqrt(sum((X(:)-reco(:)).^2)/prod(I)));

% Show a slice of the original tensor, together with the
% reconstruction and the absolute error
slice1 = X(:,:,round(I(3)/2));
slice2 = reco(:,:,round(I(3)/2));
imshow([slice1 slice2 max(X(:))-abs(slice1-slice2)],[min(X(:)),max(X(:))]);
