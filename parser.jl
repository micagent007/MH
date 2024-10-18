using DelimitedFiles
#global r, c, b, m, t;
function readfile(fname, id)    #id=le numÃ©ro d'instance, de 0 Ã  nbInst-1
    all = readdlm(fname);
    nbInst   = all[1,1];
    @assert(id<nbInst);
    deb = 2;                #instance 0 commence Ã  ligne deb
    m = all[2,1];
    t = all[2,2];
    for i in 1:id
        deb += 2m+2;        #sauter instance i (2m+2 lignes)
        m = all[deb,1];    
        t = all[deb,2];    
    end
    c = all[deb+1:deb+m,   1:t];
    r = all[deb+m+1:deb+2m,1:t];
    b = all[deb+2m+1,      1:m];
    return r, c, b, m, t;

end

#Attention: cette lecture ne fonctionne pas si le ficher n'est pas alignÃ© sous format matriciel
#des instances disponibles Ã  cedric.cnam.fr/~porumbed/