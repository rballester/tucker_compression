% Given a cube tensor X, returns a vector containing the indices resulting 
% from visiting all its elements sequentially, following a 3D zigzag 
% pattern that develops from a corner in the fashion of a 3D
% generalization of the JPEG zigzag scheme for quantization 
% (http://en.wikipedia.org/wiki/JPEG#Entropy_coding)

function result = zigzag(R)

    result = zeros(prod(R),1);
    horizontal_direction = 1;
    counter = 1;
        
    level = 1;
    while 1
        desired_sum = level + 2;
        vertical_direction = 1;

        if horizontal_direction == 1
            fiber_start = 1;
            fiber_end = 2*level - 1;
        else
            fiber_start = 2*level - 1;
            fiber_end = 1;
        end

        for fiber = fiber_start:horizontal_direction:fiber_end

            fiber_size = level;

            if vertical_direction == 1
                i = level - floor(fiber/2);
                j = desired_sum - i - 1;
            else
                if fiber <= level
                    i = level - fiber + 1;
                    j = 1;
                else
                    i = 1;
                    j = fiber - level + 1;
                end
            end

            for element = 1:fiber_size
                k = desired_sum - i - j;

                if i >= 1 && i <= R(1) && j >= 1 && j <= R(2) && k >= 1 && k <= R(3)
                    result(counter) = (k-1)*R(1)*R(2) + (j-1)*R(1) + (i-1) + 1;
                    counter = counter+1;
                    if i == R(1) && j == R(2) && k == R(3)
                        return;
                    end
                end

                i = i - vertical_direction;
                j = j - vertical_direction;
            end

            vertical_direction = -vertical_direction;
        end

        horizontal_direction = -horizontal_direction;
        level = level+1;
    end
    
end