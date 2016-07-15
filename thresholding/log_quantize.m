% Quantizes the elements of an input vector X. Each element uses 9 bits:
% 1 for the sign, the rest for quantizing (logarithmically) its absolute 
% value. Optionally, the maximum value ("hot corner") is stored aside.
% This strategy was first used in "Interactive Multiscale Tensor Reconstruction for
% Multiresolution Volume Visualization" (S. Suter et al.). They used 9 bits
%
% bits: how many bits to quantize into. The sign bit is included
%
% assume_hot_corner: whether we can assume there's a very large coefficient
% at the beginning (Tucker core) or not (factor matrices)

function [X_quantized, maximum] = log_quantize(X,quantization_bits,assume_hot_corner)
    
    X_quantized = zeros(size(X));
    start = 1;
    if assume_hot_corner
        X_quantized(1) = X(1); % We assume the hot corner lies untouched in the first position
        start = 2;
    end
    signs = sign(X);
    X_quantized(start:end) = log2(1 + abs(X(start:end)));
    X_quantized(start:end) = (2^(quantization_bits-1)-1)*X_quantized(start:end);
    maximum = log2(1 + max(abs(X(start:end)))); % Normalization factor
    if maximum > 0
        X_quantized(start:end) = round(X_quantized(start:end)./maximum);
        X_quantized(start:end) = X_quantized(start:end).*signs(start:end);
    else
        X_quantized(start:end) = 0;
    end

end