% Compress a 3D tensor using Tucker thresholding, following
% http://www.ifi.uzh.ch/en/vmml/publications/lossycompression.html
%
% Inputs:
%
% X: the input volume
%
% metric: a string specified how the desired accuracy is expressed
% ("relative error", "rmse" or "psnr")
%
% target: the desired value; see "metric"
%
% Returns:
%
% reco: the approximated tensor (i.e. after compression+decompression)
%
% n_bits: the total storage needed (in bits). Useful to compute the
% compression rate

function [reco,n_bits] = thresholding_compression(X,metric,target)

    % Compute the desired sum of squared errors from the parameter
    if strcmpi(metric,'relative error')
        sse = (target*norm(X(:)))^2;
    elseif strcmpi(metric,'rmse')
        sse = target^2*numel(X);
    elseif strcmpi(metric,'psnr')
        sse = ((max(X(:))-min(X(:))) / (2*(10^(target/20))))^2 * numel(X);
    else
        error('Only the metrics "relative error","rmse" and "psnr" are allowed');
    end

    % Compute the Tucker decomposition of X
    [core,U] = hooi(X,size(X),'dct',1);

    % Obtain the threshold that will give the desired quality
    all_coeffs = sort(abs(core(:)));
    all_squared_sum = cumsum(all_coeffs.^2);
    if sse > all_squared_sum(end) % Too much compression required
        error('Too high compression rate -> empty tensor');
    end
    if sse <= all_squared_sum(1) % No compression -> no one is thresholded
        comparison = 0;
        threshold = 0;
    else
        comparison = find(all_squared_sum > sse);
        threshold = all_coeffs(comparison(1));
    end
%     threshold = all_coeffs(numel(all_coeffs) - round(numel(all_coeffs)*fraction) + 1);
    core_t = core;
    core_t(abs(core_t) < threshold) = 0;
    R = bounding_box(core_t);
    
    % Compute the zigzag indices
    if exist('thresholding/zigzag', 'file') ~= 2
        error('Executable "thresholding/zigzag" not found. Please compile thresholding/zigzag.cpp');
    end
    system(sprintf('thresholding/zigzag %d %d %d',size(X)));
    fid = fopen('indices.raw','r');
    zigzag_indices = fread(fid,numel(X(:)),'int32');
    fclose(fid);
    delete('indices.raw');
    
    % Traverse the core in zigzag, and separate it as set of surviving
    % values + sequence of bits of presence
    core_t = core_t(zigzag_indices);
    presence = (core_t ~= 0);
    core_t(core_t==0) = [];
    
    % Try all quantization possibilities until the error is comparatively small
    for q = 2:64
        [core_t_q, maximum] = log_quantize(core_t(:),q,true);
        core2 = log_dequantize(core_t_q,maximum,q,true);
        sse_q = (sum((core_t(:)-core2(:)).^2));
        if sse_q/sse < 0.05
            break
        end
    end
    fprintf('f = %f, q = %d\n',(numel(X)-comparison(1))/numel(X),q);
    
    % Quantize (and dequantize) the surviving values. The maximum is
    % stored aside
    [core_t_q, maximum] = log_quantize(core_t(:),q,true);
    core2 = log_dequantize(core_t_q,maximum,q,true);
    reinsert = zeros(numel(core(:)),1);
    reinsert(zigzag_indices(find(presence))) = core2;
    core2 = reshape(reinsert,size(core));
    
    % Quantize (and dequantize) factor matrices
    U2 = U;
    for n = 1:3
        U2{n} = U2{n}(:,1:R(n)); % Truncate to bounding box
        [U2_quantized, maximum] = log_quantize(U2{n}(:),q,false);
        U2{n} = reshape(log_dequantize(U2_quantized,maximum,q,false),size(U2{n}));
    end
    
    % Apply RLE+Huffman encoding to the bits of presence
    fid = fopen('mask.raw', 'w');
    fwrite(fid,presence,'ubit1');
    fclose(fid);
    if exist('thresholding/rle_huffman', 'file') ~= 2
        error('Executable "thresholding/rle_huffman" not found. Please compile thresholding/rle_huffman.cpp');
    end
    [~,huffman_bits] = system('thresholding/rle_huffman');
    delete('mask.raw');

    % Reconstruction
    reco = ttm(core2(1:R(1),1:R(2),1:R(3)),U2,[1,2,3],'decompress');
    
    % We have now all the information to compute the total bits
    n_bits = numel(core_t_q(2:end))*q + ... % Core coefficients
        + 64*4 + ... % The core' and matrices' maxima are needed
        + 8 + ... % How many quantization bits are used
        + str2double(huffman_bits) + ... % Bits of presence
        + numel(U2{1})*q + ... % U{1}
        + numel(U2{2})*q + ... % U{2}
        + numel(U2{3})*q; % U{3}
end
