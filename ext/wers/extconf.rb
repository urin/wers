require 'mkmf'
require 'fileutils'
require 'win32ole'

here = File.dirname(__FILE__)
ins_path = File.expand_path('~/.wers/')
['lib', 'bin'].each { |p|
  FileUtils.copy_entry(
    "#{here}/../../#{p}", FileUtils.mkdir_p("#{ins_path}/#{p}").first
  )
}
bin_path_win = "#{ins_path}/bin".gsub('/', '\\').chomp('\\')
user_env_path = WIN32OLE.new("WScript.Shell").Environment("USER").Item("PATH").chomp('\\')
unless user_env_path.upcase.include?(bin_path_win.upcase)
  if user_env_path.empty?
    `setx PATH "#{bin_path_win}"`
  else
    `setx PATH "#{user_env_path + ';' + bin_path_win}"`
  end
end

BASH_CONFIG = File.expand_path('~/.bashrc')
ALIAS_COMMAD = "alias wers='. wers ~/.wers/bin/wers'"
if File.file? BASH_CONFIG
  File.write(BASH_CONFIG,
    [
      File.read(BASH_CONFIG).sub(/^\s*alias\s+wers\s*=.*$/, '').rstrip,
      ALIAS_COMMAD
    ].join("\n")
  )
else
  File.write(BASH_CONFIG, ALIAS_COMMAD)
end

create_makefile('wers/wers')

