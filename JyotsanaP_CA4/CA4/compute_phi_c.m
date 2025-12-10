function [c1,c2,c3,c4]=compute_phi_c(u, h, r, option)

c00 = u;
[cpc,cmc,ccp,ccm,cpcp,cmcp,cpcm,cmcm]=eightshifts(u);

c1 = psi1(sqrt((cpc-c00).^2 + (minmod(ccp-c00,c00-ccm)).^2)/h,r);
c2 = psi1(sqrt((c00-cmc).^2 + (minmod(cmcp-cmc,cmc-cmcm)).^2)/h,r);
c3 = psi1(sqrt((ccp-c00).^2 + (minmod(cpc-c00,c00-cmc)).^2)/h,r);
c4 = psi1(sqrt((c00-ccm).^2 + (minmod(cpcm-ccm,ccm-cmcm)).^2)/h,r);

function out = psi1(im,r)
out = 1./sqrt(r+im.*im);
