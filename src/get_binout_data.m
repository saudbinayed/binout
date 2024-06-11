function [binin]=get_binout_data(binout_filename)
%% What this does?
% This function reads all binary data from one or more LS-DYNA "binout" file(s) and retreive the data (LS-DYNA results), and 
% ... store them in a very organised (and self-explanatory) way as fields in the output structure (binin). The heiraracy of 
% ... the binout file is preserved.
% There is only one input arg and only one output arg.
% ======================================
%% Input:
% binout_filename = [string] name of root binout file (relative or absolute path). The root file is the first if there are more
% ... than one binout files.
% ======================================
%% Output:
% binin is struct scalar with fields like "matsum", "nodout", "elout",etc.
% Some fields have intermediate sub-fields under them.
% At some level you get 2 fields "data" and "meta":
% ... the "data" contains sub-fields named based on what they represent (mechanically, as given in the binout by lsdyna)
% ... the "meta" contains sub-fields named based on what they represent (from lsdyna)
% Example: binin.matsum has immediate fields: "data" and "meta"
% Example: binin.elout has (possibly) the intermediate fields: "solid","shell","thickshell","beam","solid_hist","shell_hist",
% ... and "thickshell_hist". The binin.elout.solid is the one that has the sub-fields "data" and "meta", and so on.
% ======================================
% If the directory containing the root binout file contains a root "d3plot" file, the function will auto detect it and read
% ... additional useful "control" data and append them to a field called "control" in the main binin struct. For example, the 
% ... the input mesh and element-node connectivity data are retrieved by this feature.
%========================================
%% Contributions: 
% Code is part of a PhD study at the Blast and Impact Engineering Reserach Group, the University of Sheffield (2024)
% Dr. Samuel E. Rigby (sam.rigby@sheffield.ac.uk / https://x.com/dr_samrigby)
% Saud A. E. Alotaibi (salotaibi2@sheffield.ac.uk / otaibi.28@qec.edu.sa / https://x.com/saudbinayed)
%========================================
% to debug: (1) comment first line of code, then (2) uncomment below
% clear;
% clc;
% binout_filename='OUT\SHELL_2DR_NU\SHELL_2DR_NU_5\shell_2dr_nu_7\binout'; %change to actual path of your binout file for debuging
%========================================
%
family=dir(binout_filename+"*");
folder0=string(family(1).folder);
family={family.name}';
family=sortrows(family,'ascend');
family=string(family);
%
dtype=["int8","int16","int32","int64","uint8","uint16","uint32","uint64","single","double"]; %order important!
dtypeDict=dictionary([1 2 3 4 5 6 7 8 9 10],dtype);
con_fac=[1,2,4,8,1,2,4,8,4,8]; %bytes per data_entry: (#bits/8) per data_entry
conFacDict=dictionary(dtype,con_fac);
clear dtype con_fac;
%
initSize=800;
stateLimMax=initSize;
tic;
%
% Looping through binout files
for j0=1:length(family)
    filename0=folder0+"\"+family(j0);
    fid=fopen(filename0,'r');
    fseek(fid,0,'eof');
    file_sz=ftell(fid);
    frewind(fid);
    fseek(fid,35,'bof');
    address=ftell(fid);
    pause(1/10000);
    %
    % Reading all data from this single binout:
    while address<file_sz 
        A0=fread(fid,1,'uint32');
        if A0==0
            fprintf(1,'running step size is zero. Serious problem. Breaking...\n')
            break;
        end
        A1=fread(fid,A0-4,'uint8');
        address=address+A0;
        A2=char(A1);
        if A1(9-4)==2 && (A1(10-4)==47 || all(A2(10-4:12-4)'=='../'))
            dir0=A2(10-4+1:end)';
            if startsWith(dir0,'./')
                dir0=A2(10-4:end)';
                refCounts=count(dir0,'../');
                for i0=1:refCounts
                    last_dir=last_dir(1:find(last_dir=='/',1,'last')-1);
                    dir0(1:3)=[];
                end
                dir0=[last_dir,'/',dir0];
            end
            last_dir=dir0;
            dir0=replace(dir0,'/','_0_'); %flatten nested structuring, to be undone at the end
            state=1;
            initQ=false;
            if endsWith(dir0,regexpPattern('d[0-9]{6}$'))
                state=str2double(dir0(end-5:end));
                dir0(end-6:end)=[];
                dir0=[dir0,'data'];
                binin.(dir0).state_max=state;
                if state==1 || state==stateLimMax
                    initQ=true;
                    if state==stateLimMax
                        stateLimMax=stateLimMax+initSize;
                    end
                end
            end
            A0=fread(fid,1,'uint32');
            A1=fread(fid,A0-4,'uint8');
            A2=char(A1);
            address=address+A0;
        end                    
        typ=A1(10-4);
        len=A1(11-4);
        field=char(A1(12-4:12-4+len-1))';
        data=A1;
        if typ==1
            data=A2;
            binin.(dir0).(field)(state,:)=data(12-4+len:end)';
        elseif typ<11
            prec=dtypeDict(typ);
            if initQ==true
                binin.(dir0).(field)(state:stateLimMax,:)=zeros(initSize,length(data(12-4+len:end))/conFacDict(prec),prec);
            end
            binin.(dir0).(field)(state,:)=typecast(uint8(data(12-4+len:end)),prec);
        elseif typ==11
            fprintf('link\n');
        end
    end
    frewind(fid);
    fclose(fid); % reading from current binout file is finished
    if j0<length(family)
        fprintf(1,"Message from %s():\n\tRead finished from file [%.0f/%.0f]:\n\t""%s"".\n\tFile is closed. Next binout file will be read...\n",mfilename(),j0,length(family),filename0);
    else
        fprintf(1,"Message from %s():\n\tRead finished from file [%.0f/%.0f]:\n\t""%s"".\n\tFile is closed. This is last file. \n\tAll data reading completed. Done!\n",mfilename(),j0,length(family),filename0);
    end
end
% Reading from all binout files is done.
%
toc;
fields=fieldnames(binin);
for j1=1:length(fields)
    dir0=fields{j1};
    if ~endsWith(dir0,'_0_data')
        continue;
    end
    subfields=fieldnames(binin.(dir0));
    for j2=1:length(subfields)
        field0=subfields{j2};
        if field0~="state_max"
            binin.(dir0).(field0)(binin.(dir0).state_max+1:end,:)=[];
            binin.(dir0).(field0)=double(binin.(dir0).(field0));
        end
    end
end
%
% Re-doing the nesting (making sub-directories to parent directory):
for j1=1:length(fields)
    dir0=fields{j1};
    if contains(dir0,'_0_')
        subfields=split(dir0,'_0_');
        binin=setfield(binin,subfields{:},binin.(dir0));
        binin=rmfield(binin,dir0);
    end
end
%
% Getting "control" data from a root "d3plot" file (if present):
word_length=4; % 4 bytes per word, assuming the root d3plot file was generated by LS-DYNA "single" precision solver. Change to 8 for 
% ... files written by the "double" precision solver. 
d3plot0_filename=[erase(char(binout_filename),'binout'),'d3plot']; %Assuming the root d3plot file is named "d3plot" (i.e., without file extension)
if exist(d3plot0_filename,'file')~=0
[control]=get_d3plot_d3thdt_control_data(d3plot0_filename,word_length);
if control.completion_flag==true
binin.control.initial=struct('x_coordinate',control.X(1,:),'y_coordinate',control.X(2,:),'z_coordinate',control.X(3,:),'info','cols->sorted node id');
binin.control.connec=struct('solid',control.IX8,'shell',control.IX4,'tshell',control.IXT,'beam',control.IX2,'info','rows->local sorted node id, cols->sorted elem id. last row is part id. row=[4,5] for beam are null (ignored)');
binin.control.id=struct('node',control.NUSERN,'solid',control.NUSERH,'shell',control.NUSERS,'tshell',control.NUSERT,'beam',control.NUSERB,'info','user_id_given, cols->sorted (node or elem) id');
binin.control.stat=struct('num_nodes',control.NUMNP,'num_solid_elem',control.NEL8,'num_shell_elem',control.NEL4,'num_tshell_elem',control.NELT,'num_beam_elem',control.NEL2);
end
end
return;
end