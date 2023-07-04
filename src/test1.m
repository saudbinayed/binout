clear; 
close all;
clc;

binout_filename='../LS-DYNA sample/binout';
binin = get_binout_data(binout_filename);


%%
[figParents,figSelect]=struct2graph(binin,"All");
