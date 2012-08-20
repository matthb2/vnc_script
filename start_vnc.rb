#!/usr/bin/ruby -W0

require 'pty'
require 'optparse'

VNCPASSTYPE=:stdin
VNCPASS='/opt/tigervnc/bin/vncpasswd'
VNCSERVER='/opt/tigervnc/bin/vncserver'
SCRIPT_HOME='/opt/vnc_script'
RANDPASS='/opt/vnc_script/randpass'
SSHGATEWAY='jumpgate'
res="1024x768" #default screen size

#filter options
optparser = OptionParser.new { |opts|
	opts.banner = "Usage: start_vnc [options]"
	opts.on("-g WxL","--geometry WxL", "Set Screen size") { |size|
		res=size
	}
	opts.on("-h", "--help", "Show this message") {
		puts opts
		exit
	}
}

optparser.parse!
password = %x["#{RANDPASS}"]
vnchome=(ENV["HOME"].dup).concat("/.vnc")

if File.directory?(vnchome) then
puts "About to edit your VNC settings (without backing them up"
puts "Is this ok? (enter \"Y\" or \"n\")"
ok = "e"
done=false
	while !done do
		tmp = STDIN.read(1)
		ok = tmp unless tmp == "\n"
		if ok == "Y" then
			done=true
		else
			exit if ok.downcase == "n"
			puts "Enter either \"Y\" or \"n\"" unless tmp == "\n"
		end
	end
else
	if File.exists?(vnchome) then
		puts ".vnc isn't a usable directory.. delete it and try again"
		Kernel.exit(1)
	end
	Kernel.system("mkdir -p ~/.vnc")	
end
Kernel.system("cp #{SCRIPT_HOME}/xstartup ~/.vnc/")
#if the vncpasswd implementation uses getpass() then we have to hook to the 
#tty 
if VNCPASSTYPE == :getpass then
	PTY.spawn(VNCPASS) { |r,w,pid|
		begin
			w.write(password.concat("\n"))
			w.write(password.concat("\n"))
		rescue PTY::ChildExited
			puts "Child Died"
		end
	}
end
#otherwise we can just popen() and go. 
if VNCPASSTYPE == :stdin then
	begin
		p = IO.popen(VNCPASS,"w+")
		p.write(password)
		p.write(password.concat("\n"))
		p.flush()
	rescue
		puts "Error Setting Password"
	end
	begin
		p.write("\n") #shouldn't be needed, ensures that we're done
	rescue 
	end
end

svr = IO.popen("#{VNCSERVER} -geometry #{res} 2>&1")
svr_o = svr.readlines
server_num = -1
i=0
while server_num < 0 do
	if i>svr_o.size then
		puts "Something Bad Happened"
		exit
	end
	if svr_o[i].match("desktop is.*") != nil then
		server_num = svr_o[i].match("desktop is.*").to_s.match(":[0-9]+").to_s.split(":")[1].to_i
		puts "match"
	end
	i=i+1
end
port = 5900 + server_num.to_i

puts "Your VNC Server is started"
puts "You should connect to #{port} on #{%x[hostname]}"
puts "you can use ssh -Ln:localhost:#{port} on #{%x[hostname]}"
puts "where n is a free port on your machine"
puts "you can then connect with vncviewer localhost:n"
puts "when you're done please run stop_vnc.sh"
puts "Your password is #{password}"
puts "You can change it by running #{VNCPASS} but be warned that VNC"
puts "is NOT a secure protocol (don't use an important password)"

puts "If you need to forward your connection to the outside world" 
puts "you can use ssh -L5905:#{%x[hostname].split("\n")[0]}:#{port} #{%x[whoami].split("\n")[0]}@#{SSHGATEWAY}"
puts "on your client machine"
puts "and connect vncviewer to \"localhost:5\""
