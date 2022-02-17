function data2LCmodel(LC,type)
%-------------------------------------------
% subroutine to write to LCmodel raw
% Vadim Malis| Feb 22'| UC San Diego
%-------------------------------------------
% LC - structure with LC model header parameters and data
%       name
%       te              echotime    [ms]
%       hzppm           Hz per ppm  [MHz]
%       volume          volume      [ml]
%       channelOption   IAVERG parameter used for coherent data averaging 
%       data            raw MRS data
%       ref             reference H2O data
%-------------------------------------------
% type
%       'raw'   raw MRS data
%       'h2o'   reference data
%-------------------------------------------

    switch type
       case 'raw'
          rawName = strcat(LC.name,'.raw');
          data = LC.raw;
        case 'h2o'
          rawName = strcat(LC.name,'.h2o');
          data = LC.ref;
       otherwise
          disp('ERROR: type not specified!')
          return
    end
    
    fid=fopen(rawName,'w+');
    fprintf(fid,' $SEQPAR');
    fprintf(fid,'\n ECHOT=%2.2f',LC.te);
    fprintf(fid,'\n HZPPPM=%5.6f',LC.hzppm);
    fprintf(fid,'\n SEQ=''%s''', LC.name );
    fprintf(fid,'\n $END');
    fprintf(fid,'\n $NMID');
    fprintf(fid,'\n ID=''ANONYMOUS''');
    fprintf(fid,'\n FMTDAT=''(2E15.6)''');
    fprintf(fid,'\n VOLUME=%2.1f', LC.volume);
    fprintf(fid,'\n TRAMP=1.0');
    if isfield (LC, 'channelOption')
        fprintf(fid,'\n IAVERG=1');
    end
    fprintf(fid,'\n $END\n');

    data=reshape(data,2,[]);

    for i=1:size(data,2)
        fprintf(fid,'%15.6E%15.6E\n',data(1,i),data(2,i));
    end

    fclose(fid);

end