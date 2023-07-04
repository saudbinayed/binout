clear; 
close all;
clc;

binout_filename='../LS-DYNA sample/binout';
binin = get_binout_data(binout_filename);

%[figParents,figSelect]=struct2graph(binin,"All"); %graphically see contents of binin

%%
Pids=binin.matsum.metadata.ids;
matsum=binin.matsum.data;  %rmfield(binin,'matsum');
t=matsum.time; % length(t)==51
ke=matsum.kinetic_energy; % kinetic energies of part 1 (column 1), and part 2 (column 2)
ie=matsum.internal_energy; % internal energy
hge=matsum.hourglass_energy; %hour-glass energy

set(0,'defaultaxesxgrid','on','defaultaxesygrid','on','defaultaxesgridalpha',0.15);
set(0,'defaultaxesxminorgrid','on','defaultaxesyminorgrid','on','defaultaxesminorgridalpha',0.1);
set(0,'defaultaxesxminortick','on','defaultaxesyminortick','on');
set(0,'defaultaxesfontname','Times','defaultaxesfontsize',10,'defaulttextinterpreter','latex');
set(0,'defaultlegendinterpreter','latex');

figure(1); clf; cla; 
fig=gcf; ax=gca;
hold(ax,"on");

plot(ax,t,ke);
txt=compose('KE Part %d',Pids);
plot(ax,t,ie);
txt(end+1:end+2)=compose('IE Part %d',Pids);

plot(t,hge);
txt(end+1:end+2)=compose('HGE Part %d',Pids);

hold(ax,'off');
legend(ax,txt);
xlabel(ax,'Time [s]'); 
ylabel(ax,'Energy [N.m]');
ax.XAxis.Exponent=-3;
posTight=tightPosition(ax,IncludeLabels=true);
ax.Position(1:2)=ax.Position(1:2)+([0 0]-posTight(1:2));
ax.Position(3:4)=ax.Position(3:4)+([1 1]-posTight(3:4));


%%
Nids=binin.nodout.metadata.ids;
nodout=binin.nodout.data; %rmfield(binin,'nodout');
x0=nodout.x_coordinate(1,:)'; %inital x-coordinate
y0=nodout.y_coordinate(1,:)';

xq=0.5;
yq=0.21;
% idq=find(abs(x0-xq)==min(abs(x0-xq)) & abs(y0-yq)==min(abs(y0-yq)));
[~,idq]=min(sqrt((x0-xq).^2+(y0-yq).^2));
xq=x0(idq); yq=y0(idq);
nid=Nids(idq);
t=nodout.time;
uy=nodout.y_displacement(:,idq); %y-displacement
vy=nodout.y_velocity(:,idq); %y-velocity

figure(2); clf; cla;
fig=gca; ax=gca;
plot(t,uy);
txt=compose('$u_y$ Node %d',nid);

legend(ax,txt);
xlabel(ax,'Time [s]');
ylabel(ax,'Displacement [m]');
ax.XAxis.Exponent=-3;
ax.YAxis.Exponent=-3;
posTight=tightPosition(ax,IncludeLabels=true);
ax.Position(1:2)=ax.Position(1:2)+([0 0]-posTight(1:2));
ax.Position(3:4)=ax.Position(3:4)+([1 1]-posTight(3:4));



%%
connec=binin.control.connec.shell;
x=nodout.x_coordinate;
y=nodout.y_coordinate;
faces=connec(1:4,:)';
vertices=[x(1,:)',y(1,:)'];
figure(3); clf; cla;
fig=gcf; ax=gca;
axis(ax,"equal");
xlim([min(x,[],"all"),max(x,[],"all")]);
ylim([min(y,[],"all"),max(y,[],"all")]);

pa =patch('Faces',faces,'Vertices',vertices,'FaceColor','interp','EdgeColor','none');
colormap(ax,'turbo');


for i=1:length(t)
    pa.Vertices=[x(i,:)',y(i,:)'];
    pa.FaceVertexCData=nodout.y_velocity(i,:)';
    pause(1/2.2);
end






