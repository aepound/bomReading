function out = writeBookDB(testament,book)
%book = 1;

getVerse = @(T,bk,ch,vs) T.book(strcmp(bk,{T.book,title})).chaps(ch).verse(vs).text;
getVerseNum = @(T,bk,ch,vs) T.book(bk).chaps(ch).verse(vs).text;

% This will produce a Latex Variable name that I can use.
nsBookName = regexprep(testament.book(book).title,'(\d*) (\w+)','$2$1');

newDB = @(name) ['\DTLnewdb{' name '}'];

fname = [nsBookName '.tex'];
fid = fopen(fname,'wt');

fprintf(fid,'%s\n',newDB(nsBookName));

nchaps = length(testament.book(book).chaps);

s.book = testament.book(book).title;
s.bookNum= num2str(book);
for citer = 1:nchaps
  nverses = length(testament.book(book).chaps(citer).verse);
  s.chapNum = num2str(citer);
  for viter = 1:nverses
    s.verseNum = num2str(viter);
    s.verseTxt = getVerseNum(testament,book,citer,viter);
    
    output = newDBentry(nsBookName,s);
    cellfun(@(x)fprintf(fid,'%s\n',x),output);
  end
end
fclose(fid);
out = true;
end

function output = newDBentry(dbname, s)
% s is a struct with the fields that should be written into the DB...

output = {['\DTLnewrow{' dbname '}']};
fldnames = fieldnames(s);
for f  = 1:length(fldnames)
  output = [output; ...
            {['\DTLnewdbentry{' dbname '}{' fldnames{f} '}{' s.(fldnames{f}) '}']} ];
end

end


