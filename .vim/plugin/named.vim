

function! UPDSERIAL(date, num) 
    if (strftime("%Y%m%d") == a:date) 
        return a:date . a:num+1 
    endif 
    return strftime("%Y%m%d") . '01' 
endfunction 

command Soa :%s/\(2[0-9]\{7}\)\([0-9]\{2}\)\(\s\+;\s\+Serial\)/\=UPDSERIAL(submatch(1), submatch(2)) . submatch(3)/igc
