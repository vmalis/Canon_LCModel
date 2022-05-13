function CoilSns = adaptive_est_sens(data)
    
    dims = max(size(size(data)));

    Nx = 1;
    Ny = 1;
    Nz = 1;
    Nc = 1;

    switch dims
        case 5
             [width,Nx,Ny,Nz,Nc]=size(data);
             data=reshape(data,[width,Nx,Ny,Nz,Nc]);
        case 4
             [width,Nx,Ny,Nc]=size(data);
             data=reshape(data,[width,Nx,Ny,Nz,Nc]);
        case 3
             [width,Nx,Nc]=size(data);
             data=reshape(data,[width,Nx,Ny,Nz,Nc]);
        case 2
            [width,Nc]=size(data);
            data=reshape(data,[width,Nx,Ny,Nz,Nc]);
    end


    CoilSns=zeros(width,Nx,Ny,Nz,Nc);


    for f=1:width

        
        P=(data(f,:,:,:,:));
        sz=size(P);
        P=reshape(P,[sz(2:end) 1]);

        S = zeros(Nx,Ny,Nz,Nc);
        w = 3;
        for i = 1:Nx
            ii = max(i-w,1):min(i+w,Nx);
            for j = 1:Ny
                jj = max(j-w,1):min(j+w,Ny);
                for k = 1:Nz
                    kk = max(k-w,1):min(k+w,Nz);
                    kernel = reshape(P(ii,jj,kk,:),[],Nc);
                    [V,D] = eigs(conj(kernel'*kernel),1);
                    S(i,j,k,:) = V*exp(-1j*angle(V(1)));
                end
            end
        end
      
        CoilSns(f,:,:,:,:)=S;
    end


end
