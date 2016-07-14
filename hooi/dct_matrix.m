% Create a matrix containing DCT frequencies arranged as columns, 
% starting from the lowest on the left

function U = dct_matrix(rows,cols)
    U = zeros(rows,cols);
    for i = 1:rows
        for j = 1:cols
            if j == 1
                U(i,j)=sqrt(1/rows)*cos((2*(i-1)+1)*(j-1)*pi/(2*rows));
            else
                U(i,j)=sqrt(2/rows)*cos((2*(i-1)+1)*(j-1)*pi/(2*rows));
            end
        end
    end
end
