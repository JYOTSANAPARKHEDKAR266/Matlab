function out = minmod(a,b)

out = ((sign(a)+sign(b))/2).*min(abs(a), abs(b));

