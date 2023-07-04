function [figParents,figSelect]=struct2graph(binin,labelQ,iterMax)
%% What this does?
% This function produces figures displaying the heiraracical graphs of a (possibly nested) MATLAB structure (struct) based on its fields and 
% ... the fields of its children (the sub-structures). The nesting of the main structure can be of any depth. The function return the handles of 
% ... these figures so that the caller can make final adjustements before printing to pdf or svg if necessary.
% ===============
%% Input:
% binin = [Required] scalar structure of type [struct] whose content to be visually displayed in graphs. Generally,  binin is nested structure (i.e 
% ... binin is a structure of sub-structures to arbitrary depth).
% labelQ = [Optional] array of labels of type [string] of main fields in the "binin" structure whose subgraphs to be generated in seperate figures.
% ... labelQ can be provided as "All" (case insensitive) so that every main fields get displayed in seperate subgraph. If labelQ is omitted, it defaults to "All".
% iterMax = [Optional] maximum number of iterations to be not exceeded during the recursive process in detecting the heiraracy of the nested structure "binin".
% ... If iterMax is omitted, it defaults to 400.
% ===============
%% Output:
% figAll = handle to the figrue containing the most overall graph (the big graph). For visual reasons, this graph layout is set as "force" (similar to neural networks)
% figParents = handle to the figure containing the most overall graph (similar to above) but without terminal leaves, i.e. only parents are shown
% figSelect = (possibly array of) handles to figures containing the subgraphs requested by "labelQ". If labelQ=="All", then figSelect is array of all sub-graphs
% ==============
%% Contributions: 
% Code is part of a PhD study at the Blast and Impact Reserach Group, the University of Sheffield (2023)
% Dr. Samuel E. Rigby (sam.rigby@sheffield.ac.uk)
% Saud A. E. Alotaibi (salotaibi2@sheffield.ac.uk)
% ==============
%% Note:
% customisations are optimised to produce graphically neat and compact graphs, with as minimum white space as possible.
% ... so that one can directly print the figures to pdf (using exportgraphics()) or svg (using print()) with minimal final adjustments.
% ===============

grootStyle=get(0,'defaultFigureWindowStyle');
set(0,'defaultfigurewindowstyle','normal');
varName=inputname(1);
baseStruc.(varName)=binin;
struc=baseStruc;
parentLabel={''};
done={};
%
%
if nargin<2
    labelQ="All";
end
if nargin<3
iterMax=400;
end
iter=0;
j=0;
stDict=dictionary();
source=[];
target=[];
while isstruct(struc) && iter<=iterMax
    iter=iter+1;
    j=j+1;
fields=append(parentLabel,fieldnames(struc));
field=fields(find(~ismember(fields,done),1,'first'));
labels(j,1)=string(extract(field,regexpPattern('(?<=\.?)\w+$')));
stDict(string(field))=j;
longLabels(j,1)=string(field);
if j>1
source(j,1)=stDict(string(parentLabel{1}(1:end-1)));
target(j,1)=stDict(string(field));
end
fieldsSeq=split(field,'.');
struc=getfield(baseStruc,fieldsSeq{:});
parentLabel=append(join(fieldsSeq,'.'),'.');
done(end+1)=field;
if ~isstruct(struc)
    field=[];
    while isempty(field) && length(fieldsSeq)>1
        fieldsSeq(end)=[];
        struc=getfield(baseStruc,fieldsSeq{:});
        parentLabel=append(join(fieldsSeq,'.'),'.');
        fields=append(parentLabel,fieldnames(struc));
        field=fields(find(~ismember(fields,done),1,'first'));
    end
    if length(fieldsSeq)==1 && isempty(field)
        fprintf(1,'end of chain reached, normal termination\n');
        break;
    end
end
end
if iter==iterMax
    fprintf(1,'A message from "%s":\n\tRecursion stopped because number of iterations reached the iterMax=%d.\n\tConsider supplying a bigger (integer) number as the third input argumnet.\n',mfilename(),iterMax);
end
source=source(2:end); target=target(2:end);
%
%
G=graph(source,target);
snId=unique(source);
% figure(1); clf; cla;
% fig=gcf;
% set(fig,'defaultfigurewindowstyle','modal');
% fig.Units='centimeters';
% fig.Position=[10 10 10 10];
% ax=gca;
% ax.Position=[0 0 1 1];
% pg=plot(G);
% pg.layout("force","UseGravity","on","WeightEffect","direct","Iterations",150);
% pg.NodeLabel(1:G.numnodes)={''};
% snId=unique(source);
% x=pg.XData;
% y=pg.YData;
% set(ax,'defaulttextInterpreter','none','defaulttextfontname','Lucida Console','defaulttextfontsize',6);
% pg.NodeLabel(snId)=cellstr(labels(snId));
% pg.NodeFontName='Lucida Console';
% seId=find(ismember(G.Edges.EndNodes(:,2),snId));
% pg.NodeColor=repmat(pg.NodeColor,G.numnodes,1);
% pg.NodeColor(snId,:)=repmat([0.8500,0.3250,0.0980],length(snId),1);
% pg.EdgeColor=repmat(pg.EdgeColor,G.numedges,1);
% pg.EdgeColor(seId,:)=repmat([0.8500,0.3250,0.0980],length(seId),1);
% figAll=fig;
% figAll.Name="All in "+inputname(1);
%
%
%
G2=G.subgraph(snId);
labels2=labels(snId);
figure(1); clf; cla;
fig=gcf;
set(fig,'defaultfigurewindowstyle','modal');
ax=gca;
fig.Units='centimeters';
fig.Position=[4 10 14 5];
ax.Position=[0 0 1 1];
pg2=plot(G2);
pg2.layout("layered","Direction","down");
pg2.NodeLabel=[];
pg2.set('EdgeColor','k','NodeColor','k','MarkerSize',2.5);
x2=pg2.XData;
y2=pg2.YData;
snId2=unique(G2.Edges.EndNodes(:,1));
set(ax,'defaulttextInterpreter','none','defaulttextfontname','Lucida Console','defaulttextfontsize',8);
set(ax,'defaultaxesunits','normalized','defaultaxesposition',[0 0 1 1]);
te2=text(x2,y2,labels2,'HorizontalAlignment','center','VerticalAlignment','middle','EdgeColor','k','LineWidth',0.08,'BackgroundColor',0.95*[1 1 1],'Margin',1);
% te2=text(x2,y2,labels2,'HorizontalAlignment','center','VerticalAlignment','middle','EdgeColor','none','BackgroundColor','none');
% iterMax=4;
% for i=1:iterMax
[y2unq,~,y2unqidx]=unique(y2);
y2crit=y2unq(floor(mode(y2unqidx)));
y2idx=find(y2==y2crit);
te2Extent=cell2mat(arrayfun(@(x) x.Extent,te2,'UniformOutput',false));
xlim([min(x2'-te2Extent(:,3)/2) max(x2'+te2Extent(:,3)/2)]);

gmin=-Inf;
iter=0;
iterMax=20;
while gmin<0.2 && iter<=iterMax
    iter=iter+1;
    %fig.Position(3)=1.2*fig.Position(3);
    fig.Position(3)=fig.Position(3)+2;
    te2LW=cell2mat(arrayfun(@(x) x.Extent([1,3]),te2(y2idx),'UniformOutput',false));
    gaps2=te2LW(2:end,1)-sum(te2LW(1:end-1,:),2);
    [gmin,gidx]=min(gaps2);
end
% xmax2=max(max(x2),max(te2Extent(:,1)+2*te2Extent(:,3)));
% xmin2=min(min(x2),min(te2Extent(:,1)-te2Extent(:,3)));
% ymin2=min(min(y2),min(te2Extent(:,2)-te2Extent(:,4)/1));
% ymax2=max(max(y2),max(te2Extent(:,2)+2*te2Extent(:,4)/1));
% xlim([xmin2 xmax2]);
% ylim([ymin2 ymax2]);
% end
figParents=fig;
figParents.Name="Parents in "+inputname(1);
%
%
%
if length(labelQ)==1 && strcmpi(labelQ,"all")
    labelQ=string(fieldnames(binin));
end
for j=1:length(labelQ)
    if ~ismember(labelQ(j),string(fieldnames(binin)))
        warning('"%s" is not part of the %s struct. Empty graph figure is returned at index %d.',labelQ(j),inputname(1),j);
        fig=figure(1+j); clf; cla;
        set(fig,'defaultfigurewindowstyle','normal');
        figSelect(j)=fig;
        figSelect(j).Name="figSelect_"+j;
        continue
    end
idQ=find(contains(longLabels,labelQ(j)));
G3=G.subgraph(idQ);
labels3=labels(idQ);
figure(1+j); clf; cla;
fig=gcf;
set(fig,'defaultfigurewindowstyle','modal');
ax=gca;
fig.Units='centimeters';
snId3=unique(G3.Edges.EndNodes(:,1));
snId3c=setdiff((1:G3.numnodes)',snId3);
seId3=find(ismember(G3.Edges.EndNodes(:,2),snId3));
seId3c=setdiff((1:G3.numedges)',seId3);
fig.Position=[10 10-3*length(seId3c)/20 8 10*length(seId3c)/20];
ax.Position=[0 0 1 1];
pg3=plot(G3,"Interpreter","none");
pg3.layout("layered","Direction","right");
pg3.NodeLabel={};
pg3.set('EdgeColor','k','NodeColor','k','MarkerSize',2.5);
xlim([min(pg3.XData)-0.5,max(pg3.XData)+3*max(strlength(labels3(snId3c)))/24]);
ylim([min(pg3.YData)-0.5,max(pg3.YData)+0.5]);

x3=pg3.XData;
y3=pg3.YData;
set(ax,'defaulttextInterpreter','none','defaulttextfontname','Lucida Console','defaulttextfontsize',8,'defaulttextmargin',0.9);
set(ax,'defaultaxesunits','normalized','defaultaxesposition',[0 0 1 1]);
te3_1=text(x3(snId3),y3(snId3),labels3(snId3),'HorizontalAlignment','center','VerticalAlignment','middle','EdgeColor','k','BackgroundColor',0.95*[1 1 1]);
te3_2=text(x3(snId3c)+0.09,y3(snId3c),labels3(snId3c),'HorizontalAlignment','left','VerticalAlignment','middle');

te3_1Extent=cell2mat({te3_1.Extent}');
te3_2Extent=cell2mat({te3_2.Extent}');

xmin=min([min(x3),min(te3_1Extent(:,1)),min(te3_2Extent(:,1))]);
ymin=min([min(y3),min(te3_1Extent(:,2)),min(te3_2Extent(:,2))]);

xmax=max([max(x3),max(sum(te3_1Extent(:,[1,3]),2)),max(sum(te3_2Extent(:,[1,3]),2))]);
ymax=max([max(y3),max(sum(te3_1Extent(:,[2,4]),2)),max(sum(te3_2Extent(:,[2,4]),2))]);

xline([xmin,xmax],'--','Color',0.99*[1 1 1]);
yline([ymin,ymax],'--','Color',0.99*[1 1 1]);

figSelect(j)=fig;
figSelect(j).Name=labelQ(j);
end
%
%
%
set(0,'defaultfigurewindowstyle',grootStyle);
end