module Msf::Ui::Console::CommandDispatcher::Analyze

  def cmd_analyze_help
    print_line "Usage: analyze [addr1 addr2 ...]"
    print_line
  end

  def cmd_analyze(*args)
    unless active?
      print_error "Not currently connected to a data service for analysis."
      return []
    end

    host_ranges = []

    while (arg = args.shift)
      case arg
        when '-h','help'
          cmd_analyze_help
          return
        else
          (arg_host_range(arg, host_ranges))
      end
    end

    host_ranges.push(nil) if host_ranges.empty?

    host_ids = []
    suggested_modules = {}
    each_host_range_chunk(host_ranges) do |host_search|
      next if host_search && host_search.empty?
      eval_hosts_ids = framework.db.hosts(address: host_search).map(&:id)
      if eval_hosts_ids
        eval_hosts_ids.each do |eval_id|
          host_ids.push(eval_id)
        end
      end
    end

    if host_ids.empty?
      print_status("No existing hosts stored to analyze.")
    else

      host_ids.each do |id|
        eval_host = framework.db.hosts(id: id).first
        next unless eval_host
        print_status("Analyzing #{eval_host.address}...")
        unless eval_host.vulns
          print_status("No suggestions for #{eval_host.address}.")
          next
        end

        reported_module = false
        host_result = framework.analyze.host(eval_host)
        found_modules = host_result[:modules]
        found_modules.each do |fnd_mod|
          print_status(fnd_mod.fullname)
          reported_module = true
        end

        suggested_modules[eval_host.address] = found_modules

        print_status("No suggestions for #{eval_host.address}.") unless reported_module
      end
    end
    suggested_modules
  end

  def cmd_analyze_tabs(_str, words)
    return [] unless framework.db.active

    hosts = framework.db.hosts.map(&:address)

    # Limit completion to supplied host if it's the only one
    return [] if words.length > 1 && hosts.length == 1

    hosts
  end

end
