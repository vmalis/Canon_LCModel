figure('Position',[0,0,1200,400]);

plot(abs(squeeze(RAW(3).sref(:,3,3,:))))
hold on
plot(abs(data(3).srefraw(:,6,7)),'LineWidth',3)
plot(abs(data(4).srefraw(:,6,7)),'LineWidth',3)

for i=1:32
    lgd{i}=strcat('ch #',num2str(i));
end

lgd{33}='32ch recon';
lgd{34}='1ch';

xlim([0,1024])


set(gca,'Fontsize',20,'XColor','w','YColor','w')


legend(lgd,'NumColumns',2,'FontSize',14)

% setup figure for plot

set(gcf,'color','w');


set(gca,'LooseInset',get(gca,'TightInset'));