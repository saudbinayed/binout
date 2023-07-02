function [control]=get_d3plot_d3thdt_control_data(filename1,word_length)
%% What this does?
% this function is a helper function to retreive control data from the root LS-DYNA ["d3plot"|"d3thdt"] that are required to
% ... to read the actual state data from sebsequent "d3plot"/"d3thdt" files.
% ... Also, this function can be handy to retreive important model data for a given LS-DYNA model such as ids of nodes, elements, parts, etc, 
% ... or the element-node connectivity arrays, or the initial geometry coordinates of the nodes to supplement data read from an LS-DYNA binout file.
% =====================================
%% Input:
% filename1 = path to root [d3plot or d3thdt], specified as [string | char], and can be relative or absolute.
% word_length = size of one LS-DYNA word. This can be 4 if d3plot/d3thdt file was produced by single-precision LS-DYNA solver (i.e. 4 bytes per 1 data unit)
% ... Or, word_length can, otherwise, be 8 if the file was produced by double-precision solver (i.e. 8 bytes per data unit)
% ====================================
%% Output:
% control = scalar structure of type [struct], which contains several fields defining the control data. Field names matche variable names in LS-DYNA binary
% ... database manual. They are not documented this function needs to be called from other functions.
%
% =====================================
%% Contributions: 
% Code is part of a PhD study at the Blast and Impact Reserach Group, the University of Sheffield (2023)
% Dr. Samuel E. Rigby (sam.rigby@sheffield.ac.uk)
% Saud A. E. Alotaibi (salotaibi2@sheffield.ac.uk)
% Thanks to :
% LSTC - "LS-DYNA binary database manual"
%======================================
%% Notes:
% This is not compatible with "get_d3plot_d3thdt_state_data()" yet.
% ... It is compatibly with "get_binout_data()".
% ... This function is not meant to be called directly by the user.
% ... The "state data" function "get_d3plot_d3thdt_state_data()" will call it from there.
% ... Alternatively, the function "get_binout_data()" will call this function from there.
% ... Variable names match those in "LS-DYNA binary database manual" - see the manaual for interpretations
% ... recommended: store this function in the same directory in which you stored the function "get_d3plot_d3thdt_state_data_5_5()"
%=====================================
lsdyna_database_manual='https://www.dynasupport.com/manuals/additional/ls-dyna-database-manual-2014'; %pdf
offset_last=0;
exit_flag=false; %false or "0" means filename1 is not closed, and it contains state data! will be updated at the end of the code below.
%
databaseType='database';
if contains(filename1,'d3plot')
    databaseType='d3plot';
elseif contains(filename1,'d3thdt')
    databaseType='d3thdt';
end
cond1= isfolder(filename1);
cond2= endsWith(filename1,digitsPattern());
cond3= endsWith(filename1,"."+lettersPattern());
if any([cond1,cond2,cond3])
    error('Error1 from "%s()":\n\tThe supplied file "%s" is not the "root" %s file.\n\tThe root file contains no digits after the word "d3plot".\n\tSupply a valid root d3plot.\n',mfilename(),filename1,databaseType);
end
%
origin="bof";
fileID=fopen(filename1,"r");
word1_address=0;
word2_address=63;
num_words=(word2_address-word1_address)+1;
fseek(fileID,(word1_address)*word_length,origin);
precision="int";
CONTROL_DATA=(word1_address:word2_address)';
CONTROL_DATA(:,2)=fread(fileID,num_words,precision);
offset=ftell(fileID);
CDATA=num2cell(CONTROL_DATA);
frewind(fileID);
fclose(fileID);
%
INUM=CONTROL_DATA(11+1,2);
if INUM~=1 && INUM~=3
    error('Error2 from "%s()":\n\tThe supplied file "%s" is not recognized as an expected root %s file.\n\tThis is could be due to how function is written. Revisit the code.\n',mfilename(),filename1,databaseType);
end
%
% NDIM, NUMNP, NGLBV, IU, IV, IA, NEL8, NUMMAT8, NV3D:
Address1=[15,16,18,20,21,22,23,24,27]; Address1=Address1+1; %for 8N solids
%=============================================================
% NEIPH, MAXINT, NARBS, IOSHL1, IOSHL2, NUMMAT, IDTDT, EXTRA:
Address2=[34,36,39,43,44,51,56,57]; Address2=Address2+1; 
%=============================================================
% IT:
Address3=[19]; Address3=Address3+1;
%=============================================================
% NUMDS, NEL4, NUMMAT4, NV2D, NEIPS, MAXINT:
Address4=[25,31,32,33,35,36]; Address4=Address4+1; %for 4N shells
%=============================================================
% IOSHL1, IOSHL2, IOSHL3, IOSHL4:
Address5=[43,44,45,46]; Address5=Address5+1;
%=============================================================
% NELT, NUMMATT, NV3DT:
Address6=[40,41,42]; Address6=Address6+1; % for thick shell (8 tshells)
%=============================================================
% NEL2, NUMMAT2, NV1D:
Address7=[28,29,30]; Address7=Address7+1; %for 2N beam
%=============================================================
% IALE,NCFDV1, NCFDV2, NUMFLUID, NMSPH, NPEFG:
Address8=[47,48,49,52,37,54]; Address8=Address8+1; %for ALE
%=============================================================
% NSTP, IFLAGD, NSTH, NSTB, NSTS, NSTT:
Address9=[58,59,60,61,62,63]; Address9=Address9+1; %for d3thdt
%=============================================================
% NDS, NST:
Address10=[25,26]; Address10=Address10+1;
%=============================================================
% NGPSPH:
Address11=[38]; Address11=Address11+1;
%
[NDIM,NUMNP,NGLBV,IU,IV,IA,NEL8,NUMMAT8,NV3D]=CDATA{Address1,2};
[NEIPH,MAXINT,NARBS,IOSHL1,IOSHL2,NUMMAT,IDTDT,EXTRA]=CDATA{Address2,2};
[IT]=CDATA{Address3,2};
[NUMDS,NEL4,NUMMAT4,NV2D,NEIPS,MAXINT]=CDATA{Address4,2}; %NUMDS is actually NDS defined below
[IOSHL1,IOSHL2,IOSHL3,IOSHL4]=CDATA{Address5,2};
[NELT,NUMMATT,NV3DT]=CDATA{Address6,2};
[NEL2,NUMMAT2,NV1D]=CDATA{Address7,2};
[IALEMAT,NCFDV1,NCFDV2,NUMFLUID,NMSPH,NPEFG]=CDATA{Address8,2};
[NSTP,IFLAGD,NSTH,NSTB,NSTS,NSTT]=CDATA{Address9,2};
[NDS,NST]=CDATA{Address10,2};
[NGPSPH]=CDATA{Address11,2};
%
if NDIM>3
    MATTYP=0;
    if NDIM==5 || NDIM==7
        MATTYP=1;
    end
    NDIM=3;
end
%
if NEL8<0
    NEL8=abs(NEL8);
    FLAG_EXTRA_NEL8=1; 
else
    FLAG_EXTRA_NEL8=0;
end
%
if MAXINT>=0
    MDLOPT=0;
    if MAXINT>10000
        MAXINT=MAXINT-10000;
    end
elseif MAXINT<0 
    if MAXINT<-10000
        MDLOPT=2;
        MAXINT=abs(MAXINT)-10000;
    else
        MDLOPT=1;
        MAXINT=abs(MAXINT);
    end
end
%
if INUM==1
    %d3plot:
    NDS=0;
    NUMDS=NUMDS;
elseif INUM==3
    %d3thdt:
    NUMDS=0;
    NDS=NDS;
end

if NUMDS<0
    MAXINT_IP=4; %shell and thick shell "in-plane" integration points number
    MAXINT_TT=MAXINT/MAXINT_IP; % "through-thickness" integration points number
else
    MAXINT_IP=0;
    MAXINT_TT=MAXINT;
end
%
if NARBS==0
    FLAG_NARBS=0; %numbering is sequential (as is in ls-dyna internal system)
else
    FLAG_NARBS=1; %there is a total number of elements equal to NARBS
    % outputed just after the GEOMETRY_DATA
    % use these to re-map the numbering of nodes, elements, materials, etc
    % between ls-dyna's internal numbering and yours
end
%
if IOSHL1==1000
    % 6 stress components flag
    IOSHL1=1; IOSOL1=1;
elseif IOSHL1==999
    IOSHL1=0; IOSOL1=1;
else
    IOSHL1=0; IOSOL1=0;
end
%
if IOSHL2==1000
    % plastic strain flag
    IOSHL2=1; IOSOL2=1;
elseif IOSHL2==999
    IOSHL2=0; IOSOL2=1;
else
    IOSHL2=0; IOSOL2=0;
end
%
if IOSHL3==1000
    %shell force resultants flag
    IOSHL3=1;
else
    IOSHL3=0;
end
%
if IOSHL4==1000
    % shell thickness + energy + 2 others flag
    IOSHL4=1;
else
    IOSHL4=0;
end
%
NEIPS_IDX=[];
NEIPS_IDX=[];
if NEIPS>0
    for j1=1:MAXINT
    NEIPS_IDX=[NEIPS_IDX,j1*(6*IOSHL1+1*IOSHL2+NEIPS)-NEIPS+1:j1*(6*IOSHL1+1*IOSHL2+NEIPS)];
    end
end
NEIPS_TSHELL_IDX=[];
if NEIPS>0
    for j1=1:MAXINT
        NEIPS_TSHELL_IDX=[NEIPS_TSHELL_IDX,j1*(6*IOSHL1+1*IOSHL2+NEIPS)-NEIPS+1:j1*(6*IOSHL1+1*IOSHL2+NEIPS)];
    end
end
fprintf('###\nA message from "%s()":\n\tAddress of NEIPS (extra history variables), which is called NEIPS_IDX, is computed and outputted.\n',mfilename());
%
IDTDT2=sprintf('%05.0f',IDTDT);
IDTDT2=str2num(IDTDT2');
IDTDT2=num2cell(IDTDT2);
[FLAG5_IDTDT,FLAG4_IDTDT,FLAG3_IDTDT,FLAG2_IDTDT,FLAG1_IDTDT]=IDTDT2{:};   
%
if IDTDT>100
    ISTRN=FLAG5_IDTDT;
else
    ISTRN=0;
end
% 
if ISTRN==0 && NV2D>0
    if NV2D-(MAXINT*(6*IOSHL1+IOSHL2+NEIPS)+8*IOSHL3+4*IOSHL4) >1
        ISTRN=1;
    else
        ISTRN=0;
    end
   
end
%
if ISTRN==0 && NELT>0
    if NV3DT-MAXINT*(6*IOSHL1+IOSHL2+NEIPS) > 1
        ISTRN=1;
    else
        ISTRN=0;
    end
end
%
% this is from database manual for d3thdt:
if NSTS>0
    ISTRN=0;
    if NV2D-MAXINT*(6*IOSHL1+IOSHL2+NEIPS)+8*IOSHL3+4*IOSHL4 >10
        ISTRN=1;
    end
end
%
if NSTT>0
    ISTRN=0;
    if NV3DT-MAXINT*(6*IOSHL1+IOSHL2+NEIPS) >10
        ISTRN=1;
    end
end
% ========= end of calculating ISTRN based on d3thdt manual
if ISTRN==1 && NEIPH>6 
    SOLID_STRAIN_FLAG=1; %the last additional 6 values in element data are the 6 components of strain.
end
%
FLAG_SOLID_SHELL_PLASTIC_STRAIN=FLAG3_IDTDT; %flag for solid and shell plastic strain "tensor", i.e. with 6 components
FLAG_THERMAL_STRAIN=FLAG4_IDTDT;
FLAG_SOLID_TOTAL_STRAIN=ISTRN; 
%
NEIPH_IDX=[6*IOSOL1+1*IOSOL2+1:6*IOSOL1+1*IOSOL2+NEIPH];
NEIPH_NO_STRAIN_IDX=NEIPH_IDX(1:end-(6*(FLAG_SOLID_TOTAL_STRAIN+FLAG_SOLID_SHELL_PLASTIC_STRAIN+FLAG_THERMAL_STRAIN)));
%
EXTRA_DATA_ALE=0;
EXTRA_DATA_ALE_LABEL=strings();
if NUMFLUID~=0
    EXTRA_DATA_ALE=1+abs(NUMFLUID)+1; 
    EXTRA_DATA_ALE_LABEL=["rho","vol_frac_mat"+(1:abs(NUMFLUID)),"dom_mat_id"]';
    if NUMFLUID<0
        EXTRA_DATA_ALE=EXTRA_DATA_ALE+abs(NUMFLUID); 
        EXTRA_DATA_ALE_LABEL(end+1:end+abs(NUMFLUID))=["mass_mat"+(1:abs(NUMFLUID))]';
    end
end
%
% Variable    |    D e s c r i p t i o n
%=============|=========================================================
% NDIM        |  Number of dimensions of analysis in database
% NUMNP       |  Total number of nodes
% NGLBV       |  Total number of global variables in each state (output time step)
% IT          |  Flag for temperature values (>=1 outputted, 0=not outputted)
% IU          |  Flag for current coordinate values (=1 outputted, 0=not outputted)
% IV          |  Flag for velocity
% IA          |  Flag for acceleration
% NEL8        |  Total number of 8-noded solid element (if <0, extra nodes are outputted for 10-noded elements, NUM_EX_NEL8 =1
% NUMMAT8     |  Total number of materials (parts) which the 8-noded elements are using
% NV3D        |  Total number of values for each 8-noded solid element (these are rows in ELEDATA for the solids)
% NEL4        |  Total number of 4-noded shell elements
% NUMMAT4     |  Total number of materials (parts) using 2d or 3d 4-N shells
% NV2D        |  Total number of values in database for 4-noded shells
% NEIPH       |  Total number of additional values for each extra integration point in solid elements
% NEIPS       |  Number of additional values per integration point to be written into database type 6 (i.e. when INUM=6, "blstfor") for shell elements
% MAXINT      |  Number of integration points for each shell element
% NARBS       |  Total entries that define the user numbering system for nodes, elements, materials, etc
% NELT        |  Total number of thick shell elements (8-noded solid shells, note this is different from thin shells with 8 nodes added for quadratic interpolation, i.e. the 8 noded thick shells are still linear)
% NUMMATT     |  Total number of materials (parts) using thick shell elements
% NV3DT       |  Total number of values to be written in database for each thick shell element
% IOSHL1      |  Flag of the six components of stress
% IOSHL2      |  Flag of plastic strain 
% NMMAT       |  Total number of materials (parts)
% IDTDT       |  Flags for temperature rate, residual forces and moments, plastic strain tensor, thermal strain tensor, ISTRN
% EXTRA       |  Total number of extra control data to take address from 64:73
%             |  ... these extra control data are for higher order elements if they are present, e.g. NEL20 for number of 20 noded solid elements, etc
%=======================================================================
%
%%
if EXTRA>0
    fileID=fopen(filename1,"r");
    fseek(fileID,offset,origin);
    precision="int";
    EXTRA_CONTROL_DATA=(64:79)';
    EXTRA_CONTROL_DATA(:,2)=fread(fileID,(79-64+1)',precision);
    EXTRA_CONTROL_DATA_NO_NEED=fread(fileID,(EXTRA-size(EXTRA_CONTROL_DATA,1))',precision); %void space!
    offset=ftell(fileID);
    EXTRA_CDATA=num2cell(EXTRA_CONTROL_DATA);
    frewind(fileID);
    fclose(fileID);
    %
    Address_extra1=[67]; Address_extra1=Address_extra1-64+1;
    [NEIPB]=EXTRA_CDATA{Address_extra1,2};
    %
    if INUM==3
        EXTRA_CDATA_D3THDT=num2cell([EXTRA_CONTROL_DATA(:,2);EXTRA_CONTROL_DATA_NO_NEED]);
        Address_extra2=[59,60,61,62,63];
        Address_extra2= Address_extra2+1; %for d3thdt
        [IFLAGD2,NSTH2,NSTB2,NSTS2,NSTT2]=EXTRA_CDATA_D3THDT{Address_extra2,1};
        if (IFLAGD2-1000)~=NDS && (IFLAGD2-1000)~=0
            warning(sprintf('from %s():\n\tNDS at location 25 in CDATA is NOT the same as in location 59 in EXTRA_CDATA_D3THDT\n',mfilename()));
        end
        %
        if NSTH2~=NSTH && NSTH2~=0
            warning(sprintf('from %s():\n\tNSTH at location 60 in CDATA is NOT the same as in location 60 in EXTRA_CDATA_D3THDT. NSTH reset to %.0f\n',mfilename(),NSTH2));
            NSTH=NSTH2;
        end
        %
        if NSTB2~=NSTB && NSTB2~=0
            warning(sprintf('from %s():\n\tNSTH at location 61 in CDATA is NOT the same as in location 61 in EXTRA_CDATA_D3THDT. NSTB reset to %.0f\n',mfilename(),NSTB2));
            NSTB=NSTB2;
        end
        %
        if NSTS2~=NSTS && NSTS2~=0
            warning(sprintf('from %s():\n\tNSTS at location 62 in CDATA is NOT the same as in location 62 in EXTRA_CDATA_D3THDT. NSTS reset to %.0f\n',mfilename(),NSTS2));
            NSTS=NSTS2;
        end
        %
        if NSTT2~=NSTT && NSTT2~=0
            warning(sprintf('from %s():\n\tNSTT at location 63 in CDATA is NOT the same as in location 63 in EXTRA_CDATA_D3THDT. NSTT reset to %.0f\n',mfilename(),NSTT2));
            NSTT=NSTT2;
        end
    end
else
    NEIPB=0;
end
%
BEAMIP=(NV1D-6-NEIPB*3)/(5+NEIPB); %no. of through-thickness integration points at each of which there will be 5+NEIPB data written in element data
%
NEIPB_IDX=[];
if NEIPB>0
    NEIPB_IDX=[6+5*BEAMIP+NEIPB*3+1:NV1D];
end
%
%=====================================================================
fileID=fopen(filename1,"r");
fseek(fileID,offset,origin);
precision="int";
sizeA=[2,NDS];
NDSB=fread(fileID,sizeA,precision); %node blocks for which time history are output, the locations 2n-1 correspond to first node in block and 2n correspond to last node in block, n=1:NDS
%
sizeA=[2,NSTH];
NSTHB=fread(fileID,sizeA,precision); %solid element blocks start and end numbers. Defined as for NDS above, here n=1:NSTH
%
sizeA=[2,NSTB];
NSTBB=fread(fileID,sizeA,precision); %beam element blocks start and end numbers. Defined as for NDS above, here n=1:NSTH
%
sizeA=[2,NSTS];
NSTSB=fread(fileID,sizeA,precision); %(thin) shell element blocks start and end numbers. Defined as for NDS above, here n=1:NSTH
%
sizeA=[2,NSTT];
NSTTB=fread(fileID,sizeA,precision); %thick shell element blocks start and end numbers. Defined as for NDS above, here n=1:NSTH
%
sizeA=[2,NSTP];
NSTPB=fread(fileID,sizeA,precision); %SPH element blocks start and end numbers. Defined as for NDS above, here n=1:NSTH
offset=ftell(fileID);
frewind(fileID);
fclose(fileID);
%
if MATTYP>0 && INUM ~= 3
    offset=offset+(1+1+NUMMAT)*word_length;
end
%
FLUIDID=[];
if IALEMAT>0 && INUM ~=3
    fileID=fopen(filename1,"r");
    fseek(fileID,offset,origin);
    precision="int";
    FLUIDID=fread(fileID,IALEMAT,precision)'; 
    offset=offset+(IALEMAT)*word_length;
end
%
if NMSPH>0
    if INUM==1
        offset=offset+(11+1+1+6+1+1+1+1+6+1+1)*word_length;
    elseif INUM==3
        offset=offset+(10+1+1+6+1+1+1+1+12+1)*word_length;
    end
end    
%
NPEFG=0;
if NPEFG>0 && INUM ~=3
    % populate if you have airbag particles data
    %
    % or skip:
    %cannot be skipped without actually reading it
    databaseProblem='airbag particles';
    warning('Warning from "%s()":\n\tModel in "%s" contains %s data\n\twhich the script is not comaptible with. code edit is required!\n\thelp is available at: %s',mfilename(),filename1,databaseProblem,lsdyna_database_manual);
    control.completion_flag=false;
    return;
end
%
%%
% GEOMETRY DATA
fileID=fopen(filename1,"r");
fseek(fileID,offset,origin);
precision="float";
X=fread(fileID,[NDIM,NUMNP],precision); % array of nodal coordinates
precision="int";
IX8=fread(fileID,[9,NEL8],precision); % connectivity and material number for each 8-node solid elements
%last row in IX8 is material number
%
IS_NEIPH_ALE=false;
if NEL8>0
    if ~isempty(FLUIDID)
        if any(any(IX8(end,:)'==FLUIDID))
            %last NEIPH data is ALE data
            IS_NEIPH_ALE=true;
        end
    end
end
%
if FLAG_EXTRA_NEL8==1 && INUM ~=3
    %if higher order solid elements are used (e.g. 20 noded bricks)
    IX8(end+1:end+2,:)=fread(fileID,[2,NEL8],precision);
end
%
if NELT>0
    %for 8-thick shell
    IXT=fread(fileID,[9,NELT],precision);
else
    IXT=[];
end
%
if NEL2>0
    %for beam
    IX2=fread(fileID,[6,NEL2],precision);
else
    IX2=[];
end
%
IS_NEIPS_ALE=false;
if NEL4>0
    %for 4-N shell
    IX4=fread(fileID,[5,NEL4],precision); %connectivity and material number for each 4 noded shell element
    %last row is material number
    if ~isempty(FLUIDID)
        if any(any(IX4(end,:)'==FLUIDID))
            IS_NEIPS_ALE=true;
        end
    end
else
    IX4=[];
end
offset=ftell(fileID);
%
frewind(fileID);
fclose(fileID);
%
NUM_NEIPH_NOT_ALE=NEIPH;
NEIPH_ALE_IDX=[];
if IS_NEIPH_ALE==true
    NUM_NEIPH_NOT_ALE=NEIPH-EXTRA_DATA_ALE;
    NEIPH_ALE_IDX=NEIPH_IDX(NUM_NEIPH_NOT_ALE+1:end);
end
%
NUM_NEIPS_NOT_ALE=NEIPS;
NEIPS_ALE_IDX=[];
if IS_NEIPS_ALE==true
    NUM_NEIPS_NOT_ALE=NEIPS-EXTRA_DATA_ALE;
    NEIPS_ALE_IDX=NEIPS_IDX(NUM_NEIPS_NOT_ALE+1:end);
end
%
% ============solid
SIG_LABEL=["sig_xx","sig_yy","sig_zz","sig_xy","sig_yz","sig_zx"]';
EPS_LABEL=["eps_xx","eps_yy","eps_zz","eps_xy","eps_yz","eps_zx"]';
NEIPH_LABEL="extra_hist_var"+(1:NEIPH)';
if ISTRN==1 && NEIPH>=6
    NEIPH_LABEL(end-5*ISTRN:end)=EPS_LABEL;
end
EFF_EPS_LABEL="plastic_eps";
%
SOLID_ELEM_DATA_LABEL_0=[SIG_LABEL(1:6*IOSOL1);EFF_EPS_LABEL(1:1*IOSOL2);NEIPH_LABEL(1:NEIPH)];
SOLID_GAUSS_PTS_NUM=1;
if NV3D>=8*(6*IOSOL1+1*IOSOL2+NEIPH)
    SOLID_GAUSS_PTS_NUM=floor(NV3D/(6*IOSOL1+IOSOL2+NEIPH));
end
SOLID_ELEM_DATA_LABEL=strings();
for j0=1:SOLID_GAUSS_PTS_NUM
    SOLID_ELEM_DATA_LABEL=[SOLID_ELEM_DATA_LABEL;SOLID_ELEM_DATA_LABEL_0+"_gp"+j0];
end
SOLID_ELEM_DATA_LABEL(1)=[];
if ~isempty(NEIPH_ALE_IDX)
SOLID_ELEM_DATA_LABEL(NEIPH_ALE_IDX)=EXTRA_DATA_ALE_LABEL(:);
end
%
%============= thin shell
SHELL_RESULTANT_LABEL=["moment_x","moment_y","moment_xy","shear_x","shear_y","normal_x","normal_y","shear_xy"]';
SHELL_SECTION_LABEL=["thickness","null_1","null_2","internal_energy"]';
NEIPS_LABEL="extra_hist_var"+(1:NEIPS)';
SHELL_ELEM_DATA_LABEL_0=[SIG_LABEL(1:6*IOSHL1);EFF_EPS_LABEL(1:IOSHL2);NEIPS_LABEL];
SHELL_ELEM_DATA_LABEL=strings();
for j0=1:MAXINT
    SHELL_ELEM_DATA_LABEL=[SHELL_ELEM_DATA_LABEL;SHELL_ELEM_DATA_LABEL_0+"_ip"+j0];
end
SHELL_ELEM_DATA_LABEL(1)=[];
SHELL_ELEM_DATA_LABEL=[SHELL_ELEM_DATA_LABEL;SHELL_RESULTANT_LABEL(1:8*IOSHL3);SHELL_SECTION_LABEL(1:3*IOSHL4)];
if NV2D>MAXINT*(6*IOSHL1+IOSHL2+NEIPS)+8*IOSHL3+4*IOSHL4
    ISTRN_SHELL=1;
elseif IDTDT>100 
    ISTRN_SHELL=FLAG5_IDTDT;
else
    ISTRN_SHELL=0;
end
SHELL_ELEM_DATA_LABEL=[SHELL_ELEM_DATA_LABEL;EPS_LABEL(1:6*ISTRN_SHELL)+"_outer_surface";EPS_LABEL(1:6*ISTRN_SHELL)+"_inner_surface"];
SHELL_ELEM_DATA_LABEL=[SHELL_ELEM_DATA_LABEL;SHELL_SECTION_LABEL(4:4*IOSHL4)];
if ~isempty(NEIPS_ALE_IDX)
SHELL_ELEM_DATA_LABEL(NEIPS_ALE_IDX)=EXTRA_DATA_ALE_LABEL;
end
%
%============ beam
% 
BEAM_RESULTANT_LABEL=["normal","shear_s","shear_t","moment_s","moment_t","torsion"]';
BEAM_SIG_LABEL=["sig_rs","sig_rt","sig_rr","plastic_eps","eps_rr"]';
NEIPB_LABEL="extra_hist_var"+(1:NEIPB)';
BEAM_ELEM_DATA_LABEL_0=[BEAM_RESULTANT_LABEL];
BEAM_ELEM_DATA_LABEL=BEAM_ELEM_DATA_LABEL_0;
for j0=1:BEAMIP
    BEAM_ELEM_DATA_LABEL=[BEAM_ELEM_DATA_LABEL;BEAM_SIG_LABEL+"_ip"+j0];
end
BEAM_ELEM_DATA_LABEL=[BEAM_ELEM_DATA_LABEL;NEIPB_LABEL+"_avg";NEIPB_LABEL+"_min";NEIPB_LABEL+"_max"];
for j0=1:BEAMIP
    BEAM_ELEM_DATA_LABEL=[BEAM_ELEM_DATA_LABEL;NEIPB_LABEL+"_ip"+j0];
end
%
%=========== tshell
if NELT>0 && NV3DT>MAXINT*(6*IOSHL1+IOSHL2+NEIPS)
    ISTRN_TSHELL=1;
elseif IDTDT>100 
    ISTRN_TSHELL=FLAG5_IDTDT;
else
    ISTRN_TSHELL=0;
end
TSHELL_ELEM_DATA_LABEL=strings(NV3DT,1);
TSHELL_D0=6*IOSHL1+1*IOSHL2+NEIPS;
for j0=1:MAXINT
TSHELL_ELEM_DATA_LABEL((j0-1)*TSHELL_D0+1:(j0-1)*TSHELL_D0+6*IOSHL1)=SIG_LABEL+"_ip"+j0;
TSHELL_ELEM_DATA_LABEL((j0-1)*TSHELL_D0+6*IOSHL1+1:(j0-1)*TSHELL_D0+6*IOSHL1+1*IOSHL2)=EFF_EPS_LABEL+"_ip"+j0;
TSHELL_ELEM_DATA_LABEL((j0-1)*TSHELL_D0+6*IOSHL1+1*IOSHL2+1:(j0-1)*TSHELL_D0+6*IOSHL1+1*IOSHL2+NEIPS)=NEIPS_LABEL+"_ip"+j0;
end
if ISTRN_TSHELL==1
    TSHELL_ELEM_DATA_LABEL(MAXINT*TSHELL_D0+1:end)=[EPS_LABEL+"_inner_surface";EPS_LABEL+"_outer_surface"];
end
num_null_tshell=length(TSHELL_ELEM_DATA_LABEL(TSHELL_ELEM_DATA_LABEL==""));
null_tshell_label="null_"+(1:num_null_tshell)';
TSHELL_ELEM_DATA_LABEL(TSHELL_ELEM_DATA_LABEL=="")=null_tshell_label;
%
c0_8N=["coord_x_n","coord_y_n","coord_z_n","vel_x_n","vel_y_n","vel_z_n"]'+(1:8);
c0_4N=["coord_x_n","coord_y_n","coord_z_n","vel_x_n","vel_y_n","vel_z_n"]'+(1:4);
EXTRA_LABELS_D3THDT_SOLID=["n"+(1:8),c0_8N(:)']';
EXTRA_LABELS_D3THDT_TSHELL=["n"+(1:8),c0_8N(:)']';
EXTRA_LABELS_D3THDT_SHELL=["n"+(1:4),c0_4N(:)']';
%
if INUM==3
    SOLID_ELEM_DATA_LABEL=[EXTRA_LABELS_D3THDT_SOLID;SOLID_ELEM_DATA_LABEL];
    SHELL_ELEM_DATA_LABEL=[EXTRA_LABELS_D3THDT_SHELL;SHELL_ELEM_DATA_LABEL];
    TSHELL_ELEM_DATA_LABEL=[EXTRA_LABELS_D3THDT_TSHELL;TSHELL_ELEM_DATA_LABEL];
elseif INUM==1
    SOLID_ELEM_DATA_LABEL=[SOLID_ELEM_DATA_LABEL;"mat_id"];
    SHELL_ELEM_DATA_LABEL=[SHELL_ELEM_DATA_LABEL;"mat_id"];
    BEAM_ELEM_DATA_LABEL=[BEAM_ELEM_DATA_LABEL;"mat_id"];
    TSHELL_ELEM_DATA_LABEL=[TSHELL_ELEM_DATA_LABEL;"mat_id"];
end
%
c0_mat=["internal_energy","kinetic_energy"]'+(["_mat"]+(1:NUMMAT));
c0_mat=c0_mat';
c0_mat=c0_mat(:);
c1_mat=["velocity_x","velocity_y","velocity_z"]'+(["_mat"]+(1:NUMMAT));
c1_mat=c1_mat(:);
c2_mat=[c0_mat;c1_mat];
GLOBAL_DATA_LABEL=["kinetic_energy","internal_energy","total_energy","velocity_x","velocity_y","velocity_z"]';
GLOBAL_DATA_LABEL=[GLOBAL_DATA_LABEL;c2_mat;"mass_mat"+(1:NUMMAT)';"hourglass_energy_mat"+(1:NUMMAT)'];
num_null=NGLBV-length(GLOBAL_DATA_LABEL);
GLOBAL_DATA_LABEL(end+1:NGLBV)="null_"+(1:num_null)';
%
if NARBS>0
    %if NSORT>0:
    %NARBS = 10+(NUMNP+NEL8+NEL2+NEL4+NELT+3*NUMMAT), and material numbering is not arbitrary (i.e. ordered in ascending order)
    %
    %if NSORT<0
    %NARBS = 16+(NUMNP+NEL8+NEL2+NEL4+NELT+3*NUMMAT), and material numbering IS arbitrary (i.e. NOT ordered in ascending order)
    % discard this note --> numbers in parantheses,i.e. NUMNP+...+3*NUMMAT, are not used if NSORT>0
    %
    %Important Note: in above, the key is the numbers 10 or 16, i.e. how many
    %control words to read; this depends on the first control word,
    %which is "NSORT", if it is positive, then read (10-1) extra
    %control words. But, if NSORT is negative, then read (16-1) extra
    %control words. Note: the 1 that is subtracted is because the first
    %word, which is NSORT, is already being read.
    %
    fileID=fopen(filename1,"r");
    precision="int";
    fseek(fileID,offset,origin);
    NSORT=fread(fileID,1,precision);
    num_words=9;
    if NSORT<0
        num_words=num_words+6; %to additionally read: NSRMA, NSRMU, NSRMP, NSRTM, NUMRBS, NMMAT
    end
    NARBS_CONTROL_DATA=fread(fileID,num_words,precision);
    %
    NSRH=NARBS_CONTROL_DATA(1); %pointer to arbitrary solid element numbers (=NSORT+NUMNP)
    NSRB=NARBS_CONTROL_DATA(2); %pointer to arbitrary beam element numbers (=NSORT+NUMNP+NEL8)
    NSRS=NARBS_CONTROL_DATA(3); %pointer to arbitrary (thin) shell element numbers (=NSORT+NUMNP+NEL8+NEL2)
    NSRT=NARBS_CONTROL_DATA(4); %pointer to arbitrary thick shell element numbers (=NSORT+NUMNP+NEL8+NEL2+NEL4)
    %
    NSORTD=NARBS_CONTROL_DATA(5); %number of nodal points (NSORTD in ls-dyna database manual)
    NSORTH=NARBS_CONTROL_DATA(6); %number of 8-N solid elements (NSRHD in ls-dyna database manual)
    NSORTB=NARBS_CONTROL_DATA(7); %number of 2-N beam elements (NSRBD in ls-dyna database manual)
    NSORTS=NARBS_CONTROL_DATA(8); %number of 4-N shell elements (NSRSD in ls-dyna database manual)
    NSORTT=NARBS_CONTROL_DATA(9); %number of 8-N thick shell elements (NSRTD in ls-dyna database manual)
    if NSORT<0
        NSRMA=NARBS_CONTROL_DATA(10);
        NSRMU=NARBS_CONTROL_DATA(11);
        NSRMP=NARBS_CONTROL_DATA(12);
        NSRTM=NARBS_CONTROL_DATA(13);
        NUMRBS=NARBS_CONTROL_DATA(14);
        NMMAT=NARBS_CONTROL_DATA(15);
    else
        NSRMA=[];
        NSRMU=[];
        NSRMP=[];
        NSRTM=[];
        NUMRBS=[];
        NMMAT=[];
    end
    NUSERN=fread(fileID,[1,NSORTD],precision); %array of user defined node numbers
    NUSERH=fread(fileID,[1,NSORTH],precision); %array of user defined solid element numbers
    NUSERB=fread(fileID,[1,NSORTB],precision); %array of user defined beam element numbers
    NUSERS=fread(fileID,[1,NSORTS],precision); %array of user defined shell element numbers
    NUSERT=fread(fileID,[1,NSORTT],precision); %array of user defined thick shell element numbers
    NORDER=fread(fileID,[1,NUMMAT],precision);  %ordered array of user defined material (part) id's
    NSRMU=fread(fileID,[1,NUMMAT],precision);   %unordered array of suer material (part) id's
    NSRMP=fread(fileID,[1,NUMMAT],precision);   %cross reference array
    offset=ftell(fileID);
    frewind(fileID);
    fclose(fileID);
else
    NUSERN=1:NUMNP;
    NUSERH=1:NEL8;
    NUSERT=1:NELT;
    NUSERS=1:NEL4;
    NUSERB=1:NEL2;
end
%%
FLAG_RIGID_BODY=0;
if FLAG_RIGID_BODY>0 && INUM ~=3
    %fill if you have rigid bodies in the model
    %
    %or skip:
    %cannot skip without reading the first words here
    databaseProblem='rigid bodies';
    warning('Warning from "%s()":\n\tModel in "%s" contains %s data\n\twhich the script is not comaptible with. code edit is required!\n\thelp is available at: %s',mfilename(),filename1,databaseProblem,lsdyna_database_manual);
    control.completion_flag=false;
    return;
end
%
NADAPT=0;
if NADAPT>0 && INUM ~=3
    %fill if you have H-type shell element adaptivity
    %
    %or skip:
    offset=offset+(2*NADAPT)*word_length;
end
%
NUMSPH=0;
if NMSPH>0 && INUM ~=3
    %fill if you have Smooth particle Hydrodynamic nodes 
    %
    %or skip
    offset=offset+(2*NUMSPH)*word_length;
end
%
if NPEFG>0 && INUM ~=3
    %fill if you have Airbag particles in the model
    %
    %or skip:
    %cannot skip without actually have a variable called NGEOM from 
    %pevious airbag control data
    databaseProblem='airbag particles';
    warning('Warning from "%s()":\n\tModel in "%s" contains %s data\n\twhich the script is not comaptible with. code edit is required!\n\thelp is available at: %s',mfilename(),filename1,databaseProblem,lsdyna_database_manual);
    control.completion_flag=false;
    return;
end
%
FLAG_RIGID_ROAD_SURFACE=0;
if FLAG_RIGID_ROAD_SURFACE==1 && INUM ~=3
    % fill if you have rigid road surfaces in model
    %
    %or skip:
    %cannot skip without actually reading the first few data here
    databaseProblem='rigid road surfaces';
    warning('Warning from "%s()":\n\tModel in "%s" contains %s data\n\twhich the script is not comaptible with. code edit is required!\n\thelp is available at: %s',mfilename(),filename1,databaseProblem,lsdyna_database_manual);
    control.completion_flag=false;
    return;
end
%
if FLAG_EXTRA_NEL8==1 && INUM ~=3
    fileID=fopen(filename1,"r");
    precision="int";
    fseek(fileID,offset,origin);
    IX8(end+1:end+2,:)=fread(fileID,[2,NEL8],precision);
    offset=ftell(fileID);
    frewind(fileID);
    fclose(fileID);
end
%
NEL48=0;
if EXTRA>0 && NEL48>0 && INUM ~=3
    %fill if you have extra 4 nodes for 4-noded shells, i.e. thin shell with 8-nodes 
    %or skip:
    offset=offset+(5*NEL48)*word_length;
end
%
NEL20=0;
if EXTRA>0 && NEL20>0 && INUM ~=3
    %fill if you have extra 20-noded solids
    %or skip:
    offset=offset+(13*NEL20)*word_length;
end
%
NEL27=0;
if EXTRA>0 && NEL27>0 && INUM ~=3
    %fill if you have extra 27-noded solids
    %or skip:
    offset=offset+(20*NEL27)*word_length;
end
%
NEL21P=0;
if EXTRA>0 && NEL21P>0 && INUM ~=3
    %fill if you have extra 21-noded solids
    %or skip:
    offset=offset+(14*NEL21P)*word_length;
end
%
NEL15T=0;
if EXTRA>0 && NEL15T>0 && INUM ~=3
    %fill if you have extra 15-noded solids
    %or skip:
    offset=offset+(8*NEL15T)*word_length;
end
%
NEL20T=0;
if EXTRA>0 && NEL20T>0 && INUM ~=3
    %fill if you have extra 20-noded solids
    %or skip:
    offset=offset+(13*NEL20T)*word_length;
end
%
% for binary files, e.g. "d3plot", after this point, LS-DYNA will write "part and model titles" here
% after the EOF (EOF=-999999.0) flag is reached 
% so if EOF is detected, we can skip the rest since no results or necessary control data will be given beyond this point
%
fileID=fopen(filename1,"r");
fseek(fileID,offset,origin);
precision="float";
b0=fread(fileID,1,precision);
% offset=ftell(fileID);
if b0==-999999.0
    exit_flag=true; %now, reading state data starts from the next d3thdt (the current control file does not have any state data, no data left)
    fprintf('###\nA message from "%s()":\n\tThe end of the root %s file "%s" is reached\n\tas (EOF=-999999.0) is detected. Reading completed, and file is closed.\n\tNo state data is contained in this just finished file.\n',mfilename(),databaseType,filename1);
end
frewind(fileID);
fclose(fileID);
if b0~=-999999.0
    offset_last=offset;
    fprintf('###\nA message from "%s()":\n\tThe current file: "%s" is NOT finished. Continue reading state data from this same file.\n\tAn exit flag "exit_flag" is set as "false" to indicate that.\n',mfilename(),filename1);
end
c=struct();
vars1={INUM,NDIM,NUMNP,NGLBV,IU,IV,IA};
vars2={NEL8,NV3D,NELT,NV3DT,NEL4,NV2D,NEL2,NV1D};
vars3={X,IX8,IXT,IX4,IX2};
vars4={NUSERN,NUSERH,NUSERT,NUSERS,NUSERB};
vars5={SOLID_ELEM_DATA_LABEL,TSHELL_ELEM_DATA_LABEL,SHELL_ELEM_DATA_LABEL,BEAM_ELEM_DATA_LABEL,GLOBAL_DATA_LABEL};
vars6={NEIPH_IDX,NEIPS_IDX,NEIPS_TSHELL_IDX,NEIPB_IDX,NEIPH_ALE_IDX,NEIPS_ALE_IDX};
vars7={EXTRA_DATA_ALE,EXTRA_DATA_ALE_LABEL};
vars8={NDS,IT,NCFDV1,NCFDV2};
vars9={NSTH,NSTT,NSTS,NSTB,NDSB,NSTHB,NSTTB,NSTSB,NSTBB};
vars10={offset_last,exit_flag,b0};

[c.INUM,c.NDIM,c.NUMNP,c.NGLBV,c.IU,c.IV,c.IA]=vars1{:};
[c.NEL8,c.NV3D,c.NELT,c.NV3DT,c.NEL4,c.NV2D,c.NEL2,c.NV1D]=vars2{:};
[c.X,c.IX8,c.IXT,c.IX4,c.IX2]=vars3{:};
[c.NUSERN,c.NUSERH,c.NUSERT,c.NUSERS,c.NUSERB]=vars4{:};
[c.SOLID_ELEM_DATA_LABEL,c.TSHELL_ELEM_DATA_LABEL,c.SHELL_ELEM_DATA_LABEL,c.BEAM_ELEM_DATA_LABEL,c.GLOBAL_DATA_LABEL]=vars5{:};
[c.NEIPH_IDX,c.NEIPS_IDX,c.NEIPS_TSHELL_IDX,c.NEIPB_IDX,c.NEIPH_ALE_IDX,c.NEIPS_ALE_IDX]=vars6{:};
[c.EXTRA_DATA_ALE,c.EXTRA_DATA_ALE_LABEL]=vars7{:};
[c.NDS,c.IT,c.NCFDV1,c.NCFDV2]=vars8{:};
[c.NSTH,c.NSTT,c.NSTS,c.NSTB,c.NDSB,c.NSTHB,c.NSTTB,c.NSTSB,c.NSTBB]=vars9{:};
[c.offset_last,c.exit_flag,c.b0]=vars10{:};
control=c; 
control.completion_flag=true;
return;
end