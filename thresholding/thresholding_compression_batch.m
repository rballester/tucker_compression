% Compress a 3D tensor using Tucker thresholding, following
% http://www.ifi.uzh.ch/en/vmml/publications/lossycompression.html
%
% In this version (cf. thresholding_compression.m), fraction and
% quantization_bits can be 1D arrays. If they have size F and Q
% respectively, then the function returns two matrices of size FxQ, rmse
% and bpv, each containing the RMSE and bits per value for each parameter
% combination respectively.

function [rmse,bpv] = thresholding_compression(X,fraction,quantization_bits)

    % Getting ready (1): compute the Tucker decomposition of X
    [core,U] = hooi(X,size(X),'dct',2);

    % Getting ready (2): compute the zigzag indices
    system(sprintf('thresholding/zigzag %d %d %d',size(X)));
    fid = fopen('indices.raw','r');
    zigzag_indices = fread(fid,numel(X(:)),'int32');
    fclose(fid);
    delete('indices.raw');
    
    rmse = zeros(numel(fraction),numel(quantization_bits));
    bpv = zeros(numel(fraction),numel(quantization_bits));
    
    for i = 1:numel(fraction)
        for j = 1:numel(quantization_bits);
            f = fraction(i);
            q = quantization_bits(j);
            fprintf('Experiment with f=%f, q=%d\n',f,q);
            
            assert (0 < f && f <= 1);
            assert (2 <= q);

            % Threshold the core
            all_coeffs = sort(abs(core(:)));
            threshold = all_coeffs(numel(all_coeffs) - round(numel(all_coeffs)*f) + 1);
            core_t = core;
            core_t(abs(core_t) < threshold) = 0;
            R = bounding_box(core_t);

            % Traverse the core in zigzag, and separate it as set of surviving
            % values + sequence of bits of presence
            core_t = core_t(zigzag_indices);
            presence = (core_t ~= 0);
            core_t(core_t==0) = [];

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
                error('Executable "thresholding/rle_huffman" not found. Compile rle_huffman.cpp');
            end
            [~,huffman_bits] = system('thresholding/rle_huffman');
            delete('mask.raw');

            % Reconstruction
            reco = ttm(core2(1:R(1),1:R(2),1:R(3)),U2,[1,2,3],'decompress');
            rmse(i,j) = sqrt(sum((X(:)-reco(:)).^2)/numel(X(:)));
            
            % We have now all the information to compute the total bits
            bpv(i,j) = numel(core_t_q)*q + ... % Core
                + str2double(huffman_bits) + ... % Bits of presence
                + numel(U2{1})*q + ... % U{1}
                + numel(U2{2})*q + ... % U{2}
                + numel(U2{3})*q; % U{3}
            
        end
    end
end