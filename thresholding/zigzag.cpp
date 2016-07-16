#include <iostream>
#include <cstring>
#include <cmath>
#include <cstdio>
#include <fstream>
#include <fstream>
#include <algorithm>

using namespace std;

int main(int argc, char* argv[])
{
	if (argc != 4) {
		std::cerr << "3 arguments needed: R(1), R(2) and R(3)" << std::endl;
		exit(1);
	}
	
	int R1 = atoi(argv[1]);
	int R2 = atoi(argv[2]);
	int R3 = atoi(argv[3]);

	int* result = new int[R1*R2*R3];
    	int horizontal_direction = 1;
    	int counter = 0;
    	int level = 1;

    	while (true) {
        	int desired_sum = level + 2;
        	int vertical_direction = 1;
		int fiber_start, fiber_end;
        	if (horizontal_direction == 1) {
            		fiber_start = 1;
            		fiber_end = 2*level - 1;
        	}
		else {
            		fiber_start = 2*level - 1;
            		fiber_end = 1;
        	}

		for (int fiber = fiber_start; fiber*horizontal_direction <= fiber_end*horizontal_direction; fiber += horizontal_direction) {

            		int fiber_size = level;
			int i, j;
            		if (vertical_direction == 1) {
                		i = level - floor(fiber/2.0);
                		j = desired_sum - i - 1;
           		}
			else {
               			if (fiber <= level) {
                    			i = level - fiber + 1;
                    			j = 1;
				}
                		else {
                    			i = 1;
                    			j = fiber - level + 1;
                		}
            		}

            		for (int element = 1; element <= fiber_size; ++element) {
                		int k = desired_sum - i - j;
		        	if (i >= 1 && i <= R1 && j >= 1 && j <= R2 && k >= 1 && k <= R3) {
		            		result[counter] = (k-1)*R1*R2 + (j-1)*R1 + (i-1) + 1;
		            		counter++;
		            		if (i == R1 && j == R2 && k == R3) {
						ofstream output("indices.raw",ios::out | ios::binary);
						output.write((char*)result,R1*R2*R3*sizeof(int));
						output.close();
		                		exit(0);
					}
		            	}

                		i = i - vertical_direction;
                		j = j - vertical_direction;
                	}
            		vertical_direction = -vertical_direction;
            	}
        	horizontal_direction = -horizontal_direction;
        	level++;
        }
}
