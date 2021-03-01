##
# This module requires Metasploit: https://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

class MetasploitModule < Msf::Post
  include Msf::Post::Windows::Priv
  include Msf::Post::Windows::ShadowCopy

  include Msf::Module::Deprecated
  deprecated(Date.new(2021, 4, 11), reason="Use post/windows/manage/vss and the VSS_SET_MAX_STORAGE_SIZE action")

  def initialize(info={})
    super(update_info(info,
      'Name'                 => "Windows Manage Set Shadow Copy Storage Space",
      'Description'          => %q{
        This module will attempt to change the amount of space
        for volume shadow copy storage. This is based on the
        VSSOwn Script originally posted by Tim Tomes and
        Mark Baggett.

        Works on win2k3 and later.
        },
      'License'              => MSF_LICENSE,
      'Platform'             => ['win'],
      'SessionTypes'         => ['meterpreter'],
      'Author'               => ['theLightCosine'],
      'References'    => [
        [ 'URL', 'http://pauldotcom.com/2011/11/safely-dumping-hashes-from-liv.html' ]
      ]
    ))
    register_options(
      [
        OptInt.new('SIZE', [ true, 'Size in bytes to set for Max Storage'])
      ])

  end


  def run
    unless is_admin?
      print_error("This module requires admin privs to run")
      return
    end
    if is_uac_enabled?
      print_error("This module requires UAC to be bypassed first")
      return
    end
    unless start_vss
      return
    end
    if vss_set_storage(datastore['SIZE'])
      print_good("Size updated successfully")
    else
      print_error("There was a problem updating the storage size")
    end
  end



end
