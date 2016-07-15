% Compress a 3D tensor using Tucker thresholding, following
% http://www.ifi.uzh.ch/en/vmml/publications/lossycompression.html
%
% Inputs:
%
% X: the input volume
%
% fraction: the proportion of core coefficients that should survive the
% thresholding
%
% quantization_bits: how many bits to quantize to (suggested: 9)
%
% Returns:
%
% reco: the approximated tensor (i.e. after compression+decompression)
%
% n_bits: the total storage needed (in bits). Useful to compute the
% compression rate

function [reco,n_bits] = thresholding_compression(X,fraction,quantization_bits)

    assert (0 < fraction && fraction <= 1);
    assert (2 <= quantization_bits);

    % Compute the Tucker decomposition of X
    [core,U] = hooi(X,size(X),'hosvd',2);
    
    all_coeffs = sort(abs(core(:)));
    threshold = all_coeffs(numel(all_coeffs) - round(numel(all_coeffs)*fraction) + 1);
    core_t = core;
    core_t(abs(core_t) < threshold) = 0;
    R = bounding_box(core_t);
    
    % Traverse the core in zigzag, and separate it as set of surviving
    % values + sequence of bits of presence
    zigzag_indices = zigzag(size(X));
    core_t = core_t(zigzag_indices);
    presence = (core_t ~= 0);
    core_t(core_t==0) = [];
    
    % Quantize (and dequantize) the surviving values. The maximum is
    % stored aside
    [core_t_q, maximum] = log_quantize(core_t(:),quantization_bits,true);
    core2 = log_dequantize(core_t_q,maximum,quantization_bits,true);
    reinsert = zeros(numel(core(:)),1);
    reinsert(zigzag_indices(find(presence))) = core2;
    core2 = reshape(reinsert,size(core));
    
    % Quantize (and dequantize) factor matrices
    for i = 1:3
        U{i} = U{i}(:,1:R(i)); % Truncate to bounding box
        [U_quantized, maximum] = log_quantize(U{i}(:),quantization_bits,false);
        U{i} = reshape(log_dequantize(U_quantized,maximum,quantization_bits,false),size(U{i}));
    end
    
    % Apply RLE+Huffman encoding to the bits of presence
    fid = fopen('mask.raw', 'w');
    fwrite(fid,presence,'ubit1');
    fclose(fid);
    if exist('thresholding/rle_huffman', 'file') ~= 2
        error('Executable "thresholding/rle_huffman" not found. Compile rle_huffman.cpp');
    end
    [~,huffman_bits] = system('thresholding/rle_huffman');
    delete('mask.raw');
    
    % Reconstruction
    reco = ttm(core2(1:R(1),1:R(2),1:R(3)),U,[1,2,3],'decompress');
    
    % We have now all the information to compute the total bits
    n_bits = numel(core_t_q)*quantization_bits + ... % Core
        + str2double(huffman_bits) + ... % Bits of presence
        + numel(U{1})*quantization_bits + ... % U{1}
        + numel(U{2})*quantization_bits + ... % U{2}
        + numel(U{3})*quantization_bits; % U{3}
    
end