#!/usr/bin/env ruby

require 'msfenv'
require 'msf/base'

def init_framework(create_opts={})
  create_opts[:module_types] ||= [
    ::Msf::MODULE_PAYLOAD, ::Msf::MODULE_ENCODER
  ]

  create_opts[:module_types].map! do |type|
    Msf.const_get("MODULE_#{type.upcase}")
  end

  @framework = ::Msf::Simple::Framework.create(create_opts.merge('DisableDatabase' => true))
end

def framework
  return @framework if @framework

  init_framework

  @framework
end

def dump_platforms
  tbl = []
  init_framework(:module_types => [])
  supported_platforms = []
  Msf::Module::Platform.subclasses.each {|c| supported_platforms << c.realname.downcase}
  supported_platforms.sort.each do |name|
    tbl << name
  end
  tbl.join(' ')
end

def dump_archs
  tbl = []
  init_framework(:module_types => [])
  supported_archs = ARCH_ALL.dup
  supported_archs.sort.each do |name|
    tbl << name
  end
  tbl.join(' ')
end

def dump_encrypts
  tbl = []
  init_framework(:module_types => [])
  ::Msf::Simple::Buffer.encryption_formats.each do |name|
    tbl << name
  end
  tbl.join(' ')
end

def dump_formats
  tbl = []
  init_framework(:module_types => [])
  [::Msf::Util::EXE.to_executable_fmt_formats, ::Msf::Simple::Buffer.transform_formats].each do |name|
    tbl << name
  end
  tbl.join(' ')
end

def dump_payloads
  tbl = []
  init_framework(:module_types => [ :payload ])
  framework.payloads.each_module() do |name|
    tbl << name
  end
  tbl.join(' ')
end

def dump_encoders
  tbl = []
  init_framework(:module_types => [ :encoder ])
  framework.encoders.each_module do |name|
    tbl << name
  end
  tbl.join(' ')
end

puts '
_msfvenom() {
  COMPREPLY=()
  local cur=$(_get_cword)
  local prev=$(_get_pword)

  case $prev in
    -l|--list)
     COMPREPLY=( $( compgen -W \' payloads encoders nops platforms archs encrypt formats all \' -- "$cur" ) )
      return 0
      ;;
    -f|--format)
      COMPREPLY=( $( compgen -W \' %s \' -- "$cur" ) )
      return 0
      ;;
    -e|--encoder)
      COMPREPLY=( $( compgen -W \' %s \' -- "$cur" ) )
      return 0
      ;;
    -p|--payload)
      COMPREPLY=( $( compgen -W \' %s \' -- "$cur" ) )
      return 0
      ;;
    -a|--arch)
      COMPREPLY=( $( compgen -W \' %s \' -- "$cur" ) )
      return 0
      ;;
    --platform)
      COMPREPLY=( $( compgen -W \' %s \' -- "$cur" ) )
      return 0
      ;;
    --encrypt)
      COMPREPLY=( $( compgen -W \' %s \' -- "$cur" ) )
      return 0
      ;;
    -o|--out|-c|--add-code|-x|--template)
      _filedir
      return 0
      ;;
  esac

  COMPREPLY=( $( compgen -W \' -l --list -p --payload --list -options -f --format -e --encoder --service -name --sec -name --smallest --encrypt --encrypt -key --encrypt -iv -a --arch --platform -o --out -b --bad -chars -n --nopsled --pad -nops -s --space --encoder -space -i --iterations -c --add -code -x --template -k --keep -v --var -name -t --timeout -h --help \' -- "$cur" ) )
} &&
complete -F _msfvenom msfvenom
' % [dump_formats, dump_encoders, dump_payloads, dump_archs, dump_platforms, dump_encrypts]
