% Compute the unfolding (matricization) of a tensor along a specified mode.

function X_unf = unfold(X,mode)
    N = ndims(X);
    modes = 1:N;
    modes(mode) = [];
    X_unf = reshape(permute(X,[mode,modes]),[size(X,mode),numel(X(:))/size(X,mode)]);
end