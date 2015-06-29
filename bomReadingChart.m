name = 'tikzpic.tex';


book = 1;

%         Long              Short
names = {'1st Nephi'        'Ne1'; 
         '2nd Nephi'        'Ne2'; 
         'Jacob'            'Jac'; 
         'Enos'             'Eno'; 
         'Jarom'            'Jar'; 
         'Omni'             'Omn';
         'Words of Mormon'  'WoM'; 
         'Mosiah'           'Mos'; 
         'Alma'             'Alm'; 
         'Helaman'          'Hel'; 
         '3rd Nephi'        'Ne3'; 
         '4th Nephi'        'Ne4'; 
         'Mormon'           'Mor'; 
         'Ether'            'Eth'; 
         'Moroni'           'Mro'};
     
pages = {[1]; 
         [2];
         [3 4 5];
         [6 7];
         [8];
         [9];
         [10];
         [11];
         [12 13];
         [14];
         [15]
         };
     
breakpts = {[16];   %1NE
            [17];   %2NE
            [];     %Jac
            [];     %Eno
            [];     %Jar
            [];     %Omn
            [];     %WoM
            [17];     %Mos
            [15 30 45 60];     %Alm
            [];     %Hel
            [16];     %3NE
            [];     %4NE
            [];     %Mor
            [];     %Eth
            [];     %Mro
            };
            
chaps = [ 22 33  7  1  1  1  1 29 63 16 30  1  9 15 10];

%         1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20
vers = {[20 24 31 38 22  6 22 38  6 22 36 23 42 30 36 39 55 25 24 22 ...
         26 31];                                    % 1st Nephi
        [32 30 25 35 34 18 11 25 54 25  8 22 26  6 30 13 25 22 21 34 ...
         16  6 22 32 30 33 35 32 14 18 21  9 15];   % 2nd Nephi
        [19 35 14 18 77 13 27];                     % Jacob
        [27];                                       % Enos
        [15];                                       % Jarom
        [30];                                       % Omni
        [18];                                       % Words of Mormon
        [18 41 27 30 15  7 33 21 19 22 29 37 35 12 31 15 20 35 29 26 ...
         36 16 39 25 24 39 37 20 47];               % Mosiah
        [33 38 27 20 62  8 27 32 34 32 46 37 31 29 19 21 39 43 36 30 ...
         23 35 18 30 17];                           % Alma - Partial
        [0 0];                                      % Helaman
        [0 0];                                      % 3rd Nephi
        [0];                                        % 4th Nephi
        [0 0];                                      % Mormon
        [0 0];                                      % Ether
        [0 0]};                                     % Moroni
%%     
     
fid = fopen('./bom.txt','rt');
chars = fscanf(fid,'%s');
fclose(fid);
fid = fopen('./bom.txt','rt');
fulltxt= fscanf(fid,'%c');
fclose(fid);
%%

chps = strfind(chars,'Chapter');
% This doesn't have the chapters of the books with only one chapter...

%
% Ok.. for each segment (ie pair) of these, we need to find the last
% occurrence of <some text> <number>:<number>\cr\lf
ex1 = '[\d]*[a-z]+\d+:(\d+)';

chps = [chps length(chars)];
dbstop if error
cc = chars(chps(1):chps(1)+45);
%regexpi(cc,ex1,'match')
vs = zeros(length(chps)-1,1);
for iter = 2:length(chps)
    [expret] = regexp(chars(chps(iter-1):chps(iter)),ex1,'tokens');
    
    % Grab the ast one:
    c = expret{end};
    vs(iter-1) = str2num(c{1}(1:floor(end/2)));
end

ex2 = '(([\d|\w]*[a-z]+)<book>)';%\w+(\d+<chap>):(\d+<verse>)';

%% Check the ones I've done by hand:
cumchap = [0 cumsum(chaps)];

check = zeros(1,length(chaps));
vers2 = cell(length(chaps),1);
for iter = 2:length(cumchap)
    
    check(iter-1) = ...
    all(...
        diag(bsxfun(@eq,vers{iter-1},vs(cumchap(iter-1)+1:cumchap(iter)))) ...
        );
    % Ok, so let's process them back into the chaps:
    vers2{iter-1} = vs(cumchap(iter-1)+1:cumchap(iter))';
end

%% So it seems good...

if exist('NoLaTexOutput','var') && ~NoLatexOutput
disp('LaTeX output processing...')
%%
% Now, Let's get to writing the actual Tikz code...

% For each book, make a 
rowlength = 10;

rows = floor(cellfun(@length,vers2)./rowlength)';
extras = chaps - rows*rowlength;
extlog = logical(extras);
rows(extlog) = rows(extlog)+1;
sum(rows)

%% Start the LaTeX writing:


rowlength = 14;

start = ['\\documentclass{standalone}\n' ...
         '\\usepackage[utf8]{inputenc}\n\n' ...
         '\\usepackage{tikz}\n' ...
         '\\usetikzlibrary{arrows,shapes}\n' ...
         '\\usetikzlibrary{positioning,calendar,er}\n'...
         '\\usetikzlibrary{decorations.markings}\n'...
         '\\usetikzlibrary{matrix}\n'...
         '\\usetikzlibrary{calc,fit}\n'...
         '\\usetikzlibrary{shapes.geometric}\n\n\n'...
         '\\begin{document}\n\n'];%...
begpic = ['\\begin{tikzpicture}\n\n'];
endpic = ['\n\n\\end{tikzpicture}\n'];
ending = ['\n\\end{document}'];

%%% Iterate over the books:
for book = 1:size(names,1)


rows = ceil(vers2{book}./rowlength);
bookstr = num2str(book);

sn = names{book,2};
ln = names{book,1};

chaplatex = [];
lastchap = [];

%%% Section to setup the Book name...
firstnodename = [sn 'Ch' num2str(1)];
topnodename = firstnodename;
bookwidth = 1; % cm 
bookTxtWidth = 1.75; % in

booknodefcn = @(topleftcrnr, botrightcrnr, Longname,bookWidth,bookTxtWidth)[ ...
'\n\n\\coordinate (aux1) at ($(' topleftcrnr '.north west) - (1em + ' ...
num2str(bookWidth) 'cm,0cm)$);\n' ...
'\\coordinate (aux2) at ($(' botrightcrnr '.south west) - (1em,0cm)$);\n' ...
'\\node[fit=(aux1)(aux2), inner sep=-.6pt](X){};\n' ...
'\\node [anchor=center, rotate=90, text centered,text width=' num2str(bookTxtWidth)...
'in ] at (X.center){\\Huge \\bf ' Longname '};\n\n'];


chlblwdth = 5;

% For-loop over the chapters:
numbreaks = length(breakpts{book});
if ~numbreaks
    chaplim = length(vers2{book});
    chaplimiter = 0;
else
    chaplimiter = 1;
    chaplim = breakpts{book}(chaplimiter);
    
end
for iter = 1:length(vers2{book})%chaplim
    ii = num2str(iter);
    chapnode = [sn 'Ch' ii];
    if isempty(lastchap) % Then this is the first for this tikzpicture...
        chaplatex = [chaplatex ...
            '\n\\node [anchor=base, draw, text width=' num2str(chlblwdth)  ...
            'em](' chapnode '){Chapter ' ii '};\n'];
        topnodename = [sn 'Ch' num2str(iter)];
    else%if rows(iter) > 2
        chaplatex = [chaplatex ...
            '\n\\node [anchor=base,text width=' num2str(chlblwdth) ...
            'em, below=' num2str(sum(rows(iter-1:iter))*1.2) ...
            'ex of ' lastchap ', draw](' chapnode '){Chapter ' ii '};\n'];
    %else
    %    chaplatex = [chaplatex ...
    %        '\n\\node [anchor=base,below=of ' lastchap ', draw](' chapnode '){Chapter ' ii '};\n'];
    end
    % start the matrix for the verses:
    chaplatex = [chaplatex ...
        '\\begin{scope}[every node/.style={text width=2em, align=flush center}]\n' ...
        '\\matrix (M' bookstr ')[right=of ' chapnode ', matrix of math nodes,' ...
        ' nodes={draw}]\n {'];
    versenodes = [];
    
    for jiter = 1:vers2{book}(iter);
        if ~mod(jiter,rowlength)
            versenodes = [versenodes num2str(jiter) ' \\\\ \n '];
        else
            versenodes = [versenodes num2str(jiter) ' & '];
        end
    end
    if mod(jiter,rowlength)
        extraneeded = true;
    else
        extraneeded = false;
    end
    while extraneeded
        if mod(jiter+1,rowlength)
            versenodes = [versenodes ' & '];
            extraneeded = true;
            jiter = jiter+1;
        else
            extraneeded = false;
            versenodes = [versenodes ' \\\\ \n'];
        end
    end
    versenodes = [versenodes '};\n \\end{scope}'];
    chaplatex = [chaplatex versenodes];
    lastchap = chapnode;
    
    if iter == chaplim
        % Then we need to break this and start a new tikzpicture...
        % Or end it and stick in the book name...
        botnodename = lastchap;

        booknode = booknodefcn(topnodename,botnodename,ln,bookwidth,bookTxtWidth);
        
        chaplatex = [chaplatex booknode endpic];
        if chaplim ~= length(vers2{book})
            chaplatex = [chaplatex '\\clearpage\n' begpic];
            % This \clreapage actually breaks the ability to 
            % Compile each book on it's own as a standalone file...
        end
        defineNewTopNode = true;
        lastchap = [];
        if chaplimiter < numbreaks
            chaplimiter = chaplimiter+1;
            chaplim = breakpts{book}(chaplimiter);
        else
            % We are done 
            chaplim = length(vers2{book}); % ie. the last chapter...
        end
    end
    
    
end % For-loop over chapters.

% Book name node will be done last....


botnodename = lastchap;




fullthing = [start begpic chaplatex ending];


% Output it:
fid = fopen(['./' sn '.tex'],'wt');
fprintf(fid,fullthing,'');
fclose(fid);

end


% The full file together
start = ['\\documentclass{article}\n' ...
         '\\usepackage{standalone}\n'...
         '\\usepackage[cm]{fullpage}\n'...
         '\\usepackage[utf8]{inputenc}\n\n' ...
         '\\usepackage{graphicx}\n'...
         '\\usepackage{tikz}\n' ...
         '\\usetikzlibrary{arrows,shapes}\n' ...
         '\\usetikzlibrary{positioning,calendar,er}\n'...
         '\\usetikzlibrary{decorations.markings}\n'... 
         '\\usetikzlibrary{calc,fit,matrix}\n'...
         '\\usetikzlibrary{shapes.geometric}\n\n\n'...
         '\\begin{document}\n\n'];%...

resizing = 0;

doc = [];
for iter=1:length(pages)
    books = pages{iter};
    
    pagetex = [];
    for jiter = 1:length(books)
        if jiter > 1
            pagetex = [pagetex ...
                '\\vspace{1em}\n\\hrulefill\n\\vspace{1em}\n'];
        end
                
        includes = ['\\input{' names{books(jiter),2} '.tex}'];
        if resizing
            includes = [...
                '\\resizebox{\\textwidth}{!}{' ...
                includes...
                '}'];
        end
        pagetex = [pagetex includes '\n\n'];
        
    end
    pagetex = [pagetex '\\clearpage\n\n'];   
    doc = [doc pagetex];
end

fulldoc = [start doc ending];

% Output it:
fid = fopen(['./bom.tex'],'wt');
fprintf(fid,fulldoc,'');
fclose(fid);

system('pdflatex -interaction nonstopmode ./bom.tex > trash');
%system('pdflatex -interaction nonstopmode ./bom.tex > trash');
delete('trash');

end



























