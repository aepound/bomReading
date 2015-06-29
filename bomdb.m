%% Front matter...
frontmatterlines = 133;
frontmatter = cell(0);

fid = fopen('bom.txt','rt');

for iter = 1:133
  nline = fgetl(fid);
  frontmatter = [ frontmatter; nline]; %#ok<AGROW>
end
testament.frontmatter = frontmatter;

% regexps
bookTitleRegExp = '^([A-Z0-9]+( [A-Z0-9]+)+) ?(\([\w ]+\))*$';
chapHdrRegExp = '(?<bookName>(\d +)?(\w+( +\w+)*)) +(?<chapNum>\d+)$';
chapRegExp = 'Chapter +(?<chap>\d+)';
verseHdrRegExp = [chapHdrRegExp(1:end-1) ':(?<verse>\d+)'];
verse1stLineRegExp = ' ?\d+ ?(?<text>\w+[^\w\s]?( +\w+[^\w\s]?)*)';
endOfBookRegExp = 'End of the Project Gutenberg EBook of The Book Of Mormon, by Anonymous';

% helper functions.
isAllCaps   = @(x) strcmp(x{1}, upper(x{1}));
isBookTitle = @(x) ~isempty(regexp(x,bookTitleRegExp, 'once')) && ...
                   any(isAllCaps(regexp(x,bookTitleRegExp,'tokens')));
isChapHdr   = @(x) ~isempty(regexp(x,chapHdrRegExp, 'once'));
isVerseHdr  = @(x) ~isempty(regexp(x,verseHdrRegExp, 'once'));
is1stLine   = @(x) ~isempty(regexp(x,verse1stLineRegExp, 'once'));



% Flags:
titleFound = false;
chapFound = false;


testament.book = struct([]);
nbooks = 0;

while ~feof(fid)
  nline = fgetl(fid); 
  if regexp(nline,endOfBookRegExp)
    break;
  end
    
  if isBookTitle(nline)
    % The whole line (except for a portion in parenthesis) is in capital
    % letters.  In the Gutenberg.org BOM.txt, this is a book title...
    titleFound = ~titleFound;
    if titleFound
      % A new book is found!
      nbooks = nbooks + 1;
      testament.book(nbooks).fulltitle = nline;
      testament.book(nbooks).title = [];
      testament.book(nbooks).subtitle = [];
      testament.book(nbooks).description = [];  
      chapFound = false;
      nchaps = 0;  
    else
      % A second line has been found...
      testament.book(nbooks).subtitle = nline;
    end
    continue;
  end
  
  % Not all the letters are the uppercase...
  % OR it doesn't match the bookRegExp
  while ~isChapHdr(nline) && ~chapFound
    % This isn't a chapter header....
    % So, add it to the description...
    testament.book(nbooks).description = ...
            [testament.book(nbooks).description ' ' nline];
    nline = fgetl(fid);
    if isempty(nline)
      break
    end
  end
  
  % If it's empty, skip over the rest...
  if isempty(nline)
    continue;
  end  
  
  % If it matches ChapHdr...
  if isChapHdr(nline) 
    % Then we found a chapter!
    nms = regexp(nline,chapHdrRegExp,'names');
    chapFound = true;
    nchaps = nchaps + 1;

    if isempty(testament.book(nbooks).title)    
      % Go ahead a save the short title.
      testament.book(nbooks).title = nms.bookName;
      % Also initialize the chapsters for this book.
      testament.book(nbooks).chaps = struct;      
      % reset the title found flag
      titleFound = false;

    end
    % Save which chapter we are currenctly working in:
    lastChapNum = str2double(nms.chapNum);   
    
    % Now, once a Chapter Header is found, we know that the next line
    % should be a chapter line...
    
    % It will be either blank or match chapRegExp
    nline = fgetl(fid);
    % Check that it matches the chapRegExp
    nms = regexp(nline,chapRegExp,'names');
    if ~isempty(nms) && isfield(nms,'chap')
      % Then it DID match the chapter 
      % Let's double check that the chapter matches...
      assert(nchaps == lastChapNum)
      assert(nchaps == str2double(nms.chap))
      
      % Restart the verse counter...
      nverses= 0;
    end

    if isempty(nline)
      nchaps = nchaps + 1;
      nverses= 0;
      continue;
    end
    continue;
  end
  
  % Done with all the Chapter heading stuff...
  % If we made it here:
  % > nline is not empty.
  % > We are in a book.
  % > A chapter has been identified.
  % > We made it to the verses...

  % Is this a "verse header"?
  if isVerseHdr(nline)
    % We found a verse header!
    nverses = nverses + 1;

    % Check the verse number...      
    nms = regexp(nline,verseHdrRegExp,'names');
    if (nverses ~= str2double(nms.verse))
      keyboard
    end
    % Initialize the verse's text...
    testament.book(nbooks).chaps(nchaps).verse(nverses).text = '';
  else
    % This is NOT a verse header...
    % Is it the first line of the verse?
    if is1stLine(nline)
      % It IS the 1st line...
      nms = regexp(nline,verse1stLineRegExp,'names');
      testament.book(nbooks).chaps(nchaps).verse(nverses).text = nms.text;
    else
      % This is just another line of the previous verse...
      testament.book(nbooks).chaps(nchaps).verse(nverses).text = ...
        [ testament.book(nbooks).chaps(nchaps).verse(nverses).text ...
          ' ' nline ];
    end
  end
end

clearvars('-except','testament');
