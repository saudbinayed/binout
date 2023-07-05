clear; 
close all;
clc;

binout_filename='../LS-DYNA-sample/binout';
binin = get_binout_data(binout_filename);

%[figParents,figSelect]=struct2graph(binin,"All"); %graphically see contents of binin

%% matsum

Pids=binin.matsum.metadata.ids; %ids of parts
matsum=binin.matsum.data;  %rmfield(binin,'matsum');
t=matsum.time; % time vector for matsum database
ke=matsum.kinetic_energy; % kinetic energy time histories of part 1 (column 1) and part 2 (column 2)
ie=matsum.internal_energy; % internal energy
hge=matsum.hourglass_energy; % hourglass energy


figure(1); clf; cla; 
fig=gcf; ax=gca;
hold(ax,"on");

plot(ax,t,ke);
txt=compose('KE Part %d',Pids);
plot(ax,t,ie);
txt(end+1:end+length(Pids))=compose('IE Part %d',Pids);

plot(t,hge);
txt(end+1:end+length(Pids))=compose('HGE Part %d',Pids);

% plot(binin.glstat.data.time,binin.glstat.data.total_energy,'-k'); % total energy
% txt(end+1)={'TE'};

hold(ax,'off');
legend(ax,txt);
xlabel(ax,'Time [s]'); 
ylabel(ax,'Energy [N.m]');
set(ax.XAxis,'Exponent',-3,'TickLabelFormat','%.2f');
set(ax.YAxis,'TickLabelFormat','%.1f');
ax=tidyAxes(ax); % local fun, given at the bottom of this script

folderName='../figs';
if exist(folderName,'dir')==0
    mkdir(folderName);
end
figFileName=[folderName,'/','energies'];
fig=printFig(fig,figFileName,["pdf","svg"]); % another local fun, given at the bottom of this script



%% nodout

Nids=binin.nodout.metadata.ids; % ids of nodes
nodout=binin.nodout.data; %rmfield(binin,'nodout');
x0=nodout.x_coordinate(1,:)'; % inital x-coordinate
y0=nodout.y_coordinate(1,:)'; % ... y-coordinate

% search for node nearest to (xq,yq)
xq=0.5;
yq=0.2;
[~,idq]=min(sqrt((x0-xq).^2+(y0-yq).^2));
idq=idq(1); 
xq=x0(idq); yq=y0(idq); % actual coordinate of node
nid=Nids(idq); % actual id of node


t=nodout.time; % time vector of nodout database
uy=nodout.y_displacement(:,idq); % y-displacement time-history at nid
vy=nodout.y_velocity(:,idq); % y-velocity ...

figure(2); clf; cla;
fig=gcf; ax=gca;
plot(t,uy);
txt=compose('$u_y$ Node %d',nid);

legend(ax,txt);
xlabel(ax,'Time [s]');
ylabel(ax,'y-Displacement [m]');
set(ax.XAxis,'Exponent',-3,'TickLabelFormat','%.2f');
set(ax.YAxis,'Exponent',-3,'TickLabelFormat','%.2f');
ax=tidyAxes(ax);




%% displaying the model geometry and motion

connec=binin.control.connec.shell; %element-node connectivity array for shell elems 
x=nodout.x_coordinate; % 2D array of x-coordinate time histories of all nodes
y=nodout.y_coordinate; % ... y-coordinate ...
faces=connec(1:4,:)'; % for patch
vertices=[x(1,:)',y(1,:)']; % for patch 

vx=nodout.x_velocity;
vy=nodout.y_velocity;
vResultant=sqrt(vx.^2+vy.^2); % resultant velocity
vResultant(abs(vResultant)<=eps)=0;


figure(3); clf; cla;
fig=gcf; 
tl=tiledlayout(fig,1,1,'TileSpacing','tight','Padding','tight');
ax=nexttile;
axis(ax,"equal");
xlim([min(x,[],"all"),max(x,[],"all")]);
ylim([min(y,[],"all"),max(y,[],"all")]);
fig.Units='centimeters';
ax.Units='centimeters'; 
axPos=ax.tightPosition(IncludeLabels=true);
fig.Position(3:4)=axPos(3:4);



xlabel(ax,'x-coordinate [m]');
ylabel(ax,'y-coordinate [m]');
ax.TickDir="both";
ax.Color='none';
ax.set('FontSize',8);

pa =patch('Faces',faces,'Vertices',vertices,'FaceColor','interp','EdgeColor','none');
colorVar='Resultant Velocity';

pa.FaceVertexCData=vResultant(1,:)';
colormap(ax,'turbo');
cb=colorbar(ax); cb.Label.set('String',[colorVar,' [m/s]'],'Interpreter','none');
cb.Layout.Tile='east';
clim(ax,[min(vResultant,[],"all"),max(vResultant,[],"all")]);
txt=compose('Time = %7.6f [s]',t(1));
te=text(0.02,1,txt,'FontSize',8,'Units','normalized','HorizontalAlignment','left','VerticalAlignment','top');

ax.NextPlot="replacechildren";
fig.ToolBar="none";
F=struct('cdata',[],'colormap',[]);
frameCount=min([120,length(t)]);
F(frameCount)=struct('cdata',[],'colormap',[]);
Im=cell(1,frameCount);

for i=1:frameCount
    pa.Vertices=[x(i,:)',y(i,:)'];
    pa.FaceVertexCData=vResultant(i,:)';
    te.String=compose('Time = %7.6f [s]',t(i));
    F(i)=getframe(fig);
    Im{i}=frame2im(F(i));
    pause(1/90);
end
F=[F([1 1 1]),F(2:end)];
frameAspectRatio=size(F(1).cdata,1)/size(F(1).cdata,2);


%% saving videos and gifs

figure(4); clf; cla;
fig=gcf; delete(gca());
fig.Position(4)=fig.Position(3)*(frameAspectRatio);
movie(fig,F,2,10,[0 0 0 0]);
videosFolder='../videos';
if exist(videosFolder,'dir')==0
    mkdir(videosFolder);
end
videoFileName=[videosFolder,'/','impact_color_resultant_vel'];
vid=VideoWriter([videoFileName,'.mp4']);
vid.FrameRate=4;
vid.Quality=90;
open(vid);
writeVideo(vid,F);
close(vid);

for i=1:length(Im)
    [A,map]=rgb2ind(Im{i},256);
    if i==1
        imwrite(A,map,[videoFileName,'.gif'],'LoopCount',Inf,'DelayTime',0.5);
    else
        imwrite(A,map,[videoFileName,'.gif'],'WriteMode',"append",'DelayTime',0.2);
    end
end



%%
elout=binin.elout.shell.data;

t2=elout.time; % time vector of elout database
pres=-(elout.sig_xx+elout.sig_yy+elout.sig_zz)/3; % pressure (+ve: compression)
[~,eids]=find(connec(1:4,:)==nid); % elem ids sharing node nid
presq=mean(pres(:,eids),2); % taking node pressure as average of those of surrounding elems

figure(5); clf; cla;
fig=gcf;  ax=gca;

yyaxis(ax,"left");
plot(ax,t2,presq)
txt=compose('P Node %d',nid);
text(ax,0.01e-3,0,{'\uparrow compression'},'Units','data','FontSize',7,'Interpreter','tex','HorizontalAlignment','left','VerticalAlignment','bottom');
text(ax,0.01e-3,0,{'\downarrow tension'},'Units','data','FontSize',7,'Interpreter','tex','HorizontalAlignment','left','VerticalAlignment','top');
ylabel(ax,'Pressure [Pa]');

yyaxis(ax,"right");
ydata=-nodout.y_velocity(:,nid);
plot(ax,t,ydata);
txt(end+1)=compose('$\\dot{u}_y$ Node %d',nid);
ylabel(ax,'Velocity [m/s]');

legend(ax,txt);
xlabel(ax,'Time [s]');
set(ax.XAxis,'Exponent',-3,'TickLabelFormat','%.2f');
ax=tidyAxes(ax);










%% local fun's

function [axOut]=tidyAxes(axIn)
% re-set defaults of axes:
set(axIn,'XGrid','on','YGrid','on','GridAlpha',0.12);
set(axIn,'XMinorGrid','on','YMinorGrid','on','MinorGridAlpha',0.11);
set(axIn,'XMinorTick','on','YMinorTick','on','TickDir','in');
set(axIn,'FontName','Times','FontSize',10);
set([axIn.XAxis.Label,axIn.YAxis.Label],'Interpreter','latex');
set(axIn,'Box','on');
set([allchild(axIn)],'LineWidth',0.75);
%
% remove un-needed white space (margins):
posTight=tightPosition(axIn,IncludeLabels=true);
axIn.Position(1:2)=axIn.Position(1:2)+([0 0]-posTight(1:2));
axIn.Position(3:4)=axIn.Position(3:4)+([1 1]-posTight(3:4));
%
fig=axIn.Parent;
leg=findobj(fig.Children,'Type','Legend');
leg.Units='normalized'; leg.Interpreter='latex';
axIn.Units='normalized';
gap(1)=sum(axIn.Position([1 3]))-sum(leg.Position([1 3]));
gap(2)=sum(axIn.Position([2 4]))-sum(leg.Position([2 4]));
leg.Position(1:2)=leg.Position(1:2)+0.4*gap;
axOut=axIn;
end



function [fig]=printFig(fig,filename,fmt)
if nargin<3 || (nargin==3 && isempty(fmt))
    fmt="pdf";
end
fmt=string(fmt);
filename=erase(filename,regexpPattern('\.[a-zA-Z0-9]+$'));
filename=char(filename);
%
if any(fmt=="pdf")
    fig.Units="centimeters";
    fig.PaperUnits="centimeters";
    fig.PaperPositionMode="manual";
    fig.PaperSize=fig.Position(3:4); %make page size = fig size
    fig.PaperPosition=[0 0 fig.Position(3:4)]; % zero margins
    %will plot later below
end
%
% scalable vector graphics (best vectorised fig for web)  
if any(fmt=="svg")
    figFileName=filename;
    print(fig,figFileName,'-dsvg');
end
%
% raster graphics
for fmt0=fmt(ismember(fmt,["png","jpeg","jpg"]))
    figFileName=[filename,'.',char(fmt0)];
    exportgraphics(fig,figFileName,'ContentType','image','Resolution',600);
end
%
% vector graphics
for fmt0=fmt(ismember(fmt,["pdf","meta","eps"]))
    figFileName=[filename,'.',char(fmt0)];
    exportgraphics(fig,figFileName,'ContentType','vector');
end
end

