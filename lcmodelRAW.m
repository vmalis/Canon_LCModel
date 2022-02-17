% Prototype script to convert bin data to LCModel .RAW
%-----------------------------------------------------
% UC San Diego
% Feb, 2022
% Vadim Malis

clear all
clc


%% read all exiting binary sraw data  -  data files

srawbin_files = dir('*.sraw.bin');
n=size(srawbin_files,1);
data = struct();

    for i=1:n

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
            data(i).vol     =     fov_W/w*fov_H/h*fov_D;    % volume in mL for single voxel

            % permute raw
            data(i).sraw    =   squeeze(reshape(sraw,[2,w,h,dp,ch,im,sl,sg]));
            
            % permute sref and pad with zeros if different size than raw

            
            if ~isempty(srefraw)

                %multi-voxel
                if h>1
                    dx = sqrt(h);
                    dy = sqrt(h);
                     
                    temp = squeeze(reshape(srefraw,[2,w,dx/2,dy/2,dp,ch,im,sl,sg]));

                    temp = cat(3, zeros(2,w,dx/4,dy/2,ch,im,sl,sg),temp);
                    temp = cat(3, temp, zeros(2,w,dx/4,dy/2,ch,im,sl,sg));

                    temp = cat(4, zeros(2,w,dx,dy/4,ch,im,sl,sg),temp);
                    temp = cat(4, temp, zeros(2,w,dx,dy/4,ch,im,sl,sg));
                
                    data(i).srefraw = temp;
                else

                    data(i).srefraw =  squeeze(reshape(srefraw,[2,w,h,dp,ch,im,sl,sg]));

                end


            else
                return
            end

            % permute mrs (channels combined)
            if ~isempty(mrs)
                data(i).mrs    =   squeeze(reshape(mrs,[2,w,h,dp,im,sl,sg]));
            end

        else
            disp('ERROR! xml file does not exist!')
            return
        end

    end

clearvars -except n data 

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