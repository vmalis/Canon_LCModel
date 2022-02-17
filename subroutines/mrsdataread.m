function data = mrsdataread(filename)

% subroutine to read bin int32 data if exists
% Vadim Malis| Feb 22'| UC San Diego

            if isfile(filename)
                fileID = fopen(filename); 
                [data, ~] = fread(fileID, 'int32');
                fclose(fileID);
            else
                 disp(strcat('File ', filename,' does not exist.'))
                 data = [];
            end

end