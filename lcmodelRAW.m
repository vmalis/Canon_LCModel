% Prototype script to convert bin data to LCModel .RAW
%-----------------------------------------------------
% UC San Diego
% Feb, 2022
% Vadim Malis

clear all
clc


%% read all exiting binary sraw data  -  data files

f = waitbar(0,'1','Name','Loading',...
    'CreateCancelBtn','setappdata(gcbf,''canceling'',1)');


srawbin_files = dir('*.sraw.bin');
n=size(srawbin_files,1);
data = struct();

    for i=1:n
        
        waitbar(i/n,f,sprintf('Reading data set %d out of %d',i,n))


        filename = srawbin_files(i).name(1:end-9);
        data(i).name = filename;
        
        % raw ---------------------------------------
        rawfilename     =   [filename,'.sraw.bin'];
        sraw            =   mrsdataread(rawfilename);

        % ref ---------------------------------------
        reffilename     =   [filename,'.srefraw.bin'];
        srefraw         =   mrsdataread(reffilename);

        % mrs ---------------------------------------
        mrsfilename     =   [filename,'.mrsraw.bin'];
        mrs             =   mrsdataread(mrsfilename);

        % xml ---------------------------------------
        xmlfilename     =   [filename,'.sraw.xml'];


        if isfile(xmlfilename)
            
            data(i).xml =   xml2struct(xmlfilename);

            % geometry
            sg      =     str2num(data(i).xml.filedesc.sliceGroups.Text);    % slice group
            sl      =     str2num(data(i).xml.filedesc.slices.Text);         % slice
            im      =     str2num(data(i).xml.filedesc.imagesPerSlice.Text); % image
            ch      =     str2num(data(i).xml.filedesc.channels.Text);       % ch
            dp      =     str2num(data(i).xml.filedesc.depth.Text);          % depth
            h       =     str2num(data(i).xml.filedesc.height.Text);         % height
            w       =     str2num(data(i).xml.filedesc.width.Text);          % width
            fov_W   =     str2num(data(i).xml.filedesc.fovu_width.Text);     % fov width  (RO)
            fov_H   =     str2num(data(i).xml.filedesc.fovu_height.Text);    % fov height (PE)
            fov_D   =     1;
            
            % needed for LCModel
            data(i).ch      =     ch;
            data(i).vol     =     fov_W/sqrt(h)*fov_H/sqrt(h);    % volume in mL for single voxel

            % permute raw
            temp            =   squeeze(reshape(sraw,[2,w,sqrt(h),sqrt(h),dp,ch,im,sl,sg]));
            real            =   temp(1,:,:,:,:,:,:,:,:);
            img             =   temp(2,:,:,:,:,:,:,:,:);

            temp            =   complex(real,img);
            temp(:,w/2+1:end,:,:,:,:,:,:,:)=[];
            temp=squeeze(temp);

           

            if ch==1 && h==1
                data(i).sraw    =   temp';

            elseif ch==1
                data(i).sraw    =   temp;
            
            else 
    
               RAW(i).sraw=temp;

               SMAP=squeeze(adaptive_est_sens(temp));
               img=squeeze(temp);
               coil_dim=max(size(size(SMAP)));
               data(i).sraw = sum(img.*conj(SMAP),coil_dim)./sum(SMAP.*conj(SMAP),coil_dim);

               clearvars SMAP

            end
            
            clearvars real img temp 
           

            if ~isempty(srefraw)

                %multi-voxel
                if h>1

                    % pad reference (2 times undersampled x,y)
                    %srefraw=kron(srefraw,[1,0,0,0]');

                    dx = sqrt(h);
                    dy = sqrt(h);
                     
                    temp = squeeze(reshape(srefraw,[2,w,dx/2,dy/2,dp,ch,im,sl,sg]));

                    real=temp(1,:,:,:,:,:,:,:,:);
                    img=temp(2,:,:,:,:,:,:,:,:);

                    temp = complex(real,img);

                    temp(:,w/2+1:end,:,:,:,:,:,:,:)=[];
                    temp=squeeze(temp);

                    RAW(i).sref=temp;
                    if ch>1
                        SMAP=squeeze(adaptive_est_sens(temp));
                        img=squeeze(temp);
                        coil_dim=max(size(size(SMAP)));
                        temp = sum(img.*conj(SMAP),coil_dim)./sum(SMAP.*conj(SMAP),coil_dim);

                        clearvars SMAP

                    end

                    temp=repmat(temp,[1,2,2]);
                    data(i).srefraw    =   temp;

                    clearvars real img temp

                else

                    temp =  reshape(srefraw,[2,w,h,dp,ch,im,sl,sg]);
                    
                    real=temp(1,:,:,:,:,:,:,:);
                    img=temp(2,:,:,:,:,:,:,:);
                    
                    temp = complex(real,img);

                    temp(:,w/2+1:end,:,:,:,:,:,:,:)=[];
                    temp=squeeze(temp);
                    
                    RAW(i).sref=temp;
                    if ch>1

                        SMAP=squeeze(adaptive_est_sens(temp));
                        img=squeeze(temp);
                        coil_dim=max(size(size(SMAP)));
                        temp = (sum(img.*conj(SMAP),coil_dim)./sum(SMAP.*conj(SMAP),coil_dim))';

                        clearvars SMAP

                    end

                    data(i).srefraw = temp';

                    clearvars real img temp

                end


            else
                return
            end


            % channels combined? no documentation avliable...
            if ~isempty(mrs)
                %mrs            = reshape(mrs,[2,w,h,dp,im,sl,sg]);
                %mrs            = complex(real,img);
                %mrs(:,w/2+1:end,:,:,:,:,:,:)=[];  
                data(i).mrs    = mrs;
            end

        else
            disp('ERROR! xml file does not exist!')
            return
        end

    end

delete(f)
clearvars -except n data RAW

%% prepare LCmodel header

Bo=3;               % Field strengt
te=20;              % echo time 
hzppm=42.577*Bo;    % Hz to ppm

% folder for data export
mkdir('lcmodel')
cd('lcmodel')



%% write files
for i=1:n

        % prepare structure for writing function
        LC.name             = [data(i).xml.filedesc.studyname.Text,'_', data(i).name];
        LC.te               = te;
        LC.hzppm            = hzppm;
        LC.volume           = data(i).vol;
        LC.raw              = data(i).sraw;
        LC.ref              = data(i).srefraw;
        if data(i).ch > 1
            LC.channelOption    = 1;
        end
            
        % write data
        data2LCmodel(LC,'raw')
        data2LCmodel(LC,'h2o')

end