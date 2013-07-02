COMMAND_NAME = File.basename(__FILE__, '.*')
require "#{File.dirname(__FILE__)}/#{COMMAND_NAME}/version"

exit if File.expand_path($0) != File.expand_path(__FILE__)

require 'yaml'
require 'win32ole'

USER_CONFIG_FILE = File.expand_path("~/.#{COMMAND_NAME}/config.yml")
LOCAL_CONFIG_FILE = "./.ruby-version"

$args = [
  [:init,    1..1, "Initialize #{COMMAND_NAME} with current available Ruby."],
  [:list,    0..0, "List all Ruby versions known by #{COMMAND_NAME}."],
  [:add,     1..2, "Add specified version of Ruby to #{COMMAND_NAME}."],
  [:delete,  1..1, "Delete specified version of Ruby from #{COMMAND_NAME}."],
  [:global,  0..1, "Set or show the global Ruby version."],
  [:local,   0..1, "Set or show the local directory-specific Ruby version."],
  [:shell,   1..1, "Set or show the shell-specific Ruby version."],
  [:version, 0..0, "Show the current Ruby version."],
  [:help,    0..0, "Show this help."]
]

#-------------------------------------------------------------------------------
# Define command method
#-------------------------------------------------------------------------------
def help(errmsg = "")
  puts(errmsg.empty? ? "" : "Error: #{errmsg}")
  unless [:global, :local, :shell].include?($command)
    puts(
"#{errmsg.empty? ? "" : "\n"}#{COMMAND_NAME} #{Wers::VERSION} - Manage multiple Ruby versions for Microsoft Windows

Usage:
  #{COMMAND_NAME} command [options...]

Commands:
#{
    len = $args.transpose[0].map { |c| c.length }.max
    $args.map { |a| sprintf("  %-#{len}s  %s", a[0], a[2]) }.join("\n")
}"
    )
  end
  exit
end

def list
  rubies = $config[:global]["rubies"]
  namelen = rubies.keys.map { |name| name.length }.max
  rubies.each { |name, path|
    using = ($config[:using].has_key?(name)) ? '=>' : ''
    local = (name == $config[:local]) ? '<local>' : ''
    global = (name == $config[:global]["default"]) ? '<global>' : ''
    printf("%2s %7s %8s  %-#{namelen}s : (%s)\n", using, local, global, name, path)
  }
end

def init
  add
end

def add
  name = (
    if $options.length == 2
      $options.shift
    else
      ruby = File.expand_path($options[0]) + '/ruby.exe'
      if File.executable?(ruby)
        `#{ruby + ' -e "puts RUBY_VERSION"'}`.chomp
      else
        help("No such Ruby in #{$options[0]}.")
      end
    end
  )
  rubies = $config[:global]["rubies"]
  rubies[name] = $options.shift.chomp('\\')
  $config[:global]["rubies"] = Hash[rubies.sort]
  if $command == :init
    $config[:global]["default"] = name
    $config[:using] = $config[:global]["rubies"]
  end
  save_config
  list
end

def delete
  name = $options.shift
  unless $config[:global]["rubies"].delete(name)
    help("No such Ruby named #{name}")
  end
  save_config
  list
end

def shell
  apply_new_path($options[0])
end

def local
  name = $options.length == 1 ? $options[0] : $config[:local] || $config[:using].keys[0]
  unless $config[:global]["rubies"].has_key?(name)
    help("No such Ruby version #{name} in #{COMMAND_NAME}.")
  end
  if(File.file?(LOCAL_CONFIG_FILE) && !File.writable?(LOCAL_CONFIG_FILE) or
    !File.file?(LOCAL_CONFIG_FILE) && !File.writable?(File.dirname(LOCAL_CONFIG_FILE)))
    help("Can't write #{LOCAL_CONFIG_FILE}.")
  end
  open(LOCAL_CONFIG_FILE, 'w') { |f| f.print(name) }
  apply_new_path(name)
end

def global
  if $options.length == 1
    unless $config[:global]["rubies"].has_key?($options[0])
      help("No such Ruby version #{$options[0]} in #{COMMAND_NAME}.")
    end
    unless File.writable?(USER_CONFIG_FILE)
      help("Can't write #{USER_CONFIG_FILE}.")
    end
    $config[:global]["default"] = $options.shift
    save_config
  else
    unless $config[:global].has_key?("default")
      help("Global default Ruby does not exist in #{USER_CONFIG_FILE}.")
    end
  end
  apply_new_path($config[:global]["default"])
  `setx /m PATH "#{
    ($env_path[:system].split(';') - $config[:global]["rubies"].values).unshift(
      $config[:global]["rubies"][$config[:global]["default"]]
    ).join(';')
  }"`
end

def version
  if $config[:using].empty?
    help("Current using Ruby does not exist. Do `#{COMMAND_NAME} init` first.")
  end
  name = $config[:using].keys[0]
  local = (name == $config[:local]) ? ' <local>' : ''
  global = (name == $config[:global]["default"]) ? ' <global>' : ''
  path = $config[:using].values[0]
  printf("=>%s%s %s : (%s)\n", local, global, name, path)
  path = File.expand_path(path)
  %w[ruby.exe irb rake gem ri bundle].each { |f|
    fullpath = "#{path}/#{f}"
    if File.file?(fullpath)
      printf("   %-8s - %s\n", f.capitalize, `#{fullpath} --version`)
    end
  }
end

#-------------------------------------------------------------------------------
# Private
#-------------------------------------------------------------------------------
def load_config
  if $command == :init
    user_config = { "default" => "", "rubies" => {} }
    using = {}
  else
    unless File.readable?(USER_CONFIG_FILE)
      help("Configuration file #{USER_CONFIG_FILE} does not exist. Do `#{COMMAND_NAME} init` first.")
    end
    user_config = YAML.load_file(USER_CONFIG_FILE)
    path = $env_path[:current].split(';')
    using = Hash[user_config["rubies"].select { |name, dir|
      path.index { |p| p.casecmp(dir) == 0 }
    }]
  end
  local_config = (
    File.readable?(LOCAL_CONFIG_FILE) ? open(LOCAL_CONFIG_FILE).read.chomp : ""
  )
  { :global => user_config, :local => local_config, :using => using }
end

def save_config
  open(USER_CONFIG_FILE, 'w') { |f| f.print($config[:global].to_yaml) }
end

def apply_new_path(name)
  unless $config[:global]["rubies"].has_key?(name)
    help("No such Ruby version #{name} in #{COMMAND_NAME}.")
  end
  new_path = $config[:global]["rubies"][name].chomp('\\')
  unless File.directory?(new_path)
    help("No such directory #{new_path} of #{name}.")
  end
  current_path = $env_path[:current].split(';')
  $config[:global]["rubies"].values.each { |config|
    current_path.delete_if { |path|
      path.chomp('\\').casecmp(config.chomp('\\')) == 0
    }
  }
  print(current_path.unshift(new_path).join(';').gsub('\\', '\\\\').gsub(/[()?*%<>|"'^]/, '^\0'))
end

#-------------------------------------------------------------------------------
# Main
#-------------------------------------------------------------------------------
$command = nil
if ARGV.length == 0
  help
end
$command = ARGV.shift.downcase.to_sym
parameter = $args.assoc($command)
unless parameter
  help("Invalid command #{$command}.")
end
unless parameter[1].include?(ARGV.length)
  help("Invalid number of options for command #{$command}.")
end

wsh = WIN32OLE.new("WScript.Shell")
$env_path = {
  :system  => wsh.Environment("SYSTEM").Item("PATH"),
  :user    => wsh.Environment("USER"  ).Item("PATH"),
  :current => ENV["PATH"]
}
$options = ARGV.map { |arg| arg.tr('"', '') }
$config = load_config
send($command)

