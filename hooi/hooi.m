% Higher-order orthogonal iteration (HOOI) to compute the Tucker
% decomposition of a 3D array with the given ranks
% Reference: "On the best rank-1 and rank-(R1, R2,...,RN ) approximation of
% higher-order tensors" (L. de Lathauwer, B. de Moor, J. Vandewalle)

function [core,U] = hooi(X,R,init,n_iterations)

    N = ndims(X);
    U = cell(N,1);
    
    % Matrix initialization
    for n = 1:N
        if strcmp(init,'random')
            U{n} = randn(size(X,n),R(n));
        elseif strcmp(init,'dct')
            U{n} = dct_matrix(size(X,n),R(n));
        elseif ~strcmp(init,'hosvd')
            error('Initialization method must be "random","dct" or "hosvd"');
        end
    end
    
    % Higher-order orthogonal iteration
    %
    % Initializing with HOSVD is like doing one iteration more,
    % with the difference that in the first one we don't project to get the
    % core
    for it = 1:n_iterations+strcmp(init,'hosvd')
        for n = 1:N
            modes = 1:N;
            modes(n) = [];
            if it == 1 && strcmp(init,'hosvd')
                X_unf = unfold(X,n);
            else
                X_proj = ttm(X,{U{modes(:)}},modes,'compress');
                X_unf = unfold(X_proj,n);
            end
            if R(n) < size(X,n) % A few eigenvectors are sought
                [U{n},~] = eigs(X_unf*X_unf',R(n));
            else % All eigenvectors are sought
                [V,D] = eig(X_unf*X_unf');
                % Eig returns unsorted eigenvectors, we have to sort them
                [~,indices] = sort(diag(D));
                U{n} = V(:, indices(end:-1:1));
            end
        end
    end
    if n_iterations == 0
        core = ttm(X,U,1:N,'compress');
    else
        core = ttm(X_proj,{U{N}},N,'compress');
    end
end
