% Compute the TTM (tensor-times-matrix) between a tensor and a sequence of
% factors
%
% X: the input tensor with N dimensions
%
% U: a cell containing 1 or more matrices. If direction is "compress",
% the number of rows of U{i} must be equal to the i-th size of X.
% If "decompress", then the number of columns must be equal. Either way, 
% the factors must have at least as many rows as columns
%
% modes: list of dimensions to project on
%
% direction: whether to "compress" or "decompress" the tensor. The former
% transposes the factor matrices; the latter does not.

function X_proj = ttm(X,U,modes,direction)
    N = ndims(X);
    X_proj = X;
    for i = 1:numel(modes)
        X_unf = unfold(X_proj,modes(i));
        if strcmp(direction,'compress')
            X_mult = U{i}'*X_unf;
        elseif strcmp(direction,'decompress')
            X_mult = U{i}*X_unf;
        else
            error('TTM direction must be either "compress" or "uncompress"');
        end
        indices = 1:N;
        indices(modes(i)) = [];
        sizes = size(X_proj);
        X_mult = reshape(X_mult,[size(X_mult,1),sizes(indices)]);
        X_proj = permute(X_mult,[2:modes(i),1,modes(i)+1:N]);
    end
end