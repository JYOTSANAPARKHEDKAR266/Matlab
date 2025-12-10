function out = div_grad_vese(u, h, r)

%[c1,c2,c3,c4]=compute_c(u, h, r);
[c1,c2,c3,c4]=compute_phi_c(u, h, r, 1);
[u_cpc,u_cmc,u_ccp,u_ccm]=fourshifts(u);
%out =(c1.*(u_cpc-u)+c2.*(u_cmc-u)+c3.*(u_ccp-u)+c4.*(u_ccm-u))/(h*h);

out = ((c1.*u_cpc+c2.*u_cmc+c3.*u_ccp+c4.*u_ccm)-(c1+c2+c3+c4).*u)/(h*h);

