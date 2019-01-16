# Unless explicitly stated otherwise all files in this repository are licensed
# under the Apache License Version 2.0.
# This product includes software developed at Datadog (https:#www.datadoghq.com/).
# Copyright 2016-2019 Datadog, Inc.

require "./lib/ostools.rb"
require 'pathname'

name "datadog-trace-agent"

dependency "datadog-agent"

trace_agent_version = ENV['TRACE_AGENT_VERSION']
if trace_agent_version.nil? || trace_agent_version.empty?
  trace_agent_version = 'master'
end
default_version trace_agent_version

source path: '..'
relative_path 'src/github.com/DataDog/datadog-agent'

if windows?
  trace_agent_binary = "trace-agent.exe"
else
  trace_agent_binary = "trace-agent"
end

build do
  ship_license "https://raw.githubusercontent.com/DataDog/datadog-trace-agent/#{version}/LICENSE"
  # set GOPATH on the omnibus source dir for this software
  gopath = Pathname.new(project_dir) + '../../../..'
  if windows?
    env = {
      # Trace agent uses GNU make to build.  Some of the input to gnu make
      # needs the path with `\` as separators, some needs `/`.  Provide both,
      # and let the makefile sort it out (ugh)

      # also on windows don't modify the path.  Modifying the path here mixes
      # `/` with `\` in the PATH variable, which confuses the make (and sub-processes)
      # below.  When properly configured the path on the windows box is sufficient.
      'GOPATH' => "#{windows_safe_path(gopath.to_path)}",
    }
  else
    env = {
      'GOPATH' => gopath.to_path,
      'PATH' => "#{gopath.to_path}/bin:#{ENV['PATH']}",
    }
  end

  block do
    # defer compilation step in a block to allow getting the project's build version, which is populated
    # only once the software that the project takes its version from (i.e. `datadog-agent`) has finished building
    env['TRACE_AGENT_VERSION'] = project.build_version.gsub(/[^0-9\.]/, '') # used by gorake.rb in the trace-agent, only keep digits and dots

    # build trace-agent
    if windows?
      maj_ver, min_ver, patch_ver = trace_agent_version.split('.')
      maj_ver ||= "0"
      min_ver ||= "99"
      patch_ver ||= "0"

      command "windmc --target pe-x86-64 -r cmd/trace-agent/windows_resources cmd/trace-agent/windows_resources/trace-agent-msg.mc", :env => env
      command "windres --define MAJ_VER=#{maj_ver} --define MIN_VER=#{min_ver} --define PATCH_VER=#{patch_ver} -i cmd/trace-agent/windows_resources/trace-agent.rc --target=pe-x86-64 -O coff -o cmd/trace-agent/rsrc.syso", :env => env
    end

    command "go generate ./pkg/trace/info", :env => env
    command "go install ./cmd/trace-agent", :env => env

    # copy binary
    if windows?
      #copy "#{gopath.to_path}/bin/#{trace_agent_binary}", "#{install_dir}/bin/agent"
      copy "#{gopath.to_path}/bin/#{trace_agent_binary}", "#{Omnibus::Config.source_dir()}/datadog-agent/src/github.com/DataDog/datadog-agent/bin/agent"
    else
      copy "#{gopath.to_path}/bin/#{trace_agent_binary}", "#{install_dir}/embedded/bin"
    end
  end
end
