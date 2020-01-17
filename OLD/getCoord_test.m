function getCoord_test(aH,evnt,inputdata)
drawnow
a = evnt;
%global inputdata;
f = ancestor(aH,'figure');
click_type = get(f,'SelectionType');
ptH = getappdata(aH,'CurrentPoint');
delete(ptH)

%Finding the closest point and highlighting it
lH = findobj(aH,'Type','line');
minDist = realmax;
finalIdx = NaN;
finalH = NaN;
pt = get(aH,'CurrentPoint'); %Getting click position
for ii = lH'
    xp=get(ii,'Xdata'); %Getting coordinates of line object
    yp=get(ii,'Ydata');
    dx=daspect(aH);      %Aspect ratio is needed to compensate for uneven axis when calculating the distance
    [newDist idx] = min( ((pt(1,1)-xp).*dx(2)).^2 + ((pt(1,2)-yp).*dx(1)).^2 );
    if (newDist < minDist)
        finalH = ii;
        finalIdx = idx;
        minDist = newDist;
    end
end
xp=get(finalH,'Xdata'); %Getting coordinates of line object
yp=get(finalH,'Ydata');
if strcmp(click_type,'normal')
    ptH = plot(aH,xp(finalIdx),yp(finalIdx),'k*','MarkerSize',20);
    setappdata(aH,'CurrentPoint',ptH);
    set(aH,'hittest','on');
    h =  findobj('type','figure');
    if numel(h)>1
        close(h(2:end));
    end
    figure;
    b = randi(10,10,1);
    plot(inputdata,b,'o');
elseif strcmp(click_type,'alt')
    previous_txt = findobj(gca,'type','text');
    if ~isempty(previous_txt)
        delete(previous_txt);
    end
    txtH = text(xp(finalIdx)+0.1,yp(finalIdx),sprintf('%s','test'));
    set(txtH.Parent,'ButtonDownFcn',{@getCoord_test, inputdata});
end