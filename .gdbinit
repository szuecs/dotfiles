define loadfs 
  attach $arg0
  p (char)[[NSBundle bundleWithPath:@"/Library/Frameworks/FScript.framework"] load]
  p (void)[FScriptMenuItem insertInMainMenu]
  continue 
end
