# Scalable-privacy preserving
Materials for scalable privacy paper
In the folder L_opac_dump_2016 are all experimental materials

## How To run : 

Before running a program make sure that you have last version of CUDA. 

All files with extension ‘.cu’ can be run using : ‘nvcc’ command

This code was tested on :
	- NVIDIA 980 with CUDA 7.5
	
Additional Requirments:
	- Thrust version > 1.8

To test your version of Thrust library run 
test_thrust.cu  and  thrust_version.cu 

After you make sure that you met all requirements run device_test.cu to know specific properties of your GPU card, change BLOCK_SIZE in ‘header.h’ file accordingly. 

First off all L-opacity framework requires a normalised graph in edge list format. 
Normalised version of a graph can be received after executing file_norm.cpp.

Run:
	file_norm.cpp your_graph.txt norm_graph.txt

After you received a normalised version of a graph you should copy all data from norm_graph.txt to graph.txt and Wiki-Vote.txt. 

To execute L-Traversal algorithm:
	to compile: nvcc graphs.cu -o graphs
	to run: ./graphs   L_value  theta_threshold. 
To execute L-FW algorithm:
	to compile: nvcc apsp.cu -o apsp
	to run: ./apsp   number_vertex  L_value. 

This folder contains all source code for GPU - L - opacity framework. 



