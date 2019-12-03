try
    %Check if an Excel server is running
    ex = actxGetRunningServer('Excel.Application');
catch ME
    disp(ME.message)
end
if exist('ex','var')
    %Get the names of all open Excel files
    wbs = ex.Workbooks;
    %List the entire path of all excel workbooks that are currently open
    for i = 1:wbs.Count
        wbs.Item(i).FullName 
    end
end