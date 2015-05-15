function f = obj(x,A,b)
    a = A*x-b;
    a(a<0)=[];
    f = sum(a.^2,1);