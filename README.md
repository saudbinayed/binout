# binout
`MATLAB` functions to work with `LS-DYNA` `binout` files:
* The function `get_binout_data()`, called the binout reader, reads result (or state) data from the binout file.
* The function `get_d3plot_d3thdt_control_data()` is a helper function and is called (internally) from within the binout reader function to retreive important control data from the root `d3plot` file (if available)
* The function `struct2graph()` is a standalone function and can be used (for convenience) to graphically display the content and hierarchy of a nested `MATLAB` `struct`. 

The `MATLAB` source files of the functions are in the [`src`](/src/) folder. Additionally, sample `LS-DYNA` files are provided in the [`LS-DYNA-sample`](/LS-DYNA-sample/) folder. You can download these files (note: the `binout` is about 78 MB) and use the `MATLAB` script `test1.m` in the `src` folder to get started. 

## binout reader
### what it does?
The function `get_binout_data()` takes the path to an `LS-DYNA` `binout` file and returns the data in it to be 
easily manipulated (i.e. post-processed) in `MATLAB`. 

### what is `binout`?
A binout is a binary file generated by [LS-DYNA](https://www.ansys.com/products/structures/ansys-`LS-DYNA`) after running an `LS-DYNA` model, and it contains various result 
databases, such as "matsum" (for material summary, like energy and rigid body velocities data), "nodout" (for nodal data, like displacements and velocities), "elout" (for element data, like stresses, stress-resultants, and strains), and so on. 

### usage
The formal syntax is 
```
[binin] = get_binout_data(binout_filename)
```
#### inputs:


| Arg | Type | Desc | Required? |
|:--- |:---  |:---  |:---       |
| `binout_filename` | [`char`\|`string`] | (relative or absolute) path of the root `binout` file | Yes |


The root `binout` file is the first if there are more than one binout file. The function is configured to auto-detect and read all files sequentially. Data from these files will be joined. 

#### outputs:

| Arg | Type | Desc | Required? |
|:--- |:---  |:---  |:---       |
| `binin` | `MATLAB` `struct`  | A `MATLAB` structure containing all result data in the `binout` file(s) |   |


This is a scalar but highly nested structure. Use the "." (dot) indexing method in `MATLAB` to traverse the `binin` structure in order to arrive at a data of interest. The returned `binin` structure will have `n` root fields, where (`n-1`) is the number of databases contained in the `binout` file(s), such as "matsum", "nodout", etc. The last n<sup>th</sup> field (when available) is called "control". 

All fields of the main `binin` structure are scalar structures themselves. In general, each of these structures contains exactly two fields: "data" and "metadata", each of which is also a structure. 
The fields of the "data" structure are the actual result (state) data of interest. Among the fields of the "metadata" structure is a field called "ids" that stores the IDs of the model entities, e.g nodes, parts, etc.
However, some fields of the `binin` have intermediate structures under them, and the "data" and "metadata" are fields of those intermediate structures. 

<!--Every root field is itself a scaler structure. Some kinds of root structures will have intermediate sub-structures (as in the `binout` file). At some level, there will be idnentically two structures: "metadata" and "data".-->

For example, the "binin.matsum" structure will have the fields "metadata" and "data" as its immediate fields. On the other hand, the "binin.elout" structure will contain intermediate fields like "shell", "solid", etc. In this case, the "metadata" and "data" structures are fields of "binin.elout.shell", "binin.elout.solid", and so on. See the [`figs/graphs`](/figs/graphs/) folder, for content and organisation of a sample `binin` struct. 

<!--The actual result (i.e. state) data are contained in the "data" structure as its fields, the names of which are borrowed directly from the original `binout` file that are practically self-explainatory. All data under the "data" structure are converted to `double` (floats with 64 bits) for unification reasons.-->

<!--The "metadata" structure is similar to the "data" (described above), and it contains mostly meta-data and few important data, namely the id's of parts, nodes, etc, which are generally stored in fields called "ids".-->

The root field "control" under the `binin` structure contains supplementary control data retrieved from the root `d3plot` file, which is provided by (internally) calling the `get_d3plot_d3thdt_control_data()` helper function. The binout reader function will auto-detect the root d3plot file. Among the control data retrieved are the element-node connectivity arrays and some others (like the initial geometry and useful info about the model).

#### notes
The values associated with the fields of the "data" structure are in general 2D arrays  except "time" (which is always a column vector). Rows of the 2D arrays correspond to 
time instants (so that the number of rows equal the number of entries of the time vector). The columns of the 2D arrays correspond to the IDs of the entities (like parts, nodes, etc), which (again) are generally found in the "metadata" structure. However, the IDs of elements and
contacts are stored directly in the "data" structure itself. The columns of the 2D arrays in the "data" structures in the "elout" database (say "elout.shell") correspond to elements IDs (stored in "ids") _and_ their integration points (the number of which is stored in a field called "nip").

In general, fields' names in "data" and "metadata" are explicit and self-explainatory (e.g. "kinetic_energy", "time", "x_velocity", "x_displacement", etc). 
Although, few fields in the "data" structure for the substructures of "elout" are abbreviated. Stresses are 
abbreviated by "sig_xx", "sig_xy", etc ("sig" for "sigma"), and, strains are abbreviated by "eps_xx" and so on ("eps" for "epsilon"). 

Lastly, the structuring and naming of fields are directly borrowed from the `binout` file. So, if one is already familiar with opening `binout` files in LS-PrePost, 
then there is no need to make further explaination since (in this case) the `binin` structure should be very familiar too. 

The [`figs/graphs`](/figs/graphs/) folder contains several example contents (as visual graphs) of a `binin` structure and its children. 

#### optional
If needed, one can use the standalone function `struct2graph()` to visually display the hierarchy map of the `binin` structure. The function accepts 
a scalar (possibly highly nested) `MATLAB` structure as the first input argument, and it produces the figures and returns their handles as output. The sample graphs in the [`figs/graphs`](/figs/graphs/) folder were generated by this function.


### how to get a `binout` file?
To make `LS-DYNA` writes the results of your interest to one (or more) `binout` file(s), follow the following steps:
1. In the input keyword file, add one or more database keywords of the form `*database_<option>`, where `<option>` is the database type, e.g. `matsum`, `nodout`, etc.
   1. In each database keyword, set the value of `BINARY` (second field of first card) to `2`, to tell `LS-DYNA` to add this database to the binout file.
1. For certain kinds of database types, you need to add some additional database keywords to activate those database types. See [`lsdyna_database`](/lsdyna_database.md) for more details. 
1. Run your model, and `LS-DYNA` should generate one (or more) `binout` files 

The first of these files is named as `binout`, which is called the root file. The number of generated binout files, by default, is about `ceil(overallSize/1)`, where `overallSize` is the total size of requested data in gigabytes (GB).

### final remarks
The aim of the work presented herein is to make working with `LS-DYNA` results easier for engineers and researchers, so please let us know if you encounter any 
problems or if you need additional clarifications about how to make this work in real use.  We also would like to explain choosing the word "binin": it is meant 
to be read as BINary output of `LS-DYNA` IN `MATLAB`. That is, `binin` contains the output (results) from `LS-DYNA`.  


## motivations
The work is shared for three aims:
+ Help (engineers and researchers) :heart: to easily work with `LS-DYNA` results.
+ Enrich `MATLAB` by affording a tool to import real-world data from world class FEA solver (`LS-DYNA`).
+ Extend `LS-DYNA` by allowing users to make use of the very powerful tools in `MATLAB` to perform additional post-processing calculations and generate graphics with publication-quality to share with others. 

We hope the work will be useful.

## contributions
This work is part of a PhD study at the [Blast and Impact Engineering Research Group](https://twitter.com/SheffieldBlast), 
at the [University of Sheffield](https://sheffield.ac.uk) (2023)

supervised by: 
+ Prof. Andrew Tyas (a.tyas@sheffield.ac.uk)
+ Dr. Samuel E. Rigby (sam.rigby@sheffield.ac.uk; [@Dr_SamRigby](https://twitter.com/Dr_SamRigby))
+ Dr. Maurizio Guadagnini (m.gaudagnini@sheffield.ac.uk)

developed by:
+ Dr. Samuel E. Rigby (sam.rigby@sheffield.ac.uk;[@Dr_SamRigby](https://twitter.com/Dr_SamRigby))
+ Saud A. E. Alotaibi (salotaibi2@sheffield.ac.uk; [@saudbinayed](https://twitter.com/saudbinayed)), sponsored by [Qassim University](https://qu.edu.sa), Saudi Arabia, and the Saudi Arabian Cultural Bureau in London, UK.

 `   
