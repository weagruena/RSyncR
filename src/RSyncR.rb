# RSyncR - Incremental backups with RSYNC
#!/usr/bin/env ruby
#
require 'fileutils'
require 'logger'
require 'optparse'
require 'yaml'

Version = "0.1"

#~ # ---------------------- Subroutines ---------------------------
def config
   cfile = 'RSyncR.ini'
   if File.exists?(cfile)
      @cfg = YAML.load_file(cfile)
      # Settings
      @rsync = @cfg['settings']['rsync']
      @temp = @cfg['settings']['temp']
      @profiles = @cfg['profiles']
   else
      puts 'Error loading configuration file: ' + cfile
      exit
   end
end

def cygwinpath(dir)
   if dir =~ /\/\//
      # UNC path
      path = dir
   else
      path = "/cygdrive/#{dir.gsub(/:/, "")}"
   end
	return path	
end

def backup(profile, logging)
   cmd = "#{@rsync} #{@profiles[profile]['options']}"
	dest = @profiles[profile]['dest']
	if !File.exists?(dest)
		FileUtils.mkdir_p dest
	end
	csrc = cygwinpath(@profiles[profile]['src'])
	cdest = cygwinpath(@profiles[profile]['dest'])
   if File.exists?("#{dest}/first")
		cmd = "#{cmd} --link-dest=#{cdest}/first #{csrc} #{cdest}/#{Time.now.strftime("%d.%m.%y_%H%M")}"
	else
		cmd = "#{cmd} #{csrc} #{cdest}/first"
	end
   if logging != ''
      @log = Logger.new("#{@temp}/#{logging}")
      @log.level = Logger::INFO
      @log.progname = "RSyncR"
      @log.datetime_format = "%Y-%m-%d %H:%M:%S"	
   end
   @log.info("#{ENV['USERID']} | Profile: #{profile}") if @log          
   @log.info("############ BACKUP #############") if @log
	@log.info("Project: " + @profiles[profile]['name']) if @log
	@log.info("Source: " + @profiles[profile]['src']) if @log
	@log.info("Destination: " + dest) if @log
   @log.info("Command: " + cmd) if @log
   @log.info("#################################") if @log
	   
	IO.popen(cmd, "r") do |l| 
		lines = l.readlines
		lines.each do |line|
			@log.info(line) if @log
		end
	end
end

#~ # ---------------------- Options ---------------------------
@options = {}
opts = OptionParser.new do |o|
	o.banner = "\n*** RSyncR (Incremental backup with RSYNC) ***
----------------------------------------------------
(C) 2012 Andreas Weber (ruby.gruena.net)
Usage:
	
"
	@options[:profile] = nil
	o.on("-p", "--profile PROFILE", "Backup / Rsync with profile PROFILE (*)") do |profile|
		@options[:profile] = profile
	end
	
	o.on_tail("-h", "--help", "Display this screen.") do
		puts o
		exit
	end	
   
	o.on_tail("-v", "--version", "Show version.") do
		puts o.ver
		puts "Written by Andreas Weber\n"
		puts "Copyright (C) 2012 ruby.gruena.net"
		exit
	end
end

#~ # ---------------------- Main program ---------------------------
begin
   config()
	opts.parse!( ARGV )		
   #~ # START backup
   prof = @options[:profile]
   log = @profiles[prof]['logfile']  
   logf = "#{@temp}/#{log}"
   puts "Start backup process ...\nLogging see file: #{logf}"
   backup(prof, log)
   puts "Backup finshed."
   
rescue => exc
	STDERR.puts "Error: #{exc.message}"
	STDERR.puts opts.to_s
	exit 1
end