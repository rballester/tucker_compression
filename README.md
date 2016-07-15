# Tucker Volume Compression

This is a MATLAB implementation of the thresholding compression method described in the paper [*Lossy Volume Compression Using Tucker Truncation and Thresholding*](http://www.ifi.uzh.ch/en/vmml/publications/lossycompression.html). For more details on the Tucker transform and tensor-based volume compression, check out my [slides](http://www.ifi.uzh.ch/dam/jcr:00000000-73a0-83b8-ffff-ffffd48b8a42/tensorapproximation.pdf).

## Usage

The core function is ```thresholding_compression(X,fraction,quantization_bits)```, where:

- ```X``` is a volume 
- 0 < ```fraction``` <= 1 determines what fraction of elements should survive the thresholding step
- 2 <= ```quantization_bits``` determines the number of quantization bins (suggested standard value: 9)

Try out the code with the example script ```run.m```:

1. Download the [bonsai data set](http://www.tc18.org/code_data_set/3D_greyscale/bonsai.raw.gz) (16MB, 8-bit unsigned int) and unpack it as ```bonsai.raw``` into the project folder.
1. Compile the C++ file ```rle_huffman.cpp``` into an executable called ```rle_huffman```.
2. In the MATLAB interpreter, go to the folder and call ```run```.

For example, ```fraction=0.025```, ```quantization_bins=9``` yields below 2.4 RMSE and 1:21 compression rate (left image is a slice from the original, right one from the reconstructed): 

<img src="https://github.com/rballester/tucker_compression/blob/master/images/original_vs_reconstructed.jpg" width="512">

You are free to **use and modify** the code. If you use it for a publication, **please cite the paper**:

```@article{BP:15, year={2015}, issn={0178-2789}, journal={The Visual Computer}, title={Lossy volume compression using {T}ucker truncation and thresholding}, publisher={Springer Berlin Heidelberg}, keywords={Tensor approximation; Data compression; Higher-order decompositions; Tensor rank reduction; Multidimensional data encoding}, author={Ballester-Ripoll, Rafael and Pajarola, Renato}, pages={1-14}}```

## How it Works

Our tresholding algorithm exploits the fact that the largest coefficients of the Tucker core tend to concentrate around one spot (the **hot corner**), that usually encodes the lowest-frequency components. Example:

<img src="https://github.com/rballester/tucker_compression/blob/master/images/hot_corner.jpg" width="256">

The algorithm runs these steps sequentially:

1. Compute the **Tucker decomposition** of a volume of size I1 * I2 * I3 into a core of size I1 * I2 * I3 and 3 factor matrices.
2. **Threshold** the core.
3. Traverse the result in a **3D zig-zag** fashion, starting from the hot corner (where most coefficients survive the thresholding).
4. Encode the result as a set of **remaining values** + a set of I1 * I2 * I3 **bits of presence** (indicating whether each core value survived the threshold or not).
5. **Quantize logarithmically** the remaining values. Quantize also the Tucker factor matrices.
6. Compress the stream of bits-of-presence using **run-length** encoding, followed by **Huffman encoding**.