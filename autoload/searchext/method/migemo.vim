ruby module SearchExt module Method module Migemo @io = IO.popen(VIM.evaluate('searchext#method#migemo#command'), 'r+') end end end

function searchext#method#migemo#Regexp(pattern)
  ruby << EOF
  module SearchExt::Method::Migemo
    @io.puts VIM.evaluate('a:pattern')
    VIM.command("return '#{@io.gets.chomp.gsub("'", "''")}'")
  end
EOF
endfunction
