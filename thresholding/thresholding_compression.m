% Compress a 3D tensor using Tucker thresholding, following
% http://www.ifi.uzh.ch/en/vmml/publications/lossycompression.html
%
% Returns:
%
% reco: the approximated tensor (i.e. after compression+decompression)
%
% n_bits: the total storage needed (in bits). Useful to compute the
% compression rate

function [reco,n_bits] = thresholding_compression(X,fraction)

    % Compute the Tucker decomposition of X
    [core,U] = hooi(X,size(X),'hosvd',2);
    
    all_coeffs = sort(abs(core(:)));
    threshold = all_coeffs(numel(all_coeffs) - round(numel(all_coeffs)*fraction));
    core_t = core;
    core_t(abs(core_t) < threshold) = 0;
    R = bounding_box(core_t);
    
    % Traverse the core in zigzag, and separate it as set of surviving
    % values + sequence of bits of presence
    zigzag_indices = zigzag(size(X));
    core_t = core_t(zigzag_indices);
    mask = (core_t ~= 0);
    core_t(core_t==0) = [];
    
    % Quantize (and reconstruct) the surviving values. The maximum is
    % stored aside
    [core_t_q, maximum] = log_quantize(core_t(:),true);
    core2 = log_dequantize(core_t_q,maximum,true);
    reinsert = zeros(numel(core(:)),1);
    reinsert(zigzag_indices(find(mask))) = core2;
    core2 = reshape(reinsert,size(core));
    
    % Quantize (and reconstruct) factor matrices
    for i = 1:3
        U{i} = U{i}(:,1:R(i));
        [U_quantized, maximum] = log_quantize(U{i}(:),false);
        U{i} = reshape(log_dequantize(U_quantized,maximum,false),size(U{i}));
    end
    
    % Apply RLE+Huffman encoding to the bits of presence
    fid = fopen('mask.raw', 'w');
    fwrite(fid,mask,'ubit1');
    fclose(fid);
    [~,huffman_bits] = system('./rle_huffman');
    % We have now all the information to compute the total bits
    n_bits = numel(core_t_q)*9 + ... % Core
        + str2double(huffman_bits) + ... % Bits of presence
        + numel(U{1})*9 + ... % U{1}
        + numel(U{2})*9 + ... % U{2}
        + numel(U{3})*9; % U{3}
    reco = ttm(core2(1:R(1),1:R(2),1:R(3)),U,[1,2,3],'decompress');
end