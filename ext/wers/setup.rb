require 'mkmf'
require 'fileutils'

here = File.dirname(__FILE__)
ins_path = File.expand_path('~/.wers/')
lib_path = "#{ins_path}/lib"
bin_path = "#{ins_path}/bin"
FileUtils.mkdir_p([lib_path, bin_path])
FileUtils.copy_entry("#{here}/../../lib", lib_path)
FileUtils.copy_entry("#{here}/../../bin", bin_path)

bin_path_win = bin_path.gsub('/', '\\').chomp('\\')
user_env_path = WIN32OLE.new("WScript.Shell").Environment("USER").Item("PATH").chomp('\\')
unless user_env_path.upcase.include?(bin_path_win.upcase)
  if user_env_path.empty?
    `setx PATH "#{bin_path_win}"`
  else
    `setx PATH "#{user_env_path + ';' + bin_path_win}"`
  end
end
create_makefile('wers/wers')
