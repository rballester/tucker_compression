// This code is a modification of https://rosettacode.org/wiki/Huffman_coding (released under the GNU Free Documentation License 1.2, http://www.gnu.org/licenses/fdl-1.2.html), which is a Huffman encoding implementation for C++. This version does a run-length encoding first, in order to efficiently compress a bit-stream.

#include <iostream>
#include <fstream>
#include <queue>
#include <map>
#include <climits>		// for CHAR_BIT
#include <iterator>
#include <algorithm>

using namespace std;

typedef
 std::vector < bool > HuffCode;
typedef
 std::map < int, HuffCode > HuffCodeMap;

class INode {
  public:
    const int
     f;

    virtual ~ INode() {
    }

  protected:
    INode(int f):f(f) {
    }
};

class InternalNode:
public INode {
  public:
    INode * const
     left;
    INode *const
     right;

  InternalNode(INode * c0, INode * c1):
    INode(c0->f + c1->f), left(c0), right(c1) {
    }
    ~InternalNode() {
	delete left;
	delete right;
    }
};

class LeafNode:
public INode {
  public:
    const int
     c;

    LeafNode(int f, int c):INode(f), c(c) {
    }
};

struct NodeCmp {
    bool operator () (const INode * lhs, const INode * rhs) const {
	return lhs->f > rhs->f;
}};

INode *BuildTree(std::map < int, int >&frequencies)
{
    std::priority_queue < INode *, std::vector < INode * >,
	NodeCmp > trees;

    for (std::map < int, int >::iterator it = frequencies.begin();
	 it != frequencies.end(); ++it) {
	trees.push(new LeafNode(it->second, (int) it->first));
    }
    while (trees.size() > 1) {
	INode *childR = trees.top();
	trees.pop();

	INode *childL = trees.top();
	trees.pop();

	INode *parent = new InternalNode(childR, childL);
	trees.push(parent);
    }
    return trees.top();
}

void
GenerateCodes(const INode * node, const HuffCode & prefix,
	      HuffCodeMap & outCodes)
{
    if (const LeafNode * lf = dynamic_cast < const LeafNode * >(node)) {
	outCodes[lf->c] = prefix;
    } else if (const InternalNode * in =
	       dynamic_cast < const InternalNode * >(node)) {
	HuffCode leftPrefix = prefix;
	leftPrefix.push_back(false);
	GenerateCodes(in->left, leftPrefix, outCodes);

	HuffCode rightPrefix = prefix;
	rightPrefix.push_back(true);
	GenerateCodes(in->right, rightPrefix, outCodes);
    }
}

int main()
{

    std::vector < char > contents;
    int fileSize;
    ifstream in;
    in.open("mask.raw", ios::in | ios::binary);

    if (in.is_open()) {
	// get the starting position
	streampos start = in.tellg();

	// go to the end
	in.seekg(0, std::ios::end);

	// get the ending position
	streampos end = in.tellg();

	// go back to the start
	in.seekg(0, std::ios::beg);

	// create a vector to hold the data that
	// is resized to the total size of the file

	fileSize = end - start;

	contents.resize(static_cast < size_t > (end - start));

	// read it in
	in.read(&contents[0], contents.size());
	in.close();
    } else {
	cerr << "Bad file access" << endl;
	exit(1);
    }
    char last_bit = 0;
    int counter = 0;
    vector < int > counters;
    for (int i = 0; i < contents.size(); ++i) {
	char c = contents[i];
	for (int j = 0; j < 8; ++j) {
	    char bit = ((c & (1 << j)) != 0);
	    if (bit == last_bit) {
		counter++;
	    } else {
		counters.push_back(counter + 1);
		counter = 0;
		last_bit = bit;
	    }
	}
    }

    int max_range = 0;
    for (int i = 0; i < counters.size(); ++i) {
	if (counters[i] > max_range) {
	    max_range = counters[i];
	}
    }

    std::map < int, int > frequencies;
    for (int i = 0; i < counters.size(); ++i) {
	++frequencies[counters[i]];
    }
    INode *root = BuildTree(frequencies);

    HuffCodeMap codes;
    GenerateCodes(root, HuffCode(), codes);
    delete root;

    // Compute the final size (in bits)
    int finalSize = 0;
    for (HuffCodeMap::const_iterator it = codes.begin(); it != codes.end();
	 ++it) {
	int key = (int) (it->first);
	int cost = it->second.end() - it->second.begin();
	finalSize += cost * frequencies[key];
    }
    std::cout << finalSize << std::endl;

}
