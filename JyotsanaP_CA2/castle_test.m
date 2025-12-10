% x: original castle image
% y: image to be tested

function score=castle_test(x,y)

score=sum(sum(x~=y))

if score<15
    disp('Outstanding');
else if score<30
        disp('Very Good');
        else if score<50
        disp('Good');
    else disp('Fair');
        end
    end
end