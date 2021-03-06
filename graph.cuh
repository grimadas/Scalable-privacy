<<<<<<< HEAD
/*

*/


/************************************************
* 												*
*  CUDA graph representation					*
*  author: Bulat 								*
*  graph.h 										*
*************************************************
*		la - look ahed parametr
*		L - opacity threshold (1, 2) - small value
=======
/************************************************
*
*  CUDA graph representation
*  author: Bulat Nasrulin
*  graph.h
*************************************************
*		la - look ahead parametr
*		L (L_VALUE) - opacity threshold (1, 2) - small value
>>>>>>> Save_Thrust
*		num_vertex - number of vetexes in a graph
*		n(n-1)/2 combinations pairs
*		2 variants : edge removal and remove (adding)
*		T - types calc distance to
*		0) Reading initial graph
*			a) In Edge format
*			b) Convert to Adj list (CSR)
*		1) Distance Matrix calculation
*		 - How to store ?
*		  * n arrays for different level opacity
*		  * special CSR format with different levels - 2 1D flatten matrix, since we know L and num_vertex
*			Example:
*				L1			L2 (same structure)
*				| 1| 2| 4|
<<<<<<< HEAD
*				| | | | | | |  Memory: O(L*|V| + L* 2*|E|) (what about dublication? ) two choices
=======
*				| | | | | | |  Memory: O(L*|V| + L* 2*|E|) (what about duplication? ) two choices
>>>>>>> Save_Thrust
*		  * COO format (same situation ?)
*							   Memory: O(2*|E|)

*/

<<<<<<< HEAD

#ifndef graph_h
#define graph_h

// STL includes
#include <stdio.h>
#include <ctime>
#include <iostream>
#include <fstream>
#include <vector>
#include <time.h>
// Thrust includes
#include <thrust/version.h>
#include <thrust/host_vector.h>
#include <thrust/device_vector.h>
#include <thrust/find.h>
#include <thrust/count.h>
#include <thrust/reduce.h>
#include <thrust/merge.h>
#include <thrust/sequence.h>
#include <thrust\sort.h>
#include <thrust/unique.h>
#include <thrust/execution_policy.h>
#include <thrust\iterator\counting_iterator.h>
#include <thrust\iterator\permutation_iterator.h>
#include <thrust\binary_search.h>



using namespace std;

int a = 0;



class Graph
{

#define vertex  unsigned int
#define edge  unsigned int

#define domain vertex*
#define field  vertex

#define opacity double


	int L_VALUE = 2;
public:

	// CSR with levels graph format
	// Distance matrix in a nuttshell
	thrust::device_vector<vertex> full_vertex_array;
	thrust::device_vector<vertex> full_edge_array;

	// Current
	thrust::device_vector<vertex>::iterator vertex_current_end;
	int current_end;

	// COO graph format (coordinate list)
	thrust::device_vector<vertex> from_array;
	thrust::device_vector<vertex> to_array;
	// Distance oracle
	// ?
	// Additional arrays
	thrust::device_vector<field> vertex_degrees;
	thrust::device_vector<field> degree_count;
	field max_degree;

	thrust::device_vector<opacity> opacity_matrix;

	unsigned int number_of_vertex;
	unsigned int number_of_edges;

	/** ** ** **
	*		Read graph in Edge list format (COO)
	*		input:
	*					string file_name
	*/
	void read_COO_format(string file_name)
	{
		ifstream myfile;
		myfile.open(file_name);
		myfile >> number_of_vertex >> number_of_edges;
		printf("%d %d \n", number_of_vertex, number_of_edges);
		// reserve maximum value needed
		from_array.reserve(number_of_edges);
		to_array.reserve(number_of_vertex);
		// Read a pair of vertex - vertex forming an edge
		int a, b;
		while (myfile >> a >> b)
		{
			from_array.push_back(a);
			to_array.push_back(b);
		}
		// Reading from file
		myfile.close();
	}

	/**
	*	Print full graph CSR format
	*
	*/
	void print_csr_graph()
	{
		cout << "Vertex degrees ";
		for (auto iter : vertex_degrees)
		{
			cout << "  " << iter;
		}
		cout << endl;

		cout << "Degree count ";
		for (auto iter : degree_count)
		{
			cout << "  " << iter;
		}
		cout << endl;

		cout << "Vertex offset: ";
		for (auto iter : full_vertex_array)
		{
			cout << "  " << iter;
		}
		cout << endl;

		cout << "Connected Edges ";
		for (auto iter : full_edge_array)
		{
			cout << "  " << iter;
		}
		cout << endl;
	}

	/**
	*	Print opacity matrix
	*/
	void print_opacity_matrix()
	{
		cout<< endl  << "Opacity : " << endl;
		for (auto i = 0; i < max_degree; i++)
		{
			for (auto j = 0; j < max_degree; j++)
				cout <<" " << opacity_matrix[max_degree*i + j];
				//	printf(" %f",  opacity_matrix[max_degree*i + j]);
			cout << endl;
		}
		cout << endl;
	}


	/**
	*	Print graph in (one layer, initial state) COO format (edge list)
	*
	*/
	void print_coo_graph()
	{
		cout << "From ";
		for (auto iter : from_array)
		{
			cout << "  " << iter;
		}
		cout << endl;
		cout << "To   ";
		for (auto iter : to_array)
		{
			cout << "  " << iter;
		}
		cout << endl;


	}

	/**
	* 	Reading test graph presented in the paper "L-opacity"
	*/
	void init_test_graph()
	{
		// COO format
		read_COO_format("graph.txt");

	}
	// ----------------------------------------------------------------
	/**
	*	 Converter functor,
	*	 INPUT:
	*				_a - from_array
	*				_b - to_array
	*				_size - number_of_edges
	*/
	struct coo_to_csr_converter
	{
		__host__ __device__
		coo_to_csr_converter(domain _a, domain _b, int _size) : a(_a), b(_b), size(_size){}

		__host__ __device__
			field operator()(field x)
		{

				if (x < size)
				{
					return b[x];
				}
				else
				{
					return a[x - size];
				}


			}

		domain a;
		domain b;
		int size;
	};


	void init_arrays()
	{

	//	full_edge_array.reserve(2 * L_VALUE * number_of_edges);
	//	full_vertex_array.reserve(L_VALUE*number_of_vertex);

		thrust::device_vector<vertex> temp_indx(2 * L_VALUE* number_of_edges);
		// Init edge vector
		thrust::fill(temp_indx.begin(), temp_indx.end(), 0);
		full_edge_array = temp_indx;
		// Init vertex vector
		temp_indx.resize(L_VALUE*number_of_vertex);
		temp_indx.shrink_to_fit();
		full_vertex_array = temp_indx;
		// Init degree vector
		temp_indx.resize(number_of_vertex);
		temp_indx.shrink_to_fit();
		vertex_degrees = temp_indx;
		degree_count = temp_indx;

		// Init opacity matrix
		thrust::device_vector<opacity> tempr_indx(number_of_vertex*(number_of_vertex));
	    thrust::fill(tempr_indx.begin(), tempr_indx.end(), 0.0);
		opacity_matrix = tempr_indx;


		temp_indx.clear();
		temp_indx.shrink_to_fit();
//
//		tempr_indx.clear();
//		tempr_indx.shrink_to_fit();

		current_end = 2 * number_of_edges;




	}

	/***
	*  Converting from COO (edge list) format to CSR (adjaceny list) format
	*  Run it after something is in COO list (from and to).
	*/
	void convert_to_CSR()
=======
#ifndef GRAPH_USED
#define GRAPH_USED



#include "headers.h"
#include "functors.cuh"
#include "kernels.cuh"



class Graph {

public:

// CSR with levels graph format
device_ptr<vertex> full_vertex_array;
device_ptr<vertex> full_edge_array;

int L_VALUE;
float threshold;

	// COO graph format (coordinate list)
domain from_array_host;
domain to_array_host;
domain from_to_host_matrix;
// Copy of arrays in the device
device_ptr<vertex> from_array;
device_ptr<vertex> to_array;
device_ptr<int> opacity_index;
int size_from_to;

device_ptr<int> remove_count;
device_ptr<int> removing_opacity_index;
int size_check;

// Additional arrays
device_ptr<int> initial_vertex_degrees;
device_ptr<int> real_vertex_degrees;
device_ptr<int> degree_count;
field max_degree;

device_ptr<opacity> opacity_matrix;
device_ptr<opacity> lessL_matrix;

int number_of_vertex;
int number_of_edges;

bool directed;

	int* num_edges()
	{
		return &number_of_edges;
	}

	/**********************************************
	*		Read graph in Edge list format (COO)
	*		input:
	*					string file_name
	***********************************************/
	void read_COO_format(const char* file_name)
	{

			std::ifstream myfile;
			myfile.open(file_name);
			myfile >> number_of_vertex >> number_of_edges;
		//	number_of_edges = 0;
			// reserve maximum value needed
			from_to_host_matrix = new vertex[number_of_vertex * number_of_vertex];
			fill(from_to_host_matrix, from_to_host_matrix + number_of_vertex*number_of_vertex, 0);
			// Read a pair of vertex - vertex forming an edge
			int a, b;
			number_of_edges = 0;
			while (myfile >> a >> b)
			{
				from_to_host_matrix[number_of_vertex*min(a,b) + max(a,b)] = 1;
				number_of_edges++;
			}
			from_array_host = new vertex[number_of_edges];
			to_array_host = new vertex[number_of_edges];
			number_of_edges = 0;
			for(int i =0; i< number_of_vertex; i++)
			{
				for(int j = i+1; j< number_of_vertex; j++)
				{
					if (from_to_host_matrix[i*number_of_vertex + j] == 1)
					{
						from_array_host[number_of_edges] = i;
						to_array_host[number_of_edges] = j;
						number_of_edges++;
					}
				}
			}
			// Reading from file
			delete from_to_host_matrix;
			if (debug)
				printf("Graph parametrs %d %d \n", number_of_vertex, number_of_edges);

			myfile.close();
	}

	/**********************************
	*	Print full graph CSR format
	* Require:
	*					initial_vertex_degrees != NULL
	*					full_vertex_array != NULL
	*					after_array_init
	************************************/
	void print_csr_graph()
	{
		std::cout << "\n Vertex degrees :";
		domain a = new vertex[number_of_vertex];
		copy(initial_vertex_degrees, initial_vertex_degrees + number_of_vertex, a);
		for(int i=0; i < number_of_vertex; i++)
		{
			 std::cout << a[i] << " ";
		}

		std::cout << "\n Real vertex degree :";
		copy(real_vertex_degrees, real_vertex_degrees + number_of_vertex, a);
		for(int i=0; i < number_of_vertex; i++)
		{
			 std::cout << a[i] << " ";
		}

		std::cout << "\n Degree count :";
		domain b= new vertex[max_degree];
		copy(degree_count, degree_count + max_degree, b);
		for(int i=0; i < max_degree; i++)
		{
			 std::cout << b[i] << " ";
		}

		std::cout << "\n Vertex offset: ";
		domain c = new vertex[L_VALUE* number_of_vertex];
		copy(full_vertex_array, full_vertex_array +  L_VALUE*number_of_vertex, c);
		for(int i=0; i < L_VALUE*number_of_vertex; i++)
		{
			 std::cout << c[i] << " ";
		}

		std::cout << "\n Connected Edges ";
		int size_to_print = full_vertex_array[L_VALUE*number_of_vertex - 1];
		domain d = new vertex[size_to_print];
		copy(full_edge_array, full_edge_array + size_to_print, d);
		for(int i=0; i < size_to_print; i++)
		{
			 std::cout << d[i] << " ";
		}
		delete a,b,c,d;
	}

	/**********************************************
	*	Print opacity matrix ON_HOST
	*	Require:
	*						opacity_matrix != NULL
	*
	***********************************************/
	void print_opacity_matrix()
	{
		printf("\n Opacity : \n");
		opacity* a = new opacity[max_degree * max_degree];
		copy(opacity_matrix, opacity_matrix + max_degree*max_degree, a);
		for (int i = 0; i< max_degree; i++)
		{
			for (int j = 0; j< max_degree; j++)
			{
				std::cout << a[i*max_degree + j] << " ";
			}
			std::cout << std::endl;
		}
		printf("\n Number of edges less L : \n");
		copy(lessL_matrix, lessL_matrix + max_degree*max_degree, a);
		for (int i = 0; i< max_degree; i++)
		{
			for (int j = 0; j< max_degree; j++)
			{
				std::cout << a[i*max_degree + j] << " ";
			}
			std::cout << std::endl;
		}

		delete a;
	}


	/********************************************
	*	Print graph in (one layer, initial state)
	* COO format (edge list) ON_HOST
	*
	*********************************************/
	void print_coo_graph()
	{
		int total_size = number_of_edges;
		std::cout << "EDGES " << number_of_edges;
		std::cout << " From: \n";
		domain a = new vertex[total_size];
		copy(from_array, from_array + total_size, a);
		for(int i=0; i < total_size; i++)
		{
			 std::cout << a[i] << " ";
		}

		std::cout << "\n To: \n";
		domain b= new vertex[total_size];
		copy(to_array, to_array + total_size, b);
		for(int i=0; i < total_size; i++)
		{
			 std::cout << b[i] << " ";
		}
		std::cout << std::endl << " Opacity index: \n";
		copy(opacity_index, opacity_index + total_size, b);
		for(int i=0; i < total_size; i++)
		{
			 std::cout << b[i] << " ";
		}
		std::cout << std::endl;
		delete a,b;
	}

	/****************************************************
	* 	Reading test graph presented in the paper "L-opacity"
	*******************************************************/
	void init_test_graph()
	{
		// COO format

		read_COO_format("graph.txt");
		std::cout << "Reading finidhed" << std::endl;
		std::cout << "Vertex " << number_of_vertex << std::endl;
		std::cout << "Edges " << number_of_edges << std::endl;

	}

	/******************************************
	*	Init arrays  via after to arrays
	*****************************************/
	void init_arrays()
	{

		from_array = device_malloc<vertex>(2*number_of_edges);
		to_array = device_malloc<vertex>(2*number_of_edges);
		opacity_index = device_malloc<int>(2*number_of_edges);


			/* Copy arrays to device */
		copy(from_array_host, from_array_host + number_of_edges, from_array);
		copy(to_array_host, to_array_host + number_of_edges, to_array);
		delete from_array_host, to_array_host;

		initial_vertex_degrees = device_malloc<vertex>(number_of_vertex);


		int num_vertex=L_VALUE*number_of_vertex;
		//	if (!directed)
		//			num_edges *= 2; // double edges
		full_vertex_array = device_malloc<vertex>(num_vertex);
		real_vertex_degrees = device_malloc<vertex>(num_vertex);
		fill(device, full_vertex_array, full_vertex_array + num_vertex, 0);
	}

	/********************************************************************
	*  Converting from COO (edge list) format to CSR (adjaceny list) format
	*  Run it after something is in COO list (from and to).
	*		Require:
	*						directed = False
	*						from_array contains values
	*						to_array contains values
	*		Input:  Create arrays ? : bool
	*						change degree properties : ? bool
	********************************************************************/
	void convert_to_CSR(bool create_arrays, bool change_properties)
>>>>>>> Save_Thrust
	{
		/*
		* First combine and sort data from and to array - this will be our new edge_list acording to their indexes
		*/
<<<<<<< HEAD
		init_arrays();
		thrust::device_vector<vertex> temp_indx(2 * number_of_edges);
		thrust::fill(temp_indx.begin(), temp_indx.end(), 0);


		thrust::counting_iterator<vertex> index_from(0);
		thrust::counting_iterator<vertex> index_to(number_of_edges);

		//	Merging from and to arrays are keys,
		//	indexes are (0..number_edges) and (num_edges to 2*number_edges)
		thrust::merge_by_key(from_array.begin(), from_array.end(),
			to_array.begin(), to_array.end(),
			index_from, index_to,
			temp_indx.begin(),
			full_edge_array.begin()
			);

		thrust::sort_by_key(temp_indx.begin(), temp_indx.end(), full_edge_array.begin());


		/*
		*	Form vertex offset list
		*/


		thrust::reduce_by_key(temp_indx.begin(), temp_indx.end(),
			thrust::make_constant_iterator(1), temp_indx.begin(), full_vertex_array.begin());

		/*
		*	Form degree vector
		*/

		thrust::copy(full_vertex_array.begin(), full_vertex_array.begin() + number_of_vertex, vertex_degrees.begin());

		thrust::copy(vertex_degrees.begin(), vertex_degrees.end(), degree_count.begin());
		thrust::sort(degree_count.begin(), degree_count.end());
		max_degree = degree_count[number_of_vertex - 1];

		thrust::reduce_by_key(degree_count.begin(), degree_count.end(), thrust::make_constant_iterator(1),
			thrust::make_discard_iterator(), degree_count.begin());


		thrust::inclusive_scan(full_vertex_array.begin(), full_vertex_array.begin()+number_of_vertex, full_vertex_array.begin());

		// Clean temporal arrays

		temp_indx.clear();
		temp_indx.shrink_to_fit();

		/*
		*	Transform the edge list array according to they paired edge.
		*	Form edge list combined by vertexes
		*/
		domain a = thrust::raw_pointer_cast(from_array.data());
		domain b = thrust::raw_pointer_cast(to_array.data());

		thrust::transform(full_edge_array.begin(), full_edge_array.begin() + 2*number_of_edges, full_edge_array.begin(),
			coo_to_csr_converter(a, b, number_of_edges));






	}


	/***
	*  Converting from COO (edge list) format to CSR (adjacency list) format
	*  Run it after someting is in COO list (from and to).
	*/
	void convert_to_CSR_no_doubles()
	{
		/*
		* First combine and sort data from and to array - this will be our new edge_list according to their indexes
		*/
		init_arrays();
		thrust::device_vector<vertex> temp_indx(2 * number_of_edges);
		thrust::fill(temp_indx.begin(), temp_indx.end(), 0);


		thrust::counting_iterator<vertex> index_from(0);
		thrust::counting_iterator<vertex> index_to(number_of_edges);

		//	Merging from and to arrays are keys,
		//	indexes are (0..number_edges) and (num_edges to 2*number_edges)
		thrust::merge_by_key(from_array.begin(), from_array.end(),
			to_array.begin(), to_array.end(),
			index_from, index_to,
			temp_indx.begin(),
			full_edge_array.begin()
			);

		thrust::sort_by_key(temp_indx.begin(), temp_indx.end(), full_edge_array.begin());

=======
		if (debug)
			std::cout << "Starting convertion ";

		if (create_arrays)
			init_arrays();
		else
			fill(device, full_vertex_array, full_vertex_array+ L_VALUE*number_of_vertex, 0);

		device_ptr<vertex> temp_indx = device_malloc<vertex>(2*number_of_edges);
		device_ptr<vertex> temp_indx2 = device_malloc<vertex>(2*number_of_edges);

		//wrap raw pointer with a device_ptr to use with Thrust functions
		fill(device, temp_indx, temp_indx + 2*number_of_edges, 0);
		counting_iterator<vertex> index_from(0);
		counting_iterator<vertex> index_to(number_of_edges);

		//	Merging from and to arrays are keys,
		//	indexes are (0..number_edges) and (num_edges to 2*number_edges)
			// Copy from to values
			copy(device, from_array, from_array + number_of_edges, temp_indx);
			copy(device, to_array, to_array + number_of_edges, temp_indx + number_of_edges);
			// Copy indexes
			copy(device, index_from, index_from + number_of_edges, temp_indx2);
			copy(device, index_to, index_to + number_of_edges, temp_indx2 + number_of_edges);
			if (debug)
				std::cout << "Merge ok : ";

			sort_by_key(device,
			temp_indx, temp_indx + 2*number_of_edges,
			temp_indx2);

			if(debug)
				std::cout << "Sort ok: ";
>>>>>>> Save_Thrust

		/*
		*	Form vertex offset list
		*/

<<<<<<< HEAD

		thrust::reduce_by_key(temp_indx.begin(), temp_indx.end(),
			thrust::make_constant_iterator(1), temp_indx.begin(), full_vertex_array.begin());

		thrust::inclusive_scan(full_vertex_array.begin(), full_vertex_array.begin() + number_of_vertex, full_vertex_array.begin());

		// Clean temporal arrays

		temp_indx.clear();
		temp_indx.shrink_to_fit();

		/*
		*	Transform the edge list array according to they paired edge.
		*	Form edge list combined by vertexes
		*/
		domain a = thrust::raw_pointer_cast(from_array.data());
		domain b = thrust::raw_pointer_cast(to_array.data());

		thrust::transform(full_edge_array.begin(), full_edge_array.begin() + 2 * number_of_edges, full_edge_array.begin(),
			coo_to_csr_converter(a, b, number_of_edges));



	}







	struct  equal
	{

		__host__ __device__
		field operator()(field x)
		{

			return x - 1;
		}

	};

	struct  prev
	{
		__host__ __device__
		prev(int _nums) : nums(_nums) {}

		__host__ __device__
		field operator()(field x)
		{
			if (x < 2)
			{
				return nums;
			}
			return x - 2;
		}
		int nums;

	};

	struct pred_if
	{
		__host__ __device__
		pred_if(domain a, domain b, int vert) : start(a), end(b), current(vert)
		{

		}

		__host__ __device__
			bool operator()(vertex x)
		{
			//	printf("SEARCHING distance %i \n", thrust::distance(start, end));
				int from = 0;
				if (current != 0)
				{
					from = end[current - 1];
				}
				int to = end[current];

				return thrust::binary_search(thrust::device, start+from, start+to, x);
		}

		domain start;
		domain end;
		int current;
	};


	struct  calcus
	{
		__host__ __device__
		calcus(domain c) :  cidt(c)
		{

		}

		template <typename Tuple>
		__host__ __device__
			void operator()(Tuple t)
		{
				// Device vector temporal array (candidate)


		}

		thrust::device_ptr<vertex> current;
		thrust::device_vector<vertex> oop;
		vertex current_vertex;
		domain vertex_array;
		vertex vertex_size;
		domain cidt;
		domain tempor;

	};


	struct  replacer
	{
		__host__ __device__
		replacer(domain c, int _size) : cidt(c), size(_size)
		{

		}


		__host__ __device__
			vertex operator()(vertex t)
		{
				// Device vector temporal array (candidate)

				if (thrust::binary_search(thrust::device, cidt, cidt + size, t))
					return 1;
				return 0;
		}


		domain cidt;
		int size;

	};

	struct  printer
	{

		__host__ __device__
			void operator()(vertex t)
		{
				// Device vector temporal array (candidate)

				printf("%u ", t);
			}


	};
	
	
	__global__  void expander(thrust::device_vector<vertex>::iterator* previous, 
		thrust::device_vector<vertex>::iterator* current,
		domain current_vertex, domain temp_from, domain temp, domain full_vertex_array, domain full_edge_array
		)
	{

		int idx = blockIdx.x*blockDim.x + threadIdx.x;
		current[current_vertex[idx]] = thrust::copy(thrust::seq,
			thrust::make_permutation_iterator(full_edge_array, thrust::make_counting_iterator<vertex>(temp_from[idx])),
			thrust::make_permutation_iterator(full_edge_array, thrust::make_counting_iterator<vertex>(temp[idx])),
			current[current_vertex[idx]]);

	
		int start = 0;
		if (idx != 0)
		{
			start = full_vertex_array[current_vertex[idx - 1]];
		}
		int end = full_vertex_array[current_vertex[idx]];

		current[current_vertex[idx]] = thrust::remove(previous[current_vertex[idx]], current[current_vertex[idx]], current_vertex[idx] + 1);

		thrust::sort(previous[current_vertex[idx]], current[current_vertex[idx]]);
		current[current_vertex[idx]] = thrust::unique(previous[current_vertex[idx]], current[current_vertex[idx]]);

		for (auto j = full_edge_array + start; j != full_edge_array + end; j++)
		{
			current[current_vertex[idx]] = thrust::remove(previous[current_vertex[idx]], current[current_vertex[idx]], *j);
		}

		full_vertex_array[current_vertex[idx] + number_of_vertex] = thrust::distance(previous[current_vertex[idx]], current[current_vertex[idx]]);
		previous[current_vertex[idx]] = current[current_vertex[idx]];
	}
	
	/*
	*	By finding shortest paths, form to L_VALUE level
	*/

	void form_full_level_graph()
	{
		//	domain a = thrust::raw_pointer_cast(full_edge_array.data());

		//	thrust::for_each(thrust::device, full_vertex_array.begin(), full_vertex_array.begin() + number_of_vertex, copier(a, 5));
		//
		thrust::device_vector<vertex> temp(number_of_edges * 2);


		thrust::device_vector<vertex> temp_fin(number_of_edges * number_of_edges);
		thrust::device_vector<vertex> temp_fin2(number_of_edges * number_of_edges);
		thrust::device_vector<vertex> temp_from(number_of_edges * 2);

		thrust::copy(full_edge_array.begin(), full_edge_array.begin() + 2 * number_of_edges, temp.begin());
		thrust::transform(temp.begin(), temp.end(), temp.begin(), equal());

		thrust::copy(full_edge_array.begin(), full_edge_array.begin() + 2 * number_of_edges, temp_from.begin());
		thrust::transform(temp_from.begin(), temp_from.end(), temp_from.begin(), prev(number_of_vertex + 1));

		thrust::copy(

			thrust::make_permutation_iterator(full_vertex_array.begin(), temp.begin()),
			thrust::make_permutation_iterator(full_vertex_array.end(), temp.end()), temp.begin());

		thrust::copy(

			thrust::make_permutation_iterator(full_vertex_array.begin(), temp_from.begin()),
			thrust::make_permutation_iterator(full_vertex_array.end(), temp_from.end()), temp_from.begin());


			thrust::device_vector<vertex> temp_index(number_of_edges*number_of_edges);



		cout << "From ";
		for (auto iter : temp_from)
		{
			cout << "  " << iter;
		}
		cout << endl;

		cout << "To   ";
		for (auto iter : temp)
		{
			cout << "  " << iter;
		}
		cout << endl;



		cout << "Temp index ";
		for (auto iter : temp_index)
		{
			cout << "  " << iter;
		}
		cout << endl;


		//domain c = ;
		vertex N = full_vertex_array[number_of_vertex - 1];
		thrust::device_vector<vertex> c (2*N);

		thrust::device_vector<vertex> tempo(2*N);
		thrust::device_vector<vertex>::iterator current = tempo.begin();

		int NUM = thrust::distance(temp.begin(), temp.end());


		thrust::transform(
			thrust::make_counting_iterator<vertex>(0),

			thrust::make_counting_iterator<vertex>(N),
			c.begin(), replacer(thrust::raw_pointer_cast(full_vertex_array.data()), number_of_vertex)
			);

		thrust::inclusive_scan(c.begin(), c.end(), c.begin());
		/**/
		int current_index = 0;
		thrust::device_vector<vertex>::iterator previous = current;

		// Change it to paralel version
		// expander<<<1, NUM>>(c, full_vertex_array, full_edge_array)
		// { 
			
			
			
			// Put a value into vertex array

			
			
		/*
		for (int i = 0; i < NUM; i++)
		{
			if (c[i] != current_index)
			{
				// We finish expanding for current index
				int start = 0;
				if (current_index != 0)
				{
					start = full_vertex_array[current_index - 1];
				}
				int end = full_vertex_array[current_index];
				//thrust::device_vector<vertex> temp_vect(number_of_edges);

				//thrust::merge(previous, current, full_edge_array.begin() + start, full_edge_array.begin() + end, temp_vect.begin());
				// Remove a self vertex
				//	current = thrust::remove(previous, current, 0);

				current = thrust::remove(previous, current, current_index + 1);
				// Remove copies

				domain from = thrust::raw_pointer_cast(&full_edge_array[start]);
				domain to = thrust::raw_pointer_cast(&full_edge_array[end]);

				cout << "Tempo " << current_index << ": ";

				//		pred_if(from, to));

			//	thrust::device_vector<vertex> temp_vector(number_of_edges);
			//	temp_vec
				thrust::sort(previous, current);
				current = thrust::unique(previous, current);
				for (auto j = full_edge_array.begin() + start; j != full_edge_array.begin() + end; j++)
				{
					current = thrust::remove(previous, current, *j);
				}

			//	current = thrust::remove_if(thrust::device, previous, current,
			//		pred_if(thrust::raw_pointer_cast(full_edge_array.data()), thrust::raw_pointer_cast(full_vertex_array.data()), current_index));

				thrust::for_each(previous, current, printer());
				cout << endl;
				full_vertex_array[current_index + number_of_vertex] = thrust::distance(previous, current);
				previous = current;
				current_index = c[i];

				// Put a value into vertex array

			}
			//thrust::make_transform_iterator(thrust::make_counting_iterator<vertex>(0), fun())
			current = thrust::copy(thrust::seq,
				thrust::make_permutation_iterator(full_edge_array.begin(), thrust::make_counting_iterator<vertex>(temp_from[i])),
				thrust::make_permutation_iterator(full_edge_array.begin(), thrust::make_counting_iterator<vertex>(temp[i])),
				current);



		}

		int start = full_vertex_array[current_index - 1];
		int end = full_vertex_array[current_index];
		// Remove current vertex (avoid loops)
		current = thrust::remove(previous, current, current_index + 1);

		cout <<endl << "Tempo " << current_index << ": ";
		// sort connected edges
		thrust::sort(previous, current);
		// remove dublicates
		current = thrust::unique(previous, current);
		// Remove all vertex that are already discovered
		for (auto j = full_edge_array.begin() + start; j != full_edge_array.begin() + end; j++)
		{
			current = thrust::remove(previous, current, *j);
		}

		// Print all edges from current vertex
		thrust::for_each(previous, current, printer());
		full_vertex_array[current_index + number_of_vertex] = thrust::distance(previous, current);
		*/

		cout << "Tempo   ";
		for (auto iter : tempo)
		{
			cout << "  " << iter;
		}
		cout << endl;

		// Update vertex
		thrust::inclusive_scan(full_vertex_array.begin() + (number_of_vertex - 1), full_vertex_array.begin() + 2 * (number_of_vertex), full_vertex_array.begin() + (number_of_vertex - 1));
		// Update edges
		thrust::copy(tempo.begin(), current, full_edge_array.begin() + full_vertex_array[number_of_vertex-1]);


		print_csr_graph();



	}


	struct minus_one
	{
		__host__ __device__
		vertex operator()(vertex t)
		{
			// -1 :
			return t - 1;

		}
	};

	struct min_max_transform
	{

		__host__ __device__
		thrust::pair<double, double> operator()(thrust::tuple<double, double> t)
		{

				double min = thrust::get<0>(t) - thrust::get<1>(t) < 0? thrust::get<0>(t) : thrust::get<1>(t);
				double max = thrust::get<0>(t) -thrust::get<1>(t) > 0 ? thrust::get<0>(t) : thrust::get<1>(t);

				return thrust::make_pair(min, max);
		}
	};


	struct opacity_counter
	{

		__host__ __device__
		thrust::pair<double, double> operator()(thrust::tuple<double, double> t)
		{

			double min = thrust::get<0>(t) -thrust::get<1>(t) < 0 ? thrust::get<0>(t) : thrust::get<1>(t);
			double max = thrust::get<0>(t)	 -thrust::get<1>(t) > 0 ? thrust::get<0>(t) : thrust::get<1>(t);

			return thrust::make_pair(min, max);
		}
	};

	__device__ void  test_funct(domain a, int end)
	{
		thrust::for_each(thrust::device, a, a + end, printer());
	}

	/*
	*	L opacity matrix calculation
	*/


	void calc_L_opacity()
	{
		for (int i = 1; i < L_VALUE; i++)
		{
			// full_edge_array - here we store all adjasent

			vertex N = full_vertex_array[number_of_vertex - 1];
			cout << "N+ " << N << endl;
			thrust::device_vector<vertex> from(N);
			// Forming indexes (from vertex)
			int starting_point = 0;
			int ending_point = full_vertex_array[(i)*number_of_vertex-1];

			if (i != 1)

			{
				starting_point = full_vertex_array[(i - 1)*number_of_vertex - 1];

			}
			/*
			*	Expanding indexes. Finding break points
			*	Example: 0 1 2 3 4 .. 20 => 0 0 1 0 0 0 1 ...
			*/
			thrust::transform(
				thrust::make_counting_iterator<vertex>(starting_point),
				thrust::make_counting_iterator<vertex>(ending_point),
				from.begin(), replacer(thrust::raw_pointer_cast(full_vertex_array.data()), number_of_vertex)
				);

			// debug print
			cout << endl << "From degrees ";
			for (auto iter : from)
			{
				cout << "  " << iter;
			}


		//	from[0] = full_vertex_array[(number_of_vertex-1)*(i-1)];
			/*
			*	Transorming into indexes:
			*	Example:	0 0 1 0 0 0 1 => 0 0 1 1 1 1 2 2 2 ..
			*/

			thrust::inclusive_scan(from.begin(), from.end(), from.begin());

			cout << endl << "From degrees ";
			for (auto iter : from)
			{
				cout << "  " << iter;
			}


			/*
			*	Transforming from indexes into degrees:
			*	Example:  0 0 1 1 1 1 2 2 2.. => 2 2 4 4 4 4 ...
			*/

			thrust::transform(thrust::make_permutation_iterator(vertex_degrees.begin(), from.begin()),
				thrust::make_permutation_iterator(vertex_degrees.begin(), from.end()),
				from.begin(), thrust::identity<vertex>());

			cout << endl << "From degrees ";
			for (auto iter : from)
			{
				cout << "  " << iter;
			}


			/*
			*	To vector. Transform edge list into degree list =>  similar techno
			*
			*/


			thrust::device_vector<vertex> to(N);
		//	auto iter_begin = thrust::make_transform_iterator(full_edge_array.begin(), minus_one());
		//	auto iter_end =   thrust::make_transform_iterator(full_edge_array.begin() + N, minus_one());

			thrust::transform(full_edge_array.begin(), full_edge_array.begin() + N, to.begin(), minus_one());

			cout << endl << "TO degrees ";
			for (auto iter : to)
			{
				cout << "  " << iter;
			}


			thrust::transform(
				thrust::make_permutation_iterator(vertex_degrees.begin(), to.begin()),
				thrust::make_permutation_iterator(vertex_degrees.begin(), to.end()),
				to.begin(), thrust::identity<vertex>());

			cout << endl << "TO degrees ";
			for (auto iter : to)
			{
				cout << "  " << iter;
			}

			/*
			 *  Find max and min in zip iterator of to - from pairs
			 */
			thrust::transform(
				thrust::make_zip_iterator(thrust::make_tuple(from.begin(), to.begin())),
				thrust::make_zip_iterator(thrust::make_tuple(from.end(), to.end())),
				thrust::make_zip_iterator(thrust::make_tuple(from.begin(), to.begin())),
				min_max_transform()
				);
			cout << endl << "From degrees ";
			for (auto iter : from)
			{
				cout << "  " << iter;
			}

			cout << endl << "TO degrees ";
			for (auto iter : to)
			{
				cout << "  " << iter;
			}

			/*
			 * 	Opacity  matrix forming. Now it is n^ 2 memory TODO: IN PARALLEL using cuda kernel
			 * 	Assumptions !!: Not optimum for undericted (div 2).
			 * 	Problem with same degree. Example: {4 = > 4} - must count only degree of one.
			 */

			for (int i =0; i < N; i++)
		   {
				double min = degree_count[from[i] - 1] * degree_count[to[i] - 1];
				if (degree_count[from[i] - 1] == degree_count[to[i] - 1])
					min = degree_count[from[i] - 1];
				cout  << endl << "FOR " << from[i]  <<" " << to[i]  << " = "<<  min;
				opacity_matrix[max_degree*(from[i]-1) + (to[i]-1)] += 1.0/(2.0*min);
			}


			/*
			 * Sort by key. Indexes (values) and degrees (keys)
			 */

			/*
			 * 	Reduce by key. Count how many pairs we have. 0 0 3 3
			 */

		}
=======
		int gridsize =(2*number_of_edges + BLOCK_SIZE - 1) / BLOCK_SIZE;
		degree_count_former<<<gridsize, BLOCK_SIZE>>>(temp_indx, full_vertex_array,2*number_of_edges,0);
		cudaDeviceSynchronize();

		copy(device,
			full_vertex_array,
			full_vertex_array + number_of_vertex,
			real_vertex_degrees);

		if(change_properties)
		{
			//
			//	Form degree vector.
			//	Each vertex has degree
			//	Total size: number_of_vertex
			//
			copy(device,
				full_vertex_array,
				full_vertex_array + number_of_vertex,
				initial_vertex_degrees);
			if(debug)
				std::cout << "Copy ok";

		// Find maximum degree value
			max_degree = reduce(device, initial_vertex_degrees,
																initial_vertex_degrees + number_of_vertex,
																0, maximum<vertex>());
		if(debug)
			std::cout << "Degree ok";

		// Opacity matrix should be create again
		opacity_matrix = device_malloc<opacity>(max_degree*max_degree);
		fill(device, opacity_matrix, opacity_matrix + max_degree*max_degree, 0);

		// Malloc lessL_matrix in memory: n^2
	 	lessL_matrix= device_malloc<opacity>(max_degree*max_degree);
		fill(device,  lessL_matrix, lessL_matrix + max_degree*max_degree, 0);

		degree_count = device_malloc<vertex>(max_degree);
			fill(device, degree_count, degree_count + max_degree, 0);
			gridsize = (number_of_vertex + BLOCK_SIZE - 1) / BLOCK_SIZE;
			// Offset is 1
			degree_count_former<<<gridsize, BLOCK_SIZE>>>
																(initial_vertex_degrees, degree_count,number_of_vertex, 1);
			cudaDeviceSynchronize();
		 }

		//
		//	Form vertex offset array
		//	Result: vertex offser array => 2 4 10 ...
		//
		inclusive_scan(device,
			 full_vertex_array,
			 full_vertex_array+number_of_vertex,
			 full_vertex_array);

		if(debug)
			std::cout << "Inclusive scan ok";
		// Clean temporal array
		device_free(temp_indx);


		int num_edges=number_of_vertex*max_degree*L_VALUE;
		if (num_edges > number_of_vertex*number_of_vertex)
		{
			num_edges = number_of_vertex*number_of_vertex;
		}
		device_free(full_edge_array);
		full_edge_array = device_malloc<vertex>(num_edges);
		fill(device, full_edge_array, full_edge_array + num_edges, -1);


		/*
		*	Transform the edge list array according to they paired edge.
		*	Form edge list combined by vertexes
		*/

		transform(device,
			temp_indx2, temp_indx2 + 2*number_of_edges,
			full_edge_array,
			coo_to_csr_converter(from_array, to_array,
				number_of_edges));


		device_free(temp_indx2);

		if(debug)
			std::cout<< std::endl << "Converting to CSR done " << std::endl;
>>>>>>> Save_Thrust
	}
};
#endif
