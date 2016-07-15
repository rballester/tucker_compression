% Dequantizes the vector X_quantized. See log_quantize.m

function X = log_dequantize(X_quantized,maximum,quantization_bits,use_hot_corner)

    X = zeros(size(X_quantized));
    start = 1;
    if use_hot_corner
        start = 2;
        X(1) = X_quantized(1); % We assume the hot corner lies untouched in the first position
    end
    
    signs = sign(X_quantized);
    X(start:end) = X_quantized(start:end)./(2^(quantization_bits-1)-1);
    X(start:end) = X(start:end).*maximum;
    X(start:end) = 2.^abs(X(start:end))-1;
    X(start:end) = X(start:end).*signs(start:end);
end